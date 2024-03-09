# A file in which configurations can be applied
# CMake first loads the global config and then the local config which overrides values from the global config
# Make a local version of this file using `make config-make` and edit that file, which is ignored by Git
# Note that this is technically ACE and not a config file as CMake will execute the content of this file

# This variable should be incremented every time a change is made to the global config
# Then the user can use `make config-diff` to determine what has changed from their local version
# Only update this in the local config when new changes in the global config have been manually merged
# Setting to a version above the global config won't generate a warning, but there is a notice
set(CONFIG_VERSION "1.2.0")

#
# Program Settings
#

# If we should print build logs at runtime in the release program
set(RELEASE_PRINT_OPENCL_ONLINE_BUILD_LOGS FALSE)

# If we should print build logs at runtime in the debug program
set(DEBUG_PRINT_OPENCL_ONLINE_BUILD_LOGS TRUE)

# 
# Optimisation Settings
#

# Use or not use optimisation flags
# NOTE: Only when using GNU GCC and CMake compilers will optimisation arguments be passed
#       i.e. I have no idea what would happen if using MSVC, for example
set(NO_OPTIMISATION FALSE)

# Should we use O2 or O3
# Set TRUE to use O2
# NOTE: NO_OPTIMISATION overrides this and disables optimisation entirely
set(AVOID_AGGRESSIVE_OPTIMISATION FALSE)


#
# Preprocessor definition settings
#

# Weather or not we want to see some noise in an OpenCV window
set(USE_OPENCV_STUFF TRUE)


