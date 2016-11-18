cmake_minimum_required(VERSION 3.3)

# project name
project(HydraTemplate)

SET(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
set(HYDRA_ROOT "../Hydra")

find_package(Hydra REQUIRED)

HydraFind()

HydraAddExecutable(PhSp src/PhSp.cpp)


