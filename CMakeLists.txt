cmake_minimum_required(VERSION 3.0)

include(${CMAKE_SOURCE_DIR}/cmake/common.cmake)

#################################################
#
# Install cmake rerun trigger 
#
#################################################

if (NOT EXISTS ${VCPKG_CMAKE__CMAKE_RERUN_TRIGGER_FILE})
    file(WRITE ${VCPKG_CMAKE__CMAKE_RERUN_TRIGGER_FILE} "# DO NOT EDIT.\n#This file was automatically created to be able to trigger re-evaluation of the CMake files.")
endif()
include(${VCPKG_CMAKE__CMAKE_RERUN_TRIGGER_FILE})

#################################################
#
# Bootstrap vcpkg if necessary
#
#################################################

include(${CMAKE_SOURCE_DIR}/cmake/check-vcpkg.cmake)

set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)

#################################################
#
# Install vcpkg toolchain
#
#################################################

# Suppresses a warning about no packages installed from the vcpkg toolchain file.
set(previous_CMAKE_IN_TRY_COMPILE ${_CMAKE_IN_TRY_COMPILE})
set(_CMAKE_IN_TRY_COMPILE TRUE)

# This call references CMAKE_TOOLCHAIN_FILE
project(vcpkg-experiment)

set(_CMAKE_IN_TRY_COMPILE ${previous_CMAKE_IN_TRY_COMPILE})

#################################################
#
# Install re-checking callbacks
#
#################################################

add_custom_target(CheckVcpkg
    ALL
    ${CMAKE_COMMAND} -E ${check_vcpkg_script})

#################################################
#
# Actually project-specific 
#
#################################################

find_package(fmt CONFIG REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main PRIVATE fmt::fmt)

