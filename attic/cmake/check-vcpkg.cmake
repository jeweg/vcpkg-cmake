include(${CMAKE_SOURCE_DIR}/cmake/common.cmake)
vcpkg_cmake__msg("check-vcpkg entered")

set(3RD_PARTY_ROOT "${CMAKE_SOURCE_DIR}/3rd_party")
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

#################################################
#
# Bootstrap vcpkg if necessary
#
#################################################

set(vcpkg_exec_stale TRUE)
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
    vcpkg_cmake__msg("vcpkg seems stale -- bootstrapping it.")
    execute_process(COMMAND ${VCPKG_BOOTSTRAP} WORKING_DIRECTORY ${VCPKG_ROOT})
endif()

#################################################
#
# Process vcpkg packages
#
#################################################

set(package_list)
vcpkg_cmake__parse_packages_list(package_list)
vcpkg_cmake__msg(${package_list})

if (OFF)
#################################################
#
# Run vcpkg install
#
#################################################

set(command "${VCPKG_EXEC} install --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} --triplet ${VCPKG_TRIPLET} fmt")
execute_process(
    COMMAND ${VCPKG_EXEC} install --overlay-triplets=${VCPKG_OVERLAY_TRIPLETS_DIR} --triplet ${VCPKG_TRIPLET} fmt
    RESULT_VARIABLE return_code
    OUTPUT_VARIABLE cmd_stdout
    ERROR_VARIABLE cmd_stderr 
)

if (${return_code} STREQUAL "0")
    vcpkg_cmake__msg("Package installation/check successful: fmt")
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
    vcpkg_cmake__msg(FATAL_ERROR "vcpkg failure.\ncommand: ${command}\noutput ${msg}")
endif()
endif()
