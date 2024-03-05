# We use bash here
SHELL := /bin/bash

# Store the name of our project
prjName = xoshiro-opencl

# Default option
release:
    # Make the build dir and cd into it, then execute cmake \
	# Use 32 as the job count, it is not a bad thing for this to be higher than the count of processors
	mkdir -p ./build/release && cd ./build/release && cmake ../.. -DCMAKE_BUILD_TYPE=Release && make -j32

# Selected with first arg as "debug"
debug:
    # Make the build dir and cd into it, then execute cmake \
	# We also use 32 as the job count
	mkdir -p ./build/debug && cd ./build/debug && cmake ../.. -DCMAKE_BUILD_TYPE=Debug && make -j32

# Execute various binaries
# Prepend only to make it clear that these do not build then run, and only run
only-run-release:
	cd ./build/release && ./$(prjName)

only-run-debug:
	cd ./build/debug && ./$(prjName)

# Define commands to build then execute
release-and-run: release only-run-release
debug-and-run: debug only-run-debug

# A command to clean up our build file
clean:
	if [ -d "./build" ]; then rm -r ./build; fi

# Define commands to clean and then build etc.
# It is possible that this command is confused for cleaning just the release etc. file
# But to me it makes more sense to have the words in the order they are executed in
clean-release: clean release
clean-debug: clean debug

# Also define commands to clean, then build, then execute
clean-release-and-run: clean release-and-run
clean-debug-and-run: clean debug-and-run

# Utilities related to our config file
config-make:
    # -e checks if that path exists at all (i.e. could be block device, dir etc.)
	if [ ! -e ./config.cmake ]; then                                   \
		cp config_global.cmake config.cmake;                           \
        echo "= Local config file created";                            \
	else                                                               \
		echo "= Local config file already exists, will not overwrite"; \
		echo "    = To re-create use \`make config-remake\`";          \
	fi

config-rm:
    # We only want to remove our local config if it's a file
	if [ -f "./config.cmake" ]; then rm ./config.cmake && echo "= Local config file removed"; fi

# A command to remake our config file
config-remake: config-rm config-make
