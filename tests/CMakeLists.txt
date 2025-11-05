# tests/CMakeLists.txt
# Build tests as an executable and reuse boltdbg_core object files.

# Simple pattern: expect tests/*.cpp (you can change glob as needed)
file(GLOB TEST_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.cc)

if(NOT TEST_SOURCES)
    message(STATUS "No test sources found in ${CMAKE_CURRENT_SOURCE_DIR}, skipping tests.")
    return()
endif()

# Create tests executable (link object files from boltdbg_core so no separate lib is needed)
add_executable(boltdbg_tests ${TEST_SOURCES})

# Make sure boltdbg_core target exists (error early if not)


# Link dependencies used by tests (gtest or other test frameworks). Example: if you use Threads and platform libs:
if(TARGET spdlog::spdlog)
    target_link_libraries(boltdbg_tests PRIVATE spdlog::spdlog)
endif()
if(TARGET imgui)
    target_link_libraries(boltdbg_tests PRIVATE imgui)
endif()
if(TARGET glad)
    target_link_libraries(boltdbg_tests PRIVATE glad)
endif()
if(DEFINED PLATFORM_LIBS AND PLATFORM_LIBS)
    target_link_libraries(boltdbg_tests PRIVATE ${PLATFORM_LIBS})
endif()
if(TARGET Threads::Threads)
    target_link_libraries(boltdbg_tests PRIVATE Threads::Threads)
endif()

# If you use a test framework (e.g. GoogleTest), link it here
# find_package(GTest REQUIRED)
# target_link_libraries(boltdbg_tests PRIVATE GTest::gtest_main)

# Register test
enable_testing()
add_test(NAME boltdbg_tests COMMAND boltdbg_tests)
