# 1. CPUID #
## 1.1 介绍
CPUID 是用于获取某个 CPU 是否支持某个 Feature 工具。为了读取到 CPU 的支持的 Feature 数据，我们需要有一套机器。

一般我们会传入 EAX和ECX，返回数据保存在 EBX, ECX, EDX 里面，然后根据里面值来判断是否支持某个Feature，注意这里要结合芯片手册，如 intel 3abcd.

传入EAX里面值称为 CPUID leaf，传入ECX里面值称为 CPUID subleaf.

具体介绍也可参考下面的网站：

https://en.wikipedia.org/wiki/CPUID

## 1.2 通过代码读取 CPUID 信息

gcc -o cpuid_common cpuid_common.c
./cpuid_common

[cpuid_common.c](/kvm_blog/files/tools/cpuid_common.c)

[cpuid_sgx.c](/kvm_blog/files/tools/cpuid_sgx.c)

或者
git clone https://github.com/01org/msr-tools.git
gcc -o cpuid cpuid.c

根据输出的值对看 intel 手册

## 1.3 通过工具读取 CPUID信息
有如下两个工具：

- CPU-Z 
- cpuid

请参考下面链接，不再叙述
https://www.cyberciti.biz/faq/linux-cpuid-command-read-cpuid-instruction-on-linux-for-cpu/


# 2. Search CPU microarchitecture #

## 2.1 命令查找 ##

	dmesg | grep "Performance Events"

## 2.2 查表获得 ##

根据下面了的信息来查询下表的信息，获取CPU的微架构

	CPU family:            6
	Model:                 63 //3FH

表格：

	g_codename_cpuid = [
	['Arrandale', '2010.1', '06_25H', 'mobile uarch= westmere'],
	['Avoton', '2013.3', '06_4DH', 'Atom SoC microserver, silvermont cores'],
	['Banias', '2003.2', '06_09H', 'pentium M cpus, based on modified p6 uarch'],
	['Bay Trail', '2013.3', '06_37H', 'atom SOC, silvermont cores'],
	['Bloomfield', '2008.4', '06_1AH', 'quad core xeon, uarch= nehalem'],
	['Briarwood', '2013.2', '?', 'storage SoCs, Intel Atom S1000 series, uarch= saltwell'],
	['Broadwell', '2014.3', '06_3DH, 06_47H, 06_4FH, 06_56H', 'broadwell'],
	['Cascades', '1999.4', '06_07H', 'pentium iii xeon, coppermine cores'],
	['Cedarmill', '2006.1', '0F_06H', 'pentium 4'],
	['Cedarview', '2011.3', '06_36H', 'atom saltwell'],
	['Centerton', '2012.4', '06_36H', 'atom saltwell'],
	['Chevelon', '2007.1', '?', 'Intel(r) IOP342 I/O Processor'],
	['Clanton', '2013.4', '05_09H', 'quark'],
	['Clarkdale', '2010.1', '06_25H', 'a westmere cpu'],
	['Clarksfield', '2009.3', '06_1EH', 'nehalem uarch'],
	['Clovertown', '2006.4', '06_0FH', 'uarch= core, Woodcrest, Tigerton, Kentfield, Clovertown'],
	['Cloverview', '2013.2', '06_35H', 'Cloverview, saltwell'],
	['Conroe', '2006.3', '06_0FH', ''],
	['Coppermine', '2000.1', '06_08H', 'pentium iii', ''],
	['Cranford', '2005.2', '0F_04H', 'pentium 4, netburst'],
	['Crystal Well', '2013.2', '06_46H', 'haswell based'],
	['Dempsey', '2006.2', '0F_06H', 'pentium 4'],
	["Devil's Canyon", '2014.2', '06_3CH', 'haswell based'],
	['Diamondville', '2008.2', '06_1CH', 'bonnell core'],
	['Dixon', '1999.1', '06_06H', 'pentium ii'],
	['Dothan', '2004.2', '06_0DH', 'pentium M, uarch= p6 variant'],
	['Dunnington', '2008.3', '06_1DH', 'quad core xeon, uarch= core'],
	['Foster', '2001.1', '0F_01H', 'pentium 4'],
	['Gallatin', '2003.2', '0F_02H', 'pentium 4'],
	['Gladden', '2012.2', '06_2AH', 'sandy bridge'],
	['Gulftown', '2010.1', '06_2CH', 'based on westmere'],
	['Harpertown', '2007.4', '06_17H', 'uarch= penryn'],
	['Haswell', '2013.2', '06_3CH', 'haswell'],
	['Haswell E', '2014.3', '06_3FH', 'haswell e'],
	['Irwindale', '2005.1', '0F_07H', 'pentium 4'],
	['Ivy Bridge', '2012.2', '06_3AH', 'ivy bridge'],
	['Ivy Bridge E', '2013.3', '06_3EH', 'ivy bridge-e, i7-4930K'],
	['Ivy Bridge EN', '2014.1', '06_3EH', 'ivy bridge en'],
	['Ivy Bridge EP', '2013.3', '06_3EH', 'ivy bridge ep'],
	['Jasper Forest', '2010.1', '06_1EH', 'xeon uarch= nehalem'],
	['Katmai', '1999.1', '06_07H', 'pentium iii'],
	['Kentsfield', '2006.4', '06_0FH', 'uarch= core'],
	['Knights Corner', '2012.4', '0B_01H', 'xeon phi'],
	['Lincroft', '2010.2', '06_26H', 'atom (bonnell)'],
	['Lynnfield', '2009.3', '06_1EH', 'uarch= nehalem'],
	['Madison', '2004.2', '1F_03H', 'itanium-2'],
	['Mendocino', '1999.1', '06_06H', 'pentium ii'],
	['Merom', '2006.3', '06_0FH', 'uarch= core'],
	['Merrifield', '2014.1', '06_4AH', 'uarch= silvermont'],
	['Montecito', '2007.1', '20_00H', 'uarch= itanium, after madison'],
	['Montvale', '2007.4', '20_01H', 'uarch= itanium, after montecito'],
	['Moorefield', '2014.2', '06_5AH', 'uarch= silvermont'],
	['Nehalem EP', '2009.1', '06_1AH', 'uarch= nehalem'],
	['Nehalem EX', '2010.1', '06_2EH', 'uarch= nehalem, beckton'],
	['Nocona', '2004.2', '0F_03H', 'pentium 4'],
	['Northwood', '2002.1', '0F_02H', 'pentium 4'],
	['Paxville', '2005.3', '0F_04H', 'pentium 4'],
	['Penryn', '2008.1', '06_17H', 'uarch= penryn'],
	['Penwell', '2012.2', '06_27H', 'atom saltwell core'],
	['Pine Cove', '2014.3', '?', 'mobile communications chip such as Intel(r) Transcede(tm) T2150'],
	['Pineview', '2010.1', '06_1CH', 'atom, bonnell core'],
	['Potomac', '2005.2', '0F_04H', 'pentium 4'],
	['Poulson', '2012.4', '21_00H', 'itanium, after tukwila'],
	['Prescott', '2004.1', '0F_03H', 'pentium 4'],
	['Presler', '2006.1', '0F_06H', 'pentium 4'],
	['Prestonia', '2002.1', '0F_02H', 'I think the dfdm is right, pentium 4 xeon'],
	['Rangeley', '2013.3', '06_4DH', 'communications chip based on avoton with silvermont cores'],
	['Sandy Bridge', '2011.1', '06_2AH', 'uarch= sandy bridge'],
	['Sandy Bridge E', '2011.4', '06_2DH', 'uarch= sandy bridge'],
	['Sandy Bridge EN', '2012.2', '06_2DH', 'uarch= sandy bridge'],
	['Sandy Bridge EP', '2012.1', '06_2DH', 'uarch= sandy bridge'],
	['Silverthorne', '2008.2', '06_1CH', 'bonnell cores'],
	['Smithfield', '2005.1', '0F_04H', 'pentium 4'],
	['Sossaman', '2006.1', '06_0EH', 'xeon based on yonah'],
	['Stellarton', '2010.4', '06_1CH', 'embedded atom, bonnell cores'],
	['Sunrise Lake', '2007.1', '?', 'ioprocessors like IOP348'],
	['Tanner', '1999.1', '06_07H', 'pentium iii xeon'],
	['Tigerton', '2007.3', '06_0FH', 'dual/quad core xeon, uarch= core'],
	['Tolapai', '2008.3', '06_0DH', 'dothan cores'],
	['Tualatin', '2001.4', '06_0BH', 'pentium iii'],
	['Tukwila', '2010.1', '20_02H', 'itanium, after montvale, before poulson'],
	['Tulsa', '2006.3', '0F_06H', 'pentium 4 dual core xeon'],
	['Tunnel Creek', '2010.3', '06_26H', 'Intel Atom Z670'],
	['Val Vista', '2007.1', '?', 'Intel(r) IOC340 I/O Controller'],
	['Westmere EP', '2010.1', '06_2CH', 'DP xeon, uarch= westmere'],
	['Westmere EX', '2011.2', '06_2FH', '4socket xeon, uarch= westmere'],
	['Willamette', '2000.4', '0F_01H', 'pentium 4'],
	['Wolfdale', '2007.4', '06_17H', 'uarch= penryn, shrink of core uarch'],
	['Woodcrest', '2006.2', '06_0FH', 'xeon uarch= core'],
	['Yonah', '2006.1', '06_0EH', 'based on Banias/Dothan-core Pentium M microarchitecture'],
	['Yorkfield', '2007.4', '06_17H', 'quad core xeon, uarch= core']
    ]
