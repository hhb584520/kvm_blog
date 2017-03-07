# 1. Cache 类型 #

- PIPT(一般用于 D cache)：该种类型避免上下文切换时要 flush cache，但是由于皆采用物理地址，每次判断命中都必须进行地址转换，速度较慢。
- VIVT(老式缓存)：该种类型避免判断 Cache 命中时的地址转换，但是上下文切换后虚拟地址映射发生改变，就必须 flush cache。 效率不高。
- VIPT(一般用于新式 I cache): 上面两个极端的折中。在 Cache 通过 index 查询正确的 sel 的时候，TLB可以完成虚拟地址到物理地址的转换，在Cache 比较 tag 的时候，物理地址已经准备就绪，也就是说 phsical tag 可以和cache 并行工作。虽然延迟不如 VIVT 但是不需要上下文切换的时候 flush cache.



# 2. Cache的初始化 #
MRC p15,0,<Rt>,c0,c0,1 ; Read CP15 Cache Type Register
这个寄存器，L1IP 表示cache类型，我的是vipt

MRC p15,1,<Rt>,c0,c0,1 ; Read CP15 Cache Level ID Register
表示当前cache一共有几级，以及每级level的配置，我的是1级cache，并且是单独的icache和dcache

MRC p15,2,<Rt>,c0,c0,0 ; Read Cache Size Selection Register
可以设置icache或者dcache，以及cache level

MRC p15,1,<Rt>,c0,c0,0 ; Read current CP15 Cache Size ID Register
根据cssr当前的配置（比如L1 dcache),读出相应的numsets, linesize, associativity,我的是256 sets* (8word*4byte) * 4way=32KB， (L1 icache也是这样的32K）


问题是：
如何知道L1 dcache的类型的？ (pipt, vipt, vivit)
假设L1 dcache是vipt，如何知道他是否是alasing的？


kernel代码：
static void __init cacheid_init(void)
{
        unsigned int cachetype = read_cpuid_cachetype();
        unsigned int arch = cpu_architecture();

        if (arch >= CPU_ARCH_ARMv6) {
                if ((cachetype & (7 << 29)) == 4 << 29) {
                        /* ARMv7 register format */ 》》》》》》》》》》》》》会走到这里
                        cacheid = CACHEID_VIPT_NONALIASING;   
                        if ((cachetype & (3 << 14)) == 1 << 14)
                                cacheid |= CACHEID_ASID_TAGGED;
                        else if (cpu_has_aliasing_icache(CPU_ARCH_ARMv7))
                                cacheid |= CACHEID_VIPT_I_ALIASING;

kernel的意思是，默认L1 dcache是vipt noaliasing的。
l1 icache的类型vipt是从ctr读出来的。
l1 icache的vipt是否aliasing，是根据csid的大小的出来的，现在我的是numset*linesize= 8KB 大于pagesize，所以设置为vipt aliasing。为什么dcache不这样计算的？
假设也多个level的cache，对软件来说cache的inv，flush等操作是透明的吗？

# 3. Cache的详细介绍 #
http://nieyong.github.io/wiki_cpu/CPU%E4%BD%93%E7%B3%BB%E6%9E%B6%E6%9E%84-Cache.html

# 4. Cache信息查看 #
tree /sys/devices/system/cpu/cpu0/cache

# 5. Cache 特殊例子 #
http://igoro.com/archive/gallery-of-processor-cache-effects/
