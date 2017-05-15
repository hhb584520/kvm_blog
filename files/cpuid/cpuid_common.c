#include <stdlib.h>
	#include <stdio.h>
	
	static inline void __cpuid(unsigned int *eax, unsigned int *ebx,
	                                unsigned int *ecx, unsigned int *edx)
	{
	        /* ecx is often an input as well as an output. */
	        asm volatile("cpuid"
	            : "=a" (*eax),
	              "=b" (*ebx),
	              "=c" (*ecx),
	              "=d" (*edx)
	            : "0" (*eax), "2" (*ecx)
	            : "memory");
	}
	
	/*
	 * Generic CPUID function
	 * clear %ecx since some cpus (Cyrix MII) do not set or clear %ecx
	 * resulting in stale register contents being returned.
	 */
	static inline void cpuid(unsigned int op, unsigned int count,
	                         unsigned int *eax, unsigned int *ebx,
	                         unsigned int *ecx, unsigned int *edx)
	{
	        *eax = op;
	        *ecx = 0;
	        __cpuid(eax, ebx, ecx, edx);
	}
	
	main()
	{
	    unsigned int eax, ebx, ecx, edx;
			unsigned int eax_in=18, ecx_in=0;

	        cpuid(eax_in, ecx_in, &eax, &ebx, &ecx, &edx);
	
	        printf("eax=%lx, ecx=%lx: eax=%lx, ebx=%lx, ecx=%lx, edx=%lx\n", eax_in, ecx_in,eax, ebx, ecx, edx);
	}