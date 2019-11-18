mkdir build
pushd build
if not errorlevel 1 del /Q /F * 
if not errorlevel 1 cmake -G "Visual Studio 16 2019" -A x64 ..
if not errorlevel 1 cmake --build .
popd
if not errorlevel 1 call build\Debug\main.exe

rem pause