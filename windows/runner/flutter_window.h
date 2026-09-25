#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  static LRESULT CALLBACK DropTargetSubclassProc(
      HWND window, UINT message, WPARAM wparam, LPARAM lparam,
      UINT_PTR subclass_id, DWORD_PTR reference_data);
  void HandleDroppedFiles(HDROP drop);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> incoming_book_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> desktop_window_channel_;
  bool close_request_pending_ = false;
  bool allow_close_ = false;
  HWND drop_target_window_ = nullptr;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
