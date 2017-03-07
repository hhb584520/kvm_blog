## 1. 锁定内存 ##
﻿
fp = fopen("/proc/self/maps", "r");
 

fgets(line, sizeof(line), fp);

sscan
f(line, "%08x-%08x", &addrStart, &addrEnd);

ret = mlock((void *)addrStart, addrEnd-addrStart);

一定要读一下内存

