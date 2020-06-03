include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

vcm_dict_get(vcm_config vcpkg repo_url vcpkg_repo_url)
vcm_dict_get(vcm_config vcpkg vcpkg_dir vcpkg_dir)
vcm_dict_get(vcm_config vcpkg default_commit vcpkg_default_commit)

if(WIN32)
    set(vcpkg_exec "${vcpkg_dir}/vcpkg.exe")
    set(vcpkg_bootstrap "${vcpkg_dir}/bootstrap-vcpkg.bat")
else()
    set(vcpkg_exec "${vcpkg_dir}/vcpkg")
    set(vcpkg_bootstrap "${vcpkg_dir}/bootstrap-vcpkg.sh")
endif()

# ===================================================================
# Clone vcpkg (only if the directory does not exist)

vcm_msg("Looking for vcpkg...")

set(_vcm_needs_cloning FALSE)
if (EXISTS "${vcpkg_dir}") 
    if (NOT IS_DIRECTORY "${vcpkg_dir}")
        message(FATAL_ERROR "vcpkg dir \"${vcpkg_dir}\" exists and is not a directory")
    else()
        file(GLOB tmp "${vcpkg_dir}/*")
        list(LENGTH tmp tmp)
        if (tmp EQUAL 0)
            set(_vcm_needs_cloning TRUE)
        endif()
    endif()
else()
    file(MAKE_DIRECTORY "${vcpkg_dir}")
    set(_vcm_needs_cloning TRUE)
endif()

if (_vcm_needs_cloning)
    vcm_msg("Cloning vcpkg to \"${vcpkg_dir}\"...")
    file(MAKE_DIRECTORY "${vcpkg_dir}")

    vcm_dict_get(vcm_config vcpkg shallow_clone shallow_clone)
    if (NOT enable_metrics)
        list(APPEND cmd_args -disableMetrics)
    endif()

    set(extra_cmd_args)
    if (shallow_clone)
        list(APPEND extra_cmd_args --depth 1)
    endif()
    _vcm_cmd_git(clone ${extra_cmd_args} "${vcpkg_repo_url}" . WORKING_DIRECTORY "${vcpkg_dir}")

    if (NOT _vcm_cmd_last_result EQUAL 0)
        message(FATAL_ERROR "cloning failed!")
    endif()
    if (vcpkg_default_commit)
        _vcm_cmd_git(checkout "${vcpkg_default_commit}" WORKING_DIRECTORY "${vcpkg_dir}")
        if (NOT _vcm_cmd_last_result EQUAL 0)
            message(FATAL_ERROR "checkout failed!")
        endif()
    endif()

endif()

# We now assume a valid vcpkg clone in the specified directory.
# Now figure out if it needs to be bootstrapped.

function(check_if_vcpkg_stale out_result)
    set(vcpkg_exec_stale TRUE)
    if (EXISTS "${vcpkg_exec}") 
        _vcm_cmd_vcpkg(version CATCH_OUTPUT)
        if (_vcm_cmd_last_output MATCHES "version ([0-9]+\\.[0-9]+\\.[0-9]+)") 
            set(reported_version ${CMAKE_MATCH_1})
            set(version_file_contents)
            file(READ "${vcpkg_dir}/toolsrc/VERSION.txt" version_file_contents LIMIT 100)
            if (version_file_contents MATCHES "([0-9]+\\.[0-9]+\\.[0-9]+)") 
                set(toolsrc_version ${CMAKE_MATCH_1})
                if (reported_version VERSION_EQUAL toolsrc_version) 
                    #vcm_msg("vcpkg executable exists and matches sources version, skipping bootstrapping.")
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
    vcm_msg("Bootstrapping vcpkg...")

    set(cmd_args "${vcpkg_bootstrap}")
    vcm_dict_get(vcm_config vcpkg enable_metrics enable_metrics)
    if (NOT enable_metrics)
        list(APPEND cmd_args -disableMetrics)
    endif()
    _vcm_cmd_run(${cmd_args})

    check_if_vcpkg_stale(is_stale)
    if (is_stale) 
        vcm_msg("Bootstrapping vcpkg failed!")
        # TODO: maybe have a vcpkg_cmake_fatal
        message(FATAL_ERROR "failure.")
    endif()
endif()

vcm_msg("vcpkg executable okay.")

# ===================================================================
# Install vcpkg packages

foreach (package_name IN LISTS vcm_config_sections)
    if (NOT package_name STREQUAL "vcpkg")

        vcm_dict_get(vcm_config ${package_name} triplet triplet)
        vcm_dict_get(vcm_config ${package_name} features features)

        # Note that for package foo, "vcpkg install foo[]:" is a valid command.

        set(triplet_part "${triplet}")
        if (NOT triplet_part)
            set(triplet_part "${vcpkg_default_commit}")
        endif()
        if (triplet_part)
            set(triplet_part ":${triplet_part}")
        endif()
        list(JOIN features "," features_part)
        if (features_part)
            set(features_part "[${features_part}]")
        endif()
        set(full_name "${package_name}${features_part}${triplet_part}")

        vcm_msg("=================================================")
        vcm_msg()
        vcm_msg("Installing ${full_name}")
        vcm_msg()
        vcm_msg("=================================================")
        # --recurse makes it possible to switch features. Without it,
        # vcpkg won't recompile.
        _vcm_cmd_vcpkg(install --recurse ${full_name})
    endif()
endforeach()

# ===================================================================
# Lastly, write the config as we now assume it has been actualized.

vcm_dict_save(vcm_config ${_vcm_last_actualized_config_file})
