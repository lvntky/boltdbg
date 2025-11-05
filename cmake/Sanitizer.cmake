# cmake/Sanitizers.cmake
#
# Adds sanitizers compile/link flags when requested.
# Usage: include(Sanitizers) ; enable_sanitizers(<target>)

function(enable_sanitizers target)
    if (NOT BOLTDBG_ENABLE_ASAN)
        message(VERBOSE "Sanitizers disabled (BOLTDBG_ENABLE_ASAN=OFF)")
        return()
    endif()

    if (MSVC)
        message(WARNING "AddressSanitizer is not fully supported on MSVC. Skipping.")
        return()
    endif()

    # AddressSanitizer + UndefinedBehaviorSanitizer recommended combo
    target_compile_options(${target} PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(${target} PRIVATE -fsanitize=address,undefined)

    # Optional: ThreadSanitizer for race conditions (enable manually if needed)
    # target_compile_options(${target} PRIVATE -fsanitize=thread -fno-omit-frame-pointer)
    # target_link_options(${target} PRIVATE -fsanitize=thread)

    # Recommended debug symbols
    target_compile_options(${target} PRIVATE -g)
    message(STATUS "Enabled AddressSanitizer and UndefinedBehaviorSanitizer for target ${target}")
endfunction()
