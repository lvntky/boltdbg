# cmake/BoltDbgOptions.cmake
#
# Define project-wide options for BoltDBG

option(BOLTDBG_BUILD_TESTS "Build boltdbg tests" ON)
option(BOLTDBG_ENABLE_ASAN "Enable AddressSanitizer (Address/Undefined)" OFF)
option(BOLTDBG_USE_SYSTEM_LIBS "Prefer system libraries (if available) over bundled" ON)
option(BOLTDBG_ENABLE_FORMAT_TARGET "Add clang-format target" ON)

set(BOLTDBG_DEFAULT_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" CACHE PATH "Default install prefix")
