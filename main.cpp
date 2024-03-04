#include <algorithm>
#include <iostream>
#include <vector>
#include <vector>
#include <memory>


#define INCBIN_PREFIX gFile_
#include "gsubmods/incbin/incbin.h"

using std::cout, std::cin, std::endl;


// constexpr char FILE_test_kernel[] = {
// 	#embed "kernels/test_kernel.cl" if_empty('N', 'O', '\x15', '\x04') // If the file is empty use negative ack & end of transmission
// };

// constexpr char FILE_xoshiro256stst[] = {
// 	#embed "kernels/xoshiro256**.cl" if_empty('N', 'O', '\x15', '\x04')
// };

// Get the compiler to check that we found a file
// static_assert(FILE_test_kernel != "NO\x15\x04");
// static_assert(FILE_test_kernel != "NO\x15\x04");


// Use 
INCTXT(test_kernel, "./resources/kernels/test_kernel.cl");
INCBIN(xoshiro_kernel, "./resources/kernels/xoshiro256**.cl");

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
	

	// C++11 raw string literal for the first kernel
	std::string kernel1{R"CLC(
		global int globalA;
		kernel void updateGlobal()
		{
			globalA = 75;
		}
	)CLC"};

	std::vector<std::string> programStrings;
	programStrings.push_back(kernel1);

	cl::Program vectorAddProgram(programStrings);
	try {
		vectorAddProgram.build("-cl-std=CL2.0");
	}
	catch (...) {
		// Print build info for all devices
		cl_int buildErr = CL_SUCCESS;
		auto buildInfo = vectorAddProgram.getBuildInfo<CL_PROGRAM_BUILD_LOG>(&buildErr);
		for (auto &pair : buildInfo) {
			std::cerr << pair.second << std::endl << std::endl;
		}

		return 1;
	}

	typedef struct { int *bar; } Foo;

	// Get and run kernel that initializes the program-scope global
	// A test for kernels that take no arguments

	//////////////////
	// SVM allocations

	auto anSVMInt = cl::allocate_svm<int, cl::SVMTraitCoarse<>>();
	*anSVMInt = 5;
	cl::SVMAllocator<Foo, cl::SVMTraitCoarse<cl::SVMTraitReadOnly<>>> svmAllocReadOnly;
	auto fooPointer = cl::allocate_pointer<Foo>(svmAllocReadOnly);
	fooPointer->bar = anSVMInt.get();
	cl::SVMAllocator<int, cl::SVMTraitCoarse<>> svmAlloc;
	std::vector<int, cl::SVMAllocator<int, cl::SVMTraitCoarse<>>> inputA(numElements, 1, svmAlloc);
	cl::coarse_svm_vector<int> inputB(numElements, 2, svmAlloc);

	//////////////
	// Traditional cl_mem allocations

	std::vector<int> output(numElements, 0xdeadbeef);
	cl::Buffer outputBuffer(output.begin(), output.end(), false);
	cl::Pipe aPipe(sizeof(cl_int), numElements / 2);

	// Default command queue, also passed in as a parameter
	cl::DeviceCommandQueue defaultDeviceQueue = cl::DeviceCommandQueue::makeDefault(
		cl::Context::getDefault(), cl::Device::getDefault());

	auto vectorAddKernel =
		cl::KernelFunctor<
			decltype(fooPointer)&,
			int*,
			cl::coarse_svm_vector<int>&,
			cl::Buffer,
			int,
			cl::Pipe&,
			cl::DeviceCommandQueue
			>(vectorAddProgram, "vectorAdd");

	// Ensure that the additional SVM pointer is available to the kernel
	// This one was not passed as a parameter
	vectorAddKernel.setSVMPointers(anSVMInt);

	cl_int error;
	vectorAddKernel(
		cl::EnqueueArgs(
			cl::NDRange(numElements/2),
			cl::NDRange(numElements/2)),
		fooPointer,
		inputA.data(),
		inputB,
		outputBuffer,
		3,
		aPipe,
		defaultDeviceQueue,
		error
		);

	cl::copy(outputBuffer, output.begin(), output.end());

	cl::Device d = cl::Device::getDefault();

	std::cout << "Output:\n";
	for (int i = 1; i < numElements; ++i) {
		std::cout << "\t" << output[i] << "\n";
	}
	std::cout << "\n\n";

	return 0;


	#if USE_OPENCV_STUFF
		
	#endif
	
	return 0;
}
