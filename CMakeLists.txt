# Version requirement: CXX_STANDARD C++23, otherwise 3.12 works
cmake_minimum_required(VERSION 3.20)

# Set our project name
set(PROJ_NAME xoshiro-opencl)
# Set the project name
project(${PROJ_NAME})

# Ask the compiler to give us some warnings
if (WIN32) # WIN32 is set to true when the target system is windows, including 64-bit according to the CMake docs
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else()
    # pedantic mode gives us warnings for non-ISO C syntax
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
endif()


# Here we do something perhaps non-standard
# We include a file not tracked by Git if it exists which is our config


# Set some optimisation flags
# See https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html for details
# CLang has a similar system
# Also allow the user to entirely dissable these optimisation flags
if( (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (NOT DEFINED NO_OPTIMISATION) )

    # If this is a debug build
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        # "Optimise debugging experience"
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Og")
        message(NOTICE "== Using debug optimisation flags")
    
    # If this is not a debug build
    else()

        # Check if we wanna avoid agressive optimisation
        if(NOT DEFINED AVOID_AGRESSIVE_OPTIMISATION)
            # Agressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
            # Tell the user
            message(NOTICE "== Using agressive optimisation flags")
            message(NOTICE "    == Try AVOID_AGRESSIVE_OPTIMISATION=1 if debug build works and release fails")
        else()
            # Use less agressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
            # Tell the user
            message(NOTICE "== Using O2 optimisation flags")
            message(NOTICE "    == Try NO_OPTIMISATION=1 if debug build works and release fails")
        endif()
    endif()
else()
    # Let the user know we're not passing optimisation flags
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        message(NOTICE "== Using ${CMAKE_CXX_COMPILER_ID} compiler without optimisation flags")
    else()
        # Throw a warning if the user isn't using GCC or Clang
        message(WARNING "== You are not compiling with GCC or Clang.")
    endif()

endif()


# Find our libraries
find_package(OpenCL REQUIRED)
find_package(OpenCV REQUIRED)

# Pass preprocessor definitions
add_compile_definitions(USE_OPENCV_STUFF=1)


# Add main.cpp to the executable
add_executable(${PROJ_NAME} main.cpp)

# Inlcude source and header files from the src dir (and all subsequent directories which that directory imports)
add_subdirectory(${PROJECT_SOURCE_DIR}/src)
# Also include files from our git submodules directory
add_subdirectory(${PROJECT_SOURCE_DIR}/gsubmods)


# Get the (global) lbiraries we're using
target_link_libraries(${PROJECT_NAME} PRIVATE OpenCL::OpenCL)
target_link_libraries(${PROJECT_NAME} PRIVATE ${OpenCV_LIBS})


# C++23 gives us some nice features
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD 23)
# # Use C23 because we use embed (not in GCC 14 yet...)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD   23)

# Define this behaviour
# Note that the program will still compile in GCC 11, even if it is missing some C++23 features
# But, for example using GCC 11.4.0, this produces an error when targeting C++26 where using GCC 14.0.1-experimental everything is dandy
# So, whilst this statement isn't a fool-proof way of checking the user has a compatible compiler,
# it should at least give erros in extreme cases when the compiler is many versions behind
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD_REQUIRED ON) # We aren't using any modern C features

# Copy our kernels into the build dir
# So this here isn't a part of the artefact, but instead something that GCC needs to compile our artefact
# Which is hopefully signified by using the "resources" directory which in my mind implies "build resources"
# The binary therefore does not need our kerenl or resource directories
# These files are copied only because I couldn't figure out a nice way of getting incbin to recognise the project directory and not the build directory
# NOTE: This command does NOT delete files. Always execute clean if removing files from source "./kernels" to avoid annoyance
file(INSTALL src/kernels DESTINATION resources/.) # FOLLOW_SYMLINK_CHAIN is an option i
