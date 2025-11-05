# cmake/FindGLFW.cmake
#
# Lightweight helper: tries find_package(GLFW3) then pkg-config fallback

# Try the standard find_package
find_package(GLFW3 QUIET)

if (GLFW3_FOUND)
    set(GLFW3_LIBRARIES GLFW)
    set(GLFW3_INCLUDE_DIRS ${GLFW_INCLUDE_DIR})
    set(GLFW3_FOUND TRUE)
else()
    find_package(PkgConfig QUIET)
    if (PKG_CONFIG_FOUND)
        pkg_check_modules(GLFW_PKG glfw3)
        if (GLFW_PKG_FOUND)
            set(GLFW3_FOUND TRUE)
            set(GLFW3_LIBRARIES ${GLFW_PKG_LIBRARIES})
            set(GLFW3_INCLUDE_DIRS ${GLFW_PKG_INCLUDE_DIRS})
            link_directories(${GLFW_PKG_LIBRARY_DIRS})
            include_directories(${GLFW_PKG_INCLUDE_DIRS})
        endif()
    endif()
endif()

if (NOT GLFW3_FOUND)
    set(GLFW3_FOUND FALSE)
endif()

mark_as_advanced(GLFW3_FOUND)
