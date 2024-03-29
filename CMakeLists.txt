# Copyright (c) 2019 Intel Corporation.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

cmake_minimum_required(VERSION 3.12)
project(eii-utils VERSION 1.0.0 LANGUAGES C CXX)

# Define CMake options
option(WITH_TESTS    "Compile with unit tests" OFF)

set(EII_COMMON_CMAKE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")
set(EII_C_UTILS_CMAKE "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_CXX_STANDARD 14)

# Include directory for CMake modules
set(CMAKE_MODULE_PATH "${EII_C_UTILS_CMAKE}")

# Find packages
find_package(cJSON REQUIRED)
find_package(IntelSafeString REQUIRED)
find_package(WJE REQUIRED)

# Export compile commands
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json")
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json
        ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
    )
endif()

# Include header directories
include_directories(
    include/
    ${CJSON_LIBRARIES}/
    ${IntelSafeString_INCLUDE}/
    ${WJE_INCLUDE_DIRS})

# Get all source files
file(GLOB SOURCES "src/*.c" "src/*.cpp")
link_directories(${CMAKE_INSTALL_PREFIX}/lib)

# Add target
add_library(eiiutils SHARED ${SOURCES})
target_link_libraries(eiiutils
    PRIVATE
        ${CJSON_LIBRARIES}
        ${OpenCV_LIBRARIES}
        ${IntelSafeString_LIBRARIES}
        ${CMAKE_DL_LIBS}
        ${WJE_LIBRARY})

# If compile in debug mode, set DEBUG flag for C code
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    target_compile_definitions(eiiutils PRIVATE DEBUG=1)
endif()

# Add unit tests if the option was selected
if(WITH_TESTS)
    add_subdirectory(tests/)
endif()

##
## Configure pkg-config file to be installed for the EII Utils
##
set(PKG_CONFIG_IN  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/libeiiutils.pc.in")
set(PKG_CONFIG_OUT "${CMAKE_CURRENT_BINARY_DIR}/libeiiutils.pc")
set(DEST_DIR       "${CMAKE_INSTALL_PREFIX}")
set(PRIVATE_LIBS   "-lcjson")

configure_file(${PKG_CONFIG_IN} ${PKG_CONFIG_OUT} @ONLY)

##
## Add CMake configuration for installing the library including files for other
## projects finding the library using CMake
##

include(GNUInstallDirs)
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/EIIUtils)

install(TARGETS eiiutils
    EXPORT eiiutils-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

set_target_properties(eiiutils PROPERTIES EXPORT_NAME EIIUtils)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# Install pkg-config libeiiutils.pc file
install(
    FILES
        ${PKG_CONFIG_OUT}
    DESTINATION
        ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# Export targets to a script
install(EXPORT eiiutils-targets
    FILE
        EIIUtilsTargets.cmake
    DESTINATION
        ${INSTALL_CONFIGDIR}
)

# Create a ConfigVersion.cmake file
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/EIIUtilsConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/cmake/EIIUtilsConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/EIIUtilsConfig.cmake
    INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
)

# Install the config, configversion and custom find modules
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/EIIUtilsConfigVersion.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/EIIUtilsConfig.cmake
    DESTINATION ${INSTALL_CONFIGDIR}
)

export(EXPORT eiiutils-targets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/EIIUtilsTargets.cmake)

# Register package in user's package registry
export(PACKAGE EIIUtils)
