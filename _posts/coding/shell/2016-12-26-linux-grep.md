# grep #
[root@ ~]# grep [-acinv] [--color=auto] '搜寻字符串' filename
选项与参数：

- -a ：将 binary 文件以 text 文件的方式搜寻数据
- -c ：计算找到 '搜寻字符串' 的次数
- -i ：忽略大小写的不同，所以大小写视为相同
- -n ：顺便输出行号
- -v ：反向选择，亦即显示出没有 '搜寻字符串' 内容的那一行
- --color=auto ：可以将找到的关键词部分加上颜色的显示喔
- -h ：查询多文件时只输出包含匹配字符的文件名。
- -s ：不显示不存在或无匹配字符的错误信息。
- -l ：查询多文件时只输出包含匹配字符的文件名。
- -e :<范本样式>或--regexp=<范本样式>   指定字符串做为查找文件内容的范本样式。
- -E :或--extended-regexp   将范本样式为延伸的普通表示法来使用

## 1. grep常用用法 ##
### 1.1 反向选择 ###

grep命令应该是我们在获取字符串内容时，或读取文件时，进行分析的好命令，但是有时候针对一些字符，我们想排除掉某些字符。

-v 参数就可以很好的实现，比如我想查看apaceh日志中，非图片的浏览记录。可以使用以下命令：

	tail -f /usr/loca/apache/logs/access.log |grep -v '.jpg'


### 1.2 正则表达式  ###

1、基本的正则表达式（Basic Regular Expression 又叫 Basic RegEx  简称 BREs）

2、扩展的正则表达式（Extended Regular Expression 又叫 Extended RegEx 简称 EREs）

具体区别：
http://blog.csdn.net/fdl19881/article/details/7800877