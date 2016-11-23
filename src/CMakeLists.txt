
HydraAddExecutable(Empty Empty.cpp)

if(ROOT_FOUND)
    
    # This was buggy until a recent version of CMake
    find_package(Threads)

    # All the targets, cuda, omp, and tbb, use this interface
    target_link_libraries(Empty INTERFACE ${ROOT_LIBRARIES} Threads::Threads)

    # Due to terrible FindCUDA support for modern CMake, this musth be global:
    include_directories(${ROOT_INCLUDE_DIR})
endif()

