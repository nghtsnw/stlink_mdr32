@echo on

if not exist build-mingw32 mkdir build-mingw32
cd build-mingw32
set PATH=C:\Program Files\CMake\bin;C:\mingw-w64\mingw32\bin;%PATH%
cmake -G "MinGW Makefiles" .. -DCMAKE_BUILD_TYPE=Release

mingw32-make clean
mingw32-make
mingw32-make package
cd ..
