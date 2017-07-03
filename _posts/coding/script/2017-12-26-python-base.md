# 基本语法 #
https://www.tutorialspoint.com/python/python_command_line_arguments.htm

## 1. loops
### 1.1 for loops

	#!/usr/bin/python
	
	for letter in 'Python':     # First Example
	   print 'Current Letter :', letter
	
	fruits = ['banana', 'apple',  'mango']
	for fruit in fruits:        # Second Example
	   print 'Current fruit :', fruit
	
	print "Good bye!"

### 1.2 while loops

	#!/usr/bin/python
	
	count = 0
	while (count < 9):
	   print 'The count is:', count
	   count = count + 1
	
	print "Good bye!"

### 1.3 nested loops

	#!/usr/bin/python
	
	i = 2
	while(i < 100):
	   j = 2
	   while(j <= (i/j)):
	      if not(i%j): break
	      j = j + 1
	   if (j > i/j) : print i, " is prime"
	   i = i + 1
	
	print "Good bye!"

### 1.4 Control Statement

	break
	continue
	pass

## 2. Variable
### 2.1 Global Variable
	$ cat check_events_log.py

	jpgdata=''
	def openlogfile():
	    global jpgdata
	    with open(options.logfile, 'rb') as inf:
	        jpgdata = inf.read()
	
	openlogfile()
	print jpgdata

### 2.2 Variable Types
Python has five standard data types −

- Numbers(int, long, float, complex)

define variable: var1=10
undefine variable: del var1

- String

		#!/usr/bin/python
		
		str = 'Hello World!'
	
		print str          # Prints complete string
		print str[0]       # Prints first character of the string
		print str[2:5]     # Prints characters starting from 3rd to 5th
		print str[2:]      # Prints string starting from 3rd character
		print str * 2      # Prints string two times
		print str + "TEST" # Prints concatenated string

- List

To some extent, lists are similar to arrays in C. One difference between them is that all the items belonging to a list can be of different data type.

	#!/usr/bin/python
	
	list = [ 'abcd', 786 , 2.23, 'john', 70.2 ]
	tinylist = [123, 'john']
	
	print list          # Prints complete list
	print list[0]       # Prints first element of the list
	print list[1:3]     # Prints elements starting from 2nd till 3rd 
	print list[2:]      # Prints elements starting from 3rd element
	print tinylist * 2  # Prints list two times
	print list + tinylist # Prints concatenated lists

- Tuple

The main differences between lists and tuples are: Lists are enclosed in brackets ( [ ] ) and their elements and size can be changed, while tuples are enclosed in parentheses ( ( ) ) and cannot be updated. Tuples can be thought of as read-only lists. For example −

	#!/usr/bin/python
	
	tuple = ( 'abcd', 786 , 2.23, 'john', 70.2  )
	tinytuple = (123, 'john')
	
	print tuple           # Prints complete list
	print tuple[0]        # Prints first element of the list
	print tuple[1:3]      # Prints elements starting from 2nd till 3rd 
	print tuple[2:]       # Prints elements starting from 3rd element
	print tinytuple * 2   # Prints list two times
	print tuple + tinytuple # Prints concatenated lists

- Dictionary

A dictionary key can be almost any Python type, but are usually numbers or strings. Values, on the other hand, can be any arbitrary Python object.

Dictionaries are enclosed by curly braces ({ }) and values can be assigned and accessed using square braces ([]). For example −

	#!/usr/bin/python
	
	dict = {}
	dict['one'] = "This is one"
	dict[2]     = "This is two"
	
	tinydict = {'name': 'john','code':6734, 'dept': 'sales'}
	
	
	print dict['one']       # Prints value for 'one' key
	print dict[2]           # Prints value for 2 key
	print tinydict          # Prints complete dictionary
	print tinydict.keys()   # Prints all the keys
	print tinydict.values() # Prints all the values

**字典方法：**

字典 setdefault() 函数和get() 方法类似, 如果键不存在于字典中，将会添加键并将值设为默认值。

	setdefault()方法语法：
	dict.setdefault(key, default=None)
	参数
	key -- 查找的键值。
	default -- 键不存在时，设置的默认键值。
	返回值
	如果字典中包含有给定键，则返回该键对应的值，否则返回为该键设置的值。

	netcard = {}	# 二级字典
	
	def set_val(**args):
	    x={}		# 一级字典
	    ibdf={'bdf:': args['bdf']}
	    idriver={'driver:': args['driver']}
	
	    x.update(ibdf)
	    x.update(idriver)	
	    y={bdf: x}
	    netcard.update(y)
	
	def show_all():
	    for yu in netcard.keys():
	        for k,v in netcard[yu].items():
	            print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	        print "\n"
	
	
	set_val(driver=driver,bdf=bdf)
	
	show_all()

### 2.3 Data Type Conversion

Sometimes, you may need to perform conversions between the built-in types. To convert between types, you simply use the type name as a function.

There are several built-in functions to perform conversion from one data type to another. These functions return a new object representing the converted value.

**int(x [,base])**:Converts x to an integer. base specifies the base if x is a string. for example: int("a", 16)

**float(x)**:Converts x to a floating-point number.

**str(x)**:Converts object x to a string representation.

**repr(x)**:Converts object x to an expression string.

**dict(d)**:Creates a dictionary. d must be a sequence of (key,value) tuples.

**hex(x)**:Converts an integer to a hexadecimal string.

**oct(x)**:Converts an integer to an octal string.



## 10.参考资料
### 10.1 Eclipse 环境搭建 ##

http://lztang1964.blog.163.com/blog/static/187545985201302310814922/
http://www.huqiwen.com/2012/05/01/spring3-mvc-quick-start-1/

### 10.2 Python工程及学习书籍 ##
i
http://www.cnblogs.com/realh/archive/2010/10/04/1841907.html

### 10.3 Python 连ia ##
https://github.com/openstack/python-novaclient