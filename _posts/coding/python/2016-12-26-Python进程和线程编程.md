Python 提供了几个用于多线程编程的模块，包括thread, threading 和Queue 等。thread 和threading 模块允许程序员创建和管理线程。thread 模块提供了基本的线程和锁的支持，而threading提供了更高级别，功能更强的线程管理的功能。Queue 模块允许用户创建一个可以用于多个线程之间共享数据的队列数据结构。

注意：避免使用thread模块，因为它不支持守护线程。当主线程退出时，所有的子线程不论它们是否还在工作，都会被强行退出。下面重点说说threading模块。我们的多线程继承threading模块里的Thread类，它的主要函数有：

- start()                  开始线程的执行
- run()                    定义线程的功能的函数（一般会被子类重写）
- join(timeout=None)       程序挂起，直到线程结束；如果给了timeout，则最多阻塞timeout 秒
- getName()                返回线程的名字
- setName(name)            设置线程的名字
- isAlive()                布尔标志，表示这个线程是否还在运行中
- isDaemon()               返回线程的daemon 标志
- setDaemon(daemonic)      把线程的daemon 标志设为daemonic（一定要在调用start()函数前调用）


例子一：

	import threading
	class http_call:
	    def __init__(self):
	        self.state = ''
	    def get_vm_info(self):
	        self.state = 'get_vm_info_done'
	        print self.state
	        
	    def hhb(self):
	        self.state = 'hhb'
	        print self.state
	        
	if __name__ == '__main__':
	    
	    #global hrc
	    hrc = http_call()
	    thread1 = threading.Thread(target=hrc.get_vm_info)
	    thread1.setDaemon(True)
	    thread1.start()
	    #thread = threading.Thread(target=hrc.start_vm, args=(vmid,))
	    
	    thread2 = threading.Thread(target=hrc.hhb)
	    thread2.setDaemon(True)
	    thread2.start()

例子二，加入了队列：

	import Queue
	import threading
	import urllib2
	import time
	#from BeautifulSoup import BeautifulSoup
	hosts = ["http://yahoo.com", "http://google.com", "http://amazon.com",
	        "http://ibm.com", "http://apple.com"]
	queue = Queue.Queue()
	out_queue = Queue.Queue()
	class ThreadUrl(threading.Thread):
	    """Threaded Url Grab"""
	    def __init__(self, queue, out_queue):
	        threading.Thread.__init__(self)
	        self.queue = queue
	        self.out_queue = out_queue
	    def run(self):
	        while True:
	            #grabs host from queue
	            host = self.queue.get()
	            #grabs urls of hosts and then grabs chunk of webpage
	            url = urllib2.urlopen(host)
	            chunk = url.read()
	            #place chunk into out queue
	            self.out_queue.put(chunk)
	            #signals to queue job is done
	            self.queue.task_done()
	class DatamineThread(threading.Thread):
	    """Threaded Url Grab"""
	    def __init__(self, out_queue):
	        threading.Thread.__init__(self)
	        self.out_queue = out_queue
	    def run(self):
	        while True:
	            #grabs host from queue
	            chunk = self.out_queue.get()
	            print chunk
	            #parse the chunk
	            #soup = BeautifulSoup(chunk)
	            #print soup.findAll(['title'])
	            #signals to queue job is done
	            self.out_queue.task_done()
	start = time.time()
	def main():
	    #spawn a pool of threads, and pass them queue instance
	    for i in range(5):
	        t = ThreadUrl(queue, out_queue)
	        t.setDaemon(True)
	        t.start()
	    #populate queue with data
	    for host in hosts:
	        queue.put(host)
	    for i in range(5):
	        dt = DatamineThread(out_queue)
	        dt.setDaemon(True)
	        dt.start()
	    #wait on the queue until everything has been processed
	    queue.join()
	    out_queue.join()
	main()
	print "Elapsed Time: %s" % (time.time() - start)
	
	'''
	 -*- coding: utf-8 -*-
	@author: intple
	'''
	from multiprocessing import Process
	import os
	def f(name):
	    print('hello', name)
	    print('process id:' ,os.getpid())
	if __name__ == '__main__':
	    p = Process(target=f, args=('bob',))
	    p.start()
	    p.join()
	    
	    p2 = Process(target=f, args=('hhb',))
	    p2.start()
	    p2.join()
	
	
	#-进程-######################################################
	'''
	 -*- coding: utf-8 -*-
	@author: intple
	'''
	from multiprocessing import Process
	import os
	def f(name):
	    print('hello', name)
	    print('process id:' ,os.getpid())
	if __name__ == '__main__':
	    p = Process(target=f, args=('bob',))
	    p.start()
	    p.join()
	    
	    p2 = Process(target=f, args=('hhb',))
	    p2.start()
	    p2.join()
	
	#-线程-######################################################
	'''
	 -*- coding: utf-8 -*-
	@author: intple
	'''
	import threading
	class http_call:
	    def __init__(self):
	        self.func = ''
	    def get_vm_info(self, a2):
	        self.func = 'get_vm_info_done'
	        print self.func
	        print a2
	        
	    def hhb(self, a2):
	        self.state = 'hhb'
	        print self.func
	        print a2 
	     
	if __name__ == '__main__':  
	    #global hrc
	    hrc = http_call()
	    
	    # thread1
	    thread1 = threading.Thread(target=hrc.get_vm_info(13))
	    thread1.setDaemon(True)
	    thread1.start()
	    # thread2
	    thread2 = threading.Thread(target=hrc.get_vm_info(16))
	    thread2.setDaemon(True)
	    thread2.start()
	    