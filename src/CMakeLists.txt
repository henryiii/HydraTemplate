
HydraAddExecutable(Empty Empty.cpp)

if(ROOT_FOUND)
    
    # This was buggy until a recent version of CMake
    find_package(Threads)

    # All the targets, cuda, omp, and tbb, use this interface
    target_link_libraries(Empty INTERFACE ${ROOT_LIBRARIES} Threads::Threads)
    target_include_directories(Empty INTERFACE ${ROOT_INCLUDE_DIR})
    target_compile_definitions(Empty INTERFACE FOUND_ROOT)
endif()


# Also an option, but need to split the string
# target_compile_options(Empty INTERFACE ${ROOT_DEFINITIONS})
