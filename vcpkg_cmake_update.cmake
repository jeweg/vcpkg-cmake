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