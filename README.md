This template uses CMake to build Pidgin 2 (libpurple 2) protocol plug-ins in a way that does not suck.  
Because having one Makefile for each toolchain is annoying.

On Windows, this will automatically setup a development environment. These compilers are known to work:

* [MinGW](https://osdn.net/projects/mingw/) with GCC 9.2.0.  
* Microsoft Visual Studio 2022 with MSVC 14.

This is being used in purple-whatsmeow and may or may not become the basis for a re-write of purple-signal.

### Linux:

    cmake -DPurple_DIR=wherever/purple-cmake ..
    cmake --build .
    sudo cmake --install .
    pidgin -d -c pidgin_config
    
This will use the system-managed pidgin installation.

### Windows

1. Configure:

    This will set-up a development environment including a pidgin installation in your build directory.

        cmake -DCMAKE_BUILD_TYPE=Debug -G "MSYS Makefiles" ..

    Note: You can use vcpkg-managed packages by adding the path like this: 
    
        -DCMAKE_PREFIX_PATH=…/vcpkg/installed/x86-windows-static

2. Build:

        cmake --build .
    
3. Install:

    This will install into the pidgin installation in your build directory.

        cmake --install .
    
4. Execute:

    This will execute the pidgin installation.

        cmake --build . --target run

    Note: You can specify the Purple user configuration directory in your build directory:
    
        -DPurple_CONFIG_DIR=wherever/.purple
