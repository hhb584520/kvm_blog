If you want to read the whole file into a variable:

	#!/bin/bash
	value=`cat sources.xml`
	echo $value

If you want to read it line-by-line:

	while read line; do    
	    echo $line    
	done < file.txt