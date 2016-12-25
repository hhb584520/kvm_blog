# Evel #
用法：eval command-line
原理：eval主要用在对参数的特殊处理上面的，一般的命令行，shell处理参数就只执行一遍，像转义和变量转变；但加上eval后就可以对参数经行两遍处理；网上有说是对command-line处理两遍，我认为是不合理的。一个eval只能使shell对参数多一次处理，因此有几个eval就可以多加几次，即eval eval command-line 这样就能对参数进行三次编译，但此时应特别注意参数的转义，下面有例子说明。
eval命令会计算(evalue)它的参数，这些参数作为表达式计算后重新组合为一个字符串，然后作为一个命令被执行。

## 1. eval command-line ##
其中command－line是在终端上键入的一条普通命令行。然而当在它前面放上eval时，其结果是shell在执行命令行之前扫描它两次。如：

    pipe="|"
    eval ls $pipe wc -l

shell第1次扫描命令行时，它替换出pipe的值｜，接着eval使它再次扫描命令行，这时shell把｜作为管道符号了。
如果变量中包含任何需要shell直接在命令行中看到的字符（不是替换的结果），就可以使用eval。
命令行结束符（；｜ &），I／o重定向符（< >）和引号就属于对shell具有特殊意义的符号，必须直接出现在命令行中。

## 2. eval echo \$$# 取得最后一个参数 ##

    如：set one two three four
    echo \$$#
    $4
    eval echo \$$#
    four
    第一遍扫描后，shell把反斜杠去掉了。当shell再次扫描该行时，它替换了$4的值，并执行echo命令

## 3.以下示意如何用eval命令创建指向变量的“指针”： ##

    x=100
    ptrx=x
    eval echo \$$ptrx 指向ptrx，用这里的方法可以理解b中的例子
    100 打印100
    eval $ptrx=50 将50存到ptrx指向的变量中。
    echo $x
    50 打印50

## 4. eval最常见的用法是将动态生成的命令行计算并执行。例如： ##

    $ name=woodie
    $ cmd="echo Helllo $name\! "
    $ eval $cmd
    Hello woodie!

## 5. 对三重的支持 ##

    root@localhost:~/test#aabbcc=alibaba
    root@localhost:~/test#a=aa
    root@localhost:~/test#b=bb
    root@localhost:~/test#c=cc
    root@localhost:~/test#alibaba="hello world"
    root@localhost:~/test#eval echo \$\$$a$b$c
    11990aabbcc
    root@localhost:~/test#eval echo \\$\$$a$b$c
    $alibaba
    root@localhost:~/test#eval eval echo \$\$$a$b$c
    11990aabbcc
    root@localhost:~/test#eval eval echo \\$\$$a$b$c
    hello world

注意这里的参数转义，第一遍处理后参数应该是：\$$aabbcc，第二次是：$alibaba，第三次就正好是：hello world。
附eval用法三例(网络收集)：

    例一:
    #寻找合符条件的变量名,然后将该变量的值赋予另一变量
    v1=aaa
    v2=bbb
    c=1
    if [ $c -eq 1 ]
    then
    vname=v$c #找到符合条件的变量名为v1
    eval vvv="$"$vname ; echo vvv: $vvv #将变量v1的值赋予vvv,即,使vvv=aaa
    eval vvv='$'$vname ; echo vvv: $vvv #将变量v1的值赋予vvv,即,使vvv=aaa
    #eval vvv=$$vname ; echo vvv: $vvv #错误用法
    fi

    #例二:
    #以变量v1的值aaa作为变量名,将变量vaaa的值赋予这一新定义的变量aaa
    v1=aaa ; vaaa="This is aaa"
    #eval $v1=$vaaa ; echo aaa: $aaa #错误用法
    #eval $v1="$vaaa" ; echo aaa: $aaa #错误用法
    eval $v1='$vaaa' ; echo aaa: $aaa

    #例三:
    #以变量v1的值aaa作为变量名,并将变量名字串作为值赋予自身
    v1=aaa ; vaaa="This is aaa"
    eval $v1=$v1 ; echo aaa: $aaa #与例二的错误用法不同,这一用法是正确的
    eval $v1="$v1" ; echo aaa: $aaa #与例二的错误用法不同,这一用法是正确的
    eval $v1='$v1' ; echo aaa: $aaa
