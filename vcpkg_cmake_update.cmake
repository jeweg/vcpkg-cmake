include(vcpkg_cmake_common.cmake)

# Read the serialized configuration and make sure our vcpkg installation reflects that.
# This code will be ran by vcpkg_cmake_end() and whenever the update_vcpkg target is built.

# * read the serialized configuration
# * do we have a clone of that vcpkg repo (from the configured url)
#   if clone exists, but not from the right origin:
#       if the working copy is unmodified, delete it.
#       else error out. we can't make a decision here.
# * does the clone exist?
#   if not: clone.
# * checkout the right commit of vcpkg
# * checkout the right commits of any packages w/ a different commit hash specified
# * figure out if vcpkg-bootstrap is necessary and possibly bootstrap.
# * install the packages w/ the specified triplet and features.

# TODO: will this update a package if we switched a packcage commit hash? -> test.

# ===================================================================
# Read the serialized configuration

if (NOT EXISTS "${__vcpkg_cmake__configuration_file}")
    vcpkg_cmake_msg(FATAL_ERROR "vcpkg configuration not found at ${__vcpkg_cmake__configuration_file}, re-run cmake.")
endif()

__vcpkg_cmake__parse_ini_file("${__vcpkg_cmake__configuration_file}" config)

vcpkg_cmake_msg("Configuration data:")
foreach (section IN LISTS config_sections)
    vcpkg_cmake_msg("  [${section}]")
    foreach (key IN LISTS config_section_${section}_keys)
        vcpkg_cmake_msg("    ${key}=${config_section_${section}_value_for_${key}}")
    endforeach()
endforeach()

# ===================================================================
# Setup

set(vcpkg_repo_url "${config_section_vcpkg_value_for_repo_url}")
set(vcpkg_dir "${config_section_vcpkg_value_for_vcpkg_dir}")
set(vcpkg_default_commit "${config_section_vcpkg_value_for_default_commit}")
if(WIN32)
    set(vcpkg_exec "${vcpkg_dir}/vcpkg.exe")
    set(vcpkg_bootstrap "${vcpkg_dir}/bootstrap-vcpkg.bat")
else()
    set(vcpkg_exec "${vcpkg_dir}/vcpkg")
    set(vcpkg_bootstrap "${vcpkg_dir}/bootstrap-vcpkg.sh")
endif()

# ===================================================================
# Helpers

function(run_git)
    find_package(Git)
    if (NOT GIT_FOUND)
        vcpkg_cmake_msg(FATAL_ERROR "git executable not found!")
    endif()
    cmake_parse_arguments(ARG "" "WORKING_DIR" "" ${ARGN})
    if (NOT ARG_WORKING_DIR) 
        set(ARGH_WORKING_DIR "${config_section_vcpkg_value_for_repo_url}")
    endif()
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${ARG_UNPARSED_ARGUMENTS}
        WORKING_DIRECTORY "${ARG_WORKING_DIR}"
        RESULT_VARIABLE return_code
        OUTPUT_VARIABLE cmd_stdout
        ERROR_VARIABLE cmd_stderr 
    )
    # Debug output
    if (ON)
        vcpkg_cmake_msg("running git command: [git ${ARG_UNPARSED_ARGUMENTS}]")
        vcpkg_cmake_msg("    return code: ${return_code}")
        vcpkg_cmake_msg("    cmd_stdout:  ${cmd_stdout}")
        vcpkg_cmake_msg("    cmd_stderr:  ${cmd_stderr}")
    endif()
endfunction()   
# ===================================================================
# Clone vcpkg if necessary

vcpkg_cmake_msg("Looking for vcpkg...")
set(must_perform_clone FALSE)
if (NOT EXISTS "${vcpkg_dir}") 
    vcpkg_cmake_msg("vcpkg directory not found, cloning.")
    set(must_perform_clone TRUE)
else()
    # TODO: check if it's from the proper url.

endif()
if (must_perform_clone)
    run_git("clone https://github.com/microsoft/vcpkg.git"
    WORKING_DIRECTORY)
endif()

return()


set(vcpkg_exec_stale TRUE)
if (EXISTS "${vcpkg_exec}") 
    set(output)
    execute_process(
        COMMAND "${vcpkg_exec}" version
        WORKING_DIRECTORY "${vcpkg_dir}"
        OUTPUT_VARIABLE output)
    message("{{ ${output} }}")
    if (output MATCHES "version ([0-9]+\\.[0-9]+\\.[0-9]+)") 
        set(reported_version ${CMAKE_MATCH_1})
        set(version_file_contents)
        file(READ "${VCPKG_ROOT}/toolsrc/VERSION.txt" version_file_contents LIMIT 100)
        if (version_file_contents MATCHES "([0-9]+\\.[0-9]+\\.[0-9]+)") 
            set(toolsrc_version ${CMAKE_MATCH_1})
            if (reported_version VERSION_EQUAL toolsrc_version) 
                set(vcpkg_exec_stale FALSE)
            endif()
        endif()
    endif()
endif()

# Try to find vcpkg.
set(must_perform_clone ON)
#if (EXISTS "${config_section_vcpkg_value_for_vcpkg_dir}") 
#endif()

