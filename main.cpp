#include <algorithm>
#include <iostream>
#include <vector>
#include <vector>
#include <memory>


// 
#define INCBIN_PREFIX gFile_
#include "gsubmods/incbin/incbin.h"

using std::cout, std::cin, std::endl;

#include "src/utils.hpp"


// Use incbin to include our kernel files in our binary
INCTXT(test_kernel, "./build_resources/kernels/test_kernel.cl");
INCTXT(xoshiro_kernel, "./build_resources/kernels/xoshiro256**.cl");

#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_TARGET_OPENCL_VERSION 200

#include <CL/opencl.hpp>


#include "src/utils.hpp"

using utils::tuchar;

const int numElements = 32;


/**
 * @brief Called when the program is launched
 * 
 * @param argc Count of command-line arguments
 * @param argv Args, zero is the name of the program
 * @return int An error code
 */
int main(int argc, char *argv[])
{
	cout << "Hello, world!! I'm xoshiro-opencl :)" << endl;

	cout << gFile_test_kernelData << endl;

	// Much of this is code is taken from the example in CL/opencl.hpp
	// Filter for a 2.0 or newer platform and set it as the default
	std::vector<cl::Platform> platforms;
	// Get available platforms
	cl::Platform::get(&platforms);
	// Where to store a selected platform 
	cl::Platform plat;

	// Loop over our platforms
	for (auto &p : platforms)
	{
		// Get this platforms' opencl version
		std::string platVer = p.getInfo<CL_PLATFORM_VERSION>();

		// Select it if we find a platform of version 2.* or 3.*
		if (platVer.find("OpenCL 2.") != std::string::npos || platVer.find("OpenCL 3.") != std::string::npos)
		{
			// Note: an OpenCL 3.x platform may not support all required features!
			plat = p;

			// Give some details about the platform and don't flush the buffer yet
			std::cout << "Found an OpenCL platform: " << p.getInfo<CL_PLATFORM_NAME>() << ' ' << platVer << p.getInfo<CL_PLATFORM_PROFILE>() << ' ' << p.getInfo<CL_PLATFORM_VENDOR>() << '\n';
		}
	}

	// Check if we've found a platform or no
	if (plat() == 0)
	{
		std::cerr << "No OpenCL 2.0 or newer platform found" << endl;
		return -1;
	}

	// "Modify the default platform to be used by subsequent operations"
	cl::Platform newP = cl::Platform::setDefault(plat);
	// Check if we've set the default platform successfully
	if (newP != plat)
	{
		std::cerr << "Error setting default platform" << endl;
		return -1;
	}
	else
	{
		std::cout << "Now using " << newP.getInfo<CL_PLATFORM_NAME>() << " platform" << endl;
	}


	#if USE_OPENCV_STUFF
		
	#endif
	
	return 0;
}
