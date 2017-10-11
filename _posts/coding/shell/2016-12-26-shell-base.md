
# 1.循环 #

## 1.1 break命令

break命令允许跳出所有循环（终止执行后面的所有循环）。

下面的例子中，脚本进入死循环直至用户输入数字大于5。要跳出这个循环，返回到shell提示符下，就要使用break命令。
    
    #!/bin/bash
    while :
    do
    	echo -n "Input a number between 1 to 5: "
    	read aNum
    	case $aNum in
    		1|2|3|4|5) echo "Your number is $aNum!"
    		;;
    	*) echo "You do not select a number between 1 to 5, game is over!"
    		break
    		;;
    	esac
    done

在嵌套循环中，break 命令后面还可以跟一个整数，表示跳出第几层循环。例如：
break n
表示跳出第 n 层循环。

下面是一个嵌套循环的例子，如果 var1 等于 2，并且 var2 等于 0，就跳出循环：
    #!/bin/bash
    for var1 in 1 2 3
    do
       for var2 in 0 5
       do
    	  if [ $var1 -eq 2 -a $var2 -eq 0 ]; then
     	  	  break 2
          else
              echo "$var1 $var2"
          fi
       done
    done

如上，break 2 表示直接跳出外层循环。运行结果：  
1 0  
1 5

## 1.2 continue命令 ##

continue命令与break命令类似，只有一点差别，它不会跳出所有循环，仅仅跳出当前循环。

对上面的例子进行修改：

    #!/bin/bash
    while :
    do
    	echo -n "Input a number between 1 to 5: "
    	read aNum
    	case $aNum in
    		1|2|3|4|5) echo "Your number is $aNum!"
    		;;
    		*) echo "You do not select a number between 1 to 5!"
    			continue
    			echo "Game is over!"
    			;;
    	esac
    done

运行代码发现，当输入大于5的数字时，该例中的循环不会结束，语句
echo "Game is over!"
永远不会被执行。

同样，continue 后面也可以跟一个数字，表示跳出第几层循环。

再看一个 continue 的例子：

    #!/bin/bash
    NUMS="1 2 3 4 5 6 7"
    for NUM in $NUMS
    do
    	Q=`expr $NUM % 2`
    	if [ $Q -eq 0 ]; then
    		echo "Number is an even number!!"
    		continue
    	fi
    	echo "Found odd number"
    done

运行结果：

Found odd number  
Number is an even number!!  
Found odd number  
Number is an even number!!  
Found odd number  
Number is an even number!!  
Found odd number

## 1.3 for & while

    while [ $i -lt $resource_node_count ]
    do
    	...
    done

	for loop in `ls *.xml`

	for((i=1; i<=10;i++));

# 2. Array(数组)
Shell在编程方面比Windows批处理强大很多，无论是在循环、运算。

bash支持一维数组（不支持多维数组），并且没有限定数组的大小。类似与C语言，数组元素的下标由0开始编号。获取数组中的元素要利用下标，下标可以是整数或算术表达式，其值应大于或等于0。

## 2.1 定义数组 ##

在Shell中，用括号来表示数组，数组元素用“空格”符号分割开。定义数组的一般形式为：

    array_name=(value1 ... valuen)

    例如：
    array_name=(value0 value1 value2 value3)
    或者
    array_name=(
    value0
    value1
    value2
    value3
    )

还可以单独定义数组的各个分量：

    array_name[0]=value0
    array_name[1]=value1
    array_name[2]=value2

可以不使用连续的下标，而且下标的范围没有限制。

## 2.2 读取数组 ##

读取数组元素值的一般格式是：

    ${array_name[index]}
    
    例如：
    valuen=${array_name[2]}
    举个例子：
    #!/bin/sh
    NAME[0]="Zara"
    NAME[1]="Qadir"
    NAME[2]="Mahnaz"
    NAME[3]="Ayan"
    NAME[4]="Daisy"
    echo "First Index: ${NAME[0]}"
    echo "Second Index: ${NAME[1]}"

运行脚本，输出：

    $./test.sh
    First Index: Zara
    Second Index: Qadir
    使用@ 或 * 可以获取数组中的所有元素，例如：
    ${array_name[*]}
    ${array_name[@]}

举个例子：

    #!/bin/sh
    NAME[0]="Zara"
    NAME[1]="Qadir"
    NAME[2]="Mahnaz"
    NAME[3]="Ayan"
    NAME[4]="Daisy"
    echo "First Method: ${NAME[*]}"
    echo "Second Method: ${NAME[@]}"
    运行脚本，输出：
    $./test.sh
    First Method: Zara Qadir Mahnaz Ayan Daisy
    Second Method: Zara Qadir Mahnaz Ayan Daisy

## 2.3 获取数组的长度 ##

获取数组长度的方法与获取字符串长度的方法相同，例如：

    # 取得数组元素的个数  
    length=${#array_name[@]}  
    # 或者
    length=${#array_name[*]}
    # 取得数组单个元素的长度
    lengthn=${#array_name[n]}

# 3.if
## 3.1 if 语句 ##

大多数情况下，可以使用测试命令来对条件进行测试。比如可以比较字符串、判断文件是否存在及是否可读等,通常用"[]"来表示条件测试。注意这里的空格很重要。要确保方括号的空格。 含条件选择的shell脚本对于不含变量的任务简单shell脚本一般能胜任。但在执行一些决策任务时，就需要包含if/then的条件判断了。shell脚本编程支持此类运算，包括比较运算、判断文件是否存在等。

    if [ 条件判断一 ] && (||) [ 条件判断二 ]; then
    elif [ 条件判断三 ] && (||) [ 条件判断四 ]; then
    else
       执行第三段內容程式
    fi
    
    eg: if [ "`ls -A $DIR`"="" ] || [-z $EDITOR ]; then

## 3.2 判断表达式
### 3.2.1 二元操作符
返回true，如果：
	
	-e  文件存在
	-a  文件存在（已被弃用）
	-f   被测文件是一个regular文件（正常文件，非目录或设备），判断是否是一个文，是文件则为真 
	-s  文件长度不为0
	-d  被测对象是目录，检查目录对象是否存在
	-b  被测对象是块设备，文件为块特殊文件为真 
	-c  被测对象是字符设备，文件为字符特殊文件为真
	-p  被测对象是管道
	-h  被测文件是符号连接
	-L  被测文件是符号连接
	-S(大写) 被测文件是一个socket
	-t  关联到一个终端设备的文件描述符。用来检测脚本的stdin[-t0]或[-t1]是一个终端，当文件描述符(默认为1)指定的设备为终端时为真
	-r  文件具有读权限，针对运行脚本的用户，用户可读为真 
	-w 文件具有写权限，针对运行脚本的用户，用户可写为真 
	-x  文件具有执行权限，针对运行脚本的用户，用户可执行为真 
	-u  set-user-id(suid)标志到文件，即普通用户可以使用的root权限文件，通过chmod +s file实现
	-k  设置粘贴位
	-O 运行脚本的用户是文件的所有者
	-G 文件的group-id和运行脚本的用户相同
	-N 从文件最后被阅读到现在，是否被修改
	f1 -nt f2文件f1是否比f2新
	f1 -ot f2文件f1是否比f2旧
	f1 -ef f2文件f1和f2是否硬连接到同一个文件
	-z 字符串为"null".就是长度为0. 
	-n 字符串不为"null"

### 3.2.2 二元比较操作符，比较变量或比较数字

**整数比较**

    -eq   等于               if [ "$a" -eq "$b" ]
    -ne   不等于             if [ "$a" -ne "$b" ]
    -gt   大于               if [ "$a" -gt "$b" ]
    -ge   大于等于            if [ "$a" -ge "$b" ]
    -lt   小于if             [ "$a" -lt "$b" ]
    -le   小于等于           if [ "$a" -le "$b" ]
    <     小于（需要双括号）   (( "$a" < "$b" ))
    <=    小于等于(...)      (( "$a" <= "$b" ))
    >     大于(...)          (( "$a" > "$b" ))
    >=    大于等于(...)      (( "$a" >= "$b" ))

**字符串比较**

    =     等于   if [ "$a" = "$b" ]
    ==    与=等价
    !=    不等于 if [ "$a" = "$b" ]
    <     小于，在ASCII字母中的顺序：
    	if [[ "$a" < "$b" ]]
    	if [ "$a" \< "$b" ] #需要对<进行转义
    >     大于
    	-z 字符串为null，即长度为0
    	-n 字符串不为null，即长度不为0

注意:==的功能在[[]]和[]中的行为是不同的,如下:

     1 [[ $a == z* ]] # 如果$a以"z"开头(模式匹配)那么将为true
     2 [[ $a == "z*" ]] # 如果$a等于z*(字符匹配),那么结果为true
     3 [ $a == z* ] # File globbing 和word splitting将会发生
     4 [ "$a" == "z*" ] # 如果$a等于z*(字符匹配),那么结果为true


## 3.3 例子 ##

    if [ -f "$FILE" ];then 
    if [[ $NUM -gt 3 ]];then
	下面操作符将在[[]]结构中使用模式匹配
    大于,在ASCII字母顺序下.如:
    	if [[ "$a" > "$b" ]]
    	if [ "$a" \> "$b" ]
    注意:在[]结构中">"需要被转义.
    if [ ${nodisk:0:3} = ${disk:0:3} ]; then    字符串截取比较


## 4.数据转换
## 4.1 字符串转数字
	
	export hhb=FD
	echo "ibase=16;obase=2;$hhb" | bc   (16进制转2进制）
	echo "ibase=16;obase=8;$hhb/23" | bc 


# 5. shell内建命令 #

UNIX 命令有内部命令和外部命令之分。内部命令实际上是shell程序的一部分，其中包含的是一些比较简练的UNIX系统命令，这些命令由shell程序识别并在shell程序内部完成运行，通常在UNIX系统加载运行时shell就被加载并驻留在系统内存中。外部命令是UNIX系统中的实用程序部分，因为实用程序的功能通常都比较强大，所以它们包含的程序量也会很大，在系统加载时并不随系统一起被加载到内存中，而是在需要时才将其调进内存。通常外部命令的实体并不包含在shell中，但是其命令执行过程是由shell 程序控制的。shell程序管理外部命令执行的路径查找、加载存放，并控制命令的执行。内部命令要比外部命令的反应时间快一些，内部命令不用启动一个子shell来运行。

### 查看shell内部命令 ###

    # man builtins

### 判断某命令是否是内部命令 ###
凡是用which命令查不到程序文件所在位置的命令都是内建命令，内建命令没有单独的man手册，要在man手册中查看内建命令，应该man bash-builtins

	#type -a command
	#command --help 查看外部命令的帮助文件
	#help command 查看内部命令的帮助文件
 
### 外部命令执行过程如下 ###

外部命令就是由 shell 副本(新的进程)所执行的命令,基本的过程如下:

- 建立一个新的进程.此进程即为 shell 的一个副本，在新的进程里,在 PATH 变量内所列出的目录中,需找特定命令.

	为 PATH 变量典型的默认值  
	/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/u sr/sbin:/usr/bin:/root/bin 

- 当命令名称含有斜杠(/)字符时,将略过路径查找步骤
- 在新的进程里,以所找到的新程序取代执行中的 shell 程序并执行
- 程序完成后,最初的 shell 会接着从终端读取下一条命令, 和执行脚本里的下一跳命令.
- 使用 type 可以查看是否是内建命令
    
	type(不带参数)会显示命令是内建的还是外部的.  
    -t : file 外部命令 ;alias 命令别名 ; builtin 内置命令  
    -a : 会将命令 PATH 路径显示出来.  

### 内建命令介绍 ###
https://www.ibm.com/developerworks/library/l-bash-test/