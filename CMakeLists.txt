# Barrier to entry being CXX_STANDARD C++23, otherwise 3.12 works
cmake_minimum_required(VERSION 3.20)

set(PROJ_NAME xoshiro-opencl)

# Set the compiler flags
# Wno-reorder disables the reorder warning
if (WIN32) # WIN32 is set to true when the target system is windows, including 64-bit according to the CMake docs
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wno-reorder")
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

# Use c++ 23 because we want the #embed directorate
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD 23)
# We need c++23 as a minimum
set_property(TARGET ${PROJ_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)

# Copy our kernels into the build dir
# See https://stackoverflow.com/a/2178327 & https://cmake.org/cmake/help/latest/command/file.html#copy
#     Particularly:
#         Relative input paths are evaluated with respect to the current source directory,
#         and a relative destination is evaluated with respect to the current build directory
# NOTE: This command does NOT delete files. Execute clean if removing files from source "./kernels"
file(INSTALL kernels DESTINATION .) # FOLLOW_SYMLINK_CHAIN is an option i
