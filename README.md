# vcpkg-based-project

Ongoing experiment to find a good way to integrate vcpkg usage with a git and CMake-based project.

What we plan to do here, as part of the CMake run:
* Clone (shallow, we don't want to work on vcpkg itself) a specific commit of vcpkg itself and any ports that deviate from the vcpkg commit

## My vcpkg insights

1. You probably really want a separate vcpkg instance per project.
2. You want to use a specific (pinned) commit of vcpkg as there is really no way to avoid backward-incompatible updates breaking your projects.
3. At the same time, we might want to deviate from that pinned vcpkg version for some packages. This makes manual package updates possible, with full control.

## Considerations

### How to clone vcpkg and ports?

Integrating vcpkg as a git submodule is not powerful enough to specify per-port commits.
CMake's `ExternalProject` (CMake 2.8.2+) seems to wrap git nicely, but again, the port-specific commits would be a problem.
git can of course be used directly (git clone $vcpkg_url ., git checkout $vcpkg_commit, git checkout $hiredis_commit ports/hiredis)

-> Use git directly.

### What do do at build time vs at CMake configuration time
* Bootstrapping vcpkg and ports?
* Installing packages?

-> We will see. For now do the entire clone/update cycle as an always-outdated custom target and get some experience with that.
We can always step back to explicit targets for tasks that take too long to run in every build.

## Overview of the current state

In a CMakeLists.txt, use the following pattern to describe vcpkg and the packages to be installed:

    include(vcpkg_cmake.cmake)
    vcpkg_cmake_begin(...)
    vcpkg_cmake_package(<NAME> ...)
    vcpkg_cmake_end()

### vcpkg_cmake_begin

Starts the used package listing and also used to specify properties of vcpkg itself.
This also creates a file in the build directory (`cmake-vcpkg-data.ini`) that will hold all internally required information from the invocations above.
vcpkg_cmake_begin also defines a custom target (`update_vcpkg`) which on every build invokes an internal script (`vcpkg_cmake_update.cmake`).

### vcpkg_cmake_package

Accepts a vcpkg package description (package name and optionally triplet and commit hash). By default, the package from the specified vcpkg version is used, but by providing a commit hash we can mix in packages from different versions.
This function only forwards the package description to to `cmake-vcpkg-data.ini`.

### vcpkg_cmake_end

Called to denote the end of the package list. Runs the aforementioned internal script `vcpkg_cmake_update.cmake` to setup vcpkg and packages.

### vcpkg_cmake_update.cmake

1. Reads `cmake-vcpkg-data.ini` into a dictionary-like data structure (quite ingenious, if I may say so myself)
2. If the vcpkg dir (whose location is configurable in the call to `vcpkg_cmake_begin`) doesn't exist, we clone it and make sure we checkout the possibly specified version. *TODO* Allow for switching repo_url and default_commit. Also define what happens if there are any local changes to vcpkg.
3. Once we have a vcpkg, determine if it's properly bootstrapped. We test for the executable and compare the version reported by the executable with the version from the vcpkg sources. If something doesn't check out ("vcpkg is stale"), call vcpkg's bootstrap script.
4. Now install the vcpkg packes. *TODO* Not implemented yet. This also must support switching triplet and commit hash, if specified for a package.

## TODO
* Install packages from the list file (is it fast enough to just call `vcpkg install` for each package on every build?)
* Configure Travis/AppVeyor (no tests on Apple yet) -- or github actions?
* Configurable: vcpkg git url (might want to use own fork), vcpkg (default) commit
* We might want to do a shallow clone of vcpkg for space/performance. 
* Do we remove packages when their CMake declaration vanishes? (Might just have been temporarily commented out, after all)
* vcpkg command echoing

## References:
* [A good overview of the different ways of integrating external libraries into a git project](https://github.com/google/googletest/tree/master/googletest#incorporating-into-an-existing-cmake-project)
* https://www.infohit.net/blog/post/git-checkout-subdirectory-with-sparse-shallow-checkout/
* https://github.com/Microsoft/vcpkg/blob/master/docs/about/faq.md#how-do-i-use-different-versions-of-a-library-on-one-machine
* https://github.com/microsoft/vcpkg/issues/6727
* https://devblogs.microsoft.com/cppblog/vcpkg-introducing-installation-options-with-feature-packages/