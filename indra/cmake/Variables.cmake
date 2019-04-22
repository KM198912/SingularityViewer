# -*- cmake -*-
#
# Definitions of variables used throughout the Second Life build
# process.
#
# Platform variables:
#
#   DARWIN  - Mac OS X
#   LINUX   - Linux
#   WINDOWS - Windows

# Relative and absolute paths to subtrees.
if(NOT DEFINED ${CMAKE_CURRENT_LIST_FILE}_INCLUDED)
set(${CMAKE_CURRENT_LIST_FILE}_INCLUDED "YES")

if(NOT DEFINED COMMON_CMAKE_DIR)
    set(COMMON_CMAKE_DIR "${CMAKE_SOURCE_DIR}/cmake")
endif(NOT DEFINED COMMON_CMAKE_DIR)

set(LIBS_CLOSED_PREFIX)
set(LIBS_OPEN_PREFIX)
set(SCRIPTS_PREFIX ../scripts)
set(VIEWER_PREFIX)
set(INTEGRATION_TESTS_PREFIX)
option(LL_TESTS "Build and run unit and integration tests (disable for build timing runs to reduce variation" OFF)

option(INCREMENTAL_LINK "Use incremental linking on win32 builds (enable for faster links on some machines)" OFF)
option(USE_PRECOMPILED_HEADERS "Enable use of precompiled header directives where supported." ON)
option(USE_LTO "Enable Whole Program Optimization and related folding and binary reduction routines" OFF)
option(UNATTENDED "Disable use of uneeded tooling for automated builds" OFF)

# Media Plugins
option(ENABLE_MEDIA_PLUGINS "Turn off building media plugins if they are imported by third-party library mechanism" ON)
option(LIBVLCPLUGIN "Turn off building support for libvlc plugin" ON)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux" OR ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(LIBVLCPLUGIN OFF)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux" OR ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")

# Mallocs
set(DISABLE_TCMALLOC OFF CACHE BOOL "Disable linkage of TCMalloc. (64bit builds automatically disable TCMalloc)")
set(DISABLE_FATAL_WARNINGS TRUE CACHE BOOL "Set this to FALSE to enable fatal warnings.")

# Audio Engines
option(FMODSTUDIO "Build with support for the FMOD Studio audio engine" ON)

# Window implementation
option(LLWINDOW_SDL2 "Use SDL2 for window and input handling" OFF)

# Proprietary Library Features
option(NVAPI "Use nvapi driver interface library" OFF)

if(LIBS_CLOSED_DIR)
  file(TO_CMAKE_PATH "${LIBS_CLOSED_DIR}" LIBS_CLOSED_DIR)
else(LIBS_CLOSED_DIR)
  set(LIBS_CLOSED_DIR ${CMAKE_SOURCE_DIR}/${LIBS_CLOSED_PREFIX})
endif(LIBS_CLOSED_DIR)
if(LIBS_COMMON_DIR)
  file(TO_CMAKE_PATH "${LIBS_COMMON_DIR}" LIBS_COMMON_DIR)
else(LIBS_COMMON_DIR)
  set(LIBS_COMMON_DIR ${CMAKE_SOURCE_DIR}/${LIBS_OPEN_PREFIX})
endif(LIBS_COMMON_DIR)
set(LIBS_OPEN_DIR ${LIBS_COMMON_DIR})

set(SCRIPTS_DIR ${CMAKE_SOURCE_DIR}/${SCRIPTS_PREFIX})
set(VIEWER_DIR ${CMAKE_SOURCE_DIR}/${VIEWER_PREFIX})

set(AUTOBUILD_INSTALL_DIR ${CMAKE_BINARY_DIR}/packages)

set(LIBS_PREBUILT_DIR ${AUTOBUILD_INSTALL_DIR} CACHE PATH
    "Location of prebuilt libraries.")

if (EXISTS ${CMAKE_SOURCE_DIR}/Server.cmake)
  # We use this as a marker that you can try to use the proprietary libraries.
  set(INSTALL_PROPRIETARY ON CACHE BOOL "Install proprietary binaries")
endif (EXISTS ${CMAKE_SOURCE_DIR}/Server.cmake)
set(TEMPLATE_VERIFIER_OPTIONS "" CACHE STRING "Options for scripts/template_verifier.py")
set(TEMPLATE_VERIFIER_MASTER_URL "https://forge.alchemyviewer.org/alchemy/tools/Master-Message-Template/raw/master/message_template.msg" CACHE STRING "Location of the master message template")

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
      "Build type.  One of: Debug Release RelWithDebInfo" FORCE)
endif (NOT CMAKE_BUILD_TYPE)

# If someone has specified an address size, use that to determine the
# architecture.  Otherwise, let the architecture specify the address size.
if (ADDRESS_SIZE EQUAL 32)
  #message(STATUS "ADDRESS_SIZE is 32")
  set(ARCH i686)
elseif (ADDRESS_SIZE EQUAL 64)
  #message(STATUS "ADDRESS_SIZE is 64")
  set(ARCH x86_64)
else (ADDRESS_SIZE EQUAL 32)
  #message(STATUS "ADDRESS_SIZE is UNRECOGNIZED: '${ADDRESS_SIZE}'")
  # Use Python's platform.machine() since uname -m isn't available everywhere.
  # Even if you can assume cygwin uname -m, the answer depends on whether
  # you're running 32-bit cygwin or 64-bit cygwin! But even 32-bit Python will
  # report a 64-bit processor.
  execute_process(COMMAND
                  "${PYTHON_EXECUTABLE}" "-c"
                  "import platform; print platform.machine()"
                  OUTPUT_VARIABLE ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
  # We expect values of the form i386, i686, x86_64, AMD64.
  # In CMake, expressing ARCH.endswith('64') is awkward:
  string(LENGTH "${ARCH}" ARCH_LENGTH)
  math(EXPR ARCH_LEN_2 "${ARCH_LENGTH} - 2")
  string(SUBSTRING "${ARCH}" ${ARCH_LEN_2} 2 ARCH_LAST_2)
  if (ARCH_LAST_2 STREQUAL 64)
    #message(STATUS "ARCH is detected as 64; ARCH is ${ARCH}")
    set(ADDRESS_SIZE 64)
  else ()
    #message(STATUS "ARCH is detected as 32; ARCH is ${ARCH}")
    set(ADDRESS_SIZE 32)
  endif ()
endif (ADDRESS_SIZE EQUAL 32)

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
  set(WINDOWS ON BOOL FORCE)
  set(LL_ARCH ${ARCH}_win32)
  set(LL_ARCH_DIR ${ARCH}-win32)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Windows")

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(LINUX ON BOOL FORCE)

  if (ADDRESS_SIZE EQUAL 32)
    set(DEB_ARCHITECTURE i386)
    set(FIND_LIBRARY_USE_LIB64_PATHS OFF)
    set(CMAKE_SYSTEM_LIBRARY_PATH /usr/lib32 ${CMAKE_SYSTEM_LIBRARY_PATH})
  else (ADDRESS_SIZE EQUAL 32)
    set(DEB_ARCHITECTURE amd64)
    set(FIND_LIBRARY_USE_LIB64_PATHS ON)
  endif (ADDRESS_SIZE EQUAL 32)

  execute_process(COMMAND dpkg-architecture -a${DEB_ARCHITECTURE} -qDEB_HOST_MULTIARCH 
      RESULT_VARIABLE DPKG_RESULT
      OUTPUT_VARIABLE DPKG_ARCH
      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  #message (STATUS "DPKG_RESULT ${DPKG_RESULT}, DPKG_ARCH ${DPKG_ARCH}")
  if (DPKG_RESULT EQUAL 0)
    set(CMAKE_LIBRARY_ARCHITECTURE ${DPKG_ARCH})
    set(CMAKE_SYSTEM_LIBRARY_PATH /usr/lib/${DPKG_ARCH} /usr/local/lib/${DPKG_ARCH} ${CMAKE_SYSTEM_LIBRARY_PATH})
  endif (DPKG_RESULT EQUAL 0)

  include(ConfigurePkgConfig)

  set(LL_ARCH ${ARCH}_linux)
  set(LL_ARCH_DIR ${ARCH}-linux)

  if (INSTALL_PROPRIETARY)
    # Only turn on headless if we can find osmesa libraries.
    include(FindPkgConfig)
    #pkg_check_modules(OSMESA osmesa)
    #if (OSMESA_FOUND)
    #  set(BUILD_HEADLESS ON CACHE BOOL "Build headless libraries.")
    #endif (OSMESA_FOUND)
  endif (INSTALL_PROPRIETARY)

endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(DARWIN 1)

  # Architecture
  set(CMAKE_OSX_SYSROOT macosx10.14)
  set(CMAKE_OSX_ARCHITECTURES "x86_64")
  set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS "x86_64")

  # Build Options
  set(CMAKE_XCODE_ATTRIBUTE_GCC_VERSION "com.apple.compilers.llvm.clang.1_0")
  set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug] "dwarf")
  set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] "dwarf-with-dsym")

  # Deployment
  set(CMAKE_OSX_DEPLOYMENT_TARGET 10.13)

  # Linking 
  set(CMAKE_XCODE_ATTRIBUTE_DEAD_CODE_STRIPPING YES)

  # Apple Clang - Code Gen
  set(CMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=Release] YES)
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_X86_VECTOR_INSTRUCTIONS sse4.1)
  set(CMAKE_XCODE_ATTRIBUTE_GCC_STRICT_ALIASING NO)
  set(CMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=Debug] 0)
  set(CMAKE_XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL[variant=Release] 3)
  set(CMAKE_XCODE_ATTRIBUTE_GCC_FAST_MATH NO)

  # Apple Clang - Custom Compiler Flags
  set(CMAKE_XCODE_ATTRIBUTE_WARNING_CFLAGS "-Wall -Wextra -Wno-reorder -Wno-sign-compare -Wno-ignored-qualifiers -Wno-unused-local-typedef -Wno-unused-parameter")

  # Apple Clang - Language - C++
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD c++14)
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")

  # Apple Clang - Warning Policies
  set(CMAKE_XCODE_ATTRIBUTE_GCC_TREAT_WARNINGS_AS_ERRORS YES)

  set(LL_ARCH ${ARCH}_darwin)
  set(LL_ARCH_DIR universal-darwin)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")

# Default deploy grid
set(GRID agni CACHE STRING "Target Grid")

set(VIEWER_PRODUCT_NAME "Singularity" CACHE STRING "Viewer Base Name")
string(TOLOWER ${VIEWER_PRODUCT_NAME} VIEWER_PRODUCT_NAME_LOWER)

set(VIEWER_CHANNEL_BASE "Test" CACHE STRING "Viewer Channel Name")
set(VIEWER_CHANNEL "${VIEWER_PRODUCT_NAME} ${VIEWER_CHANNEL_BASE}")
string(TOLOWER ${VIEWER_CHANNEL} VIEWER_CHANNEL_LOWER)
string(REPLACE " " "" VIEWER_CHANNEL_ONEWORD ${VIEWER_CHANNEL})

option(VIEWER_CHANNEL_GRK "Greek character(s) to represent the viewer channel for support purposes, override only for special branches" "")
if (NOT VIEWER_CHANNEL_GRK)
    if (1) # This branch has a special indicator
        set(VIEWER_CHANNEL_GRK "\\u03BC") # "�"
    elseif (VIEWER_CHANNEL_BASE MATCHES "Test")
        set(VIEWER_CHANNEL_GRK "\\u03C4") # "τ"
    elseif (VIEWER_CHANNEL_BASE MATCHES "Alpha")
        set(VIEWER_CHANNEL_GRK "\\u03B1") # "α"
    elseif (VIEWER_CHANNEL_BASE MATCHES "Beta")
        set(VIEWER_CHANNEL_GRK "\\u03B2") # "β"
    endif ()
endif (NOT VIEWER_CHANNEL_GRK)

if(VIEWER_CHANNEL_LOWER MATCHES "^${VIEWER_PRODUCT_NAME_LOWER} release")
  set(VIEWER_PACKAGE_ID "${VIEWER_PRODUCT_NAME}Release")
  set(VIEWER_EXE_STRING "${VIEWER_PRODUCT_NAME}Viewer")
  set(VIEWER_SHORTCUT_STRING "${VIEWER_PRODUCT_NAME} Viewer")
else()
  set(VIEWER_PACKAGE_ID ${VIEWER_CHANNEL_ONEWORD})
  set(VIEWER_EXE_STRING ${VIEWER_CHANNEL_ONEWORD})
  set(VIEWER_SHORTCUT_STRING ${VIEWER_CHANNEL})
endif()

set(VIEWER_CHANNEL_NOSPACE ${VIEWER_CHANNEL_ONEWORD} CACHE STRING "Prefix used for resulting artifacts.")

set(VIEWER_BRANDING_ID "singularity" CACHE STRING "Viewer branding id")

option(ENABLE_SIGNING "Enable signing the viewer" OFF)
set(SIGNING_IDENTITY "" CACHE STRING "Specifies the signing identity to use, if necessary.")

set(VERSION_BUILD "0" CACHE STRING "Revision number passed in from the outside")
# Compiler and toolchain options
option(USESYSTEMLIBS "Use libraries from your system rather than Linden-supplied prebuilt libraries." OFF)
option(STANDALONE "Use libraries from your system rather than Linden-supplied prebuilt libraries." OFF)
if (USESYSTEMLIBS)
    set(STANDALONE ON)
elseif (STANDALONE)
    set(USESYSTEMLIBS ON)
endif (USESYSTEMLIBS)



source_group("CMake Rules" FILES CMakeLists.txt)

endif(NOT DEFINED ${CMAKE_CURRENT_LIST_FILE}_INCLUDED)
