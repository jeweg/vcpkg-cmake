cmake_minimum_required(VERSION 3.0)

set(CVCPKG_DEFAULT_COMMIT_HASH) # If left empty, get HEAD
set(3RD_PARTY_ROOT "${CMAKE_SOURCE_DIR}/3rd_party")
set(CVCPKG_VCPKG_DIR "${3RD_PARTY_ROOT}/vcpkg")
set(CVCPKG_VCPKG_REPO_URL "https://github.com/microsoft/vcpkg.git")
set(VCPKG_OVERLAY_TRIPLETS_DIR "${3RD_PARTY_ROOT}/vcpkg-triplets")

if(WIN32)
    set(VCPKG_EXEC "${CVCPKG_VCPKG_DIR}/vcpkg.exe")
    set(VCPKG_BOOTSTRAP "${CVCPKG_VCPKG_DIR}/bootstrap-vcpkg.bat")
    set(VCPKG_TRIPLET "x64-windows-custom")
else()
    set(VCPKG_EXEC "${CVCPKG_VCPKG_DIR}/vcpkg")
    set(VCPKG_BOOTSTRAP "${CVCPKG_VCPKG_DIR}/bootstrap-vcpkg.sh")
    set(VCPKG_TRIPLET "x64-linux-custom")
endif()


function(bootstrap_vcpkg)
    message("** bootstrap_vcpkg called with ${ARGV}")

    if (NOT EXISTS ${CVCPKG_VCPKG_DIR})
        file(MAKE_DIRECTORY ${CVCPKG_VCPKG_DIR})
    endif()

    set(VCPKG_EXEC_STALE TRUE)
    if (EXISTS ${VCPKG_EXEC}) 
        set(output)
        execute_process(
            COMMAND ${VCPKG_EXEC} version
            WORKING_DIRECTORY ${CVCPKG_VCPKG_DIR}
            OUTPUT_VARIABLE output)
        if (output MATCHES "version ([0-9]+\\.[0-9]+\\.[0-9]+)") 
            set(reported_version ${CMAKE_MATCH_1})
            set(version_file_contents)
            file(READ "${CVCPKG_VCPKG_DIR}/toolsrc/VERSION.txt" version_file_contents LIMIT 100)
            if (version_file_contents MATCHES "([0-9]+\\.[0-9]+\\.[0-9]+)") 
                set(toolsrc_version ${CMAKE_MATCH_1})
                if (reported_version VERSION_EQUAL toolsrc_version) 
                    message("** vcpkg executable seems up-to-date,")
                    set(VCPKG_EXEC_STALE FALSE)
                endif()
            endif()
        endif()
    endif()

    if (VCPKG_EXEC_STALE)

        # TODO: this only works the first time
        execute_process(COMMAND git clone ${CVCPKG_VCPKG_REPO_URL} . WORKING_DIRECTORY ${CVCPKG_VCPKG_DIR})
        if (CVCPKG_DEFAULT_COMMIT_HASH)
            execute_process(COMMAND git checkout ${CVCPKG_DEFAULT_COMMIT_HASH} WORKING_DIRECTORY ${CVCPKG_VCPKG_DIR})
        endif()

        message(STATUS "[cvcpkg] bootstrapping vcpkg")
        execute_process(COMMAND ${VCPKG_BOOTSTRAP} WORKING_DIRECTORY ${CVCPKG_VCPKG_DIR})

    endif()

endfunction()

function(install_vcpkg_package package_name)
    message("** install_vcpkg_package called with ${ARGV}")

    if (NOT package_name)
        message(FATAL_ERROR "xxxx")
    endif()
    include(CMakeParseArguments)

    # cmake_parse_arguments(<prefix> <options> <one_value_keywords> <multi_value_keywords> args…)
    cmake_parse_arguments(ARG "" "TRIPLET;COMMIT" "" ${ARGC})
    if (ARG_COMMIT)
        execute_process(COMMAND git checkout ${ARG_COMMIT} ports/${PACKAGE} WORKING_DIRECTORY ${CVCPKG_VCPKG_DIR})
    endif()
    set(command "${VCPKG_EXEC} install ")
    if (VCPKG_OVERLAY_TRIPLETS_DIR)
        set(command "${command} --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} ")
    endif()
    if (ARG_TRIPLET)
        set(command "${command} --triplet ${VCPKG_TRIPLET} ")
    endif()
    set(command "${command} ${package_name}")

    execute_process(
        #COMMAND ${VCPKG_EXEC} install --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} --triplet ${VCPKG_TRIPLET} fmt
        #COMMAND ${command}
        COMMAND D:/__jw__/vcpkg-based-project/3rd_party/vcpkg/vcpkg.exe install --overlay-triplets=D:/__jw__/vcpkg-based-project/3rd_party/vcpkg-triplets fmt
        RESULT_VARIABLE return_code
        OUTPUT_VARIABLE cmd_stdout
        ERROR_VARIABLE cmd_stderr 
    )

    if (${return_code} STREQUAL "0")
        message("Package installation/check successful: fmt")
    else()
        set(msg)
        # Unfortunately, vcpkg errors like "Cannot build windows triplets from non-windows."
        # end up in the non-error output, so we cannot assume the correct stream is used.
        if (cmd_stdout)
            set(msg "${msg} ${cmd_stdout}")
        endif()
        if (cmd_stderr)
            set(msg "${msg} ${cmd_stderr}")
        endif()
        message(FATAL_ERROR "vcpkg failure.\ncommand: ${command}\noutput ${msg}")
    endif()

endfunction()

bootstrap_vcpkg()
install_vcpkg_package(fmt)


set(CMAKE_TOOLCHAIN_FILE "${CVCPKG_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)

# Suppresses a warning about no packages installed from the vcpkg toolchain file.
set(previous_CMAKE_IN_TRY_COMPILE ${_CMAKE_IN_TRY_COMPILE})
set(_CMAKE_IN_TRY_COMPILE TRUE)
# This call references CMAKE_TOOLCHAIN_FILE
project(vcpkg-experiment)
set(_CMAKE_IN_TRY_COMPILE ${previous_CMAKE_IN_TRY_COMPILE})

#################################################
# Project-specific:

find_package(fmt CONFIG REQUIRED)

add_executable(main src/main.cpp)
target_link_libraries(main PRIVATE fmt::fmt)