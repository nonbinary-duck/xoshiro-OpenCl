# Barrier to entry being CXX_STANDARD C++23, otherwise 3.12 works
cmake_minimum_required(VERSION 3.20)

# Set our project name
set(PROJ_NAME xoshiro-opencl)

# Set the compiler flags
# Wno-reorder disables the reorder warning
if (WIN32) # WIN32 is set to true when the target system is windows, including 64-bit according to the CMake docs
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wno-reorder")
endif()


# Set some optimisation flags
# See https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html for details
# CLang has a similar system
# Also allow the user to entirely dissable these optimisation flags
if( (CMAKE_CXX_COMPILER_ID == "GNU" OR CMAKE_CXX_COMPILER_ID == "Clang") AND (NOT NO_OPTIMISATION) )

    if(CMAKE_BUILD_TYPE == "Debug")
        # "Optimise debugging experience"
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Og")
        message(NOTICE "Using debug optimisation flags")
    else()
        if(NOT AVOID_AGRESSIVE_OPTIMISATION)
            # Agressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
            message(NOTICE "Using agressive optimisation flags\nTry AVOID_AGRESSIVE_OPTIMISATION=1 if debug build works and release fails")
        else()
            # Use less agressive optimisation
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
            message(NOTICE "Using O2 optimisation flags\nTry NO_OPTIMISATION=1 if debug build works and release fails")
        endif()
    endif()
else()
    # Throw a warning if the user isn't using GCC or Clang
    message(WARNING "You are not copiling with GCC or Clang.")
    message(WARNING "${CMAKE_C_COMPILER_ID}")
endif()



# Set the project name
project(${PROJ_NAME})

# Find our libraries
find_package(OpenCL REQUIRED)
find_package(OpenCV REQUIRED)

add_compile_definitions(USE_OPENCV_STUFF=1)

# Give directories where header files are located
include_directories(
    ${PROJECT_SOURCE_DIR}/src
)

# Add main.cpp to the executable
add_executable(${PROJ_NAME} main.cpp)

# Inlcude source files from the src dir
add_subdirectory(${PROJECT_SOURCE_DIR}/src)

target_link_libraries(${PROJECT_NAME} PRIVATE OpenCL::OpenCL)
target_link_libraries(${PROJECT_NAME} PRIVATE ${OpenCV_LIBS})

# C++23 gives us some nice features
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD 23)
# # Use C23 because we use embed (not in GCC 14 yet...)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD   23)

# Define this behaviour
# Note that the program will still compile in GCC 11, but it will
# hopefully give someone with a very outdated compiler a hint to where the issue is
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)
# set_property(TARGET ${PROJ_NAME} PROPERTY C_STANDARD_REQUIRED ON)

# Copy our kernels into the build dir
# See https://stackoverflow.com/a/2178327 & https://cmake.org/cmake/help/latest/command/file.html#copy
#     Particularly:
#         Relative input paths are evaluated with respect to the current source directory,
#         and a relative destination is evaluated with respect to the current build directory
# NOTE: This command does NOT delete files. Execute clean if removing files from source "./kernels"
# file(INSTALL kernels DESTINATION .) # FOLLOW_SYMLINK_CHAIN is an option i

# So, we could indeed use this ⬆ and expect that directory to be moved around with the binary executable,
# but instead we include the files in the binary executable
