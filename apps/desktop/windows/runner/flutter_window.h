#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  // Tray mode: when armed, a close request (the window's X button, or a
  // WM_CLOSE from anywhere) hides the window instead of destroying it, so the
  // process keeps running with only a tray icon.
  void SetHideOnClose(bool hide_on_close);

  // Shows and focuses the window again (called from Dart when the user picks
  // "show window" in the tray menu).
  void ShowWindowFromDart();

  // The messenger of the hosted engine, used to set up method channels.
  flutter::BinaryMessenger* GetBinaryMessenger();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Whether WM_CLOSE should hide the window instead of destroying it.
  bool hide_on_close_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
