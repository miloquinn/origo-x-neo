#include "flutter_window.h"

#include <optional>
#include <shellapi.h>
#include <commctrl.h>
#include <chrono>
#include <variant>

#include <flutter/method_result_functions.h>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

constexpr wchar_t kWindowStateKey[] = L"Software\\Origo X";
constexpr wchar_t kWindowBoundsValue[] = L"MainWindowBounds";

void RestoreWindowBounds(HWND window) {
  RECT bounds{};
  DWORD size = sizeof(bounds);
  if (::RegGetValueW(HKEY_CURRENT_USER, kWindowStateKey, kWindowBoundsValue,
                     RRF_RT_REG_BINARY, nullptr, &bounds, &size) !=
          ERROR_SUCCESS ||
      size != sizeof(bounds) || bounds.right - bounds.left < 640 ||
      bounds.bottom - bounds.top < 480) {
    return;
  }
  if (::MonitorFromRect(&bounds, MONITOR_DEFAULTTONULL) == nullptr) return;
  ::SetWindowPos(window, nullptr, bounds.left, bounds.top,
                 bounds.right - bounds.left, bounds.bottom - bounds.top,
                 SWP_NOZORDER | SWP_NOACTIVATE);
}

void SaveWindowBounds(HWND window) {
  if (::IsIconic(window)) return;
  WINDOWPLACEMENT placement{};
  placement.length = sizeof(placement);
  if (!::GetWindowPlacement(window, &placement)) return;
  const RECT bounds = placement.rcNormalPosition;
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kWindowStateKey, kWindowBoundsValue,
                    REG_BINARY, &bounds, sizeof(bounds));
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RestoreWindowBounds(GetHandle());

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  incoming_book_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.niki.xxread/incoming_books",
          &flutter::StandardMethodCodec::GetInstance());
  incoming_book_channel_->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() == "getInitialIncomingBooks") {
          result->Success(flutter::EncodableValue(flutter::EncodableList{}));
        } else if (call.method_name() == "completeIncomingRequest") {
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }
      });
  desktop_window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.niki.xxread/desktop_window",
          &flutter::StandardMethodCodec::GetInstance());
  drop_target_window_ = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(drop_target_window_);
  ::SetWindowSubclass(drop_target_window_, DropTargetSubclassProc, 1,
                      reinterpret_cast<DWORD_PTR>(this));
  ::DragAcceptFiles(drop_target_window_, TRUE);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    if (drop_target_window_) {
      ::DragAcceptFiles(drop_target_window_, FALSE);
      ::RemoveWindowSubclass(drop_target_window_, DropTargetSubclassProc, 1);
      drop_target_window_ = nullptr;
    }
    incoming_book_channel_.reset();
    desktop_window_channel_.reset();
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // The close request must reach Dart before the engine can process WM_CLOSE;
  // an active reader may turn it into a route pop instead of destroying the
  // native window.
  if (message == WM_CLOSE) {
    SaveWindowBounds(hwnd);
    if (allow_close_ || !desktop_window_channel_) {
      return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
    }
    if (close_request_pending_) return 0;
    close_request_pending_ = true;
    desktop_window_channel_->InvokeMethod(
        "requestClose", nullptr,
        std::make_unique<
            flutter::MethodResultFunctions<flutter::EncodableValue>>(
            [this](const flutter::EncodableValue* value) {
              close_request_pending_ = false;
              const bool handled =
                  value != nullptr && std::holds_alternative<bool>(*value) &&
                  std::get<bool>(*value);
              if (handled) return;
              allow_close_ = true;
              ::PostMessage(GetHandle(), WM_CLOSE, 0, 0);
            },
            [this](const std::string&, const std::string&,
                   const flutter::EncodableValue*) {
              close_request_pending_ = false;
              allow_close_ = true;
              ::PostMessage(GetHandle(), WM_CLOSE, 0, 0);
            },
            [this]() {
              close_request_pending_ = false;
              allow_close_ = true;
              ::PostMessage(GetHandle(), WM_CLOSE, 0, 0);
            }));
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_EXITSIZEMOVE:
      SaveWindowBounds(hwnd);
      break;
    case WM_DROPFILES:
      HandleDroppedFiles(reinterpret_cast<HDROP>(wparam));
      return 0;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK FlutterWindow::DropTargetSubclassProc(
    HWND window, UINT message, WPARAM wparam, LPARAM lparam,
    UINT_PTR subclass_id, DWORD_PTR reference_data) {
  (void)subclass_id;
  auto* self = reinterpret_cast<FlutterWindow*>(reference_data);
  if (message == WM_DROPFILES && self) {
    self->HandleDroppedFiles(reinterpret_cast<HDROP>(wparam));
    return 0;
  }
  return ::DefSubclassProc(window, message, wparam, lparam);
}

void FlutterWindow::HandleDroppedFiles(HDROP drop) {
  const UINT count = ::DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
  flutter::EncodableList items;
  for (UINT index = 0; index < count; ++index) {
    const UINT length = ::DragQueryFileW(drop, index, nullptr, 0);
    std::wstring path(length + 1, L'\0');
    ::DragQueryFileW(drop, index, path.data(), length + 1);
    path.resize(length);
    const auto utf8_path = Utf8FromUtf16(path);
    const auto separator = utf8_path.find_last_of("/\\");
    const auto name = separator == std::string::npos
                          ? utf8_path
                          : utf8_path.substr(separator + 1);
    flutter::EncodableMap item;
    item[flutter::EncodableValue("id")] =
        flutter::EncodableValue(std::to_string(index));
    item[flutter::EncodableValue("displayName")] =
        flutter::EncodableValue(name);
    item[flutter::EncodableValue("localPath")] =
        flutter::EncodableValue(utf8_path);
    items.emplace_back(item);
  }
  ::DragFinish(drop);
  if (!items.empty() && incoming_book_channel_) {
    const auto now =
        std::chrono::steady_clock::now().time_since_epoch().count();
    flutter::EncodableMap request;
    request[flutter::EncodableValue("requestId")] =
        flutter::EncodableValue("drop:" + std::to_string(now));
    request[flutter::EncodableValue("action")] =
        flutter::EncodableValue("open");
    request[flutter::EncodableValue("items")] =
        flutter::EncodableValue(items);
    incoming_book_channel_->InvokeMethod(
        "incomingBooks", std::make_unique<flutter::EncodableValue>(request));
  }
}
