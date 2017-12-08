# 基本语法 #

## python -m
	unap@honap:~/test/tosca/tran$ cat shell.py
	import sys
	
	def main(args=None):
	    if args is None:
	        args = sys.argv[1:]
	        print args
	
	
	if __name__ == '__main__':
	    main()
	
	
	unap@honap:~/test/tosca/tran$ PYTHONPATH=$PYTHONPATH:. python -m shell yui ert
	['yui', 'ert']

## python -c

	python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < openwrt-vnf.yaml

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

## 2. if
## 2.1 int compare

	def letterGrade(score):
	    if score >= 90:
	        letter = 'A'
	    elif score >= 80:
	        letter = 'B'
	    elif score >= 70:
	        letter = 'C'
	    elif score >= 60:
	        letter = 'D'
	    else:
	        letter = 'F'
	    return letter

## 2.2 string compare
	
    if(action == "get"):
	    resp = requests.get(url, verify=False)
	    content = resp.json()
	
	elif(action == "post"):
	    headers = {'Content-Type': 'application/json',}
	    resp = requests.post(url, headers=headers, data=json.JSONEncoder().encode(request.data), verify=False)
	    content = resp.json()
	
	elif (action == "delete"):
	    resp = requests.delete(url, verify=False)
	    content = resp.json()
            


## 3. Variable
### 3.1 Global Variable
	$ cat check_events_log.py

	jpgdata=''
	def openlogfile():
	    global jpgdata
	    with open(options.logfile, 'rb') as inf:
	        jpgdata = inf.read()
	
	openlogfile()
	print jpgdata

### 3.2 Variable Types
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
	print tinydict          # Prints complete dictionaryi
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

### 3.3 Data Type Conversion

Sometimes, you may need to perform conversions between the built-in types. To convert between types, you simply use the type name as a function.

There are several built-in functions to perform conversion from one data type to another. These functions return a new object representing the converted value.

**int(x [,base])**:Converts x to an integer. base specifies the base if x is a string. for example: int("a", 16)

**float(x)**:Converts x to a floating-point number.

**str(x)**:Converts object x to a string representation.

**repr(x)**:Converts object x to an expression string.

**dict(d)**:Creates a dictionary. d must be a sequence of (key,value) tuples.

**hex(x)**:Converts an integer to a hexadecimal string.

**oct(x)**:Converts an integer to an octal string.


## 4.class
### 4.1 private method

	$ cat test.py
	class Se:
	
	    def __in(self):
	        print "Bet you can't see me..."
	
	    def ac(self):
	        print "the secret message is:"
	        self.__in()
	
	s = Se()
	s.ac()
	s.__in()


	s.__in()
	AttributeError: Se instance has no attribute '__in'

### 4.2 static variable

	$ cat selftest.py
	class Mc:
	    members = 0
	    def init(self):
	        Mc.members += 1
	
	m1 = Mc()
	m1.init()
	print Mc.members
	
	m2 = Mc()
	m2.init()
	print Mc.members

### 4.3 self variable
	class Mc:
	    def init(self):
	        self.members = 1
	
	m1 = Mc()
	m1.init()
	print m1.members
	
	m2 = Mc()
	m2.init()
	print m2.members

### 4.4 inherit
	$ cat inherit.py
	#!/usr/bin/python
	# Filename: inherit.py
	
	class SchoolMember:
	    '''Represents any school member.'''
	    def __init__(self, name, age):
	        self.name = name
	        self.age = age
	        print '(Initialized SchoolMember:%s)' % self.name
	
	    def tell(self):
	        '''Tell my details.'''
	        print 'Name:"%s" Age:"%s"' % (self.name, self.age)
	
	class Teacher(SchoolMember):
	    '''Represents a teacher.'''
	    def __init__(self, name, age, salary):
	        SchoolMember.__init__(self, name, age)
	        self.salary = salary
	        print'(Initialized Teacher: %s)'% self.name
	
	    def tell(self):
	        SchoolMember.tell(self)
	        print'Salary: "%d"'% self.salary
		
	class Student(SchoolMember):
	    '''Represents a student.'''
	    def __init__(self, name, age, marks):
	        SchoolMember.__init__(self, name, age)
	        self.marks = marks
	        print'(Initialized Student: %s)'% self.name
	
	    def tell(self):
	        SchoolMember.tell(self)
	        print'Salary: "%d"'% self.marks
	
	t = Teacher('Mrs.shrividya', 40, 3000)
	s = Student('Swaroop', 22, 75)
	
	members = [t, s]
	for member in members:
	    member.tell()


## 10.参考资料
### 10.1 Eclipse 环境搭建 ##

http://lztang1964.blog.163.com/blog/static/187545985201302310814922/
http://www.huqiwen.com/2012/05/01/spring3-mvc-quick-start-1/

### 10.2 Python工程及学习书籍 ##

http://www.cnblogs.com/realh/archive/2010/10/04/1841907.html

### 10.3 Python 连ia ##
https://github.com/openstack/python-novaclient