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

find_package(Git)
if (NOT GIT_FOUND)
    message(FATAL_ERROR "git executable not found!")
endif()

# ===================================================================
# Read the serialized configuration

if (NOT EXISTS "${__vcpkg_cmake__configuration_file}")
    message(FATAL_ERROR "vcpkg configuration not found at ${__vcpkg_cmake__configuration_file}, re-run cmake.")
endif()

__vcpkg_cmake__parse_ini_file("${__vcpkg_cmake__configuration_file}" config)

message("Configuration data:")
foreach (section IN LISTS config_sections)
    message("  [${section}]")
    foreach (key IN LISTS config_section_${section}_keys)
        message("    ${key}=${config_section_${section}_value_for_${key}}")
    endforeach()
endforeach()
