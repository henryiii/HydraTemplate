# - Find HYDRA
# Find the HYDRA headers. Set HYDRA_ROOT or the include, module, and thrust
#
# Make sure you have the TBB, CUDA, etc. find modules in your cmake path (available with Hydra).
#
# HYDRA_INCLUDE_DIR      - where to find the HYDRA headers
# HYDRA_CMAKE_MODULE_DIR - where to find HYDRA's cmake helpers
# HYDRA_THRUST_DIR       - where to find the variadic thrust
# HYDRA_FOUND            - True if HYDRA is found
# HYDRA_CXX_FLAGS        - Flags for building on your current system
# HydraAddExecutable     - Macro to build Hydra packages

if (HYDRA_INCLUDE_DIR)
    # already in cache, be silent
    set (Hydra_FIND_QUIETLY TRUE)
endif (HYDRA_INCLUDE_DIR)

# find the headers
find_path (HYDRA_ROOT_PATH hydra/Hydra.h cmake/FindCudaArch.cmake
  PATHS
  ${HYDRA_ROOT}
  ${HYDRA_INCLUDE_DIR}
  )

# find the headers
find_path (HYDRA_INCLUDE_DIR hydra/Hydra.h
  PATHS
  ${CMAKE_SOURCE_DIR}/include
  ${CMAKE_INSTALL_PREFIX}/include
  ${HYDRA_ROOT}
  )

find_path(HYDRA_CMAKE_MODULE_DIR FindCudaArch.cmake FindROOT.cmake
    PATHS
    ${HYDRA_ROOT}/cmake
    ${HYDRA_INCLUDE_DIR}/cmake
    ./cmake
  )

find_path(HYDRA_THRUST_DIR thrust/version.h
    PATHS
    ${HYDRA_ROOT}
    ${HYDRA_INCLUDE_DIR}
  )

# handle the QUIETLY and REQUIRED arguments and set HYDRA_FOUND to
# TRUE if all listed variables are TRUE
include (FindPackageHandleStandardArgs)

find_package_handle_standard_args (HYDRA "HYDRA (http://github.com/multithreadcorner/Hydra) could not be found. Set HYDRA_INCLUDE_PATH to point to the headers adding '-DHYDRA_INCLUDE_PATH=/path/to/hydra' to the cmake command." HYDRA_INCLUDE_DIR)

#if (HYDRA_FOUND)
#  set (HYDRA_INCLUDE_DIR ${HYDRA_INCLUDE_PATH})
#endif (HYDRA_FOUND)


######### Preparing basic info ##########

set(HYDRA_GENERAL_FLAGS "-DTHRUST_VARIADIC_TUPLE --std=c++11 -fPIC") # -Wl,--no-undefined,--no-allow-shlib-undefined")

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(HYDRA_CXX_FLAGS ${HYDRA_CXX_FLAGS} "${HYDRA_GENERAL_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0 -march=native -O3")
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(HYDRA_CXX_FLAGS "${HYDRA_GENERAL_FLAGS} -xHost -O3 -march=native")
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(HYDRA_CXX_FLAGS "${HYDRA_GENERAL_FLAGS} -O3")
else()
    set(HYDRA_CXX_FLAGS "${HYDRA_GENERAL_FLAGS} -O3")
endif()

macro(HydraFind)
    message(STATUS "HydraFind")
    if(HYDRA_CMAKE_MODULE_DIR)
        list (FIND ${CMAKE_MODULE_PATH} ${HYDRA_CMAKE_MODULE_DIR} _index)
        if (${_index} EQUAL -1)
            set(CMAKE_MODULE_PATH ${HYDRA_CMAKE_MODULE_DIR} ${CMAKE_MODULE_PATH})
        endif()
    endif()

    find_package(CUDA 8.0)
    find_package(TBB)
    find_package(OpenMP)
endmacro(HydraFind)

macro(HydraAddExecutable NAMEEXE SOURCES)
    
    if(CUDA_FOUND)
        message(STATUS "Making CUDA target: ${NAMEEXE}_cuda")
        set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -std=c++11;
            -I${HYDRA_INCLUDE_DIR} --cudart; static; -O4;
            --expt-relaxed-constexpr; -ftemplate-backtrace-limit=0;
            --expt-extended-lambda;--relocatable-device-code=false;
            --generate-line-info; -Xptxas -fmad=true ;-Xptxas -dlcm=cg;
            -Xptxas --opt-level=4 )

        set(CUDA_SEPARABLE_COMPILATION OFF)
        set(CUDA_VERBOSE_BUILD ON)
        
        include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCudaArch.cmake)

        select_nvcc_arch_flags(NVCC_FLAGS_EXTRA)

        list(APPEND CUDA_NVCC_FLAGS ${NVCC_FLAGS_EXTRA})

        #hack for gcc 5.x.x
        if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
            list(APPEND CUDA_NVCC_FLAGS " -D_MWAITXINTRIN_H_INCLUDED ")
        endif()

        cuda_add_executable("${NAMEEXE}_cuda"
            ${SOURCES}
            OPTIONS -x cu -Xcompiler ${OpenMP_CXX_FLAGS} -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CUDA  -DTHRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP -lgomp
        )
        
        target_link_libraries("${NAMEEXE}_cuda" rt)
        target_include_directories("${NAMEEXE}_cuda" PUBLIC ${HYDRA_INCLUDE_DIR})
    endif()

    if(OMP_FOUND)
        add_executable("${NAMEEXE}_omp" ${SOURCES})
        set_target_properties("${NAMEEXE}_omp" PROPERTIES 
            COMPILE_FLAGS "-DTHRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP ${OpenMP_CXX_FLAGS} ${HYDRA_CXX_FLAGS}")
        target_link_libraries("${NAMEEXE}_omp" ${TBB_LIBRARIES})
        target_include_directories("${NAMEEXE}_omp" PUBLIC ${HYDRA_INCLUDE_DIR})
    endif()

    if(TBB_FOUND)
        add_executable("${NAMEEXE}_tbb" src/PhSp.cpp)
        set_target_properties("${NAMEEXE}_tbb" PROPERTIES 
            COMPILE_FLAGS "-DTHRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB  ${TBB_DEFINITIONS} ${HYDRA_CXX_FLAGS}")
        target_link_libraries("${NAMEEXE}_tbb" ${TBB_LIBRARIES})
        target_include_directories("${NAMEEXE}_tbb" PUBLIC ${TBB_INCLUDE_DIRS} ${HYDRA_INCLUDE_DIR})
    endif()

endmacro(HydraAddExecutable)

if(HYDRA_FOUND)
    if(NOT Hydra_FIND_QUIETLY)
        message(STATUS "Found Hydra: ${HYDRA_INCLUDE_DIR}")
    endif()
else(HYDRA_FOUND)
    if(Hydra_FIND_REQUIRED)
        message(FATAL_ERROR "Could NOT find Hydra")
    endif()
endif()

mark_as_advanced(HYDRA_INCLUDE_PATH HYDRA_GENERAL_FLAGS)


