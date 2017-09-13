gva to gpa

	#include <assert.h>
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <unistd.h>
	#include <fcntl.h>
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <sys/mman.h>
	
	struct pagemaps {
	    unsigned long long  pfn:55;
	    unsigned long long  pgshift:6; /* legacy */
	    unsigned long long  rsvd:1;
	    unsigned long long  swapped:1;
	    unsigned long long  present:1;
	};
	
	static int pagesize;
	
	static unsigned long long vtop(unsigned long long addr)
	{
	    struct pagemaps pinfo;
	    unsigned int pinfo_size = sizeof(pinfo);
	    int pagesize = getpagesize();
	    unsigned long long offset = addr / pagesize * pinfo_size;
	    int fd, pgmask;
	    const char *pagemapname = "/proc/self/pagemap";
	
	    fd = open(pagemapname, O_RDONLY);
	    if (fd == -1) {
	        perror(pagemapname);
	        return 0;
	    }
	    if (pread(fd, (void *)&pinfo, pinfo_size, offset) != pinfo_size) {
	        perror(pagemapname);
	        close(fd);
	        return 0;
	    }
	    close(fd);
	    pgmask = pagesize - 1;
	    return (pinfo.pfn * pagesize) | (addr & pgmask);
	}
	
	int main()
	{
	    unsigned long long gpa;
	    void *buf;
	
	    pagesize = getpagesize();
	
	    /*
	     * First, allocate one page at least, so that we can ensure at
	     * least one page is completely owned by this process.
	     *
	     * Second, if you are going to allocate only one page, do not use
	     * malloc()/calloc()/... that do not make any promise on the
	     * alignment. If you are going to allocate more than one page,
	     * remember to find a page-aligned address in the allocated space.
	     */
	    buf = mmap(NULL, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC,
	               MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
	    if ( buf == MAP_FAILED ) {
	        perror("Failed to allocate memory");
	        return -1;
	    }
	    assert(!((unsigned long long)buf & (pagesize - 1)));
	    /*
	     * Write to the buffer to ensure a physical page is really
	     * allocated and mapped. Otherwise, vtop below may fail.
	     */
	    memset(buf, 0xcc, pagesize);
	
	    printf("gva=0x%p\n", buf);
	
	    /* translate GVA to GPA */
	    gpa = vtop((unsigned long long)buf);
	    printf("gpa=0x%llx\n", gpa);
	
	    /* keep the GPA is valid. */
	    while(1) {
	        sleep(1);
	    }
	    return 1;
	}
