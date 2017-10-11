http://www.bioinfo.org.cn/~casp/temp/spring.lecture/Matplotlib_slides.pdf

https://stackoverflow.com/questions/9215658/plot-a-circle-with-pyplot

## install lib ##

	pip install numpy
	pip install matplotlib

## examples ##

	01 import numpy as np
	02 import matplotlib.pyplot as plt
	03 
	04 a = [2,2]
	05 b = [3,1]
	06 
	07 c = [1,3]
	08 d = [2,2]
	09 
	10 e = [2,1]
	11 f = [1,0]
	12 
	13 g = [2,3]
	14 h = [1,0]
	15 
	16 
	17 ax = plt.gca()
	18 ax.cla()
	19 ax.set_xlim(0,10)
	20 ax.set_ylim(0,10)
	21 
	22 circle1=plt.Circle((2,3.5),0.5,color='g')
	23 ax.add_artist(circle1)
	24 
	25 line2 = plt.plot(a, b, color='r')
	26 line3 = plt.plot(c, d)
	27 line4 = plt.plot(e, f)
	28 line5 = plt.plot(g, h)
	29 
	30 plt.title("plot")
	31 plt.show()
	
