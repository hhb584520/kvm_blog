#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

static inline uint64_t rdtsc(void)
{
        uint32_t lo, hi;
        asm volatile("lfence; rdtsc" : "=a" (lo), "=d" (hi));
        return (uint64_t)hi << 32 | lo;
}

static inline uint64_t rdtscp(void)
{
        uint32_t lo, hi, dummy;
        asm volatile("rdtscp" : "=a" (lo), "=d" (hi), "=c" (dummy));
        return (uint64_t) hi << 32 | lo;
}

int main(int argc, char **argv)
{
        uint64_t tsc0, tscp0, tsc1, tscp1;
        int ns, tsc_khz;
        double delta, period, error;

        if (argc < 2) {
                printf("Usage: %s <nr_seconds> <tsc_khz>\n", argv[0]);
                return -1;
        }

        if ((ns = atoi(argv[1])) <= 0)
                return -1;
        if ((tsc_khz = atoi(argv[2])) <= 0)
                return -1;

        tsc0 = rdtsc();
        tscp0 = rdtscp();
        sleep(ns);
        tsc1 = rdtsc();
        tscp1 = rdtscp();

        delta = tsc1 - tsc0;
        period = delta / (tsc_khz * 1000.0);
        error = (period - ns) / (double) ns;
        printf("[rdtsc ] Passed %lf s, error %lf\n", period, error);

        delta = tscp1 - tscp0;
        period = delta / (tsc_khz * 1000.0);
        error = (period - ns) / (double) ns;
        printf("[rdtscp] Passed %lf s, error %lf\n", period, error);

        return 0;
}
