# Default option
release:
    # Make the build dir and cd into it, then execute cmake
	# Use 32 as the job count, it is not a bad thing for this to be higher than the count of processors
	mkdir -p ./build/release; cd ./build/release; cmake ../.. -DCMAKE_BUILD_TYPE=Release && make -j32

# Selected with first arg as "debug"
debug:
    # Make the build dir and cd into it, then execute cmake
	# We also use 32 as the job count
	mkdir -p ./build/debug; cd ./build/debug; cmake ../.. -DCMAKE_BUILD_TYPE=Debug && make -j32

fresh-debug: clean debug

fresh-release: clean release


# Optionally clean up after the last build
clean:
	if [ -d "./build" ]; then rm -r ./build; fi