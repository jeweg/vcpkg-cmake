# vcpkg-based-project

Ongoing experiment to find a good way to integrate vcpkg usage with a git and CMake-based project.

What we plan to do here, as part of the CMake run:
* Clone (shallow, we don't want to work on vcpkg itself) a specific commit of vcpkg itself and any ports that deviate from the vcpkg commit

## My vcpkg conclusions

1. You probably really want a separate vcpkg instance per project.
2. You want to use a specific (pinned) commit of vcpkg as there is really no way to avoid backward-incompatible updates breaking your projects.
3. At the same time, we might want to deviate from that pinned vcpkg version for some packages. This makes manual package updates possible, with full control.

## Considerations

### How to clone vcpkg and ports?

Integrating vcpkg as a git submodule is not powerful enough to specify per-port commits.
CMake's `ExternalProject` (CMake 2.8.2+) seems to wrap git nicely, but again, the port-specific commits would be a problem.
git can of course be used directly (git clone $vcpkg_url ., git checkout $vcpkg_commit, git checkout $hiredis_commit ports/hiredis)

-> Use git directly.

## Overview of the current state

In a CMakeLists.txt, use the following pattern to describe vcpkg and the packages to be installed:

    include(vcpkg_cmake.cmake)
    vcpkg_cmake_begin(...)
    vcpkg_cmake_package(<NAME> ...)
    vcpkg_cmake_end()

## References:
* [A good overview of the different ways of integrating external libraries into a git project](https://github.com/google/googletest/tree/master/googletest#incorporating-into-an-existing-cmake-project)
* https://www.infohit.net/blog/post/git-checkout-subdirectory-with-sparse-shallow-checkout/
* https://github.com/Microsoft/vcpkg/blob/master/docs/about/faq.md#how-do-i-use-different-versions-of-a-library-on-one-machine
* https://github.com/microsoft/vcpkg/issues/6727
* https://devblogs.microsoft.com/cppblog/vcpkg-introducing-installation-options-with-feature-packages/