cmake_minimum_required(VERSION 3.15)
project(boltdbg VERSION 0.1.0 LANGUAGES C CXX)

# Load BoltDBG option definitions first
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(BoltDbgOptions)

# Some basic options
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_C_STANDARD 11)

# include helper modules
include(compiler_warnings)
include(Sanitizer)
include(PlatformConfig)
#include(CodeStyle)

# src
add_subdirectory(src)

# add optional format targets if enabled
if (BOLTDBG_ENABLE_FORMAT_TARGET)
    #add_clang_format_target(boltdbg)
endif()

# Tests
if (BOLTDBG_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
