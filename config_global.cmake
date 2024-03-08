# A file in which configurations can be applied
# CMake first loads the global config and then the local config which overrides values from the global config
# Make a local version of this file using `make config-make` and edit that file, which is ignored by Git
# Note that this is technically ACE and not a config file as CMake will execute the content of this file

# This variable should be incremented every time a default 
set(CONFIG_VERSION "1.0")

# 
# Optimisation Settings
#

# Use or not use optimisation flags
# NOTE: Only when using GNU GCC and CMake compilers will optimisaion arguments be passed
#       i.e. I have no idea what would happen if using MSVC, for example
set(NO_OPTIMISATION BOOL FALSE)

# Should we use O2 or O3
# Set TRUE to use O2
# NOTE: NO_OPTIMISATION overrides this and dissables optimisation entirely
set(AVOID_AGRESSIVE_OPTIMISATION BOOL FALSE)


#
# Preprocessor definition settings
#

# Weather or not we want to see some noise in an OpenCV window
set(USE_OPENCV_STUFF BOOL TRUE)


