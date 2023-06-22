This template uses CMake to build Pidgin 2 (libpurple 2) protocol plug-ins in a way that does not suck.  
Because having one Makefile for each toolchain is annoying.

On Windows, this will automatically setup a development environment geared towards [MinGW](https://osdn.net/projects/mingw/) with GCC 9.2.0.  
Compiling with Microsoft Visual Studio 2022 has not been successful.

This is being used in purple-whatsmeow and may or may not become the basis for a re-write of purple-signal.

### Linux:

    cmake ..
    cmake --build .
    sudo cmake --install .
    pidgin -d -c pidgin
    
This will use the system-managed pidgin installation.

### Windows

1. Configure:

    This will set-up a development environment including a pidgin installation.

        cmake -DCMAKE_BUILD_TYPE=Debug -G "MSYS Makefiles" ..

    Note: You can use vcpkg-managed packages by adding the path like this: 
    
        -DCMAKE_PREFIX_PATH=…/vcpkg/installed/x86-mingw-static

2. Build:

        cmake --build .
    
3. Install:

    This will install into the pidgin installation from the first step.

        cmake --install .
    
4. Execute:

        env PATH="$PATH":dependencies/win32/gtk/bin:dependencies/win32/pidgin-2.14.12-win32bin/ pidgin -d -c pidgin
