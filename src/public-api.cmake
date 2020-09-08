include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)
include(CMakeParseArguments)

set(_vcm_vcpkg_dir)
set(_vcm_in_spec_block ON)

vcm_dict_clear(vcm_config)

function (vcpkg_cmake_begin)

    cmake_parse_arguments(ARG "ENABLE_METRICS;SHALLOW_CLONE" "VCPKG_DIR;COMMIT;DEFAULT_TRIPLET;REPO_URL" "" ${ARGN})
    set(_vcm_in_block 1 PARENT_SCOPE)

    if (ARG_UNPARSED_ARGUMENTS)
        vcm_fatal("Unrecognized arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Set unspecified arguments to defaults
    if (NOT ARG_VCPKG_DIR)
        set(ARG_VCPKG_DIR "${CMAKE_SOURCE_DIR}/3rd_party/vcpkg")
    else()
        _vcm_canonicalize_path("${ARG_VCPKG_DIR}" ARG_VCPKG_DIR)
    endif()

    if (NOT ARG_REPO_URL)
        set(ARG_REPO_URL "https://github.com/microsoft/vcpkg.git")
    endif()

    if (NOT ARG_DEFAULT_TRIPLET)
        if (WIN32)
            # On Windows set the default triplet explicitly, otherwise it selects 
            # x86 (not x64) by default: https://github.com/microsoft/vcpkg/issues/1254
            # Note that CMAKE_SIZEOF_VOID_P is unavailable at this point.
            if (CMAKE_GENERATOR_PLATFORM STREQUAL x64)
                set(ARG_DEFAULT_TRIPLET x64-windows)
            else()
                set(ARG_DEFAULT_TRIPLET x86-windows)
            endif()
        endif()
    endif()

    vcm_dict_set(vcm_config vcpkg repo_url "${ARG_REPO_URL}")
    vcm_dict_set(vcm_config vcpkg vcpkg_dir "${ARG_VCPKG_DIR}")
    vcm_dict_set(vcm_config vcpkg default_commit "${ARG_COMMIT}")
    vcm_dict_set(vcm_config vcpkg default_triplet "${ARG_DEFAULT_TRIPLET}")
    vcm_dict_set(vcm_config vcpkg enable_metrics "${ARG_ENABLE_METRICS}")
    vcm_dict_set(vcm_config vcpkg shallow_clone "${ARG_SHALLOW_CLONE}")

    set(_vcm_vcpkg_dir "${ARG_VCPKG_DIR}" PARENT_SCOPE)
endfunction()


function (vcpkg_cmake_end)
    set(_vcm_in_spec_block OFF PARENT_SCOPE)

    vcm_msg("Current configuration:")
    vcm_dict_print(vcm_config SKIP_EMPTY LINE_PREFIX "  ")
    vcm_dict_save(vcm_config ${_vcm_last_declared_config_file})

    add_custom_target(vcpkg-update
        COMMAND ${CMAKE_COMMAND} -D vcm_build_tree_root=${CMAKE_BINARY_DIR} -P "${_vcm_src_dir}/update-standalone.cmake"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        VERBATIM)

	# Checking possible early-outs, only then fall through to doing the full update checks.
    set(run_full_update ON)
    vcm_msg("vcpkg dir is \"${_vcm_vcpkg_dir}\"")

    if (NOT run_full_update AND NOT EXISTS "${_vcm_vcpkg_dir}")
        set(run_full_update ON)
    endif()

    if (NOT run_full_update AND EXISTS ${_vcm_last_actualized_config_file})
        file(SHA1 "${_vcm_last_declared_config_file}" _vcm_hash_1)
        file(SHA1 "${_vcm_last_actualized_config_file}" _vcm_hash_2)
        if (NOT _vcm_hash_1 STREQUAL _vcm_hash_2)
			set(run_full_update ON)
        endif()
    endif()

    if (run_full_update)
		include(${_vcm_src_dir}/update.cmake)
	else()
		vcm_msg("Skipping vcpkg update. Build the vcpkg-update target to force an update.")
    endif()

    set(CMAKE_TOOLCHAIN_FILE "${_vcm_vcpkg_dir}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)
endfunction()


function (vcpkg_cmake_package package_name)
    if (NOT _vcm_in_spec_block)
        message(FATAL_ERROR "vcpkg_cmake_package: called outside of vcpkg_cmake block!")
    endif()
    if (NOT package_name)
        message(FATAL_ERROR "vcpkg_cmake_package: package name must be specified!")
	elseif (package_name STREQUAL vcpkg)
        message(FATAL_ERROR "vcpkg_cmake_package: options to vcpkg must be specified with vcpkg_cmake_begin")
    endif()
    # cmake_parse_arguments(<prefix> <options> <one_value_keywords> <multi_value_keywords> args…)
    cmake_parse_arguments(ARG "" "TRIPLET;COMMIT" "FEATURES" ${ARGN})

    vcm_dict_set(vcm_config ${package_name} triplet "${ARG_TRIPLET}")
    vcm_dict_set(vcm_config ${package_name} commit_hash "${ARG_COMMIT}")
    vcm_dict_set(vcm_config ${package_name} features "${ARG_FEATURES}")
endfunction()
