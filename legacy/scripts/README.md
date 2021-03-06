Raspberry build scripts
=======================

`fetch-llvm-src.sh`
-------------------

Automatically download and places all the LLVM source files into a given folder, ready to build.

Usage example:
```
$ ./fetch-llvm-src.sh --no-llvm --projects libcxx libcxxabi --tools  --version 90
You need to install curl for this to work. I will install it for you since you are root in docker.
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
  openssl
The following NEW packages will be installed:
  ca-certificates curl openssl
0 upgraded, 3 newly installed, 0 to remove and 0 not upgraded.
Need to get 1265 kB of archives.
After this operation, 2297 kB of additional disk space will be used.
[... apt installing]
Pulling libcxx from https://github.com/llvm-mirror/libcxx/archive/release_90.zip
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   127  100   127    0     0    631      0 --:--:-- --:--:-- --:--:--   631
100 7513k  100 7513k    0     0  2188k      0  0:00:03  0:00:03 --:--:-- 2655k
libcxx.zip: Zip archive data, at least v1.0 to extract
Pulling libcxxabi from https://github.com/llvm-mirror/libcxxabi/archive/release_90.zip
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   130  100   130    0     0    734      0 --:--:-- --:--:-- --:--:--   730
100  790k  100  790k    0     0   451k      0  0:00:01  0:00:01 --:--:--  837k
libcxxabi.zip: Zip archive data, at least v1.0 to extract
```

`cross-build-libcxx.sh`
-----------------------
Downloads and cross-compiles `libc++` of the given version for the Raspberry Pi.
This can also be used as an usage example for the cross-compiling toolchain.
Assumes that there is a Raspberry Pi sysroot at `/usr/share/rpi-sysroot` and
that the `src/cmake_toolchains/RPi.cmake` toolchain is placed at `/usr/share/RPi.cmake`
(although this is customizable). Will then install the library in the very same sysroot.
Uses `fetch-llvm-src.sh` as a base to obtain the sources.
Of course, `make`, `cmake` and cross-compilers must be available.

Usage example:
```
>> The script will download and crosscompile libc++ and libc++abi with the following settings:
>>   LLVM version:         90
>>   Toolchain CMake file: /usr/share/RPi.cmake
>>   Build type:           MinSizeRel
>>   Install prefix:       /root/prefix
/root/fetch-llvm-src.sh --no-llvm --projects libcxx libcxxabi --tools  --version 90 /tmp/tmp.T7sijQMxyQ
[... fetch-llvm-src.sh output]
/tmp/tmp.YnaJCol8GA /
cmake -DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,notext -DCMAKE_TOOLCHAIN_FILE=/usr/share/RPi.cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/root/prefix -DLIBCXXABI_LIBCXX_PATH=/tmp/tmp.T7sijQMxyQ/llvm/projects/libcxx -DLIBCXXABI_LIBCXX_INCLUDES=/tmp/tmp.T7sijQMxyQ/llvm/projects/libcxx/include -Wno-dev /tmp/tmp.T7sijQMxyQ/llvm/projects/libcxxabi
-- The CXX compiler identification is Clang 7.0.1
-- The C compiler identification is Clang 7.0.1
[...]
-- Build files have been written to: /tmp/tmp.YnaJCol8GA
make -j 8
Scanning dependencies of target cxxabi_shared
Scanning dependencies of target cxxabi_static
[  2%] Building CXX object src/CMakeFiles/cxxabi_shared.dir/cxa_aux_runtime.cpp.o
[...]
[100%] Linking CXX static library ../lib/libc++abi.a
[100%] Linking CXX shared library ../lib/libc++abi.so
ld: warning: lld uses extended branch encoding, no object with architecture supporting feature detected.
ld: warning: lld may use movt/movw, no object with architecture supporting feature detected.
[100%] Built target cxxabi_static
[100%] Built target cxxabi_shared
make install
[ 50%] Built target cxxabi_static
[100%] Built target cxxabi_shared
Install the project...
-- Install configuration: "MinSizeRel"
-- Installing: /root/prefix/lib/libc++abi.so.1.0
-- Installing: /root/prefix/lib/libc++abi.so.1
-- Installing: /root/prefix/lib/libc++abi.so
-- Installing: /root/prefix/lib/libc++abi.a
rm -rf ./CMakeCache.txt ./CMakeFiles ./Makefile ./cmake_install.cmake ./fuzz ./install_manifest.txt ./lib ./src ./test
cmake -DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,notext -DCMAKE_TOOLCHAIN_FILE=/usr/share/RPi.cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/root/prefix -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/tmp/tmp.T7sijQMxyQ/llvm/projects/libcxxabi/include -DLIBCXX_CXX_ABI_LIBRARY_PATH=/root/prefix/lib -Wno-dev /tmp/tmp.T7sijQMxyQ/llvm/projects/libcxx
-- The CXX compiler identification is Clang 7.0.1
-- The C compiler identification is Clang 7.0.1
[...]
-- Configuring for standalone build.
-- Found LLVM_CONFIG_PATH as /usr/bin/llvm-config
-- Linker detection: LLD
-- Could NOT find PythonInterp (missing: PYTHON_EXECUTABLE)
CMake Warning at CMakeLists.txt:41 (message):
  Failed to find python interpreter.  The libc++ test suite will be disabled.

[...]
-- Configuring done
-- Generating done
-- Build files have been written to: /tmp/tmp.YnaJCol8GA
make -j 8
Scanning dependencies of target cxx_abi_headers
[  2%] Copying C++ ABI header cxxabi.h...
[  2%] Copying C++ ABI header __cxxabi_config.h...
[  2%] Built target cxx_abi_headers
Scanning dependencies of target cxx_shared
Scanning dependencies of target cxx_static
[  4%] Building CXX object src/CMakeFiles/cxx_static.dir/algorithm.cpp.o
[...]
[ 95%] Linking CXX static library ../lib/libc++.a
[ 95%] Built target cxx_static
[ 97%] Linking CXX shared library ../lib/libc++.so
ld: warning: lld uses extended branch encoding, no object with architecture supporting feature detected.
ld: warning: lld may use movt/movw, no object with architecture supporting feature detected.
[ 97%] Built target cxx_shared
Scanning dependencies of target cxx_experimental
[ 98%] Building CXX object src/CMakeFiles/cxx_experimental.dir/experimental/memory_resource.cpp.o
[100%] Linking CXX static library ../lib/libc++experimental.a
[100%] Built target cxx_experimental
make install
[  2%] Built target cxx_abi_headers
[ 50%] Built target cxx_static
[ 97%] Built target cxx_shared
[100%] Built target cxx_experimental
Install the project...
-- Install configuration: "MinSizeRel"
[...]
rm -rf ./CMakeCache.txt ./CMakeFiles ./Makefile ./benchmarks ./cmake_install.cmake ./docs ./include ./install_manifest.txt ./lib ./src ./test
/
rm -rf /tmp/tmp.YnaJCol8GA
rm -rf /tmp/tmp.T7sijQMxyQ
```
