cmake_minimum_required(VERSION 3.18) # for file(ARCHIVE_EXTRACT ...)

if(NOT ${CMAKE_SIZEOF_VOID_P} EQUAL 4)
    message(FATAL_ERROR "On Windows, Pidgin 2 is 32 bit only.")
endif()

# Pidgin 2.14.12 is shipped with gtk+ 2.16.6 and glib 2.28.8
# NOTE: There is a purple-flavoured variant of the bundle at https://sourceforge.net/projects/pidgin/files/GTK%2B%20for%20Windows/2.16.6.3/, but the file is larger and less convenient to use
set(GTK_BUNDLE_ZIP gtk+-bundle_2.16.6-20100912_win32.zip) # NOTE: This contains glib 2.24.2
set(GTK_BUNDLE_URL "https://download.gnome.org/binaries/win32/gtk+/2.16/" CACHE STRING "Where to download ${GTK_BUNDLE_ZIP} from.")
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${GTK_BUNDLE_ZIP})
    message(STATUS "Fetching ${GTK_BUNDLE_ZIP}...")
    file(DOWNLOAD ${GTK_BUNDLE_URL}${GTK_BUNDLE_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${GTK_BUNDLE_ZIP} SHOW_PROGRESS EXPECTED_HASH SHA256=8742eeb383641aa8028d1af7fcfc16b164d8a17d4c8489f4e83ab881453eb847)
ENDIF()
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/include/gtk-2.0/gtk/gtk.h)
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/win32/${GTK_BUNDLE_ZIP} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk)
ENDIF()
set(GTK_INCLUDE_DIRS 
    ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/include
    ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/include/glib-2.0
    ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/include/gtk-2.0/gtk
    ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/lib/glib-2.0/include
)
set(GTK_LIBRARY_DIRS 
    ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/lib
)
find_file(GLIB_LIB "glib-2.0.lib" PATHS ${GTK_LIBRARY_DIRS})

# not always strictly considered a part of gtk, but gdk-pixbuf is part of the bundle
set(PIXBUF_INCLUDE_DIRS ${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/include/gtk-2.0)
find_file(PIXBUF_LIB "gdk_pixbuf-2.0.lib" PATHS ${GTK_LIBRARY_DIRS})
set(PIXBUF_LIBRARIES ${PIXBUF_LIB})

set(PIDGIN_VERSION 2.14.13)
set(PIDGIN_DIRNAME pidgin-${PIDGIN_VERSION})
set(PIDGIN_SOURCE_ZIP ${PIDGIN_DIRNAME}.tar.bz2)
set(PIDGIN_BINARY_ZIP ${PIDGIN_DIRNAME}-win32-bin.zip)
set(PIDGIN_SOURCE_URL "http://prdownloads.sourceforge.net/pidgin/" CACHE STRING "Where to download ${PIDGIN_SOURCE_ZIP} and ${PIDGIN_BINARY_ZIP} from.")
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP})
    message(STATUS "Fetching ${PIDGIN_SOURCE_ZIP}...")
    file(DOWNLOAD ${PIDGIN_SOURCE_URL}${PIDGIN_SOURCE_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP} SHOW_PROGRESS EXPECTED_HASH SHA256=120049dc8e17e09a2a7d256aff2191ff8491abb840c8c7eb319a161e2df16ba8)
ENDIF()
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}/libpurple/purple.h)
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/win32)
ENDIF()

IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_BINARY_ZIP})
    message(STATUS "Fetching ${PIDGIN_BINARY_ZIP}...")
    file(DOWNLOAD ${PIDGIN_SOURCE_URL}${PIDGIN_BINARY_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_BINARY_ZIP} SHOW_PROGRESS EXPECTED_HASH SHA256=f3667f3076bebdee8ae687dd694cd2a3a6dffef97c6889b2d14bee61c1c9fa91)
ENDIF()
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll)
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_BINARY_ZIP} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/win32)
ENDIF()
IF (MSVC)
    # MSVC needs a .lib file
    set(LIBPURPLE_LIB ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.lib)
    add_custom_target(
      libpurple_lib
      DEPENDS ${LIBPURPLE_LIB}
    )
    add_custom_command(
        OUTPUT ${LIBPURPLE_LIB}
        COMMAND cmd # this explicitly calls the "cmd" batch processor because the default shell could also be PowerShell or even bash
        ARGS /c ${CMAKE_CURRENT_LIST_DIR}/dll2lib.bat 32 ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin
        MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll
        COMMENT "Generating .lib file from .dll..."
    )
ELSE()
    # MinGW GCC can use the .dll directly
    set(LIBPURPLE_LIB ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll)
ENDIF()

set(PURPLE_INCLUDE_DIRS
    ${GTK_INCLUDE_DIRS}
    ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}/libpurple
)
set(PURPLE_LIBRARIES
    ${GLIB_LIB} ${LIBPURPLE_LIB} 
)
set(_PURPLE_DATA_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin
)
set(_PURPLE_PLUGIN_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/plugins
)
set(PURPLE_VERSION
    ${PIDGIN_VERSION}
)
set(PURPLE_FOUND
    TRUE
)

set(PURPLE_CONFIG_DIR "${CMAKE_CURRENT_BINARY_DIR}/pidgin_config" CACHE PATH "The purple user configuration directory. For production, this is ~/.purple.")
add_custom_target(run
    COMMAND ${CMAKE_COMMAND} -E env "PATH=$ENV{PATH};${CMAKE_CURRENT_BINARY_DIR}/win32/gtk/bin;${CMAKE_CURRENT_BINARY_DIR}/win32/pidgin-${PIDGIN_VERSION}-win32bin" pidgin -d -c ${PURPLE_CONFIG_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
