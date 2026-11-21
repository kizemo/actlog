#define INITGUID
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <propkey.h>
#include <propsys.h>
#include <propvarutil.h>
#include <shellapi.h>
#include <shobjidl_core.h>
#include <windows.h>

#include <string>
#include <variant>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The taskbar button name is owned by the shell: the shell reads the window
// properties, keeps its own copy, and never asks again. So the runner both
// writes them and remembers the last value, because the window can be shown
// again later (hide to tray -> tray click) long after Dart pushed the label.
//
// The text is never spelled out here: main.cpp is compiled without /utf-8, so a
// non-ASCII literal would be decoded with the local code page. Dart sends UTF-8
// and the widening happens at run time.
std::wstring g_taskbar_display_name;

// Identity of the taskbar button. The shell groups buttons by AppUserModelID:
// without an explicit one the identity falls back to the executable path, and
// the shell then prefers the title of any shortcut that targets that path -
// which is exactly how the installer's static "actlog" shortcut hides the
// localized name (measured: Task 47 W1c-2c A/B, same exe, only the .lnk moved).
// An explicit AUMID changes the identity, so the shortcut title stops winning.
// Both literals are ASCII on purpose: this file is compiled without /utf-8.
constexpr wchar_t kAppUserModelId[] = L"com.actlog.actlog";
constexpr char kAppUserModelIdUtf8[] = "com.actlog.actlog";

// Result of SetCurrentProcessExplicitAppUserModelID, captured in wWinMain
// before the first window exists. The call can only be made once per process,
// so the HRESULT is remembered and reported back with every property write
// instead of being lost where nobody can read it.
HRESULT g_hr_aumid = E_PENDING;

// Full path of this executable. Written as the window relaunch command so the
// shell knows what to start when the user pins the button.
std::wstring ExecutablePath() {
  std::vector<wchar_t> buffer(MAX_PATH);
  for (;;) {
    const DWORD length = ::GetModuleFileNameW(
        nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) {
      return std::wstring();
    }
    if (length < static_cast<DWORD>(buffer.size())) {
      return std::wstring(buffer.data(), static_cast<size_t>(length));
    }
    if (buffer.size() >= 32768) {
      return std::wstring();
    }
    buffer.resize(buffer.size() * 2);
  }
}

// Widens the UTF-8 payload coming from Dart. Returns false when it cannot be
// decoded, so the caller can report a failure instead of a silent no-op.
bool Utf8ToWide(const std::string& utf8, std::wstring* wide) {
  if (utf8.empty()) {
    return false;
  }
  const int length = ::MultiByteToWideChar(
      CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return false;
  }
  std::wstring converted(static_cast<size_t>(length), L'\0');
  const int written =
      ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                            static_cast<int>(utf8.size()), &converted[0], length);
  if (written != length) {
    return false;
  }
  *wide = converted;
  return true;
}

// Machine readable outcome of one write attempt. Every HRESULT is reported on
// its own: "the store opened but Commit failed" has to stay distinguishable
// from "the store never opened" when this shows up in the startup log. The same
// holds for the two new fields - hr_aumid answers "did the process get the
// identity" and hr_reg answers "did the AUMID get a display name", and neither
// may be inferred from the property store result.
flutter::EncodableMap TaskbarResult(HRESULT hr_store, HRESULT hr_cmd,
                                    HRESULT hr_name, HRESULT hr_commit,
                                    HRESULT hr_read, HRESULT hr_reg,
                                    bool readback_ok) {
  flutter::EncodableMap result;
  result[flutter::EncodableValue("hr_store")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_store));
  result[flutter::EncodableValue("hr_cmd")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_cmd));
  result[flutter::EncodableValue("hr_name")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_name));
  result[flutter::EncodableValue("hr_commit")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_commit));
  result[flutter::EncodableValue("hr_read")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_read));
  result[flutter::EncodableValue("hr_reg")] =
      flutter::EncodableValue(static_cast<int64_t>(hr_reg));
  result[flutter::EncodableValue("hr_aumid")] =
      flutter::EncodableValue(static_cast<int64_t>(g_hr_aumid));
  result[flutter::EncodableValue("aumid")] =
      flutter::EncodableValue(std::string(kAppUserModelIdUtf8));
  result[flutter::EncodableValue("readback_ok")] =
      flutter::EncodableValue(readback_ok);
  return result;
}

// Publishes the localized name for our AUMID. The shell resolves an AUMID
// button name from
//   HKEY_CURRENT_USER\Software\Classes\AppUserModelId\<aumid>\DisplayName
// so the value has to exist before the button is drawn, and it has to be
// rewritten whenever the UI language changes. Wide character APIs only: the
// name is UTF-16 and this file must not depend on the local code page.
HRESULT WriteAumidDisplayName(const std::wstring& name) {
  if (name.empty()) {
    return E_INVALIDARG;
  }
  const std::wstring subkey =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + kAppUserModelId;
  HKEY key = nullptr;
  DWORD disposition = 0;
  LSTATUS status =
      ::RegCreateKeyExW(HKEY_CURRENT_USER, subkey.c_str(), 0, nullptr,
                        REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                        &disposition);
  if (status != ERROR_SUCCESS) {
    return HRESULT_FROM_WIN32(status);
  }
  const DWORD bytes = static_cast<DWORD>((name.size() + 1) * sizeof(wchar_t));
  status = ::RegSetValueExW(key, L"DisplayName", 0, REG_SZ,
                            reinterpret_cast<const BYTE*>(name.c_str()), bytes);
  ::RegCloseKey(key);
  if (status != ERROR_SUCCESS) {
    return HRESULT_FROM_WIN32(status);
  }
  return S_OK;
}

// Writes the two window properties the shell needs, publishes the same text as
// the AUMID display name, then reads the name back and compares it code point
// by code point (a truncated or re-encoded value has to fail here).
//
// Order is the whole point of this function:
//   1. the process AUMID is already set in wWinMain, before any window exists,
//      so the shell creates the button with our identity;
//   2. the AUMID gets its display name in the registry (this call), which is
//      what the shell shows for that identity and what follows the language;
//   3. the window properties are committed afterwards, because they are only
//      consulted for the fallback identity - keeping them is deliberate, they
//      are a capability, not the suppression source.
flutter::EncodableMap ApplyTaskbarDisplayName(HWND window,
                                              const std::wstring& name) {
  HRESULT hr_store = E_FAIL;
  HRESULT hr_cmd = E_FAIL;
  HRESULT hr_name = E_FAIL;
  HRESULT hr_commit = E_FAIL;
  HRESULT hr_read = E_FAIL;
  HRESULT hr_reg = E_FAIL;
  bool readback_ok = false;

  IPropertyStore* store = nullptr;
  hr_store = ::SHGetPropertyStoreForWindow(window, IID_PPV_ARGS(&store));
  if (FAILED(hr_store) || store == nullptr) {
    return TaskbarResult(hr_store, hr_cmd, hr_name, hr_commit, hr_read, hr_reg,
                         readback_ok);
  }

  PROPVARIANT command_value;
  ::PropVariantInit(&command_value);
  const std::wstring exe = ExecutablePath();
  if (!exe.empty()) {
    hr_cmd = ::InitPropVariantFromString(exe.c_str(), &command_value);
    if (SUCCEEDED(hr_cmd)) {
      hr_cmd =
          store->SetValue(PKEY_AppUserModel_RelaunchCommand, command_value);
    }
  }
  ::PropVariantClear(&command_value);

  PROPVARIANT name_value;
  ::PropVariantInit(&name_value);
  if (!name.empty()) {
    hr_name = ::InitPropVariantFromString(name.c_str(), &name_value);
    if (SUCCEEDED(hr_name)) {
      hr_name = store->SetValue(PKEY_AppUserModel_RelaunchDisplayNameResource,
                                name_value);
    }
  }
  ::PropVariantClear(&name_value);
  if (SUCCEEDED(hr_name)) {
    g_taskbar_display_name = name;
  }

  hr_reg = WriteAumidDisplayName(name);

  hr_commit = store->Commit();

  PROPVARIANT read_value;
  ::PropVariantInit(&read_value);
  hr_read =
      store->GetValue(PKEY_AppUserModel_RelaunchDisplayNameResource, &read_value);
  if (SUCCEEDED(hr_read) && read_value.vt == VT_LPWSTR &&
      read_value.pwszVal != nullptr) {
    readback_ok = (name == read_value.pwszVal);
  }
  ::PropVariantClear(&read_value);

  store->Release();
  return TaskbarResult(hr_store, hr_cmd, hr_name, hr_commit, hr_read, hr_reg,
                       readback_ok);
}

}  // namespace

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

  // Identity before the first window: the shell fixes the identity of a taskbar
  // button when the window is created, so this has to run before FlutterWindow
  // is constructed. It is process wide and only the first call wins, therefore
  // the HRESULT is kept for the log. A failure is not fatal (the shell falls
  // back to the exe path) but it must never be silent.
  g_hr_aumid = ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);

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
        } else if (method == "setTaskbarDisplayName") {
          const std::string* requested =
              std::get_if<std::string>(call.arguments());
          std::wstring wide;
          if (requested == nullptr || !Utf8ToWide(*requested, &wide)) {
            // Nothing reached the store: say so instead of reporting success.
            result->Success(flutter::EncodableValue(
                TaskbarResult(E_INVALIDARG, E_FAIL, E_FAIL, E_FAIL, E_FAIL,
                              E_INVALIDARG, false)));
          } else {
            result->Success(flutter::EncodableValue(
                ApplyTaskbarDisplayName(window.GetHandle(), wide)));
          }
        } else if (method == "showWindow") {
          window.ShowWindowFromDart();
          // Re-applying is idempotent and cheap; the shell may have dropped the
          // label while the window sat hidden in the tray.
          if (!g_taskbar_display_name.empty()) {
            ApplyTaskbarDisplayName(window.GetHandle(), g_taskbar_display_name);
          }
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
