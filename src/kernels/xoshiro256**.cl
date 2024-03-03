#pragma once
#ifndef CL_360679_KERNELS_XOSHIRO256
#define CL_360679_KERNELS_XOSHIRO256 1

/**
 * Code migrated, merged, commented and edited from https://prng.di.unimi.it/ which links to https://prng.di.unimi.it/xoshiro256starstar.c
 * which is "Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)"
 * which is released in the public domain under the CC-0 licence: see <http://creativecommons.org/publicdomain/zero/1.0/>
 */

/* This is xoshiro256** 1.0, one of our all-purpose, rock-solid
   generators. It has excellent (sub-ns) speed, a state (256 bits) that is
   large enough for any parallel application, and it passes all tests we
   are aware of.

   For generating just floating-point numbers, xoshiro256+ is even faster.

   The state must be seeded so that it is not everywhere zero. If you have
   a 64-bit seed, we suggest to seed a splitmix64 generator and use its
   output to fill s. */

/**
 * @brief A left circular shift, beforming a left bit-shift according
 *     to k wherin the leftmost bit(s) "loops" around to the right
 * @note See: https://en.wikipedia.org/wiki/Circular_shift#Example
 *     It's unclear if static does anything here
 */
static inline ulong xoshiro256stst_rotl(const ulong x, uint k)
{
	return (x << k) | (x >> (64 - k));
}

// Forward definition
void xoshiro256stst_jump(ulong4 *s);

/**
 * @brief Return an initalised and jumped state for the random number generator
 * 
 * @param seed The seed to initalise it
 * @return ulong4 A state
 */
static inline ulong4 xoshiro256stst_init(const ulong seed)
{
	// Initalise a simple state
	ulong4 state = (ulong4)(
		seed ^ 0x45df1f30916742f0,
		seed ^ 0xcefa4b36bd2f909f,
		seed ^ 0xff258602b296dd1d,
		seed ^ 0x02ec31fb65555974
	);
	
	// Progress it
	xoshiro256stst_jump(&state);
	
	// Return it
	return state;
}

/**
 * @brief Returns us a pseudorandom number
 * 
 * @param s The state of our xoshiro256** RNG
 * 
 * @return ulong A pseudorandom number
 */
inline ulong xoshiro256stst_next(ulong4 *s)
{
	// Vectors of size 4 have x,y,z,w accessors
	const ulong result = xoshiro256stst_rotl(s->x * 5, 7) * 9;
	const ulong t = s->x << 17;

	s->zwyx ^= s->xyzw;
	// s->z ^= s->x;
	// s->w ^= s->y;
	// s->y ^= s->z;
	// s->x ^= s->w;

	s->z ^= t;
	s->w = xoshiro256stst_rotl(s->z, 45);

	return result;
}


/**
 * @brief Returned a random number within a range
 * 
 * @param s The state
 * @param min Minimum value (inclusive)
 * @param max Maximum value (exclusive)
 * @return ulong A number 𝐧 of the range 𝐦𝐢𝐧 ≤ 𝐧 < 𝐦𝐚𝐱
 *     i.e. if 𝐦𝐢𝐧 is 5 and 𝐦𝐚𝐱 is 10, 𝐧 could be 5, 6, 7, 8, or 9
 */
inline ulong xoshiro256stst_nextRange_UL(ulong4 *s, const ulong min, const ulong max)
{
	return min + (xoshiro256stst_next(s) % (max - min));
}

/**
 * @brief Returned a random number within a range
 * 
 * @param s The state
 * @param min Minimum value (inclusive)
 * @param max Maximum value (exclusive)
 * @return ulong A number 𝐧 of the range 𝐦𝐢𝐧 ≤ 𝐧 < 𝐦𝐚𝐱
 *     i.e. if 𝐦𝐢𝐧 is 5 and 𝐦𝐚𝐱 is 10, 𝐧 could be 5, 6, 7, 8, or 9
 */
inline long xoshiro256stst_nextRange_SL(ulong4 *s, const long min, const long max)
{
	// This does the same as the unsigned long but we chopp off a bit
		return 
			min + (
				// This hopefully is the same as doing `next(s) % LONG_MAX`
				// Here we remove the sign bit
				(signed long)(xoshiro256stst_next(s) & 0x7FFFFFFFFFFFFFFF)
					% (max - min)
				);
}


// C11 defines generic selecion which provides the functionality of overloading
// OpenCL C is a mix of C99 & C11: https://registry.khronos.org/OpenCL/specs/3.0-unified/html/OpenCL_C.html
// Based on the example provided in https://en.cppreference.com/w/c/language/generic
#define xoshiro256stst_nextRange(s, min, max) _Generic( \
		(s),											\
		ulong : xoshiro256stst_nextRange_UL, 			\
		 long : xoshiro256stst_nextRange_SL  			\
	)(s, min, max)


/**
 * @brief Perform a jump
 * 
 * @note This is the jump function for the generator. It is equivalent
 *       to 2^128 calls to next(); it can be used to generate 2^128
 *       non-overlapping subsequences for parallel computations.
 * 
 * @param s The state to advance
 */
inline void xoshiro256stst_jump(ulong4 *s)
{
	// Assign some random values for the way we progress our state
	static const ulong4 JUMP = { 0x180ec6d33cfd0aba, 0xd5a61266f0c9392c, 0xa9582618e03fc9aa, 0x39abdc4529b1661c };

	// Assign a second state for us to play with
	ulong4 sNew = { 0, 0, 0, 0 };
	
	// sizeof JUMP / sizeof *JUMP
	// Previously the code did some maths about the address space, but we don't need that here
	for(uchar i = 0; i < 4; i++)
	{
		// 64 times do some maths
		for(uchar b = 0; b < 64; b++)
		{
			// Give us (about) a 50% chance of updating our new state
			// For this static JUMP we get 134 times false and 122 times true
			if (JUMP[i] & 1ul << b)
			{
				// Progress sNew state
				sNew ^= *s;
				// sNew[0] ^= s->x;
				// sNew[1] ^= s->y;
				// sNew[2] ^= s->z;
				// sNew[3] ^= s->w;
			}

			// Progress the state of s
			xoshiro256stst_next(s);
		}
	}

	// Output the new state
	*s = sNew;
	// s->x = sNew[0];
	// s->y = sNew[1];
	// s->z = sNew[2];
	// s->w = sNew[3];
}



/**
 * @brief Perform a long jump
 * 
 * @param s The state to progress as if there had been 2^192 calls to next()
 * 
 * @note This is the long-jump function for the generator. It is equivalent to
 *       2^192 calls to next(); it can be used to generate 2^64 starting points,
 *       from each of which jump() will generate 2^64 non-overlapping
 *       subsequences for parallel distributed computations.
 */
inline void xoshiro256stst_long_jump(ulong4 *s)
{
	static const ulong LONG_JUMP[] = { 0x76e15d3efefdcbbf, 0xc5004e441c522fb3, 0x77710069854ee241, 0x39109bb02acbe635 };

	// Assign a second state for us to play with
	ulong4 sNew = { 0, 0, 0, 0 };

	// Do the jump
	// sizeof LONG_JUMP / sizeof *LONG_JUMP == 4
	for(int i = 0; i < 4; i++)
	{
		for(int b = 0; b < 64; b++)
		{
			if (LONG_JUMP[i] & UINT64_C(1) << b)
			{
				// Advance the state sNew by s
				sNew ^= *s;
				// s0 ^= s->x;
				// s1 ^= s->y;
				// s2 ^= s->z;
				// s3 ^= s->w;
			}

			// Advance the state s
			xoshiro256stst_next(s);
		}
	}
		
	// Assign our output
	*s = sNew;
	// s->x = s0;
	// s->y = s1;
	// s->z = s2;
	// s->w = s3;
}

#endif // End CL_360679_KERNELS_XOSHIRO256