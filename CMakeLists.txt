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
