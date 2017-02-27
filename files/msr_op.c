#include <stdio.h>

#define VARIANT_ID_BYTE 18
#define VARIANT_ID_MASK 7
#define 
typedef struct msr_struct
{
	unsigned lo;
	unsigned hi;
} msr_t;

static inline  __attribute__((always_inline)) msr_t rdmsr(unsigned index)
{
	msr_t result;
	__asm__ __volatile__ (
	"rdmsr"
	: "=a" (result.lo), "=d" (result.hi)
	: "c" (index)
	);
	return result;
}

static inline __attribute__((always_inline)) void wrmsr(unsigned index, msr_t msr)
{
	__asm__ __volatile__ (
	"wrmsr"
	: /* No outputs */
	: "c" (index), "a" (msr.lo), "d" (msr.hi)
	);
}

int main(int argc, char *argv[])
{
	
    	msr_t platform_id = rdmsr(MSR_IA32_PLATFORM_ID);

	printf("msr platform_id=%d\n", platform_id);
	return 0;
} 
