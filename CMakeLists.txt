cmake_minimum_required(VERSION 3.0)
include(vcpkg_cmake.cmake)

# example: zlib
# commit before update to 1.2.11: 6a220edfb8454a4fc1652f82f537518ac620033f
# commit with update to 1.2.11: 97a2b5a793c439a8961f1c51dca4117d1cbd1cc2

vcpkg_cmake_begin(VCPKG_DIR vcpkg COMMIT 00a29c6879db2981093b73fa7006c9d07fb2f861)
vcpkg_cmake_package(zlib TRIPLET foo COMMIT 6a220edfb8454a4fc1652f82f537518ac620033f) # zlib 1.2.10
#vcpkg_cmake_package(zlib COMMIT 97a2b5a793c439a8961f1c51dca4117d1cbd1cc2) # zlib 1.2.11
vcpkg_cmake_end()

project(test CXX)

find_package(ZLIB REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main PRIVATE ZLIB::ZLIB)
