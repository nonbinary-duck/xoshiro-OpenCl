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
include(config_global.cmake)

# Make a copy of the config version included from the global config
set(GLOBAL_CONFIG_VERSION ${CONFIG_VERSION})

# Then override the global config by anything included in the optional local config
# In CMAKE 3.29 there is the option IS_READABLE which is better
if(EXISTS "${PROJECT_SOURCE_DIR}/config_local.cmake")
    # Instead of using the optional argument for include, we search for the file and tell the user what we're doing
    include(config_local.cmake)
    message(NOTICE "== Using local config")

    # If the local version is lesser than the global one, display a warning
    if( CONFIG_VERSION VERSION_LESS GLOBAL_CONFIG_VERSION )
        # Report when there has been an update to the global config
        message(WARNING "== Local config ver ${CONFIG_VERSION} lesser than global ver ${GLOBAL_CONFIG_VERSION}\nExecute `make config-diff` to determine differences")
    elseif( CONFIG_VERSION VERSION_EQUAL GLOBAL_CONFIG_VERSION )
        # Report when things are normal
        message(NOTICE "== Local config up-to-date")
    else()
        # If the user has set their local config to a value greater than the global it's
        # probably an intentional way of saying "Don't bother me", so we don't bother them
        message(NOTICE "== Local config ignoring global config version structure")
    endif()
    
else()
    message(NOTICE "== Not using local config")
endif()




# Set some optimisation flags
# See https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html for details
# CLang has a similar system
# Also allow the user to entirely disable these optimisation flags
if( (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (NOT NO_OPTIMISATION) )

    # If this is a debug build
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        # "Optimise debugging experience"
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Og")
        message(NOTICE "== Using debug optimisation flags")
    
    # If this is not a debug build
    else()

        # Check if we wanna avoid aggressive optimisation
        if(NOT AVOID_AGGRESSIVE_OPTIMISATION)
            # Aggressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
            # Tell the user
            message(NOTICE "== Using aggressive optimisation flags")
            message(NOTICE "    == Try toggling AVOID_AGGRESSIVE_OPTIMISATION if debug build works and release fails")
        else()
            # Use less aggressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
            # Tell the user
            message(NOTICE "== Using O2 optimisation flags")
            message(NOTICE "    == Try toggling NO_OPTIMISATION if debug build works and release fails")
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

# If we're using OpenCV
if(USE_OPENCV_STUFF)
    message(NOTICE "== Using OpenCV stuff")
    
    # Find that library
    find_package(OpenCV REQUIRED)
    
    # Pass preprocessor definitions
    add_compile_definitions(USE_OPENCV_STUFF=1)
else()
    message(NOTICE "== Not using OpenCV stuff")
endif()

# Preprocessor definitions RE: online kernels
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    if (DEBUG_PRINT_OPENCL_ONLINE_BUILD_LOGS)

        add_compile_definitions(PRINT_OCL_ONLINE_LOGS=1)

        message(NOTICE "== Defined (for preprocessor) PRINT_OCL_ONLINE_LOGS=1")

    endif()
else()
    if (RELEASE_PRINT_OPENCL_ONLINE_BUILD_LOGS)

        add_compile_definitions(PRINT_OCL_ONLINE_LOGS=1)

        message(NOTICE "== Defined (for preprocessor) PRINT_OCL_ONLINE_LOGS=1")

    endif()
endif()

# Add main.cpp to the executable
add_executable(${PROJ_NAME} main.cpp)

# Include source and header files from the src dir (and all subsequent directories which that directory imports)
add_subdirectory(${PROJECT_SOURCE_DIR}/src)
# Also include files from our git submodules directory
add_subdirectory(${PROJECT_SOURCE_DIR}/gsubmods)


# Get the (global) libraries we're using
target_link_libraries(${PROJECT_NAME} PRIVATE OpenCL::OpenCL)
# If we're using OpenCV stuff
if(USE_OPENCV_STUFF)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${OpenCV_LIBS})
endif()


# C++23 gives us some nice features
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD 23)
# # Use C23 because we use embed (not in GCC 14 yet...)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD   23)

# Define this behaviour
# Note that the program will still compile in GCC 11, even if it is missing some C++23 features
# But, for example using GCC 11.4.0, this produces an error when targeting C++26 where using GCC 14.0.1-experimental everything is fine
# So, whilst this statement isn't a fool-proof way of checking the user has a compatible compiler,
# it should at least give errors in extreme cases when the compiler is many versions behind
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD_REQUIRED ON) # We aren't using any modern C features

# Copy our kernels into the build dir
# So this here isn't a part of the artefact, but instead something that GCC needs to compile our artefact
# The binary therefore does not need our kernel or resource directories
# These files are copied only because I couldn't figure out a nice way of getting incbin to recognise the project directory and not the build directory
# NOTE: This command does NOT delete files. Always execute clean if removing files from source "./kernels" to avoid annoyance
file(INSTALL src/kernels DESTINATION build_resources/.) # FOLLOW_SYMLINK_CHAIN is an option i
