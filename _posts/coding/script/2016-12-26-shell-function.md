# linux shell 可以用户定义函数
 

## 1. 定义shell函数(define function)

语法：

    [ function ] funname [()]
    
    {
    
    	action;
    
    	[return int;]
    
    }

说明：

1、可以带function fun()  定义，也可以直接fun() 定义,不带任何参数。

2、参数返回，可以显示加：return 返回，如果不加，将以最后一条命令运行结果，作为返回值。 return后跟数值n(0-255

 

实例（testfun1.sh）：
    
    #!/bin/sh
      
     fSum 3 2;
     function fSum()
     {
     	echo $1,$2;
     	return $(($1+$2));
     }
     fSum 5 7;
     total=$(fSum 3 2);
     echo $total,$?;
      
    sh testfun1.sh
    testfun1.sh: line 3: fSum: command not found
    5,7
    3,2
    1
    5
 

从上面这个例子我们可以得到几点结论：

1、必须在调用函数地方之前，声明函数，shell脚本是逐行运行。不会像其它语言一样先预编译。一次必须在使用函数前先声明函数。

2、total=$(fSum 3 2);  通过这种调用方法，我们清楚知道，在shell 中 单括号里面，可以是：命令语句。 因此，我们可以将shell中函数，看作是定义一个新的命令，它是命令，因此 各个输入参数直接用 空格分隔。 一次，命令里面获得参数方法可以通过：$0…$n得到。 $0代表函数本身。

3、函数返回值，只能通过$? 系统变量获得，直接通过=,获得是空值。其实，我们按照上面一条理解，知道函数是一个命令，在shell获得命令返回值，都需要通过$?获得。

 

## 2.函数作用域，变量作用范围

先我们看一个实例(testfun2.sh )：

    #!/bin/sh
     
    echo $(uname);
    declare num=1000;
     
    uname()
    {
    	echo "test!";
    	((num++));
    	return 100;
    }
    testvar()
    {
    	local num=10;
    	((num++));
    	echo $num;
     
    }
     
    uname;
    echo $?
    echo $num;
    testvar;
    echo $num;
    
       
    sh testfun2.sh
    Linux
    test!
    100
    1001
    11
    1001

我们一起来分析下上面这个实例，可以得到如下结论：

1、定义函数可以与系统命令相同，说明shell搜索命令时候，首先会在当前的shell文件定义好的地方查找，找到直接执行。

2、需要获得函数值：通过$?获得

3、如果需要传出其它类型函数值，可以在函数调用之前，定义变量（这个就是全局变量）。在函数内部就可以直接修改，然后在执行函数就可以读出修改过的值。

4、如果需要定义自己变量，可以在函数中定义：local 变量=值 ，这时变量就是内部变量，它的修改，不会影响函数外部相同变量的值 。

这些，是我在工作中，对linux ,shell 函数使用一些经验总结，有没有提到地方，欢迎交流！

## 3. 参数传递 ##
### 3.1 入参 ###

    test_ass_nic(0
    {
            local des=$1
    }

    test_ass_nic "Y" 

### 3.2 返回值 ###
直接返回值

    return $ret
    
通过 echo 返回

    #! /bin/sh
    echo_test()
    {
          echo "test is ok"
    }

    hhb=`echo_test`
    echo $hhb

获取函数返回值

    test_ass_nic
    RESULT=$?

### 3.3 外部参数传入 ###

    368 function usage()
    369 {
    370 echo "Usage:"
    371 echo "   -v changeset   the default changeset is the latest one"
    372 echo "   -c clean all configure file"
    373 echo "   -r reserve configure file(default option)"
    374 echo "   -p patch a file to XVS source"
    375 echo "   -u uninstall XVS"
    376 echo "   -h show this menu"
    377 return 0
    378 }
    
    476 while getopts rhcv:p:n: o
    477 do
    478 case "$o" in
    479 r)  RESERVE_CONF=yes;;
    480 c)  RESERVE_CONF=no;;
    481 v)  CHANGESET=$OPTARG;;
    482 p)  XVSPATCH=$OPTARG;;
    483 n)  NFS_SERVER=$OPTARG;;
    484 u)  xvs_uninstall
    485 quit 0;;
    486 h)  usage
    487 quit 0;;
    488 *)  usage
    489 quit 1;;
    490 esac
    491 done
    492 OPTIND=1


	[root@hhb-kvm tools]# sh getopt.sh --instance hhj --data hho --quit
	#!/bin/sh
	#set -x
	quita=0
	
	ARGV=($(getopt -a -l instance:,data:,quit -- "$@"))
	eval set -- "$ARGV"
	while true
	do
	    case "$1" in
	    --instance)
	            echo $2
	            shift 2
	            ;;
	    --data)
	        echo "$2"
	            shift 2
	            ;;
	    --)
	        shift
	        quita=1
	            ;;
	    esac
	
	    if [ $quita=="1" ]; then
	            break
	    fi
	done
	
	echo "yui"


### 3.4 特殊参数 ###
$? 执行上一个指令的返回值，可以获取上一个命令的退出状态。所谓退出状态，就是上一个命令执行后的返回结果

	if [ $? -eq 0 ]; then
	    create_bridge
	fi
	
	$0 这个程序的名字
	$n 这个程序的第 n 个参数
	$* 这个程序的所有参数
	$# 这个程序的参数个数
	$! 执行上一个背景指令的 PID
	$$ 表示当前 Shell 进程的 ID，即 pid
	$@ 传递给脚本或函数的所有参数。被双引号（“”）包含时，与 $* 稍有不同。


	$* 和 $@ 的区别
    $* 和 $@ 都表示传递给函数或脚本的所有参数，不被双引号（“”）包含时，都以“$1” "$2"  ... "$n"的形式输出所有参数。
    但是当它们被双引号（“”）包含时，“$*”会降所有的参数作为一个整体，以“$1 $2 ... $n"的形式输出所有参数； "$@"会将各个参数分开，以“$1” "$2"  ... "$n"的形式输出所有参数。

### 3.5 Shift 移动位置参数 ###
位置参数可以用shift命令左移。比如shift 3表示原来的$4现在变成$1，原来的$5现在变成$2等等，原来的$1、$2、$3丢弃，$0不移动。不带参数的shift命令相当于shift 1。
非常有用的 Unix 命令:shift。我们知道，对于位置变量或命令行参数，其个数必须是确定的，或者当 Shell 程序不知道其个数时，可以把所有参数一起赋值给变量$*。若用户要求 Shell 在不知道位置变量个数的情况下，还能逐个的把参数一一处理，也就是在 $1 后为 $2,在 $2 后面为 $3 等。在 shift 命令执行前变量 $1 的值在 shift 命令执行后就不可用了。

	示例1：移动一个参数
	#测试 shift 命令(x_shift.sh)
	until [ $# -eq 0 ]
	do
	     echo "第一个参数为: $1 参数个数为: $#"
	     shift
	done
	执行以上程序x_shift.sh：$./x_shift.sh 1 2
	结果显示如下：
	第一个参数为: 1 参数个数为: 2
	第一个参数为: 2 参数个数为: 1
	从上可知 shift 命令每执行一次，变量的个数($#)减一，而变量值提前一位，下面代码用 until 和 shift 命令计算所有命令行参数的和。
    
    示例2：移动多个参数
    #shift 上档命令的应用(x_shift2.sh)
    sum=0
    until [ $# -eq 0 ]
    do
    sum=`expr $sum + $1`
    shift
    done
    echo "sum is: $sum"
    
    执行上述程序: $x_shift2.sh 10 20 15
    
    其显示结果为：45
    
    Shift 命令还有另外一个重要用途, Bsh 定义了9个位置变量，从 $1 到 $9,这并不意味着用户在命令行只能使用9个参数，借助 shift 命令可以访问多于9个的参数。
    Shift 命令一次移动参数的个数由其所带的参数指定。例如当 shell 程序处理完前九个命令行参数后，可以使用 shift 9 命令把 $10 移到 $1。
    
    示例3：传多组参数
    #!/bin/sh
    set -x
    function Test_Co_Try_NetUpdomain()
    {
    tp_name=$1
    #shift
    for para in "$@"
    do
    local img_file=`echo $para | awk -F, '{print $1}'`
    local img_type=`echo $para | awk -F, '{print $2}'`
    local other=`echo $para | awk -F, '{print $NF}'`
    done
    }
    
    Test_Co_Try_NetUpdomain tp41 1,2 3,4 ,5

### 3.6 函数返回值 ###
函数可以带 function fun() 定义，也可以直接 fun()定义，不带任何参数。
参数返回，可以显式加：return 返回，如果不加，将以最后一条命令运行结果，作为返回值。return后跟数值 n(0-255)

