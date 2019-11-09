#Next up: choose a name for this whole plumbing and a var/func prefix.

# vcpkg cmake
# cmake vcpkg


set(VCPKG_CMAKE__3RD_PARTY_ROOT "${CMAKE_SOURCE_DIR}/3rd_party")
set(VCPKG_CMAKE__VCPKG_ROOT "${VCPKG_CMAKE__3RD_PARTY_ROOT}/vcpkg")
set(VCPKG_CMAKE__PACKAGES_LIST_FILE "${CMAKE_SOURCE_DIR}/vcpkg-packages.txt")
set(VCPKG_CMAKE__CMAKE_RERUN_TRIGGER_FILE "${CMAKE_BINARY_DIR}/vcpkg-cmake-rerun.stamp")
set(VCPKG_CMAKE__CHECK_VCPKG_SCRIPT "${CMAKE_SOURCE_DIR}/cmake/cmake-vcpkg.cmake")

if(WIN32)
    set(VCPKG_CMAKE__VCPKG_EXEC "${VCPKG_ROOT}/vcpkg.exe")
    set(VCPKG_CMAKE__VCPKG_BOOTSTRAP_SCRIPT "${VCPKG_ROOT}/bootstrap-vcpkg.bat")
    set(VCPKG_CMAKE__VCPKG_TRIPLET "x64-windows-custom")
else()
    set(VCPKG_CMAKE__VCPKG_EXEC "${VCPKG_ROOT}/vcpkg")
    set(VCPKG_CMAKE__VCPKG_BOOTSTRAP_SCRIPT "${VCPKG_ROOT}/bootstrap-vcpkg.sh")
    set(VCPKG_CMAKE__VCPKG_TRIPLET "x64-linux-custom")
endif()
 
set(VCPKG_CMAKE__NAMED_MODES
    FATAL_ERROR
    SEND_ERROR 
    WARNING
    AUTHOR_WARNING 
    DEPRECATION 
    NOTICE 
    STATUS
    VERBOSE 
    DEBUG 
    TRACE)


function (vcpkg_cmake__msg)
    set(mode STATUS)
    if (ARGC GREATER 0)
        list(GET ARGN 0 maybe_mode_arg)
        list(FIND VCPKG_CMAKE__NAMED_MODES ${maybe_mode_arg} index)
        if (NOT index EQUAL -1)
            list(REMOVE_AT ARGN 0)
            set(mode ${mayve_mode_arg})
        endif()
    endif()
    message(${mode} "[vcpkg-cmake] ${ARGN}")
endfunction()


function (vcpkg_cmake__parse_packages_list out_package_list)
    file(STRINGS ${VCPKG_CMAKE__PACKAGES_LIST_FILE} lines)
    set(results)
    foreach (line IN LISTS lines)
        if (line MATCHES "^[ \t]*#")
            # Line is a comment. Ignore.
        elseif (line MATCHES "^[ \t]*(.*[^ \t])[ \t]*$")
            list(APPEND results ${CMAKE_MATCH_1})
        endif()
    endforeach()
    set(${out_package_list} ${results} PARENT_SCOPE)
endfunction()
