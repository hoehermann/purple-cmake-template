cmake_minimum_required(VERSION 3.18) # for file(ARCHIVE_EXTRACT ...)

if(NOT ${CMAKE_SIZEOF_VOID_P} EQUAL 4)
    message(FATAL_ERROR "On Windows, Pidgin 2 is 32 bit only.")
endif()

# Pidgin 2.14.12 is shipped with gtk+ 2.16.6 and glib 2.28.8
set(GTK_BUNDLE_ZIP gtk+-bundle_2.16.6-20100912_win32.zip)  # NOTE: This contains glib 2.24.2
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${GTK_BUNDLE_ZIP})
    message(STATUS "Fetching ${GTK_BUNDLE_ZIP}...")
    file(DOWNLOAD http://ftp.gnome.org/pub/gnome/binaries/win32/gtk+/2.16/${GTK_BUNDLE_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${GTK_BUNDLE_ZIP} SHOW_PROGRESS)
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
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP})
    message(STATUS "Fetching ${PIDGIN_SOURCE_ZIP}...")
    file(DOWNLOAD http://prdownloads.sourceforge.net/pidgin/${PIDGIN_SOURCE_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP} SHOW_PROGRESS)
ENDIF()
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}/libpurple/purple.h)
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_SOURCE_ZIP} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/win32)
ENDIF()

set(PIDGIN_BINARY_ZIP ${PIDGIN_DIRNAME}-win32-bin.zip)
IF(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_BINARY_ZIP})
    message(STATUS "Fetching ${PIDGIN_BINARY_ZIP}...")
    file(DOWNLOAD http://prdownloads.sourceforge.net/pidgin/${PIDGIN_BINARY_ZIP} ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_BINARY_ZIP} SHOW_PROGRESS)
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
    COMMAND ${CMAKE_CURRENT_LIST_DIR}/dll2lib.bat 
    ARGS 32 ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin
    MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin/libpurple.dll
    COMMENT "Generating .lib file from .dll..."
    USES_TERMINAL
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
set(PURPLE_DATA_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/win32/${PIDGIN_DIRNAME}-win32bin
)
set(PURPLE_PLUGIN_DIR
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
