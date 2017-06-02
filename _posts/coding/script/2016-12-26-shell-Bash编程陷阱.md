下文参考如下链接  
http://oenhan.com/bash-pitfalls-1  
http://oenhan.com/bash-pitfalls-2

Bash编程陷阱:bash-pitfalls里面介绍了43条shell陷阱，都是一些很常见的应用场景，新手和老手都有可能犯的错误，为了加深记忆，自己就大致记录下来，英文文章用wiki编辑，条目随时可能增加，建议直接看英文。

如下的内容不完全翻译原文，穿插了一些自己的修改。

## 1. for i in $(ls *.mp3)
bash编程中最常见的错误之一就是把循环写出如下样子：

 for i in $(ls *.mp3); do # Wrong!
 some command $i # Wrong!
 done
 for i in $(ls) # Wrong!
 for i in ls # Wrong!
 for i in $(find . -type f) # Wrong!
 for i in find . -type f # Wrong!
为什么说上面错了呢，文件名里面可能存在空格，空格作为分隔符，拆分成参数传递给for循环处理，一个文件就会被拆分成多个文件。

更糟糕的是，如果文件名里面存在星号，则会被shell进一步处理，匹配成更多文件。

直接加上""的写法也是错误的

for i in "$(ls *.mp3)"; do # Wrong!
双引号会将ls的所有结果当做一个条目进行处理，错误往反方向行进，得不到应有的结果。

正确的方式应该不使用ls 或find等命令显示结果替换，直接使用。

for i in *.mp3; do
 [[ -f "$i" ]] || continue #多加一条保护
 some command "$i"
done
事实上，shell里面很多问题都是空格分离单词导致的，经常使用引号和注意单词分离，就能少很多bug。

## 2. cp $file $target
这个基本在于两个变量没有加上双引号括住，如果变量中存在空格，两个变量就会变成3个变量，恰好里面如果存在*等可以正则匹配形式，那么就可能匹配到多个文件。问题和前面表述的基本一样。

正确示例：

cp "$file" "$target"

## 3. 文件名里面有破折号“-”
如-ko a.oen文件，破折号会被当做前置的命令的入参处理，导致一次错误

oenhan@oenhan ~/code/tmp $ ls “-koa.oen”
ls：无效选项 -- .
正确的处理方式是在前面加上2个破折号

cp -- "$file" "$target"[/shel]
或者文件名前面没有直接命令
[shell]
for i in ./*.mp3; do
 cp "$i" /target
 ...
## 4. [ $foo = "bar" ]
此处有两个问题，foo值可能会空，或者foo值里面有空格

解释器就会看到

[ = "bar" ]
$或者
[ www oenhan com = "bar" ]
正常用法

[ "$foo" = bar ] # Pretty close!
$或者
[[ $foo = bar ]] # Right!
[[号有替换test的作用。

## 5. cd $(dirname "$f")
还是讨论过的空格的问题，命令替换就可能会导致字符分离或者路径匹配的问题。

正确用法：

cd "$(dirname "$f")"
C程序员可能会认为此处的双引号匹配有问题，其实都是OK的，因为$()的优先级更高。但是反引号`就不是这个样子了，所有还是推荐使用$()。

## 6. [ "$foo" = bar && "$bar" = foo ]
[]判断中使用&&是错误的。

正确的使用方式是

[ bar = "$foo" ] && [ foo = "$bar" ] # Right!
[[ $foo = bar && $bar = foo ]] # Also right!
更传统的方式是使用-a参数

[ bar = "$foo" -a foo = "$bar" ] # Not portable.
但这是有一定风险的，因为当test的入参判断多余4的时候，最后的结果结果是不确定的，参看POSIX标准。

>4 arguments:The results are unspecified.

## 7. [[ $foo > 7 ]]
[[不应被用于数学运算里面，更多用于字符串比较里面。数学运算常用的是(())符号。

((foo > 7)) # Right!
事实上在[[中使用>并不一定会出错，它事实上将7当做字符串和foo比较，如果它是从右开始比较的，可能会正常工作，如果从左开始比较，就有问题了。如果在[]里面使用>就更槽糕了，>号被当做重定向使用的。

~/code/tmp/oenhan $ if [ 7>5 ];then echo oenhan;fi
~/code/tmp/oenhan $ ls
5
~/code/tmp/oenhan $ if [ 5>7 ];then echo oenhan;fi
~/code/tmp/oenhan $ ls
5 7
~/code/tmp/oenhan $ rm 5 7
~/code/tmp/oenhan $ ls
~/code/tmp/oenhan $ if [ 5 > 7 ];then echo oenhan;fi
oenhan
~/code/tmp/oenhan $ if [ 7 > 5 ];then echo oenhan;fi
oenhan
~/code/tmp/oenhan $ ls
5 7
结果完全不可控，而且有垃圾文件生成。

当然也可以如下使用

test $foo -gt 7 # Also right!
[[ $foo -gt 7 ]] # Also right!
## 8. grep foo bar | while read -r; do ((count++)); done
有时候程序员用count这种方式来计算行数，是没办法工作的。

因为grep创立一个管道将内容传递给while，而管道是启动了一个子shell执行的，而count在子shell计算的结果是没办法传递到外面来的。

建议用法：

while read -r; do ((count++)); done << grep foo bar
## 9. if [grep foo myfile]
新手可能会以为[是if语法的一部分，事实上if是一个命令，[也是一个命令即是test。

使用一个命令的执行情况作为if判断，直接如下即可，不需要test

if grep foo myfile;then echo oenhan;fi
## 10. if [bar="$foo"]
 if [bar="$foo"] # Wrong!
 if [ bar="$foo" ] # Still wrong!
如9条所述，[是test命令，后面所有的参数都要用空格隔开。

## 11. if [ [ a = b ] && [ c = d ] ]; then
还是讲[，他是test命令，不是C语言中的括号用法。正确示例如下：

if [ a = b ] && [ c = d ]
 if test a = b && test c = d
if [[ a = b && c = d ]]

## 12. read $foo
read变量不需要使用$符号，直接read foo即可。

而read $foo会把内容读入到变量中，该变量的名称存储在$foo中，相当于双重间接指针。

## 13. cat file | sed s/foo/bar/ > file
你不能在一个管道里面读一个文件并写同一个文件，这个时候文件是有冲突的，导致的变化不可知。

建议创建一个临时文件搞定。sed -i修改文件也是通过临时文件搞定的，修改前后可以观察一个文件的inode号。

## 14. echo $foo
也是一个没有加""的问题，但是很容易被忽略，认为没有影响。

var="*.zip"
echo "$var" # 输出 *.zip
echo $var # 输出所有以 .zip 结尾的压缩文件
但双引号也是不安全的，如果文件名里面有类似-n的字段就会被认为是echo命令的参数使用。

最好还是使用printf。

printf "%sn" "$foo"

## 15. $foo=bar
在定义具体变量的时候不需要$符号

## 16. foo = bar
shell对空格敏感，认为它是一个参数，所以不需要空格。

## 17. echo <<EOF
echo不支持从标准输入读取内容，此处需要使用cat

	# This is wrong:
	 echo <<EOF
	 Hello world
	 How's it going?
	 EOF
	 # This is what you were trying to do:
	 cat <<EOF
	 Hello world
	 How's it going?
	 EOF

## 18. su -c 'some command'
su -c参数在不同的平台上意义不同，在openBSD上-c是用于指定login-class，执行su -c命令会出错，建议如下：

$ su root -c 'some command' # Now it's right.

## 19. cd /foo; bar
这个的主要原因是cd可能会失败，而后面的命令也许是rm -rf *,结果可能是很糟糕的。

简单点就是

cd /foo && bar
同时不建议使用cd命令和cd -命令，目录来回切换推荐用pushd和popd。

## 20. [ bar == "$foo" ]
正确用法如下

[ bar = "$foo" ] && echo yes
[[ bar == $foo ]] && echo yes

## 21. for i in {1..10}; do ./something &; done
&和分号一样也可以用作命令终止符,他们两个不用混用。

for i in {1..10}; do ./something &amp; done
$或者改成多行的形式：
for i in {1..10}; do
 ./something &amp;
done

## 22. cmd1 && cmd2 || cmd3
一般情况下使用是没有问题

true && cd oenhan || echo "error"
需要注意cmd2很多获取的是命令的执行输出还是命令的执行返回值

i=0
true && ((i++)) || ((i--))
echo $i # 输出 0
i=0
true && ((++i)) || (( --i ))
echo $i # 输出 1
(())获取的就是命令的执行输出，而不是说命令的执行返回值，上例需要注意前缀自增和后缀自增的不同。

本身用法无问题，只是使用者要注意区分命令的执行输出和执行返回值的不同。

## 23. echo "Hello World!"
一般报警为：bash: !": event not found

！号不能直接在双引号中使用，它会被解释为展开历史命令。

简单的方法就是用单引号。

## 24. for arg in $*
bash使用$*或者$@来承担脚本的所有入参，但用for遍历的时候需要注意

for arg in "$@"
$ 或者更简单的写法
for arg
这里的$@需要添加上"",此处的"$@"相当于"$1","$2","$3",而非"$1 $2 $3"

加引号的目的自然是预防空格，如果$1存在空格，那么就多出一个参数

## 25. function foo()
function的写法并不在所有的shell解释器中兼容。请使用

foo() {
 ...
}

## 26. echo "~"
~符号只有被引号括起来的时候才能转换为home目录的绝对地址，在""中只能打印出～符号，在特殊的日志输出里面需要注意。

示例：

tmp/oenhan $ echo ~/
/home/oenhan/
tmp/oenhan $ echo "~/"
~/

## 27. local varname=$(command)
一般情况下，在其后使用ret=$?获取command的返回值，但事实上获取是local定义的返回值，应该如下写法

local varname
varname=$(command)
rc=$?

## 28. export foo=~/bar
~并不在所有shell解释器中自动转换为home的绝对路径，不过bash里面是支持的。

## 29. sed 's/$foo/good bye/'
单引号里面不会转换$foo变量，可以使用双引号，当然，双引号内考虑的事情更多了

强迫症患者可能感觉不太美观，可以换成如下样子

sed 's/'$foo'/good bye/'
看起来有点乱，其实是正常的。

## 30. tr [A-Z] [a-z]
这样写法有三个问题，1，[a-z]被认为是通配符，如果当前没有单字母命名的文件，执行应该是OK的，否则就会对文件操作了。2.tr转换字符将[转换为对应的[，没有意义，直接去掉。3,A-Z在不同的语言环境中不一定会代表26个 ASCII 字母，使用前需要设定语言环境

LC_COLLATE=C tr A-Z a-z
不建议上面这个写法，推荐man手册中的写法

tr '[:upper:]' '[:lower:]'

## 31. ps ax | grep gedit
靠名称判断进程不靠谱，具体不解释

## 32. printf "$foo"
当foo中有特殊字符作为printf参数存在的时候，直接使用printf是有害的

需要在printf后面加上打印格式，示例：

$ foo='a%sdn'
$ printf $foo
ad
$ printf %s $foo
a%sdn
## 33. for i in {1..$n}
此处的$n不会展开，{x..y}的展开的限制条件是：1) 整数或者单个字符; 2)两者要是同一个类型。{1..$n}不满足以上条件。具体参考GNU手册

具体实现推荐直接使用for循环搞定

## 34. if [[ $foo = $bar ]]
[[]]里面不加引号会做模式匹配，$bar如果*,则结果永远为真。

## 35. if [[ $foo =~ 'some RE' ]]
加''后正则表达式就失效了，和34结果相反。

## 36. [ -n $foo ] or [ -z $foo ]
仍然是字符串没有加引号，不为空有空格或者为空，都会有语法错误。

## 37. [[ -e "$broken_symlink" ]] 
-e判断一个文件是否存在，但在判断软链接的时候，实际返回值是链接文件是否存在的结果；即链接的目标文件不存在，但软链接仍然存在，此时仍然返回失败。符号链接的判断建议用-L处理。

## 38. ed file <<<"g/d{0,3}/s//e/g" fails
ed使用的正则表达式，不支持0的出现次数

## 39. expr sub-string fails for "match"
match是expr的关键字，使用的时候需要加+号

word=match
expr + "$word" : ".(.*)"
atch
expr古董般难用的命令，应该被抛弃了

## 40. On UTF-8 and Byte-Order Marks (BOM)
BOM在脚本执行的时候和win的换行符一样可能有问题。

## 41. content=$(<file)
所有内容只有1行，换行符丢掉了

## 42. for file in ./* ; do if [[ $file != *.* ]]
file的字符串会带上./，在匹配的时候就会有问题。

## 43. somecmd 2>&1 >>logfile
解释器对位置敏感，此处相当于somecmd >> logfile;somecmd 2 >&1

