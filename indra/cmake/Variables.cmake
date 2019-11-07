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

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
option(GEN_IS_MULTI_CONFIG "" ${_isMultiConfig})
mark_as_advanced(GEN_IS_MULTI_CONFIG)

set(LIBS_CLOSED_PREFIX)
set(LIBS_OPEN_PREFIX)
set(SCRIPTS_PREFIX ../scripts)
set(VIEWER_PREFIX)
set(INTEGRATION_TESTS_PREFIX)

option(LL_TESTS "Build and run unit and integration tests (disable for build timing runs to reduce variation" OFF)
option(BUILD_TESTING "Build test suite" OFF)
option(UNATTENDED "Disable use of uneeded tooling for automated builds" OFF)
option(INCREMENTAL_LINK "Use incremental linking on win32 builds (enable for faster links on some machines)" OFF)
option(USE_PRECOMPILED_HEADERS "Enable use of precompiled header directives where supported." ON)
option(USE_LTO "Enable global and interprocedural optimizations" OFF)
option(FULL_DEBUG_SYMS "Enable Generation of full pdb on msvc" OFF)
option(ENABLE_MEDIA_PLUGINS "Turn off building media plugins if they are imported by third-party library mechanism" ON)
set(VIEWER_SYMBOL_FILE "" CACHE STRING "Name of tarball into which to place symbol files")
set(BUGSPLAT_DB "" CACHE STRING "BugSplat database name, if BugSplat crash reporting is desired")

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
set(TEMPLATE_VERIFIER_MASTER_URL "https://bitbucket.org/alchemyviewer/master-message-template/raw/tip/message_template.msg" CACHE STRING "Location of the master message template")

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
    #message(STATUS "ADDRESS_SIZE is UNDEFINED")
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
      message(STATUS "Size of void pointer is detected as 8; ARCH is 64-bit")
      set(ARCH x86_64)
      set(ADDRESS_SIZE 64)
    elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
      message(STATUS "Size of void pointer is detected as 4; ARCH is 32-bit")
      set(ADDRESS_SIZE 32)
      set(ARCH i686)
    else()
      message(FATAL_ERROR "Unkown Architecture!")
    endif()
endif (ADDRESS_SIZE EQUAL 32)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
  set(WINDOWS ON BOOL FORCE)
  if (ADDRESS_SIZE EQUAL 64)
    set(LL_ARCH ${ARCH}_win64)
    set(LL_ARCH_DIR ${ARCH}-win64)
  elseif (ADDRESS_SIZE EQUAL 32)
    set(LL_ARCH ${ARCH}_win32)
    set(LL_ARCH_DIR ${ARCH}-win32)
  else()
    message(FATAL_ERROR "Unkown Architecture!")
  endif ()
endif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")

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
  set(DARWIN ON BOOL FORCE)

  # Architecture
  set(CMAKE_OSX_SYSROOT macosx10.14)
  set(CMAKE_OSX_ARCHITECTURES "x86_64")
  set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS "x86_64")

  # Xcode setup
  if (XCODE_VERSION LESS 10.2.0)
    message( FATAL_ERROR "Xcode 10.2.0 or greater is required." )
  endif (XCODE_VERSION LESS 10.2.0)
    message( "Building with " ${CMAKE_OSX_SYSROOT} )
  set(CMAKE_OSX_DEPLOYMENT_TARGET 10.13)

  # Compiler setup
  set(CMAKE_XCODE_ATTRIBUTE_GCC_VERSION "com.apple.compilers.llvm.clang.1_0")
  set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug] "dwarf")
  set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] "dwarf-with-dsym")

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
  set(CMAKE_XCODE_ATTRIBUTE_WARNING_CFLAGS "-Wall -Wextra -Wno-reorder -Wno-sign-compare -Wno-ignored-qualifiers -Wno-unused-local-typedef -Wno-unused-parameter -Wno-unused-template")

  # C++ specifics
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++17")
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")

  # Apple Clang - Warning Policies
  set(CMAKE_XCODE_ATTRIBUTE_GCC_TREAT_WARNINGS_AS_ERRORS YES)

  set(ADDRESS_SIZE 64)
  set(ARCH x86_64)
  set(CMAKE_OSX_ARCHITECTURES x86_64)

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
set(USESYSTEMLIBS OFF CACHE BOOL "Use libraries from your system rather than Linden-supplied prebuilt libraries.")
option(STANDALONE "Use libraries from your system rather than Linden-supplied prebuilt libraries." OFF)
if (USESYSTEMLIBS)
    set(STANDALONE ON)
elseif (STANDALONE)
    set(USESYSTEMLIBS ON)
endif (USESYSTEMLIBS)

set(USE_PRECOMPILED_HEADERS ON CACHE BOOL "Enable use of precompiled header directives where supported.")

source_group("CMake Rules" FILES CMakeLists.txt)

endif(NOT DEFINED ${CMAKE_CURRENT_LIST_FILE}_INCLUDED)
