// --- ActLog: ATL borrow "direct evidence" probe --------------------------
//
// ASCII-only on purpose: this file is compiled by MSVC with codepage 936,
// and non-ASCII bytes here raise warning C4819.
//
// This file is added by cmake/atl_borrow.cmake into the
// flutter_local_notifications_windows target (not a standalone project), so it
// goes through exactly the same include / link search paths as the plugin
// itself.
//
// It proves three things:
//   1. <atlbase.h> really compiles on this machine. The local VS BuildTools
//      have no ATL component installed, so there is no atlbase.h to fall back
//      on: without the borrow the build MUST fail with C1083. That is the
//      "has teeth" property - disable the borrow (PLOG_ATL_BORROW_OFF=1) and
//      this file stops compiling at once.
//   2. ATL types are really usable, not just "the file was found".
//   3. WHICH ATL was borrowed: PLOG_ATL_BORROW_ROOT is injected by CMake and
//      compiled into a string inside the DLL, so the path can be read straight
//      out of the shipped artifact.

#include <atlbase.h>

#ifndef PLOG_ATL_BORROW_ROOT
#error "PLOG_ATL_BORROW_ROOT was not injected: the ATL borrow patch did not run."
#endif

namespace {

// A real ATL type: proves the header content is usable, not merely present.
using ActLogAtlProbePtr = ATL::CComPtr<IUnknown>;

}  // namespace

extern "C" __declspec(dllexport) const char* actlog_atl_borrow_root() {
  return PLOG_ATL_BORROW_ROOT;
}
