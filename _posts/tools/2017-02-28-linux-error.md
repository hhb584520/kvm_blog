### fatal error: gnu/stubs-32.h ###

	/usr/include/gnu/stubs.h:7:27: fatal error: gnu/stubs-32.h: No such file or directory
	 # include <gnu/stubs-32.h>  
	要先：yum distribution-synchronization
	然后：yum install glibc-devel.i686
