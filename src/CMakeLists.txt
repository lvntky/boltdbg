# src/CMakeLists.txt
cmake_minimum_required(VERSION 3.15) # local guard if included standalone

# Collect core sources (placeholder + real sources later)
set(BOLTDBG_CORE_SOURCES
    dummy.cpp            # placeholder; replace/add real core sources here
    # src/core/debugger.cpp
    # src/core/process.cpp
)

# Application executable
add_executable(boltdbg
    main.cpp
    ${BOLTDBG_CORE_SOURCES}
)

# Public include dirs (so main and core can include project headers)
target_include_directories(boltdbg PRIVATE ${CMAKE_SOURCE_DIR}/include)

# Ensure imgui include dirs available for includes like "imgui.h" and "backends/..."
target_include_directories(boltdbg PRIVATE
    ${CMAKE_SOURCE_DIR}/external/imgui
    ${CMAKE_SOURCE_DIR}/external/imgui/backends
)

# Link imgui (various targets depending on provider)
if (TARGET imgui)
    target_link_libraries(boltdbg PRIVATE imgui)
elseif (TARGET imgui::imgui)
    target_link_libraries(boltdbg PRIVATE imgui::imgui)
endif()

# GLFW linking: prefer config target then vendor
if (TARGET GLFW::GLFW)
    target_link_libraries(boltdbg PRIVATE GLFW::GLFW)
elseif (TARGET glfw)
    target_link_libraries(boltdbg PRIVATE glfw)
endif()

# glad (loader)
if (TARGET glad::glad)
    target_link_libraries(boltdbg PRIVATE glad::glad)
elseif (TARGET glad)
    target_link_libraries(boltdbg PRIVATE glad)
endif()

# spdlog
if (TARGET spdlog::spdlog)
    target_link_libraries(boltdbg PRIVATE spdlog::spdlog)
elseif (TARGET spdlog)
    target_link_libraries(boltdbg PRIVATE spdlog)
endif()

# Platform OpenGL libs
if (APPLE)
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
    find_library(COREVIDEO_FRAMEWORK CoreVideo REQUIRED)
    find_library(OPENGL_FRAMEWORK OpenGL REQUIRED)
    target_link_libraries(boltdbg PRIVATE ${COCOA_FRAMEWORK} ${IOKIT_FRAMEWORK} ${COREVIDEO_FRAMEWORK} ${OPENGL_FRAMEWORK})
elseif (WIN32)
    target_link_libraries(boltdbg PRIVATE opengl32)
else()
    find_package(OpenGL REQUIRED)
    target_link_libraries(boltdbg PRIVATE OpenGL::GL dl pthread)
endif()

# Optional: apply project warning settings if you created compiler_warnings.cmake
if (EXISTS "${CMAKE_SOURCE_DIR}/cmake/compiler_warnings.cmake")
    include(${CMAKE_SOURCE_DIR}/cmake/compiler_warnings.cmake)
    set_project_warnings(boltdbg)
endif()
