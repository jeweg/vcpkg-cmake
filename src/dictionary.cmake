# This implements a list of key-value pairs organized in (non-hierarchical) sections.
# The data structure is implemented in a family of variable names with a provided prefix.
#
# <variable_prefix>_sections): the list of section names
# <variable_prefix>_section_<section name>_keys: the list of keys names in that section 
# <variable_prefix>_section_<section name>_value_for_<key name>: the value for that key in that section

cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0012 NEW)
cmake_policy(SET CMP0057 NEW)


function(vcm_dict_clear variable_prefix)
    unset(${variable_prefix}_sections CACHE)
endfunction()


function(vcm_dict_get variable_prefix section key result)
    #message("vcm_dict_get: ${variable_prefix}_section_${section}_value_for_${key} = ${${variable_prefix}_section_${section}_value_for_${key}}")
    set(${result} ${${variable_prefix}_section_${section}_value_for_${key}} PARENT_SCOPE)
endfunction()


function(vcm_dict_set variable_prefix section key value)
    set(sections ${${variable_prefix}_sections})
    if (NOT sections OR NOT section IN_LIST sections)
        list(APPEND sections ${section})
        set(${variable_prefix}_sections "${sections}" CACHE INTERNAL "TODO")
        # We might have leftover keys from previous runs.
        unset(${variable_prefix}_section_${section}_keys CACHE)
    endif()
    set(keys ${${variable_prefix}_section_${section}_keys})
    if (NOT key IN_LIST keys)
        list(APPEND keys ${key})
        set(${variable_prefix}_section_${section}_keys ${keys} CACHE INTERNAL "TODO")
    endif()
    set(${variable_prefix}_section_${section}_value_for_${key} ${value} CACHE INTERNAL "TODO")
endfunction()


function(vcm_dict_append variable_prefix section key value)
    set(sections ${${variable_prefix}_sections})
    if (NOT section IN_LIST sections)
        list(APPEND sections ${section})
        set(${variable_prefix}_sections ${sections} CACHE INTERNAL "TODO")
        # We might have leftover keys from previous runs.
        unset(${variable_prefix}_section_${section}_keys CACHE)
    endif()
    set(keys ${${variable_prefix}_section_${section}_keys})
    if (NOT key IN_LIST keys)
        list(APPEND keys ${key})
        set(${variable_prefix}_section_${section}_keys ${keys} CACHE INTERNAL "TODO")
    endif()
    set(value_list ${${variable_prefix}_section_${section}_value_for_${key}})
    list(APPEND value_list ${value})
    set(${variable_prefix}_section_${section}_value_for_${key} ${value_list} CACHE INTERNAL "TODO")
endfunction()


function(vcm_dict_unset variable_prefix section key)
    set(sections ${${variable_prefix}_sections})
    set(keys ${${variable_prefix}_section_${section}_keys})
    if (key IN_LIST keys)
		# Remove from keys list
        list(REMOVE_ITEM keys ${key})
		set(${variable_prefix}_section_${section}_keys ${keys} CACHE INTERNAL "TODO")
        # If this left this section without keys, remove the section as well.
        list(LENGTH keys keys_count)
        if (keys_count EQUAL 0)
            list(REMOVE_ITEM sections ${section})
			set(${variable_prefix}_sections ${sections} CACHE INTERNAL "TODO")
        endif()
		# Unset the value itself
		unset(${variable_prefix}_section_${section}_value_for_${key} CACHE)
    endif()
endfunction()


# Note that values are compared with STREQUAL.
function(vcm_dict_equals variable_prefix1 variable_prefix2 result)
    # Short-circuit comparison with itself
	if (variable_prefix1 STREQUAL variable_prefix2)
        set(${result} ON PARENT_SCOPE)
        return()
	endif()

    # Loop through the union of both dicts' sections
    set(all_sections ${${variable_prefix1}_sections} ${${variable_prefix2}_sections})
    list(REMOVE_DUPLICATES all_sections)
    foreach (section IN LISTS all_sections)

		# If a section is missing from one of them, it's an early out.
        if (NOT section IN_LIST ${variable_prefix1}_sections OR
            NOT section IN_LIST ${variable_prefix2}_sections)
			set(${result} OFF PARENT_SCOPE)
			return()
		endif()

		# Otherwise do the same with the section's keys.
		set(all_keys ${${variable_prefix1}_section_${section}_keys} ${${variable_prefix2}_section_${section}_keys})
		list(REMOVE_DUPLICATES all_keys)
        foreach (key IN LISTS all_keys)

			if (NOT key IN_LIST ${variable_prefix1}_section_${section}_keys OR
				NOT key IN_LIST ${variable_prefix2}_section_${section}_keys)
				set(${result} OFF PARENT_SCOPE)
				return()
			endif()

			# Lastly, compare values.
			vcm_dict_get(${variable_prefix1} "${section}" "${key}" value1)
			vcm_dict_get(${variable_prefix2} "${section}" "${key}" value2)
            # Fun fact: if (NOT value1 STREQUAL value2) without quotes is
            # for some reason true for empty string values.
			if (NOT "${value1}" STREQUAL "${value2}")
				set(${result} OFF PARENT_SCOPE)
				return()
			endif()
        endforeach() # key loop
    endforeach() # section loop
	set(${result} ON PARENT_SCOPE)
endfunction()


function(vcm_dict_load variable_prefix filename)
	file(STRINGS "${filename}" lines)
    set(current_section)
    set(sections)
    foreach (line IN LISTS lines)
        if (line MATCHES "^[ \t]*$")
            # Line is empty, ignore.
            continue()
        elseif (line MATCHES "^[ \t]*#")
            # Line is a comment, ignore.
            continue()
        elseif (line MATCHES "^[ \t]*\\[[ \t]*([^ \t]+)[ \t]*\\][ \t]*$")
            # Section start
            set(current_section "${CMAKE_MATCH_1}")
            list(APPEND sections "${current_section}")
            set(${variable_prefix}_sections "${sections}" CACHE INTERNAL "TODO")
        elseif (line MATCHES "^[ \t]*([^ \t]+)[ \t]*=[ \t]*(.*)[ \t]*$")
            # Key-value pair
            if (NOT current_section)
                # It's debatable whether this should be an error.
                #message(FATAL_ERROR "Key-value pair outside of section")
                continue()
            endif()
            set(key "${CMAKE_MATCH_1}")
            set(value "${CMAKE_MATCH_2}")
            list(APPEND section_${current_section}_keys "${key}")
            set(${variable_prefix}_section_${current_section}_keys "${section_${current_section}_keys}" CACHE INTERNAL "TODO")
            set(section_${current_section}_value_for_${key} "${value}")
            set(${variable_prefix}_section_${current_section}_value_for_${key} "${section_${current_section}_value_for_${key}}" CACHE INTERNAL "TODO")
        endif()
    endforeach()
endfunction()


function(vcm_dict_save variable_prefix filename)
	file(WRITE "${filename}" "# Generated by vcpkg-cmake, changes will be overwritten!\n")
    foreach (section IN LISTS ${variable_prefix}_sections)
        file(APPEND "${filename}" "[${section}]\n")
        foreach (key IN LISTS ${variable_prefix}_section_${section}_keys)
            file(APPEND "${filename}" "${key}=${${variable_prefix}_section_${section}_value_for_${key}}\n")
        endforeach()
        file(APPEND "${filename}" "\n")
    endforeach()
endfunction()


function(vcm_dict_print variable_prefix)
    foreach (section IN LISTS ${variable_prefix}_sections)
        message(STATUS "[${section}]")
        foreach (key IN LISTS ${variable_prefix}_section_${section}_keys)
            list(JOIN ${variable_prefix}_section_${section}_value_for_${key} ", " joined)
            message(STATUS "  ${key}=${joined}")
        endforeach()
    endforeach()
endfunction()

