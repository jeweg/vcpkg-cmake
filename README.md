# vcpkg-based-project

Ongoing experiment to find a good way to integrate vcpkg usage with a git and CMake-based project.

What we plan to do here, as part of the CMake run:
* Clone (shallow, we don't want to work on vcpkg itself) a specific commit of vcpkg itself and any ports that deviate from the vcpkg commit

## Considerations

### How to clone vcpkg and ports?
* git submodule is not powerful enough to specify per-port commits.
* CMake's `ExternalProject` (CMake 2.8.2+) seems to wrap git nicely, but again, the port-specific commits would be a problem.

git can of course be used directly like his:
    git clone $vcpkg_url .
    git checkout $vcpkg_commit 
    git checkout $hiredis_commit ports/hiredis

### Build time vs CMake configuration time
* Bootstrapping vcpkg and ports?
* Installing packages?

## TODO
* Install packages from the list file (is it fast enough to just call `vcpkg install` for each package on every build?)
* Configure Travis/AppVeyor (no tests on Apple yet)
* Configurable: vcpkg git url (might want to use own fork), vcpkg (default) commit

## References:
* [A good overview of the different ways of integrating external libraries into a git project](https://github.com/google/googletest/tree/master/googletest#incorporating-into-an-existing-cmake-project)
* https://www.infohit.net/blog/post/git-checkout-subdirectory-with-sparse-shallow-checkout/
* https://github.com/Microsoft/vcpkg/blob/master/docs/about/faq.md#how-do-i-use-different-versions-of-a-library-on-one-machine
* https://github.com/microsoft/vcpkg/issues/6727
