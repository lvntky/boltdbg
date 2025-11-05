# Unit tests for BoltDBG

# Optionally enable sanitizers for test builds
if(BOLTDBG_ENABLE_ASAN)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address)
endif()

# Collect test sources
set(TEST_SOURCES
    test_main.cpp
    test_logger.cpp
)

add_executable(boltdbg_tests ${TEST_SOURCES})
target_include_directories(boltdbg_tests PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(boltdbg_tests PRIVATE libboltdbg)

# If using CTest (already enabled from top-level)
add_test(NAME boltdbg_tests COMMAND boltdbg_tests)
