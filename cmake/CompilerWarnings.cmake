# cmake/CompilerWarnings.cmake
# Comprehensive compiler warnings for C++

function(set_project_warnings target_name)
    set(MSVC_WARNINGS
        /W4     # Baseline reasonable warnings
        /w14242 # Conversion possible loss of data
        /w14254 # Operator conversions
        /w14263 # Member function does not override
        /w14265 # Class has virtual functions but destructor is not virtual
        /w14287 # Unsigned/negative constant mismatch
        /we4289 # Loop variable used outside loop (error)
        /w14296 # Expression is always true/false
        /w14311 # Pointer truncation
        /w14545 # Expression before comma evaluates to function
        /w14546 # Function call before comma missing argument list
        /w14547 # Operator before comma has no effect
        /w14549 # Operator before comma has no effect
        /w14555 # Expression has no effect
        /w14619 # Unknown pragma warning
        /w14640 # Thread-unsafe static member initialization
        /w14826 # Conversion is sign-extended
        /w14905 # Wide string literal cast
        /w14906 # String literal cast
        /w14928 # Illegal copy-initialization
        /permissive- # Conformance mode
    )

    set(CLANG_WARNINGS
        -Wall
        -Wextra
        -Wshadow
        -Wnon-virtual-dtor
        -Wold-style-cast
        -Wcast-align
        -Wunused
        -Woverloaded-virtual
        -Wpedantic
        -Wconversion
        -Wsign-conversion
        -Wnull-dereference
        -Wdouble-promotion
        -Wformat=2
        -Wimplicit-fallthrough
    )

    set(GCC_WARNINGS
        ${CLANG_WARNINGS}
        -Wmisleading-indentation
        -Wduplicated-cond
        -Wduplicated-branches
        -Wlogical-op
        -Wuseless-cast
    )

    if(MSVC)
        set(PROJECT_WARNINGS_CXX ${MSVC_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
        set(PROJECT_WARNINGS_CXX ${CLANG_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(PROJECT_WARNINGS_CXX ${GCC_WARNINGS})
    else()
        message(WARNING "No compiler warnings set for CXX compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif()

    # C warnings (similar but adapted)
    set(CLANG_C_WARNINGS
        -Wall
        -Wextra
        -Wshadow
        -Wcast-align
        -Wunused
        -Wpedantic
        -Wconversion
        -Wsign-conversion
        -Wnull-dereference
        -Wdouble-promotion
        -Wformat=2
        -Wimplicit-fallthrough
    )

    set(GCC_C_WARNINGS ${CLANG_C_WARNINGS})

    if(CMAKE_C_COMPILER_ID MATCHES ".*Clang")
        set(PROJECT_WARNINGS_C ${CLANG_C_WARNINGS})
    elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set(PROJECT_WARNINGS_C ${GCC_C_WARNINGS})
    endif()

    target_compile_options(${target_name}
        PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${PROJECT_WARNINGS_CXX}>
            $<$<COMPILE_LANGUAGE:C>:${PROJECT_WARNINGS_C}>
    )

endfunction()