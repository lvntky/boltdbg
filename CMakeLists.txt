cmake_minimum_required(VERSION 3.15)

# ============================================================================
# Project Definition
# ============================================================================
project(BoltDBG
    VERSION 0.1.0
    DESCRIPTION "Modern C++ Debugger with GUI"
    LANGUAGES C CXX
)

# ============================================================================
# C++ Standard
# ============================================================================
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Export compile commands for IDE support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Make builds more robust when mixing static/shared libs
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ============================================================================
# Options
# ============================================================================
option(BOLTDBG_BUILD_TESTS "Build test suite" OFF)
option(BOLTDBG_BUILD_EXAMPLES "Build examples" OFF)
option(BOLTDBG_USE_SYSTEM_LIBS "Prefer system libraries" ON)
option(BOLTDBG_ENABLE_ASAN "Enable Address Sanitizer" OFF)
option(BOLTDBG_ENABLE_UBSAN "Enable UB Sanitizer" OFF)
option(BOLTDBG_ENABLE_TSAN "Enable Thread Sanitizer" OFF)

# ============================================================================
# CMake Modules Path
# ============================================================================
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Include compiler warnings if available
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CompilerWarnings.cmake")
    include(CompilerWarnings)
endif()

# Include sanitizers if available
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Sanitizers.cmake")
    include(Sanitizers)
endif()

# ============================================================================
# Basic packages
# ============================================================================
# Threads (pthread) is commonly required for libraries and linking
find_package(Threads REQUIRED)

# ============================================================================
# Dependencies (FetchContent)
# ============================================================================
include(FetchContent)

# --- GLFW ---
if(BOLTDBG_USE_SYSTEM_LIBS)
    find_package(glfw3 3.3 QUIET)
endif()

if(NOT TARGET glfw AND NOT TARGET glfw3::glfw3)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/glfw/CMakeLists.txt")
        message(STATUS "Using vendored GLFW from external/glfw")
        set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
        set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
        set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
        set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
        add_subdirectory(external/glfw)
    else()
        message(STATUS "Fetching GLFW via FetchContent")
        FetchContent_Declare(
            glfw
            GIT_REPOSITORY https://github.com/glfw/glfw.git
            GIT_TAG 3.3.8
            GIT_SHALLOW TRUE
        )
        set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
        set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
        set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(glfw)
    endif()
endif()

# Create alias if needed
if(TARGET glfw3::glfw3 AND NOT TARGET glfw)
    add_library(glfw ALIAS glfw3::glfw3)
endif()

# --- spdlog ---
if(BOLTDBG_USE_SYSTEM_LIBS)
    find_package(spdlog 1.11 QUIET)
endif()

if(NOT TARGET spdlog::spdlog)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/spdlog/CMakeLists.txt")
        message(STATUS "Using vendored spdlog from external/spdlog")
        add_subdirectory(external/spdlog)
    else()
        message(STATUS "Fetching spdlog via FetchContent")
        FetchContent_Declare(
            spdlog
            GIT_REPOSITORY https://github.com/gabime/spdlog.git
            GIT_TAG v1.11.0
            GIT_SHALLOW TRUE
        )
        FetchContent_MakeAvailable(spdlog)
    endif()
endif()

# --- ImGui ---
if(NOT TARGET imgui)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/imgui/imgui.cpp")
        message(STATUS "Using vendored ImGui from external/imgui")
        set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/imgui")
    else()
        message(STATUS "Fetching ImGui via FetchContent")
        FetchContent_Declare(
            imgui
            GIT_REPOSITORY https://github.com/ocornut/imgui.git
            GIT_TAG v1.89.8
            GIT_SHALLOW TRUE
        )
        FetchContent_MakeAvailable(imgui)
        set(IMGUI_DIR ${imgui_SOURCE_DIR})
    endif()
    
    # Create ImGui library target
    add_library(imgui STATIC
        ${IMGUI_DIR}/imgui.cpp
        ${IMGUI_DIR}/imgui_demo.cpp
        ${IMGUI_DIR}/imgui_draw.cpp
        ${IMGUI_DIR}/imgui_tables.cpp
        ${IMGUI_DIR}/imgui_widgets.cpp
        ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
        ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
    )
    target_include_directories(imgui PUBLIC
        ${IMGUI_DIR}
        ${IMGUI_DIR}/backends
    )

    # Link libraries imgui backend needs — glad/glfw/OpenGL/Threads
    # Note: glad and platform libs may be created later; using PUBLIC allows consumers to pick them up.
    # We'll append actual platform libs after platform-detection block below.
endif()

# --- GLAD ---
if(NOT TARGET glad)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/glad/src/glad.c")
        message(STATUS "Using vendored GLAD from external/glad")
        set(GLAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/glad")
        # Create GLAD library target manually
        add_library(glad STATIC ${GLAD_DIR}/src/glad.c)
        target_include_directories(glad PUBLIC ${GLAD_DIR}/include)
    else()
        message(STATUS "Fetching GLAD via FetchContent")
        FetchContent_Declare(
            glad
            GIT_REPOSITORY https://github.com/Dav1dde/glad.git
            GIT_TAG v0.1.36
            GIT_SHALLOW TRUE
        )
        FetchContent_MakeAvailable(glad)
        # GLAD's CMakeLists.txt typically creates the 'glad' target automatically.
    endif()
endif()

# ============================================================================
# Platform-specific OpenGL and platform libs
# ============================================================================
set(PLATFORM_LIBS "")
if(APPLE)
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
    find_library(COREVIDEO_FRAMEWORK CoreVideo REQUIRED)
    find_library(OPENGL_FRAMEWORK OpenGL REQUIRED)
    list(APPEND PLATFORM_LIBS ${COCOA_FRAMEWORK} ${IOKIT_FRAMEWORK} ${COREVIDEO_FRAMEWORK} ${OPENGL_FRAMEWORK})
elseif(WIN32)
    list(APPEND PLATFORM_LIBS opengl32)
else()
    # Unix/Linux
    find_package(OpenGL REQUIRED)
    list(APPEND PLATFORM_LIBS OpenGL::GL ${CMAKE_DL_LIBS})
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        list(APPEND PLATFORM_LIBS pthread)
    endif()
endif()

# Now that PLATFORM_LIBS and glad exist, make sure imgui links them
if(TARGET imgui)
    # link what we have: glfw, glad, platform libs, threads
    # Use PRIVATE here because imgui's public headers don't require these symbols, but keep PUBLIC if consumers need transitive link.
    # Use PUBLIC to be safe for consumers (exe targets).
    target_link_libraries(imgui PUBLIC glfw)
    if(TARGET glad)
        target_link_libraries(imgui PUBLIC glad)
    endif()
    # PLATFORM_LIBS may contain import targets or plain names; link them too
    if(PLATFORM_LIBS)
        target_link_libraries(imgui PUBLIC ${PLATFORM_LIBS})
    endif()
    # Threads
    target_link_libraries(imgui PUBLIC Threads::Threads)
endif()

# ============================================================================
# Subdirectories
# ============================================================================
# Add src (this file should contain project targets like executable/library)
add_subdirectory(src)

# Tests and examples
if(BOLTDBG_BUILD_TESTS AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
    enable_testing()
    add_subdirectory(tests)
endif()

if(BOLTDBG_BUILD_EXAMPLES AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples/CMakeLists.txt")
    add_subdirectory(examples)
endif()


# ==============================================================================
# Clang-Format Integration
# ==============================================================================

# Find clang-format executable
find_program(CLANG_FORMAT_EXECUTABLE
    NAMES clang-format-17 clang-format-16 clang-format-15 clang-format-14 clang-format
    DOC "Path to clang-format executable"
)

if(CLANG_FORMAT_EXECUTABLE)
    message(STATUS "Found clang-format: ${CLANG_FORMAT_EXECUTABLE}")
    
    # Get all project source files (excluding external dependencies)
    file(GLOB_RECURSE ALL_CXX_SOURCE_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cxx
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hxx
    )
    
    # Add test files if they exist
    if(BOLTDBG_BUILD_TESTS AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests")
        file(GLOB_RECURSE TEST_SOURCE_FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.hpp
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.h
        )
        list(APPEND ALL_CXX_SOURCE_FILES ${TEST_SOURCE_FILES})
    endif()
    
    # Add example files if they exist
    if(BOLTDBG_BUILD_EXAMPLES AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples")
        file(GLOB_RECURSE EXAMPLE_SOURCE_FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/examples/*.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/examples/*.hpp
            ${CMAKE_CURRENT_SOURCE_DIR}/examples/*.h
        )
        list(APPEND ALL_CXX_SOURCE_FILES ${EXAMPLE_SOURCE_FILES})
    endif()
    
    # Remove duplicates
    list(REMOVE_DUPLICATES ALL_CXX_SOURCE_FILES)
    
    # Target: format - Format all source files in-place
    add_custom_target(format
        COMMAND ${CLANG_FORMAT_EXECUTABLE}
        -i
        -style=file
        ${ALL_CXX_SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Formatting all source files with clang-format"
        VERBATIM
    )
    
    # Target: format-check - Check formatting without modifying files (CI-friendly)
    add_custom_target(format-check
        COMMAND ${CLANG_FORMAT_EXECUTABLE}
        --dry-run
        --Werror
        -style=file
        ${ALL_CXX_SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Checking code formatting (no modifications)"
        VERBATIM
    )
    
    # Target: format-diff - Show diff of formatting changes
    add_custom_target(format-diff
        COMMAND ${CLANG_FORMAT_EXECUTABLE}
        --dry-run
        --Werror
        -style=file
        --output-replacements-xml
        ${ALL_CXX_SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Showing formatting differences"
        VERBATIM
    )
    
    message(STATUS "Clang-format targets added: format, format-check, format-diff")
else()
    message(WARNING "clang-format not found. Format targets will not be available.")
    message(WARNING "Install with: sudo apt-get install clang-format (Linux) or brew install llvm (macOS)")
endif()

# ==============================================================================
# Clang-Tidy Integration
# ==============================================================================

# Find clang-tidy executable
find_program(CLANG_TIDY_EXECUTABLE
    NAMES clang-tidy-17 clang-tidy-16 clang-tidy-15 clang-tidy-14 clang-tidy
    DOC "Path to clang-tidy executable"
)

if(CLANG_TIDY_EXECUTABLE)
    message(STATUS "Found clang-tidy: ${CLANG_TIDY_EXECUTABLE}")
    
    # Option to enable clang-tidy during build (slower but catches issues early)
    option(ENABLE_CLANG_TIDY "Run clang-tidy during compilation" OFF)
    
    if(ENABLE_CLANG_TIDY)
        # Enable clang-tidy for all targets
        set(CMAKE_CXX_CLANG_TIDY 
            ${CLANG_TIDY_EXECUTABLE};
            --config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy;
            --header-filter=${CMAKE_CURRENT_SOURCE_DIR}/(src|include|tests|examples)/.*;
            --warnings-as-errors=*;
        )
        message(STATUS "clang-tidy ENABLED during build (slower compilation)")
        message(STATUS "Disable with: cmake -DENABLE_CLANG_TIDY=OFF")
    else()
        message(STATUS "clang-tidy available for manual runs")
        message(STATUS "Enable during build with: cmake -DENABLE_CLANG_TIDY=ON")
    endif()
    
    # Target: tidy - Run clang-tidy on all source files
    add_custom_target(tidy
        COMMAND ${CMAKE_COMMAND} -E echo "Running clang-tidy analysis..."
        COMMAND ${CLANG_TIDY_EXECUTABLE}
        -p ${CMAKE_BINARY_DIR}
        --config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy
        ${ALL_CXX_SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-tidy static analysis"
        VERBATIM
    )
    
    # Target: tidy-fix - Run clang-tidy and apply automatic fixes
    add_custom_target(tidy-fix
        COMMAND ${CMAKE_COMMAND} -E echo "Running clang-tidy with automatic fixes..."
        COMMAND ${CMAKE_COMMAND} -E echo "This will modify your source files!"
        COMMAND ${CLANG_TIDY_EXECUTABLE}
        -p ${CMAKE_BINARY_DIR}
        --config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy
        --fix
        --fix-errors
        ${ALL_CXX_SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-tidy with automatic fixes (MODIFIES FILES)"
        VERBATIM
    )
    
    # Target: tidy-src - Run clang-tidy only on src/ directory (faster)
    file(GLOB_RECURSE SRC_ONLY_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc
    )
    add_custom_target(tidy-src
        COMMAND ${CLANG_TIDY_EXECUTABLE}
        -p ${CMAKE_BINARY_DIR}
        --config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy
        ${SRC_ONLY_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-tidy on src/ only"
        VERBATIM
    )
    
    message(STATUS "Clang-tidy targets added: tidy, tidy-fix, tidy-src")
else()
    message(WARNING "clang-tidy not found. Tidy targets will not be available.")
    message(WARNING "Install with: sudo apt-get install clang-tidy (Linux) or brew install llvm (macOS)")
endif()

# ==============================================================================
# Combined Quality Check Targets
# ==============================================================================

if(CLANG_FORMAT_EXECUTABLE AND CLANG_TIDY_EXECUTABLE)
    # Target: check - Run both format-check and tidy (ideal for CI)
    add_custom_target(check
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target format-check
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target tidy
        COMMENT "Running all code quality checks (format + tidy)"
        VERBATIM
    )
    
    # Target: fix-all - Format code and apply tidy fixes
    add_custom_target(fix-all
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target format
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target tidy-fix
        COMMENT "Applying all automatic fixes (MODIFIES FILES)"
        VERBATIM
    )
    
    message(STATUS "Combined targets added: check, fix-all")
    message(STATUS "")
    message(STATUS "Code Quality Targets Available:")
    message(STATUS "  make format        - Format all code")
    message(STATUS "  make format-check  - Check formatting (CI)")
    message(STATUS "  make tidy          - Run static analysis")
    message(STATUS "  make tidy-fix      - Apply tidy fixes")
    message(STATUS "  make check         - Run all checks (CI)")
    message(STATUS "  make fix-all       - Apply all fixes")
endif()

# ==============================================================================
# Documentation
# ==============================================================================
message(STATUS "")
message(STATUS "Code Quality Tools:")
if(CLANG_FORMAT_EXECUTABLE)
    message(STATUS "  ✓ clang-format: ${CLANG_FORMAT_EXECUTABLE}")
else()
    message(STATUS "  ✗ clang-format: not found")
endif()
if(CLANG_TIDY_EXECUTABLE)
    message(STATUS "  ✓ clang-tidy:   ${CLANG_TIDY_EXECUTABLE}")
    if(ENABLE_CLANG_TIDY)
        message(STATUS "    (enabled during build)")
    endif()
else()
    message(STATUS "  ✗ clang-tidy:   not found")
endif()
message(STATUS "")

# ============================================================================
# Sanitizers flags summary (if your included Sanitizers.cmake sets flags, keep it)
# (Sanitizers.cmake is optional and included at top if exists)
# ============================================================================

# ============================================================================
# Summary
# ============================================================================
message(STATUS "")
message(STATUS "========================================")
message(STATUS "  BoltDBG ${PROJECT_VERSION}")
message(STATUS "========================================")
message(STATUS "Build type:       ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ compiler:     ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "")
message(STATUS "Options:")
message(STATUS "  Build tests:    ${BOLTDBG_BUILD_TESTS}")
message(STATUS "  Build examples: ${BOLTDBG_BUILD_EXAMPLES}")
message(STATUS "  System libs:    ${BOLTDBG_USE_SYSTEM_LIBS}")
message(STATUS "  ASAN:           ${BOLTDBG_ENABLE_ASAN}")
message(STATUS "  UBSAN:          ${BOLTDBG_ENABLE_UBSAN}")
message(STATUS "  TSAN:           ${BOLTDBG_ENABLE_TSAN}")
message(STATUS "========================================")
message(STATUS "")
