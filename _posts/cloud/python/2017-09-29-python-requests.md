https://liam0205.me/2016/02/27/The-requests-library-in-Python/

http://cuiqingcai.com/2556.html

http://docs.python-requests.org/en/master/user/advanced/#session-objects

	import requests
	 
	r = requests.get('https://kyfw.12306.cn/otn/', verify=True)
	print r.text

