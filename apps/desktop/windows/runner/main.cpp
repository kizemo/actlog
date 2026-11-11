#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"actlog", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Channel used by the Dart side to drive the runner level window behaviour.
  //
  // Why the runner needs to know at all: a plugin level "prevent close" only
  // covers the closes the plugin raises itself. The close button of the
  // window (and any other WM_CLOSE) ends up in DefWindowProc, which destroys
  // the window and quits the process - so "close hides to tray" would never
  // happen for the user. The runner therefore takes the WM_CLOSE itself and
  // hides the window instead, once Dart says the tray is ready.
  flutter::MethodChannel<flutter::EncodableValue> window_channel(
      window.GetBinaryMessenger(), "actlog/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel.SetMethodCallHandler(
      [&window](const flutter::MethodCall<flutter::EncodableValue>& call,
                 std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                     result) {
        const std::string& method = call.method_name();
        if (method == "setHideOnClose") {
          window.SetHideOnClose(true);
          result->Success(flutter::EncodableValue(true));
        } else if (method == "showWindow") {
          window.ShowWindowFromDart();
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }
      });

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
