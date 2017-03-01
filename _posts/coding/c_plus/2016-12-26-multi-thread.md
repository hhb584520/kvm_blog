# 1.多线程编程之join()方法 #


java线程多线程join编程 
现实生活中，有些工作是需要团队中成员依次完成的，这就涉及到了一个顺序问题。现在有T1、T2、T3三个工人，如何保证T2在T1执行完后执行，T3在T2执行完后执行？

问题分析：首先问题中有三个实体，T1、T2、T3， 因为是多线程编程，所以都要设计成线程类。关键是怎么保证线程能依次执行完呢？
 
Java实现过程如下：
Java代码  收藏代码
public class T1 implements Runnable{  
  
    @Override  
    public void run() {  
        try {  
            System.out.println("T1开始工作.....");  
            Thread.sleep(RandomUtils.nextInt(300));  
            System.out.println("T1结束工作>>>>>");  
        } catch (InterruptedException e) {  
            e.printStackTrace();  
        }  
    }  
  
}  
 
Java代码  收藏代码
package thread.join.demo1;  
  
import org.apache.commons.lang.math.RandomUtils;  
  
public class T2 implements Runnable{  
  
    @Override  
    public void run() {  
        try{  
            System.out.println("T2开始工作.....");  
            Thread.sleep(RandomUtils.nextInt(300));  
            System.out.println("T2结束工作>>>>>");  
        } catch (InterruptedException e) {  
            e.printStackTrace();  
        }  
    }  
  
}  
 
Java代码  收藏代码
public class T3 implements Runnable{  
  
    @Override  
    public void run() {  
        try{  
            System.out.println("T3开始工作.....");  
            Thread.sleep(RandomUtils.nextInt(300));  
            System.out.println("T3结束工作>>>>>");  
        } catch (InterruptedException e) {  
            e.printStackTrace();  
        }  
    }  
  
}  
 
Java代码  收藏代码
public class Main {  
  
    public static void main(String[] args){  
          
        Thread t1 = new Thread(new T1());  
        Thread t2 = new Thread(new T2());  
        Thread t3 = new Thread(new T3());  
          
        t1.start();  
        t2.start();  
        t3.start();  
          
        System.out.println("T1、T2、T3依次工作结束.");  
    }  
  
}  
 
运行结果：
T1开始工作.....
T2开始工作.....
T3开始工作.....
T1、T2、T3依次工作结束.
T3结束工作>>>>>
T2结束工作>>>>>
T1结束工作>>>>>
 
说明：从结果来看，T1、T2、T3并没有依次执行。查看JDK文档，java.lang.Thread 类有三个join()方法，其解释为：等待该线程终止。试用它来解决该问题……
 
Main.java修改如下：
Java代码  收藏代码
public class Main {  
  
    public static void main(String[] args) throws InterruptedException {  
          
        Thread t1 = new Thread(new T1());  
        Thread t2 = new Thread(new T2());  
        Thread t3 = new Thread(new T3());  
          
        t1.start();  
        t1.join();  
          
        t2.start();  
        t2.join();  
          
        t3.start();  
        t3.join();  
          
        System.out.println("T1、T2、T3依次工作结束.");  
    }  
  
}  
 
 
运行结果:
T1开始工作.....
T1结束工作>>>>>
T2开始工作.....
T2结束工作>>>>>
T3开始工作.....
T3结束工作>>>>>
T1、T2、T3依次工作结束.
 
 
查看jdk源码，其中join方法代码片断如下：
 
Java代码  收藏代码
/** 
     * Waits at most <code>millis</code> milliseconds for this thread to  
     * die. A timeout of <code>0</code> means to wait forever.  
     * 
     * @param      millis   the time to wait in milliseconds. 
     * @exception  InterruptedException if any thread has interrupted 
     *             the current thread.  The <i>interrupted status</i> of the 
     *             current thread is cleared when this exception is thrown. 
     */  
    public final synchronized void join(long millis)   
    throws InterruptedException {  
    long base = System.currentTimeMillis();  
    long now = 0;  
  
    if (millis < 0) {  
            throw new IllegalArgumentException("timeout value is negative");  
    }  
  
    if (millis == 0) {  
        while (isAlive()) {  
        wait(0);  
        }  
    } else {  
        while (isAlive()) {  
        long delay = millis - now;  
        if (delay <= 0) {  
            break;  
        }  
        wait(delay);  
        now = System.currentTimeMillis() - base;  
        }  
    }  
    }   
 
 
单纯从代码上看：如果线程被生成了，但还未被起动，isAlive()将返回false，调用它的join()方法是没有作用的，将直接继续向下执行。在Main.java类中，t1.join()是判断t1线程的状态，如果t1的isActive()方法返回false，在 t1.join(),这一点就不用阻塞了，可以继续向下进行了。从源码里看，wait方法中有参数，也就是不用唤醒谁，只是不再执行wait，向下继续执行而已。在join()方法中，对于isAlive()和wait()方法的作用对象是个比较让人困惑的问题：
isAlive()方法的签名是：public final native boolean isAlive()，也就是说isAlive()是判断当前线程的状态，也就是t1的状态。


# 2. eclipse pthread_create 未声明 # 


**Eclipse + CDT:**
pthread_create函数编译时报错:undefined reference to `pthread_create’
undefined reference to `pthread_create’

由于pthread 库不是 Linux 系统默认的库，连接时需要使用静态库 libpthread.a，所以在使用pthread_create()创建线程，以及调用 pthread_atfork()函数建立fork处理程序时，在编译中要加 -lpthread参数。
例如：在加了头文件#include 之后执行 pthread.c文件，需要使用如下命令：

gcc thread.c -o thread -lpthread

**问题原因：**

pthread 库不是 Linux 系统默认的库，连接时需要使用静态库 libpthread.a，所以在使用pthread_create()创建线程，以及调用 pthread_atfork()函数建立fork处理程序时，需要链接该库。
问题解决：
在编译中要加 -lpthread参数
gcc thread.c -o thread -lpthread
thread.c为你些的源文件，不要忘了加上头文件#include

**解决方法为：**

Project->Properties->C/C++ Build->Settings->GCC C++ Linker->Libraries
在Libraries(-l)中添加pthread即可
在Libraries search path(-L)中添加crypto即可