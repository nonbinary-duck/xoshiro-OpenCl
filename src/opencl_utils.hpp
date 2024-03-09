#ifndef H_360679_SRC_OPENCL_UTILS
#define H_360679_SRC_OPENCL_UTILS 1
#pragma once

#include <variant>
#include <vector>
#include <iosfwd>

#include <CL/opencl.hpp>


namespace ocl_utils
{

    typedef std::pair< cl::Program*, cl::BuildLogType > program_log_pair;

    /**
     * @brief Find available OpenCL version 2.x or 3.x platforms
     * 
     * @return std::vector<cl::Platform> A vector on the heap of ver 2.x or 3.x platforms
     */
    inline std::vector<cl::Platform> *find_opencl_2_3_platforms() noexcept
    {
        // Much of this is code is taken from the example in CL/opencl.hpp
        // Filter for a 2.0 or newer platform and set it as the default
        std::vector<cl::Platform> platforms;
        // Get available platforms
        cl::Platform::get(&platforms);
        // Where to store good platforms
        auto *goodPlatforms = new std::vector<cl::Platform>();

        // Loop over our platforms
        for (auto &p : platforms)
        {
            // Get this platform's opencl version
            std::string platVer = p.getInfo<CL_PLATFORM_VERSION>();

            // Select it if we find a platform of version 2.* or 3.*
            if (platVer.find("OpenCL 2.") != std::string::npos || platVer.find("OpenCL 3.") != std::string::npos)
            {
                // Note: an OpenCL 3.x platform may not support all required features!
                // Add this platform to the list
                goodPlatforms->push_back(p);
            }
        }

        // Return a vector of our good platforms
        return goodPlatforms;
    }

    /**
     * @brief Prints some info about a platform to an ostream
     * 
     * @param p 
     * @param out 
     */
    inline void printPlatformInfo(const cl::Platform &p, std::ostream &out) noexcept
    {
        // Output info about the platform
        out << p.getInfo<CL_PLATFORM_NAME>() << ' ' << p.getInfo<CL_PLATFORM_VERSION>() << p.getInfo<CL_PLATFORM_PROFILE>() << ' ' << p.getInfo<CL_PLATFORM_VENDOR>() << '\n';
    }

    /**
     * @brief Prints some info about many platforms to an ostream
     * 
     * @param p 
     * @param out 
     */
    inline void printPlatformInfo(const std::vector<cl::Platform> &p, std::ostream &out) noexcept
    {
        // Loop over our platforms and print info for each
        for (auto &&plat : p)
        {
            printPlatformInfo(plat, out);
        }
    }


    /**
     * @brief Builds a vector of kernels into a program
     * 
     * @param kernels Kernels to pass
     * @return std::variant< program_log_pair, cl::BuildLogType> Returns a program (on the HEAP, and log on stack) if success, and only a buildLog (also on stack) if fail
     */
    inline std::variant< program_log_pair, cl::BuildLogType> buildKernel(const std::vector<std::string> &kernels) noexcept
    {
        // Make a program on the heap
        auto program = new cl::Program(kernels);

        try
        {
            // Build the program
            program->build("-cl-std=CL2.0");
        }
        catch (const cl::BuildError e)
        {
            // Return build info if we've encountered a problem
            cl_int buildErr = CL_SUCCESS;
            auto log = program->getBuildInfo<CL_PROGRAM_BUILD_LOG>(&buildErr);
            // We're now done with the program
            delete program;
            // Return our log without the platform (thereby signifying that there was an error)
            return log;
        }

        // Return the program if we've built successfully
        cl_int buildErr = CL_SUCCESS;
        return ( program, program->getBuildInfo<CL_PROGRAM_BUILD_LOG>(&buildErr) );
    }

    inline std::string printBuildLog(const cl::BuildLogType &logs) noexcept
    {
		std::string buildLog("");

        // Snippet taken from OpenCL boilerplate code
		for (auto &&pair : logs)
		{
			buildLog.append( pair.second + '\n' );
		}

        return buildLog;
    }

    
} // namespace utils



#endif // End H_360679_SRC_UTILS