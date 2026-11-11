# --- ActLog: 通知插件的构建兼容补丁 -------------------------------------
#
# 背景（D1 实测，见 docs/D1_技术选型结论.md）：
#   1. flutter_local_notifications_windows 1.0.3 的 src/plugin.cpp 无条件
#      #include <atlbase.h>，而本机 VS 2026 BuildTools(14.51.36231) 未安装
#      ATL 组件（atlmfc 目录不存在）=> 编译报 C1083。
#   2. MSVC 14.51 把 <experimental/coroutine> 的弃用升级为硬错误
#      (STL1011, experimental/coroutine:36)，官方抑制宏是
#      _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS。
#
# 做法：不改动系统安装、不装任何组件，只在本工程内借用本机「已装 ATL 的
# Visual Studio」的 ATL 头文件与 atls.lib（atlbase.h 里的
# #pragma comment(lib, "atls.lib") 会自动产生链接需求）。版本路径用 glob
# 探测，VS 升级后仍然有效；一旦 VS2026 补装 ATL，会自动优先用更新的那套。
# 真正的根治方案是给 VS2026 补装「C++ ATL for v143」组件（需用户授权）。
#
# 本文件由 windows/CMakeLists.txt 在 include(flutter/generated_plugins.cmake)
# **之后** include —— 此时插件 target 才已存在。
#
# 「借用到底生效没有」的三层证据（本文件负责前两层，第三层在
# tools/verify/atl_borrow_evidence.ps1）：
#   A. 探针：atl_borrow_probe.cpp 被编进插件 target，它 #include <atlbase.h>
#      并真的用 ATL 类型 —— 借不到就编译不过（C1083）。**有牙**。
#   B. 路径注入：PLOG_ATL_BORROW_ROOT 由这里注入，编译进 DLL 的字符串里，
#      产物中可直接搜到「这次借的是哪一套 ATL」。
#   C. 反向验证：设 PLOG_ATL_BORROW_OFF=1 就故意不借，构建必须失败。

if(NOT TARGET flutter_local_notifications_windows)
  message(STATUS
    "ActLog: flutter_local_notifications_windows not in this build; "
    "skipping ATL borrow.")
  return()
endif()

# (2) STL1011 抑制宏：只能设到具体 target 上，不能全局。
target_compile_definitions(flutter_local_notifications_windows
  PRIVATE _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)

# --- 「有牙」开关：设了 PLOG_ATL_BORROW_OFF 就**故意不借** -----------------
# 反向验证用：借不到时 flutter_local_notifications_windows 必须编译失败
#（C1083: cannot open include file: 'atlbase.h'）。
# 正向构建绝不能设这个环境变量。
if(DEFINED ENV{PLOG_ATL_BORROW_OFF})
  message(WARNING
    "ActLog: PLOG_ATL_BORROW_OFF is set - the ATL borrow is DISABLED on purpose.")
  file(WRITE "${CMAKE_BINARY_DIR}/actlog_atl_borrow.txt"
    "disabled_by=PLOG_ATL_BORROW_OFF\n")
  return()
endif()

# (1) ATL 头文件 + atls.lib 借用
set(PLOG_ATL_ROOT "")
set(_plog_atl_ok "")
file(GLOB _plog_atl_candidates
  "C:/Program Files (x86)/Microsoft Visual Studio/*/*/VC/Tools/MSVC/*"
  "C:/Program Files/Microsoft Visual Studio/*/*/VC/Tools/MSVC/*")
foreach(_c IN LISTS _plog_atl_candidates)
  if(EXISTS "${_c}/atlmfc/include/atlbase.h" AND EXISTS "${_c}/atlmfc/lib/x64/atls.lib")
    get_filename_component(_ver "${_c}" NAME)
    list(APPEND _plog_atl_ok "${_ver}|${_c}")
  endif()
endforeach()
if(_plog_atl_ok)
  list(SORT _plog_atl_ok COMPARE NATURAL ORDER DESCENDING)
  list(GET _plog_atl_ok 0 _plog_atl_first)
  string(REPLACE "|" ";" _plog_atl_parts "${_plog_atl_first}")
  list(GET _plog_atl_parts 1 PLOG_ATL_ROOT)
endif()

if(PLOG_ATL_ROOT)
  message(STATUS "ActLog: borrowing ATL headers/atls.lib from ${PLOG_ATL_ROOT}")
  target_include_directories(flutter_local_notifications_windows
    PRIVATE "${PLOG_ATL_ROOT}/atlmfc/include")
  # 只给「库搜索目录」，**不要**把 atls.lib 写进 Link.AdditionalDependencies。
  # 原因：Microsoft.CppBuild.targets:506 的 ATL 组件校验条件是
  #   AdditionalDependencies 含有 'atls.lib' 且 $(ATL_KeyFile) 指向的文件不存在
  #   => 报 MSB8041「此项目需要 ATL 库」。
  # 而 atlbase.h 里的 #pragma comment(lib, "atls.lib") 已经让 cl.exe 自动
  # 传 /DEFAULTLIB:atls.lib，链接器只要能在搜索目录里找到 atls.lib 即可。
  target_link_directories(flutter_local_notifications_windows
    PRIVATE "${PLOG_ATL_ROOT}/atlmfc/lib/x64")

  # (3) 直接证据：探针 + 路径注入 + 配置期存根。
  set(PLOG_ATL_HEADER "${PLOG_ATL_ROOT}/atlmfc/include/atlbase.h")
  set(PLOG_ATL_LIB "${PLOG_ATL_ROOT}/atlmfc/lib/x64/atls.lib")

  target_sources(flutter_local_notifications_windows
    PRIVATE "${CMAKE_CURRENT_LIST_DIR}/atl_borrow_probe.cpp")
  target_compile_definitions(flutter_local_notifications_windows
    PRIVATE "PLOG_ATL_BORROW_ROOT=\"${PLOG_ATL_ROOT}\"")

  # 配置期存根：构建目录里留下「这次借了什么」的白纸黑字。
  file(WRITE "${CMAKE_BINARY_DIR}/actlog_atl_borrow.txt"
    "borrowed_root=${PLOG_ATL_ROOT}\nheader=${PLOG_ATL_HEADER}\nlib=${PLOG_ATL_LIB}\n")
else()
  message(WARNING
    "ActLog: no Visual Studio with ATL found. flutter_local_notifications_windows "
    "will fail to compile (missing atlbase.h).")
  file(WRITE "${CMAKE_BINARY_DIR}/actlog_atl_borrow.txt"
    "borrowed_root=\nheader=\nlib=\nreason=no Visual Studio with ATL found\n")
endif()
