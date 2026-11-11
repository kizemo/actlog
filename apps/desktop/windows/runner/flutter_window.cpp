#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

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
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::SetHideOnClose(bool hide_on_close) {
  hide_on_close_ = hide_on_close;
}

void FlutterWindow::ShowWindowFromDart() {
  HWND handle = GetHandle();
  if (handle == nullptr) {
    return;
  }
  ShowWindow(handle, SW_SHOW);
  SetForegroundWindow(handle);
}

flutter::BinaryMessenger* FlutterWindow::GetBinaryMessenger() {
  if (!flutter_controller_ || !flutter_controller_->engine()) {
    return nullptr;
  }
  // NOTE: the FlutterEngine accessor is messenger(), not binary_messenger().
  return flutter_controller_->engine()->messenger();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Tray mode is handled here, on purpose, BEFORE the plugin hook and before
  // DefWindowProc:
  //   * DefWindowProc on WM_CLOSE destroys the window, which ends the Flutter
  //     message loop and quits the process - the app would disappear from the
  //     taskbar and from the tray at the same time;
  //   * a plugin level "prevent close" only covers the closes that the plugin
  //     itself raises, not the WM_CLOSE that Windows sends when the user
  //     clicks the X button.
  // So the X button is turned into "hide to tray" right here.
  if (message == WM_CLOSE && hide_on_close_) {
    ShowWindow(hwnd, SW_HIDE);
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
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
