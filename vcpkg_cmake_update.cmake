include(${CMAKE_CURRENT_LIST_DIR}/vcpkg_cmake_common.cmake)

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

if (ON)
    vcpkg_cmake_msg("Configuration:")
    foreach (section IN LISTS config_sections)
        vcpkg_cmake_msg("  [${section}]")
        foreach (key IN LISTS config_section_${section}_keys)
            __vcpkg_cmake__list_to_string(tmp ", " ${config_section_${section}_value_for_${key}})
            vcpkg_cmake_msg("    ${key}=${tmp}")
        endforeach()
    endforeach()
endif()

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
set(cmd_last_output)

function(cmd_run)
    cmake_parse_arguments(ARG "CATCH_OUTPUT" "WORKING_DIRECTORY" "" ${ARGN})
    if (NOT ARG_WORKING_DIRECTORY) 
        set(ARG_WORKING_DIRECTORY "${vcpkg_dir}")
    endif()

    set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

    set(catch_output_args)
    if (ARG_CATCH_OUTPUT) 
        set(catch_output_args
            OUTPUT_VARIABLE cmd_output
            ERROR_VARIABLE cmd_output
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
    endif()

    execute_process(
        COMMAND ${ARG_UNPARSED_ARGUMENTS}
        WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}"
        RESULT_VARIABLE return_code
        ${catch_output_args}
    )
    if (NOT return_code EQUAL 0)
        vcpkg_cmake_msg("Command failed: [${ARG_UNPARSED_ARGUMENTS}]")
        vcpkg_cmake_msg("  in: ${ARG_WORKING_DIRECTORY}")
        vcpkg_cmake_msg("  returned: ${return_code}")
        vcpkg_cmake_msg("  output: ${cmd_output}")
        message(FATAL_ERROR "Command execution failed.")
    endif()
    # Debug output
    if (OFF)
        vcpkg_cmake_msg("running command: [${ARG_UNPARSED_ARGUMENTS}]")
        vcpkg_cmake_msg("  return code: ${return_code}")
        vcpkg_cmake_msg("  output: ${cmd_output}")
    endif()
    # TODO: maybe more error handling built-in.
    set(cmd_last_result "${return_code}" PARENT_SCOPE)
    set(cmd_last_output "${cmd_output}" PARENT_SCOPE)
    set(cmd_failed "${command_failed}" PARENT_SCOPE)
endfunction()   


function(cmd_git)
    find_package(Git)
    if (NOT GIT_FOUND)
        vcpkg_cmake_msg(FATAL_ERROR "git executable not found!")
    endif()
    set(cmd_last_result)
    set(cmd_last_output)
    cmd_run("${GIT_EXECUTABLE}" ${ARGV})
    set(cmd_last_result "${cmd_last_result}" PARENT_SCOPE)
    set(cmd_last_output "${cmd_last_output}" PARENT_SCOPE)
endfunction()   


function(cmd_vcpkg)
    set(cmd_last_result)
    set(cmd_last_output)
    cmd_run("${vcpkg_exec}" ${ARGV})
    set(cmd_last_result "${cmd_last_result}" PARENT_SCOPE)
    set(cmd_last_output "${cmd_last_output}" PARENT_SCOPE)
endfunction()   

# ===================================================================
# Clone vcpkg (only if the directory does not exist)

vcpkg_cmake_msg("Looking for vcpkg...")

set(needs_cloning FALSE)
if (EXISTS "${vcpkg_dir}") 
    if (NOT IS_DIRECTORY "${vcpkg_dir}")
        message(FATAL_ERROR "vcpkg dir \"${vcpkg_dir}\" exists and is not a directory")
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
    vcpkg_cmake_msg("Cloning vcpkg to \"${vcpkg_dir}\"...")
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

# We now assume a valid vcpkg clone in the specified directory.
# Now figure out if it needs to be built (bootstrapped).

function(check_if_vcpkg_stale out_result)
    set(vcpkg_exec_stale TRUE)
    if (EXISTS "${vcpkg_exec}") 
        cmd_vcpkg(version CATCH_OUTPUT)
        if (cmd_last_output MATCHES "version ([0-9]+\\.[0-9]+\\.[0-9]+)") 
            set(reported_version ${CMAKE_MATCH_1})
            set(version_file_contents)
            file(READ "${vcpkg_dir}/toolsrc/VERSION.txt" version_file_contents LIMIT 100)
            if (version_file_contents MATCHES "([0-9]+\\.[0-9]+\\.[0-9]+)") 
                set(toolsrc_version ${CMAKE_MATCH_1})
                if (reported_version VERSION_EQUAL toolsrc_version) 
                    #vcpkg_cmake_msg("vcpkg executable exists and matches sources version, skipping bootstrapping.")
                    set(${out_result} FALSE PARENT_SCOPE)
                    return()
                endif()
            endif()
        endif()
    endif()
    set(${out_result} TRUE PARENT_SCOPE)
endfunction()

check_if_vcpkg_stale(is_stale)
if (is_stale) 
    vcpkg_cmake_msg("Bootstrapping vcpkg...")
    cmd_run("${vcpkg_bootstrap}")
    check_if_vcpkg_stale(is_stale)
    if (is_stale) 
        vcpkg_cmake_msg("Bootstrapping vcpkg failed!")
        # TODO: maybe have a vcpkg_cmake_fatal
        message(FATAL_ERROR "failure.")
    endif()
endif()

vcpkg_cmake_msg("vcpkg executable okay.")

# ===================================================================
# Install vcpkg packages

set(default_triplet "${config_section_vcpkg_value_for_default_triplet}")
foreach (package_name IN LISTS config_sections)
    if (NOT package_name STREQUAL "vcpkg")
        set(triplet "${config_section_${package_name}_value_for_triplet}")
        set(features "${config_section_${package_name}_value_for_features}")

        # Note that for package foo, "vcpkg install foo[]:" is a valid command.

        set(triplet_part "${triplet}")
        if (NOT triplet_part)
            set(triplet_part "${default_triplet}")
        endif()
        if (triplet_part)
            set(triplet_part ":${triplet_part")
        endif()
        __vcpkg_cmake__list_to_string(features_part "," ${features})
        if (features_part)
            set(features_part "[${features_string}]")
        endif()
        set(full_name "${package_name}${features_part}${triplet_part}")

        vcpkg_cmake_msg("=================================================")
        vcpkg_cmake_msg("Installing ${package_name}[${features_string}]:${triplet}")
        cmd_vcpkg(install ${full_name})
    endif()
endforeach()

