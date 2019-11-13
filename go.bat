pushd build
del /Q /F *
cmake -G "Visual Studio 16 2019" -A x64 ..
cmake --build .
popd
call build\Debug\main.exe
rem pause