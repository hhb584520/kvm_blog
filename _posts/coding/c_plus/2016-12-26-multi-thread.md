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


# 3. 线程相关操作 #

## 3.1 线程相关操作 ##

### pthread_t ###

pthread_t在头文件/usr/include/bits/pthreadtypes.h中定义：
　　typedef unsigned long int pthread_t;
　　它是一个线程的标识符。

### pthread_create ###

函数pthread_create用来创建一个线程，它的原型为：

	　extern int pthread_create __P ((pthread_t *__thread, __const pthread_attr_t *__attr,
	　void *(*__start_routine) (void *), void *__arg));

第一个参数为指向线程标识符的指针，第二个参数用来设置线程属性，第三个参数是线程运行函数的起始地址，最后一个参数是运行函数的参数。这里，我们的函数thread不需要参数，所以最后一个参数设为空指针。第二个参数我们也设为空指针，这样将生成默认属性的线程。对线程属性的设定和修改我们将在下一节阐述。当创建线程成功时，函数返回0，若不为0则说明创建线程失败，常见的错误返回代码为EAGAIN和EINVAL。前者表示系统限制创建新的线程，例如线程数目过多了；后者表示第二个参数代表的线程属性值非法。创建线程成功后，新创建的线程则运行参数三和参数四确定的函数，原来的线程则继续运行下一行代码。

### pthread_join pthread_exit ###
　　
函数pthread_join用来等待一个线程的结束。函数原型为：

	extern int pthread_join __P ((pthread_t __th, void **__thread_return));
　　
第一个参数为被等待的线程标识符，第二个参数为一个用户定义的指针，它可以用来存储被等待线程的返回值。这个函数是一个线程阻塞的函数，调用它的函数将一直等待到被等待的线程结束为止，当函数返回时，被等待线程的资源被收回。一个线程的结束有两种途径，一种是象我们上面的例子一样，函数结束了，调用它的线程也就结束了；另一种方式是通过函数pthread_exit来实现。它的函数原型为：

	extern void pthread_exit __P ((void *__retval)) __attribute__ ((__noreturn__));

　　
唯一的参数是函数的返回代码，只要pthread_join中的第二个参数thread_return不是NULL，这个值将被传递给 thread_return。最后要说明的是，一个线程不能被多个线程等待，否则第一个接收到信号的线程成功返回，其余调用pthread_join的线程则返回错误代码ESRCH。在这一节里，我们编写了一个最简单的线程，并掌握了最常用的三个函数pthread_create，pthread_join和pthread_exit。下面，我们来了解线程的一些常用属性以及如何设置这些属性。


## 3.2 互斥锁相关 ##

互斥锁用来保证一段时间内只有一个线程在执行一段代码。

### pthread_mutex_init ###

函数pthread_mutex_init用来生成一个互斥锁。NULL参数表明使用默认属性。如果需要声明特定属性的互斥锁，须调用函数 pthread_mutexattr_init。函数pthread_mutexattr_setpshared和函数 pthread_mutexattr_settype用来设置互斥锁属性。前一个函数设置属性pshared，它有两个取值， PTHREAD_PROCESS_PRIVATE和PTHREAD_PROCESS_SHARED。前者用来不同进程中的线程同步，后者用于同步本进程的不同线程。在上面的例子中，我们使用的是默认属性PTHREAD_PROCESS_ PRIVATE。后者用来设置互斥锁类型，可选的类型有PTHREAD_MUTEX_NORMAL、PTHREAD_MUTEX_ERRORCHECK、 PTHREAD_MUTEX_RECURSIVE和PTHREAD _MUTEX_DEFAULT。它们分别定义了不同的上所、解锁机制，一般情况下，选用最后一个默认属性。

### pthread_mutex_lock pthread_mutex_unlock pthread_delay_np  ###

pthread_mutex_lock声明开始用互斥锁上锁，此后的代码直至调用pthread_mutex_unlock为止，均被上锁，即同一时间只能被一个线程调用执行。当一个线程执行到pthread_mutex_lock处时，如果该锁此时被另一个线程使用，那此线程被阻塞，即程序将等待到另一个线程释放此互斥锁。


# 参考资料 #
http://zhuwenlong.blog.51cto.com/209020/40339