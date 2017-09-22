# 常用命令
## 去除空行和注释行
	cat postgresql.conf | grep -v "^$" | grep -v "^#"


## 后台执行一个进程并获取PID
    
    SLEEP=$1
    /bin/bash -c "while true ; do continue ; done" & pid=$!
    sleep $SLEEP
    kill -9 $pid

## 向后/向前增加一条输出
    grep “hhb” -A/B 1

## 替代分割符号中某个符号

    echo "12:90,45:90" | tr , '.'
    用点替代其中的逗号

## 运行程序不要输出

     72 # run program and do not display the output
     73 function run_quiet()
     74 {
     75 	local cmd=$*
     76 	$cmd >/dev/null 2>&1
     77 	return $?
     78 }
     79
     80 # run program in background and echo the reture value to a temp file if finished
     81 function run_bg()
     82 {
     83 	local flag_file=$1
     84 	shift
     85 	local cmd=$*
     86 	run_quiet $cmd
     87 	echo $? > $flag_file
     88 }

## 免密脚本 ##
https://gist.github.com/reorx/4147128

### ssh 免密执行脚本 ###

    VMM_SSH_Time_Out() {
    	echo '' > /root/.ssh/known_hosts
    	local host=$1
    	local time_out=$2
    	shift;shift
    	local command=$@
    	echo $command
    	local exp_cmd=`cat << EOF
    	eval spawn ssh $host "$command"
    	set timeout $time_out
    	expect {
    		"*assword:" { send "123456\r"; exp_continue}
    		"*(yes/no)?" { send "yes\r"; exp_continue }
    		eof  { exit [ lindex [wait] 3 ] }
    	}
   		EOF`
    	expect -c "$exp_cmd"
    	# if ssh failed because of time out, it will return 255
    	return $?
    }

在linux下，expect自动交互语言，可以实现在shell脚本中为scp和ssh等自动输入密码自动登录。


### 免密交互模式 ###
    
     #!/usr/bin/expect
     # 设置超时时间为 60 秒
     set timeout  60
     # 设置要登录的主机 IP 地址
     set host hsw-ep1
     # 设置以什么名字的用户登录
     set name root
     # 设置用户名的登录密码
     set password 123456
    
     #spawn 一个 ssh 登录进程
     spawn  ssh $host -l $name
     # 等待响应，第一次登录往往会提示是否永久保存 RSA 到本机的 know hosts 列表中；等到回答后，在提示输出密码；之后
    就直接提示输入密码
     expect {
    "(yes/no)?" {
    send "yes\n"
    expect "assword:"
    send "$pasword\n"
    }
    "assword:" {
    send "$password\n"
    }
     }
     expect "#"
     # 下面测试是否登录到 $host
     send "uname\n"
     expect "Linux"
     send_user  "Now you can do some operation on this terminal\n"
     # 这里使用了 interact 命令，使执行完程序后，用户可以在 $host 终端进行交互操作。
     interact


