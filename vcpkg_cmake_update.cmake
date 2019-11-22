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
# Setup, mostly shortcuts for configuration keys

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

set(cmd_last_result)

function(cmd_run)
    cmake_parse_arguments(ARG "" "WORKING_DIRECTORY" "" ${ARGN})
    if (NOT ARG_WORKING_DIRECTORY) 
        set(ARG_WORKING_DIRECTORY "${vcpkg_dir}")
    endif()
    execute_process(
        COMMAND ${ARG_UNPARSED_ARGUMENTS}
        WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}"
        RESULT_VARIABLE return_code
        OUTPUT_VARIABLE cmd_stdout
        ERROR_VARIABLE cmd_stderr 
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )
    if (NOT return_code EQUAL 0)
        vcpkg_cmake_msg("Command failed: [${ARG_UNPARSED_ARGUMENTS}]")
        vcpkg_cmake_msg("  in: ${ARG_WORKING_DIRECTORY}")
        vcpkg_cmake_msg("  returned: ${return_code}")
        vcpkg_cmake_msg("  output: ${cmd_stderr}")
    endif()
    # Debug output
    if (OFF)
        vcpkg_cmake_msg("running git command: [git ${ARG_UNPARSED_ARGUMENTS}]")
        vcpkg_cmake_msg("    return code: ${return_code}")
        vcpkg_cmake_msg("    cmd_stdout:  ${cmd_stdout}")
        vcpkg_cmake_msg("    cmd_stderr:  ${cmd_stderr}")
    endif()
    # TODO: maybe more error handling built-in.
    set(cmd_last_result "${return_code}" PARENT_SCOPE)
endfunction()   


function(cmd_git)
    find_package(Git)
    if (NOT GIT_FOUND)
        vcpkg_cmake_msg(FATAL_ERROR "git executable not found!")
    endif()
    set(cmd_last_result)
    cmd_run("${GIT_EXECUTABLE}" ${ARGV})
    set(cmd_last_result "${return_code}" PARENT_SCOPE)
endfunction()   

# ===================================================================
# Clone vcpkg (only if the directory doesn't exist)

vcpkg_cmake_msg("Looking for vcpkg...")

set(needs_cloning FALSE)
if (EXISTS "${vcpkg_dir}") 
    if (NOT IS_DIRECTORY "${vcpkg_dir}")
        message(FATAL_ERROR "vcpkg dir ... exists and is not a directory")
    else()
        file(GLOB tmp "${vcpkg_dir}/*")
        list(LENGTH tmp tmp)
        if (tmp EQUAL 0)
            set(needs_cloning TRUE)
        endif()
    endif()
else()
    file(MAKE_DIRECTORY "${vcpkg_dir}")
    set(needs_cloning TRUE)
endif()

if (needs_cloning)
    vcpkg_cmake_msg("Cloning vcpkg...")
    file(MAKE_DIRECTORY "${vcpkg_dir}")

    cmd_git(clone "${vcpkg_repo_url}" . WORKING_DIRECTORY "${vcpkg_dir}")
    if (NOT cmd_last_result EQUAL 0)
        message(FATAL_ERROR "cloning failed!")
    endif()
    if (vcpkg_default_commit)
        cmd_git(checkout "${vcpkg_default_commit}" WORKING_DIRECTORY "${vcpkg_dir}")
        if (NOT cmd_last_result EQUAL 0)
            message(FATAL_ERROR "checkout failed!")
        endif()
    endif()

endif()

# We now assume a valid vcpkg in the specified directory

set(vcpkg_exec_stale TRUE)
if (NOT EXISTS "${vcpkg_exec}") 

    message(FATAL_ERROR "no vcpkg executable found!")

else()

    if (CMAKE_NOT_USING_CONFIG_FLAGS IS_FILE "${vcpkg_exec}")
    endif()

    cmd_run("${vcpkg_exec}"

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
