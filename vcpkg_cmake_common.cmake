# When run in -P script mode, CMake sets the variables CMAKE_BINARY_DIR,
# CMAKE_SOURCE_DIR, CMAKE_CURRENT_BINARY_DIR and CMAKE_CURRENT_SOURCE_DIR
# to the current working directory.
# We expect the variable build_tree_root to be set so we're mode-agnostic here.

set(__vcpkg_cmake__configuration_file "${build_tree_root}/cmake-vcpkg-data.ini")
set(__vcpkg_cmake__update_script "${CMAKE_SOURCE_DIR}/vcpkg_cmake_update.cmake")

message("build_tree_root = ${build_tree_root}")
message("__vcpkg_cmake__configuration_file = ${__vcpkg_cmake__configuration_file}")
message("__vcpkg_cmake__update_script = ${__vcpkg_cmake__update_script}")

function(__vcpkg_cmake__parse_ini_file file_path variable_prefix)

    # TODO: this code will not remove trailing comments in section or key-value lines.
    # It's unclear if we want that because a hash sign might be valid as part of a value.

    file(STRINGS "${file_path}" lines)
    set(__current_section)
    set(__sections)
    foreach (line IN LISTS lines)
        if (line MATCHES "^[ \t]*$")
            # Line is empty, ignore.
            continue()
        elseif (line MATCHES "^[ \t]*#")
            # Line is a comment, ignore.
            continue()
        elseif (line MATCHES "^[ \t]*\\[[ \t]*([^ \t]+)[ \t]*\\][ \t]*$")
            # Section start
            set(__current_section "${CMAKE_MATCH_1}")
            list(APPEND __sections "${__current_section}")
            set(${variable_prefix}_sections "${__sections}" PARENT_SCOPE)
        elseif (line MATCHES "^[ \t]*([^ \t]+)[ \t]*=[ \t]*(.+)[ \t]*$")
            # Key-value pair
            if (NOT __current_section)
                # It's debatable whether this should be an error.
                #message(FATAL_ERROR "Key-value pair outside of section")
                continue()
            endif()
            set(key "${CMAKE_MATCH_1}")
            set(value "${CMAKE_MATCH_2}")
            list(APPEND __section_${__current_section}_keys "${key}")
            set(${variable_prefix}_section_${__current_section}_keys "${__section_${__current_section}_keys}" PARENT_SCOPE)
            set(__section_${__current_section}_value_for_${key} "${value}")
            set(${variable_prefix}_section_${__current_section}_value_for_${key} "${__section_${__current_section}_value_for_${key}}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()

