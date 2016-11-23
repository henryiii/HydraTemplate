cmake_minimum_required(VERSION 3.3)
# Cmake is easy to build and install (you can use an older version to make it)
# and is very backward compatible - setting the min version actually causes
# Cmake to emulate the older version

# Project name and type (c++)
project(HydraTemplate CXX)

# Output the programs in build dir instead of in src/
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

# Include our FindHYDRA module
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

# This assumes this folder is next to the Hydra folder
set(HYDRA_ROOT "../Hydra")

find_package(Hydra REQUIRED)

# Optional find (If using FindROOT.cmake in the Hydra cmake, this must be after Hydra is found)
find_package(ROOT)

# Organization: see src/CMakeLists.txt
add_subdirectory(src)


