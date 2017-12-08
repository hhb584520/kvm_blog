# 0.lib 基础知识 #
## 0.1 导入库 #
Python学习之import与from xx import

今天在python的运行框里分别输入import datetime.datetime 和 from datetime import datetime，本以为结果应该是一样，结果前者却报错。

importdatetime.datetimeTraceback (most recent call last):  File "<stdin>", line 1, in<module>ImportError: No module named datetime>>>

上面前者的用法只能在3.x中使用。下面说下这两者的不同：当我们使用“import A.B”导入模块的时候, 在代码中使用B，仍然得使用“A.B”这种方式才能正确索引；而对于“from A import B”这样的语句，我们可以在代码中直接使用B就可以索引到B。乍一看之下，貌似后者比前者方便很多，不用使用太多的“...”，但看到不少人说并不提倡使用“from A import B ”这样的语句，原因就是它会使得当前程序的命名空间混乱，出现重名覆盖的问题，比如程序中其他地方或者其他模块会出现一个也叫“B”的模块，这样在程序执行中就会出现很大的问题。但是呢，事情并不是完全没有解决方案，如果我们非要使用后面这种语句（毕竟它比较简练，索引变量也比较方便，尤其在vim下编程来说），除了要非常小心不能出现这种重名问题之外，还可以使用“from A import B as m_B”，这样在后面的程序就用m_B来代替B了，这样就不会出重名的问题啦。

## 0.2 查看帮助

	python
	
	>>> import re
	>>> help(re)
	>>> help(re.compile)
	>>> print(re.__file__)   # 查看对应库的源文件
	>>> print(re.__doc__)    # 查看对应的文档
	>>> re.__all__           # 查看导出的函数
	
	
在编写模块的时候，像设置 __all__ 这样的技术是相当有用的。因为模块中可能会有一大堆其他程序不需要或不想要的变量、函数和类，__all__会把它过滤掉。如果没有设定 __all__ , 用 import * 语句默认将会导入模块中所有不以下划线开头的全局名称。


## 0.3 包


#1. 参数解析
http://www.cnblogs.com/captain_jack/archive/2011/01/11/1933366.html

Python 有两个内建的模块用于处理命令行参数：
一个是 getopt，《Deep in python》一书中也有提到，只能简单处理 命令行参数；
另一个是 optparse，它功能强大，而且易于使用，可以方便地生成标准的、符合Unix/Posix 规范的命令行说明。

## 1.1 参数说明 
增加参数

	ArgumentParser.add_argument(name or flags...[, action][, nargs][, const][, default][, type][, choices][, required][, help][, metavar][, dest])

每个参数解释如下:

- name or flags - 参数的名字.
- action - 遇到参数时的动作，默认值是store。store_const，表示赋值为const；append，将遇到的值存储成列表，也就是如果参数重复则会保存多个值; append_const，将参数规范中定义的一个值保存到一个列表；count，存储遇到的次数；此外，也可以继承argparse.Action自定义参数解析；store 也有其它的两种形式： store_true 和 store_false ，用于处理带命令行参数后面不 带值的情况。如 -v,-q 等命令行参数：
	
	parser.add_option("-v", action="store_true", dest="verbose")  
	parser.add_option("-q", action="store_false", dest="verbose")  

- nargs - 参数的个数，可以是具体的数字，或者是?号，当不指定值时对于Positional argument使用default，对于Optional argument使用const；或者是*号，表示0或多个参数；或者是+号表示1或多个参数.

- const - action和nargs所需要的常量值.
- default - 不指定参数时的默认值.
- type - 参数的类型.
- choices - 参数允许的值.
- required - 可选参数是否可以省略(仅针对optionals). 
- help - 参数的帮助信息，当指定为argparse.SUPPRESS时表示不显示该参数的帮助信息.
- metavar - 在 usage 说明中的参数名称，对于必选参数默认就是参数名称，对于可选参数默认是全大写的参数名称. 
- dest - 解析后的参数名称，默认情况下，对于可选参数选取最长的名称，中划线转换为下划线.

## 1.2 使用例子
	
	import re, os, string, glob
	from optparse import OptionParser
	
	usage = "usage: %prog [options] arg"
	parser = OptionParser(usage=usage)
	parser.add_option("-f", "--file", dest="logfile", action="store",
	                help="input log file to check.")
	
	(options, args) = parser.parse_args()
	
	print options.logfile
	
	if not os.path.exists(options.logfile):
	        print options.logfile + " not exist."
	
	logfile = open(r"%s" % options.logfile)

## 1.3 系统参数

	sys.argv[1]      # 第一个参数
	len(sys.argv)    # 参数个数

# 2. 模式匹配
正则表达式是一个特殊的字符序列，它能帮助你方便的检查一个字符串是否与某种模式匹配。
Python 自1.5版本起增加了re 模块，它提供 Perl 风格的正则表达式模式。
re 模块使 Python 语言拥有全部的正则表达式功能。

**compile** 函数根据一个模式字符串和可选的标志参数生成一个正则表达式对象。该对象拥有一系列方法用于正则表达式匹配和替换。
re 模块也提供了与这些方法功能完全一致的函数，这些函数使用一个模式字符串做为它们的第一个参数。
本章节主要介绍Python中常用的正则表达式处理函数。

	case_pattern = re.compile("\[CASE\]")
	pass_pattern = re.compile("failed")  

## 2.1 re.match函数
re.match 尝试从字符串的起始位置匹配一个模式，如果不是起始位置匹配成功的话，match()就返回none。

	import re
	print(re.match('www', 'www.runoob.com').span())  # 在起始位置匹配
	print(re.match('com', 'www.runoob.com'))         # 不在起始位置匹配

## 2.2 re.search方法
re.search 扫描整个字符串并返回第一个成功的匹配。
函数语法：
re.search(pattern, string, flags=0)

	print(re.search('www', 'www.runoob.com').span())  # 在起始位置匹配
	print(re.search('com', 'www.runoob.com').span())  # 不在起始位置匹配

## 2.3 re.sub 检索和替换
Python 的 re 模块提供了re.sub用于替换字符串中的匹配项。

语法：

	re.sub(pattern, repl, string, count=0, flags=0)
	参数：
	pattern : 正则中的模式字符串。
	repl : 替换的字符串，也可为一个函数。
	string : 要被查找替换的原始字符串。
	count : 模式匹配后替换的最大次数，默认 0 表示替换所有的匹配。

实例：
	phone = "2004-959-559 # 这是一个国外电话号码"
	# 删除字符串中的 Python注释 
	num = re.sub(r'#.*$', "", phone)
	print "电话号码是: ", num
	 
	# 删除非数字(-)的字符串 
	num = re.sub(r'\D', "", phone)
	print "电话号码是 : ", num

以上实例执行结果如下：

	电话号码是:  2004-959-559 
	电话号码是 :  2004959559

# 3. file
## 3.1 open

open的第一个参数是文件名。第二个(mode 打开模式)决定了这个文件如何被打开。

- 如果你想读取文件，传入r
- 如果你想读取并写入文件，传入r+
- 如果你想覆盖写入文件，传入w
- 如果你想在文件末尾附加内容，传入a

虽然有若干个其他的有效的mode字符串，但有可能你将永远不会使用它们。mode很重要，不仅因为它改变了行为，而且它可能导致权限错误。举个例子，我们要是在一个写保护的目录里打开一个jpg文件， open(.., 'r+')就失败了。mode可能包含一个扩展字符；让我们还可以以二进制方式打开文件(你将得到字节串)或者文本模式(字符串)

一般来说，如果文件格式是由人写的，那么它更可能是文本模式。jpg图像文件一般不是人写的（而且其实不是人直接可读的），因此你应该以二进制模式来打开它们，方法是在mode字符串后加一个b(你可以看看开头的例子里，正确的方式应该是rb)。
如果你以文本模式打开一些东西（比如，加一个t,或者就用r/r+/w/a），你还必须知道要使用哪种编码。对于计算机来说，所有的文件都是字节，而不是字符。

## 3.2 读一行

	with open(options.logfile, 'rb') as logfile:
        for line in logfile.readlines():

## 3.3 使用例子

	import io
	
	with open('photo.jpg', 'rb') as inf:
	    jpgdata = inf.read()

	
	if jpgdata.startswith(b'\xff\xd8'):
	    text = u'This is a JPEG file (%d bytes long)\n'
	else:
	    text = u'This is a random file (%d bytes long)\n'
	
	with io.open('summary.txt', 'w', encoding='utf-8') as outf:
	    outf.write(text % len(jpgdata)

### 3.4 glob

glob是python自己带的一个文件操作相关模块，内容也不多，用它可以查找符合自己目的的文件，就类似于Windows下的文件搜索，而且也支持通配符，*,?,[]这三个通配符，*代表0个或多个字符，?代表一个字符，[]匹配指定范围内的字符，如[0-9]匹配数字。

它的主要方法就是glob,该方法返回所有匹配的文件路径列表，该方法需要一个参数用来指定匹配的路径字符串（本字符串可以为绝对路径也可以为相对路径），比如：
	
	[root@vt-master ~]$ python
	>>> import glob
	>>> glob.glob(r'/root/*.py')  # 获得 /root 目录下的所有 py 文件
	['/root/hhb_net.py', '/root/get_network.py', '/root/check_replay_log.py']
	>>>


使用相对路径：

	glob.glob(r'../*.py')

iglob方法：

获取一个可编历对象，使用它可以逐个获取匹配的文件路径名。与glob.glob()的区别是：glob.glob同时获取所有的匹配路径，而 glob.iglob一次只获取一个匹配路径。这有点类似于.NET中操作数据库用到的DataSet与DataReader。下面是一个简单的例子：

	[root@hhb-xen ~]# cat yui.py
	#!/usr/bin/python
	
	import glob
	f=glob.iglob(r'/root/*.py')
	for py in f:
	        print py


## 4.explain external app
### 4.1 Python 调用本地程序

	import subprocess
	
	cmd="cmd.exe"
	begin=197
	end=240
	while begin<end:
		p=subprocess.Popen(cmd,shell=True,	stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
		
		p.stdin.write("ping 12.0.0."+str(begin)+"\n")
		
		p.stdin.close()
		p.wait()
		begin = begin+1
		
		print "execution result: %s"%p.stdout.read()

### 4.2 解析 shell 命令

	import os
	def parse_cmd(cmd):
	    output=os.popen(cmd)
	    return output.read()

## 5. 迭代器

http://www.wklken.me/posts/2013/08/20/python-extra-itertools.html#itertoolsisliceiterable-stop

	from itertools import islice
	with open(filepath + 'Summary.csv', "r") as csv_file:
	    for row in islice(csv_file, 1, None):
	        row_0 = row.split(',')[0]
	        row_1 = row.split(',')[1]
	        arr.append(row_0 + ',' + row_1)
	        status_dic[row_1] = row_2
	        if row_2 in dic.keys():
	             dic[row_2] += 1
	        else:
	             dic[row_2] = 1
	        
	csv_file.close()

## 6. mail
### 6.1 send mail
https://www.tutorialspoint.com/python/python_sending_email.htm
	
	import smtplib
	
	sender = 'root@intel.com'
	receivers = ['haibin.huang@intel.com']
	
	message = """From: From Person <root@intel.com>
	To: To Person <haibin.huang@intel.com>
	Subject: SMTP e-mail test
	
	This is a test e-mail message.
	"""
	
	try:
	    smtpObj = smtplib.SMTP('localhost')
	    smtpObj.sendmail(sender, receivers, message)
	    print "Successfully sent email"
	except SMTPException:
	    print "Error: unable to send email"

## 7.request session
http://docs.python-requests.org/zh_CN/latest/user/advanced.html

## 8. database
### 8.1 install mysql
https://www.linode.com/docs/databases/mysql/how-to-install-mysql-on-centos-7

### 8.2 op mysql

	mysql -u root -p
	SHOW DATABASES;
	create database testdb;
	create user 'testuser'@'localhost' identified by 'password';
	grant all on testdb.* to 'testuser' identified by 'password';
	use testdb;
	CREATE TABLE EMPLOYEE (FIRST_NAME CHAR(20) NOT NULL,AGE INT,INCOME FLOAT);
	INSERT INTO EMPLOYEE(FIRST_NAME, AGE, INCOME) VALUES('Mac', 20, 2000);
	select * from EMPLOYEE;

### 8.3 python mysql

MySQL-python-1.2.3.win-amd64-py2.7.exe
MySQL-work

代码如下：

	#-*- encoding: utf8 -*-
	import os, sys, string
	import MySQLdb
	
	class Mysql:
	    # 连接数据库
	    def conn(self):
	        try:
	            conn = MySQLdb.connect(host='12.0.0.201',user='root',passwd='intple',db='test')
	        except Exception, e:
	            print e
	            sys.exit()
	            # 获取cursor对象来进行操作
	
	        cursor = conn.cursor()
	        
	        # 创建表
	        sql = "create table if not exists test1(name varchar(128) primary key, age int(4))"
	        cursor.execute(sql)
	            
	        # 插入多条
	        sql = "insert into test1(name, age) values (%s, %s)" 
	        val = (("李四", 24), ("王五", 25), ("洪六", 26))
	        try:
	            cursor.executemany(sql, val)
	        except Exception, e:
	                print e
	
	        #查询出数据
	        sql = "select * from test1"
	        cursor.execute(sql)
	        alldata = cursor.fetchall()
	        # 如果有数据返回，就循环输出, alldata是有个二维的列表
	        if alldata:
	            for rec in alldata:
	                print rec[0], rec[1]
	        
	        cursor.close()
	        conn.close()