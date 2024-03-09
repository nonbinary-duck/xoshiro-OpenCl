# We use bash here
SHELL := /bin/bash

# Store the name of our project (so it can be easily edited)
prjName = xoshiro-opencl

# We don't want make to print our enormous commands
# Taken from this stack overflow answer: https://stackoverflow.com/a/11015111
.SILENT:

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
	if [ ! -e ./config_local.cmake ]; then                             \
	    cp config_global.cmake config_local.cmake;                     \
        echo "= Local config file created";                            \
	else                                                               \
	    echo "= Local config file already exists, will not overwrite"; \
	    echo "    = To re-create use \`make config-remake\`";          \
	fi

config-rm:
    # We only want to remove our local config if it's a file
	if [ -f "./config_local.cmake" ]; then rm ./config_local.cmake && echo "= Local config file removed"; fi

config-diff:
    # We need for the local config to exist for this
	if [ -f "./config_local.cmake" ]; then                                                      \
	    diff ./config_local.cmake --to-file=config_global.cmake -y --suppress-common-lines;     \
		DIF=$$?; # Store the output of diff                                                     \
	    if [ $$DIF -eq 1 ]; then printf "\n= Local config (left) is different to the global config\n"; \
	    elif [ $$DIF -eq 0 ]; then echo "= Local and global config files are identical\n";        \
	    else echo "= Diff encountered an error! $$DIF";                                         \
	    fi                                                                                      \
	else                                                                                        \
	    echo "= Local config does not exist";                                                   \
	fi

# A command to remake our config file
config-remake: config-rm config-make

# An alias
config-local: config-make


help:
    # A target to list various targets in this makefile
	printf "Build automation system help menu:\n  Usage: \`make [GNU Make options] [target]\`\n    Executing without [target] is equivalent to \`make release\`\n    Append \`--dry-run\` to inspect what a target will execute\n  Available targets:\n    release:               Build a release version of this project\n    debug: - - - - - - - - Build a debug version\n    only-run-release:      Attempt to execute an already built release executable\n    only-run-debug: - - -  Attempt to execute a debug build's binary\n    release-and-run:       Perform a release build and execute the binary\n    debug-and-run: - - - - Perform a debug build and execute the binary\n    clean:                 Remove all build-related files (i.e. both debug and release)\n    clean-release: - - - - Remove ALL build-related files, then perform a release build\n    clean-debug:           Remove ALL build-related files, then perform a debug build\n    clean-release-and-run: Clean all, build release and run\n    clean-debug-and-run:   Clean all, build debug and run\n    config-make: - - - - - Makes an un-tracked copy of the global config included by the CMake file\n    config-local:          Alias for \`config-make\`\n    config-rm: - - - - - - Removes the local config\n    config-remake:         Executes \`config-rm\` then \`config-make\`\n    config-diff: - - - - - Displays differences between local and global config file\nExecute \`make --help\` for GNU Make options\n"