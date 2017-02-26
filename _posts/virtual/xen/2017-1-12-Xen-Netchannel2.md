1. 底层平台涉及的主要模块
    xenstore-ls -f
2. I/O环
2.1 前端驱动和后端驱动间通过事件通道进行异步消息传递。
2.2 I/O环通过基于授权机制的共享内存传递数据。
2.3 I/O环通过环缓冲发出和接收I/O请求和反馈的描述符。
 
3. 操作系统对内存的要求  
3.1 地址从 0开始。  
3.2 地址大粒度连续。
 
4. NetChannel2
4.1 NetChannel2 特性
  -> ByPass，优化同一Host上DomU间的通信。
  -> Automatic ByPass，自动识别与之通信的DomU是否在同一个Host上。
  -> Guest Grant Copy，由DomU自己Copy，减少Dom0压力。
  -> 提升了小包上性能提升（Small packet copy）
     -> 小包放在 IO 环中，无需授权操作。
     -> IP包总长度小于等于 96即为小包。
4.2 NetChannel2 应用
  -> 加载NetChannel2模块 insmod ./netchannel2.ko。
  -> 在配置文件中添加 vif2=['bridge=br0',]
  -> 动态配置NetChannel2网卡
      xm network2-attach domid bridge=br0

5. 虚拟化时间
5.1 实际时间：以纳秒为单位，从计算机启动即开始计时。
5.2 虚拟时间：是每个客户机实际占用CPU资源执行所消耗的时间，对VCPU调度至关重要。
5.3 墙钟时间：是为每个客户机单独维护的逻辑上消耗的时间，它与真实的时间流逝同步。
5.4 挂钟时间：看作GOS刚运行的时间基准，系统时间则可以看着是在这个时间基准上的偏移量。 