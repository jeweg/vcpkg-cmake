include(${CMAKE_CURRENT_LIST_DIR}/dictionary.cmake)

# When run in -P script mode, CMake sets the variables CMAKE_BINARY_DIR,
# CMAKE_SOURCE_DIR, CMAKE_CURRENT_BINARY_DIR and CMAKE_CURRENT_SOURCE_DIR
# to the current working directory. This is not desired.
# We instead assume the variable vcm_build_tree_root to be properly set
# and make sure that is the case.

set(_vcm_last_declared_config_file "${vcm_build_tree_root}/vcpkg-cmake-config.ini")
set(_vcm_last_actualized_config_file "${vcm_build_tree_root}/vcpkg-cmake-last-actualized-config.ini")
set(_vcm_src_dir "${CMAKE_CURRENT_LIST_DIR}")

function(vcm_msg)
    message(STATUS "[vcpkg-cmake] " ${ARGN})
endfunction()

set(_vcm_cmd_last_result)
set(_vcm_cmd_last_output)

function(_vcm_cmd_run)
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
        vcm_msg("Command failed: [${ARG_UNPARSED_ARGUMENTS}]")
        vcm_msg("  in: ${ARG_WORKING_DIRECTORY}")
        vcm_msg("  returned: ${return_code}")
        vcm_msg("  output: ${cmd_output}")
        message(FATAL_ERROR "Command execution failed.")
    endif()
    # Debug output
    if (OFF)
        vcm_msg("running command: [${ARG_UNPARSED_ARGUMENTS}]")
        vcm_msg("  return code: ${return_code}")
        vcm_msg("  output: ${cmd_output}")
    endif()
    set(_vcm_cmd_last_result "${return_code}" PARENT_SCOPE)
    set(_vcm_cmd_last_output "${cmd_output}" PARENT_SCOPE)
    set(cmd_failed "${command_failed}" PARENT_SCOPE)
endfunction()   


function(_vcm_cmd_git)
    find_package(Git)
    if (NOT GIT_FOUND)
        vcm_msg(FATAL_ERROR "git executable not found!")
    endif()
    set(_vcm_cmd_last_result)
    set(_vcm_cmd_last_output)
    _vcm_cmd_run("${GIT_EXECUTABLE}" ${ARGV})
    set(_vcm_cmd_last_result "${_vcm_cmd_last_result}" PARENT_SCOPE)
    set(_vcm_cmd_last_output "${_vcm_cmd_last_output}" PARENT_SCOPE)
endfunction()   


function(_vcm_cmd_vcpkg)
    set(_vcm_cmd_last_result)
    set(_vcm_cmd_last_output)
    _vcm_cmd_run("${vcpkg_exec}" ${ARGV})
    set(_vcm_cmd_last_result "${_vcm_cmd_last_result}" PARENT_SCOPE)
    set(_vcm_cmd_last_output "${_vcm_cmd_last_output}" PARENT_SCOPE)
endfunction()   


function (_vcm_canonicalize_path path out_path)
    if (IS_SYMLINK "${path}")
        file (READ_SYMLINK "${path}" path)
        if (NOT IS_ABSOLUTE "${path}")
            get_filename_component(dir "${path}" DIRECTORY)
            set(path "${dir}/${path}")
        endif()
    endif()
    if (NOT IS_ABSOLUTE "${path}")
        set (path "${CMAKE_CURRENT_SOURCE_DIR}/${path}")
    endif()
    set (${out_path} "${path}" PARENT_SCOPE)
endfunction()


