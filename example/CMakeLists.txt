cmake_minimum_required(VERSION 3.18) # see purple-config.cmake

project("purple-cmake-sample")

# include purple-cmake config file path
set(CMAKE_PREFIX_PATH "..")
find_package(Purple REQUIRED)

# have some debug output
message(STATUS "PURPLE_INCLUDE_DIRS: ${PURPLE_INCLUDE_DIRS}")
message(STATUS "PURPLE_LIBRARY_DIRS: ${PURPLE_LIBRARY_DIRS}")
message(STATUS "PURPLE_LIBRARIES: ${PURPLE_LIBRARIES}")
message(STATUS "PURPLE_PLUGIN_DIR: ${PURPLE_PLUGIN_DIR}")
message(STATUS "PURPLE_DATA_DIR: ${PURPLE_DATA_DIR}")

# define our target
set(TARGET_NAME "cmake")
add_library(${TARGET_NAME} SHARED 
    "src/c/init.c"
)

file(READ "${CMAKE_SOURCE_DIR}/VERSION" PLUGIN_VERSION)
target_compile_definitions(${TARGET_NAME} PRIVATE PLUGIN_VERSION=${PLUGIN_VERSION})
target_include_directories(${TARGET_NAME} PRIVATE ${PURPLE_INCLUDE_DIRS})
target_link_libraries(${TARGET_NAME} PRIVATE ${PURPLE_LIBRARIES}) # TODO: switch to PkgConfig::Purple
set_target_properties(${TARGET_NAME} PROPERTIES PREFIX "lib")

# declare destinations
if (WIN32)
    install(TARGETS ${TARGET_NAME} RUNTIME DESTINATION "${PURPLE_PLUGIN_DIR}")
else()
    install(TARGETS ${TARGET_NAME} DESTINATION "${PURPLE_PLUGIN_DIR}")
endif()
install(DIRECTORY "pixmaps" DESTINATION "${PURPLE_DATA_DIR}" FILES_MATCHING PATTERN "*.png")
