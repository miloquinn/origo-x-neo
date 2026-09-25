#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <clocale>
#include <cstring>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

// Get localized app name based on system locale
static const char* get_localized_app_name() {
  // Try to get system locale
  const char* locale = setlocale(LC_ALL, nullptr);
  if (locale) {
    // Check if locale contains Chinese
    if (strstr(locale, "zh_CN") || strstr(locale, "zh_TW") ||
        strstr(locale, "zh-Hans") || strstr(locale, "zh-Hant") ||
        strstr(locale, "Chinese")) {
      return u8"开元阅读";
    }
  }
  // Default to English
  return "Origo X";
}

static void set_window_icon(GtkWindow* window) {
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* executable_path =
      g_file_read_link("/proc/self/exe", &error);
  if (executable_path == nullptr) {
    g_warning("Failed to locate executable for window icon: %s",
              error->message);
    return;
  }

  g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
  g_autofree gchar* icon_path =
      g_build_filename(executable_dir, "data", "flutter_assets", "assets",
                       "images", "app_icon_desktop.png", nullptr);
  if (!gtk_window_set_icon_from_file(window, icon_path, &error)) {
    g_warning("Failed to load window icon from %s: %s", icon_path,
              error->message);
  }
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* incoming_book_channel;
  FlMethodChannel* desktop_window_channel;
  GtkWindow* main_window;
  gboolean close_request_pending;
  gboolean allow_close;
  gint window_width;
  gint window_height;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static gchar* window_state_path() {
  g_autofree gchar* directory =
      g_build_filename(g_get_user_config_dir(), "origo-x", nullptr);
  g_mkdir_with_parents(directory, 0700);
  return g_build_filename(directory, "window-state.ini", nullptr);
}

static void restore_window_size(MyApplication* self, GtkWindow* window) {
  g_autofree gchar* path = window_state_path();
  g_autoptr(GKeyFile) state = g_key_file_new();
  if (!g_key_file_load_from_file(state, path, G_KEY_FILE_NONE, nullptr)) return;
  const gint width = g_key_file_get_integer(state, "window", "width", nullptr);
  const gint height = g_key_file_get_integer(state, "window", "height", nullptr);
  if (width >= 640 && height >= 480) {
    self->window_width = width;
    self->window_height = height;
    gtk_window_set_default_size(window, width, height);
  }
}

static void save_window_size(MyApplication* self) {
  const gint width = self->window_width;
  const gint height = self->window_height;
  if (width < 640 || height < 480) return;
  g_autoptr(GKeyFile) state = g_key_file_new();
  g_key_file_set_integer(state, "window", "width", width);
  g_key_file_set_integer(state, "window", "height", height);
  gsize length = 0;
  g_autofree gchar* data = g_key_file_to_data(state, &length, nullptr);
  g_autofree gchar* path = window_state_path();
  g_file_set_contents(path, data, length, nullptr);
}

static gboolean window_configure_event_cb(GtkWidget* widget,
                                          GdkEventConfigure* event,
                                          gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  const GdkWindowState state =
      gdk_window == nullptr ? static_cast<GdkWindowState>(0)
                            : gdk_window_get_state(gdk_window);
  if ((state & (GDK_WINDOW_STATE_MAXIMIZED | GDK_WINDOW_STATE_FULLSCREEN |
                GDK_WINDOW_STATE_ICONIFIED)) == 0) {
    self->window_width = event->width;
    self->window_height = event->height;
  }
  return FALSE;
}

static void desktop_close_response_cb(GObject* object, GAsyncResult* result,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  self->close_request_pending = FALSE;
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  gboolean handled = FALSE;
  if (response != nullptr) {
    FlValue* value = fl_method_response_get_result(response, &error);
    handled = value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
              fl_value_get_bool(value);
  }
  if (!handled && self->main_window != nullptr) {
    self->allow_close = TRUE;
    gtk_window_close(self->main_window);
  }
}

static gboolean window_delete_event_cb(GtkWidget*, GdkEvent*,
                                       gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  save_window_size(self);
  if (self->allow_close || self->desktop_window_channel == nullptr) return FALSE;
  if (self->close_request_pending) return TRUE;
  self->close_request_pending = TRUE;
  fl_method_channel_invoke_method(self->desktop_window_channel, "requestClose",
                                  nullptr, nullptr,
                                  desktop_close_response_cb, self);
  return TRUE;
}

static void incoming_method_call_cb(FlMethodChannel*, FlMethodCall* call,
                                    gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  if (strcmp(method, "getInitialIncomingBooks") == 0) {
    g_autoptr(FlValue) value = fl_value_new_list();
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(value));
    fl_method_call_respond(call, response, nullptr);
  } else if (strcmp(method, "completeIncomingRequest") == 0) {
    g_autoptr(FlValue) value = fl_value_new_bool(TRUE);
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(value));
    fl_method_call_respond(call, response, nullptr);
  } else {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(call, response, nullptr);
  }
}

static void books_dropped_cb(GtkWidget*, GdkDragContext*, gint, gint,
                             GtkSelectionData* data, guint, guint,
                             gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  g_auto(GStrv) uris = gtk_selection_data_get_uris(data);
  g_autoptr(FlValue) items = fl_value_new_list();
  for (guint index = 0; uris != nullptr && uris[index] != nullptr; ++index) {
    g_autofree gchar* path = g_filename_from_uri(uris[index], nullptr, nullptr);
    if (path == nullptr) continue;
    g_autofree gchar* name = g_path_get_basename(path);
    g_autoptr(FlValue) item = fl_value_new_map();
    fl_value_set_string_take(item, "id", fl_value_new_int(index));
    fl_value_set_string_take(item, "displayName", fl_value_new_string(name));
    fl_value_set_string_take(item, "localPath", fl_value_new_string(path));
    fl_value_append_take(items, fl_value_ref(item));
  }
  if (fl_value_get_length(items) > 0 && self->incoming_book_channel != nullptr) {
    g_autoptr(FlValue) request = fl_value_new_map();
    g_autofree gchar* request_id = g_strdup_printf("drop:%" G_GINT64_FORMAT,
                                                   g_get_monotonic_time());
    fl_value_set_string_take(request, "requestId", fl_value_new_string(request_id));
    fl_value_set_string_take(request, "action", fl_value_new_string("open"));
    fl_value_set_string_take(request, "items", fl_value_ref(items));
    fl_method_channel_invoke_method(self->incoming_book_channel, "incomingBooks",
                                    request, nullptr, nullptr, nullptr);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif

  const char* app_name = get_localized_app_name();

  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, app_name);
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, app_name);
  }

  set_window_icon(window);
  self->window_width = 1280;
  self->window_height = 720;
  gtk_window_set_default_size(window, 1280, 720);
  restore_window_size(self, window);
  self->main_window = window;
  g_signal_connect(window, "delete-event", G_CALLBACK(window_delete_event_cb),
                   self);
  g_signal_connect(window, "configure-event",
                   G_CALLBACK(window_configure_event_cb), self);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->incoming_book_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.niki.xxread/incoming_books", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->incoming_book_channel, incoming_method_call_cb, self, nullptr);
  self->desktop_window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.niki.xxread/desktop_window", FL_METHOD_CODEC(codec));

  GtkTargetEntry targets[] = {{const_cast<gchar*>("text/uri-list"), 0, 0}};
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, targets, 1,
                    GDK_ACTION_COPY);
  g_signal_connect(view, "drag-data-received", G_CALLBACK(books_dropped_cb), self);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->incoming_book_channel);
  g_clear_object(&self->desktop_window_channel);
  self->main_window = nullptr;
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
