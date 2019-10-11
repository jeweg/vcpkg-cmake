cmake_minimum_required(VERSION 3.0)

set(3RD_PARTY_ROOT "${CMAKE_CURRENT_LIST_DIR}/3rd_party")
set(VCPKG_ROOT "${3RD_PARTY_ROOT}/vcpkg")

if(WIN32)
    set(VCPKG_EXEC "${VCPKG_ROOT}/vcpkg.exe")
    set(VCPKG_BOOTSTRAP "${VCPKG_ROOT}/bootstrap-vcpkg.bat")
    set(VCPKG_TRIPLET "x64-windows-custom")
else()
    set(VCPKG_EXEC "${VCPKG_ROOT}/vcpkg")
    set(VCPKG_BOOTSTRAP "${VCPKG_ROOT}/bootstrap-vcpkg.sh")
    set(VCPKG_TRIPLET "x64-linux-custom")
endif()
set(VCPKG_OVERLAY_TRIPLETS_DIR "${3RD_PARTY_ROOT}/vcpkg-triplets")
set(VCPKG_TARGET_TRIPLET "${VCPKG_TRIPLET}" CACHE STRING "" FORCE)
set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)

project(vcpkg-experiment)

# Detect if bootstrap necessary
set(VCPKG_EXEC_STALE TRUE)
if (EXISTS ${VCPKG_EXEC}) 
    set(output)
    execute_process(
        COMMAND ${VCPKG_EXEC} version
        WORKING_DIRECTORY ${VCPKG_ROOT}
        OUTPUT_VARIABLE output)
    if (output MATCHES "version ([0-9]+\\.[0-9]+\\.[0-9]+)") 
        set(reported_version ${CMAKE_MATCH_1})
        set(version_file_contents)
        file(READ "${VCPKG_ROOT}/toolsrc/VERSION.txt" version_file_contents LIMIT 100)
        if (version_file_contents MATCHES "([0-9]+\\.[0-9]+\\.[0-9]+)") 
            set(toolsrc_version ${CMAKE_MATCH_1})
            if (reported_version VERSION_EQUAL toolsrc_version) 
                set(VCPKG_EXEC_STALE FALSE)
            endif()
        endif()
    endif()
endif()
if (VCPKG_EXEC_STALE)
    execute_process(COMMAND ${VCPKG_BOOTSTRAP} WORKING_DIRECTORY ${VCPKG_ROOT})
endif()

# This kinda works. No live output, though.
# also: to remove packages manually, we also need to specify overlay dir and triplet, cumbersome.

set(command "${VCPKG_EXEC} install --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} --triplet ${VCPKG_TRIPLET} fmt")
message(STATUS ${command})
execute_process(
COMMAND ${VCPKG_EXEC} install --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} --triplet ${VCPKG_TRIPLET} fmt
OUTPUT_VARIABLE cmd_stdout
ERROR_VARIABLE cmd_stderr 
)

if (cmd_stdout AND FALSE)
    message("${cmd_stdout}")
endif()
if (cmd_stderr)
    message("${cmd_stderr}")
endif()

find_package(fmt CONFIG REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main PRIVATE fmt::fmt)
