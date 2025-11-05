add_library(libboltdbg INTERFACE)
target_include_directories(libboltdbg INTERFACE ${CMAKE_SOURCE_DIR}/include)

add_executable(boltdbg main.cpp)
target_link_libraries(boltdbg PRIVATE libboltdbg)
