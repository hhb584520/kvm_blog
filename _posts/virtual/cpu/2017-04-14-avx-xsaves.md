# 3. AVX和XSAVE指令 #
AVX(Advanced Vector Extensions，高级矢量扩展)是Intel 和AMD的x86 架构指令集的一个扩展，2011年Intel 发布Sandy Bridge处理器时开始第一次正式支持 AVX. AVX 中的新特性有：将向量化宽度从128位提升到256位，且将 XMM0~XMM15寄存器重命名为 YMM0~YMM15；引入了三操作数、四操作数的 SIMD 指令格式；弱化了对 SIMD 指令中对内存操作对齐的要求，支持灵活的不对齐内存地址访问。
    
向量就是多个标量的组合，通常意味着SIMD（单指令多数据），就是一个指令同时对多个数据进行处理，达到很大的吞吐量。MMX(多媒体扩展 64bits)--SSE(流式 SIMD 扩展 128bits).另外，XSAVE 指令（包括 XSAVE, XRSTOR等）是在 Intel Nehalem处理器中开始引入的，是为了保存和恢复处理器
扩展状态的，在AVX引入后，XSAVE 也要处理 YMM 寄存器状态。在KVM虚拟化环境中，客户机的动态迁移需要保存处理器状态，然后迁移后恢复处理器的执行状态，如果有AVX指令要执行，在保存和恢复时也需要 XSAVE, XRSTOR 指令的支持。
   
下面介绍以下如何在KVM中为客户机提供 AVX、XSAVE 特性。
1)  检查宿主机中 AVX、XSAVE 的支持，Sandy之后硬件平台都支持，较新的内核（如3.x）也支持。

    # cat /proc/cpuinfo | grep avx | grep xsave

2) 启动客户机，将 AVX、XSAVE 特性提供客户机使用，命令行操作如下：

    # qemu-system-x86_64 -smp 2 -m 1024 rhel6u3.img -cpu host -net nic -net tap

3) 在客户机中，查看 QEMU 提供的CPU信息中是否支持 AVX和XSAVE，命令行如下：

    # cat /proc/cpuinfo | grep avx |  grep xsave

另外，Intel 在Haswell 平台将会引入新的指令集 AVX2，它将会提供包括支持 256 位向量的整数运算在内的更多功能用 -cpu host 参数也可以将 AVX2 的特性提供给客户机使用。 
