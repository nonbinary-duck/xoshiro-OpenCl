#include <stdexcept>
#include <algorithm>
#include <iostream>
#include <vector>
#include <vector>
#include <memory>

#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_TARGET_OPENCL_VERSION 200

#include <CL/opencl.hpp>

// What prefix to use for incbin
#define INCBIN_PREFIX gFile_
#include "gsubmods/incbin/incbin.h"

using std::cout, std::cin, std::endl;

// Include our utils
#include "src/utils.hpp"
#include "src/opencl_utils.hpp"

using utils::tuchar;


// Use incbin to include our kernel files in our binary
INCTXT(test_kernel, "./build_resources/kernels/test_kernel.cl");
INCTXT(xoshiro_kernel, "./build_resources/kernels/xoshiro256**.cl");

const int numElements = 32;



/**
 * @brief The main function of our executable
 * 
 * @param argc Count of command-line arguments
 * @param argv Args, zero is the name of the program
 * @return int An error code
 */
int main(int argc, char *argv[])
{
	// Much of this is code is taken or expanded from the example in CL/opencl.hpp

	// Get the available platforms
	auto *platforms = ocl_utils::find_opencl_2_3_platforms();

	
	// Check if we've found a platform or no
	if (platforms->size() < 1)
	{
		delete platforms;
		throw std::runtime_error("ERROR: No OpenCL 2.0 or newer platform found");
	}

	// "Modify the default platform to be used by subsequent operations"
	cl::Platform plat = cl::Platform::setDefault(platforms->at(0));
	// Check if we've set the default platform successfully
	if (plat != platforms->at(0))
	{
		delete platforms;
		throw std::runtime_error("ERROR: Cannot set default platform");
	}
	else
	{
		// We no longer need a list of platforms
		delete platforms;
		std::cout << "Now using " << plat.getInfo<CL_PLATFORM_NAME>() << " platform" << endl;
	}

	// Make a vector to store our kernel source in
	// The source for these kernels come from the start of the file where we include the files in the binary
	const std::vector<std::string> kernelSource = { gFile_test_kernelData, gFile_xoshiro_kernelData };

	// Build our program!
	auto programOut = ocl_utils::buildKernel( kernelSource );
	cl::Program *program;
	cl::BuildLogType log;

	// If we've received a program or a build log (i.e. an error happened)
	// This works because true==1, so if we changed the order of the output of ocl_utils::buildKernel, this would have to change too
	if (programOut.index())
	{
		// Print a log if we get a build error
		throw std::runtime_error("Failed to build program. Log:\n" + ocl_utils::printBuildLog( std::get<cl::BuildLogType>(programOut) ));
	}
	else
	{
		// Otherwise, get our program and the log
		std::tie( program, log ) = std::get< ocl_utils::program_log_pair >(programOut);

		// If we want to always print the logs, do that
		#ifdef PRINT_OCL_ONLINE_LOGS
			cout << "Online build success. Log:\n" << ocl_utils::printBuildLog( std::get<cl::BuildLogType>(programOut) ) << endl;
		#endif
	}

	// cout << program.index() << endl;
	// cout << program << endl;


	#if USE_OPENCV_STUFF
		
	#endif
	
	// Clean up
	delete program;

	return 0;
}
