# cmake/PlatformConfig.cmake
#
# Set platform-specific compile definitions and helper variables

function(configure_platform target)
    if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
        target_compile_definitions(${target} PRIVATE BOLTDBG_PLATFORM_LINUX=1)
        message(STATUS "Configuring for Linux")
    elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        target_compile_definitions(${target} PRIVATE BOLTDBG_PLATFORM_MACOS=1)
        message(STATUS "Configuring for macOS")
    elseif (CMAKE_SYSTEM_NAME MATCHES "Windows")
        target_compile_definitions(${target} PRIVATE BOLTDBG_PLATFORM_WINDOWS=1)
        message(STATUS "Configuring for Windows")
    else()
        target_compile_definitions(${target} PRIVATE BOLTDBG_PLATFORM_UNKNOWN=1)
        message(WARNING "Unknown platform: ${CMAKE_SYSTEM_NAME}")
    endif()

    # Example: helper macro for visibility
    if (MSVC)
        target_compile_definitions(${target} PRIVATE BOLTDBG_EXPORT=__declspec(dllexport))
    else()
        target_compile_definitions(${target} PRIVATE BOLTDBG_EXPORT=__attribute__((visibility(\"default\"))))
    endif()
endfunction()
