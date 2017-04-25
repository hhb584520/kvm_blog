# crontab #

## 1. 经典例子 ##

    /sbin/service crond restart
    crontab -e
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/tet/bin:/usr/local/sbin:/usr/local/bin
    HOME=/
    
    7 19 * * * lsmod > /root/lstx
    7 19 * * * /usr/tet/XVS/cadence/bin/run.sh -i
    20 19 * * * /usr/tet/XVS/cadence/bin/run.sh -r nightly/nightly_64


实例1：每1分钟执行一次myCommand

    * * * * * myCommand
    
实例2：每小时的第3和第15分钟执行

    3,15 * * * * myCommand

实例3：在上午8点到11点的第3和第15分钟执行

    3,15 8-11 * * * myCommand

实例4：每隔两天的上午8点到11点的第3和第15分钟执行

    3,15 8-11 */2  *  * myCommand

实例5：每周一上午8点到11点的第3和第15分钟执行

    3,15 8-11 * * 1 myCommand

实例6：每晚的21:30重启smb

    30 21 * * * /etc/init.d/smb restart

命令执行用全路径

实例7：每月1、10、22日的4 : 45重启smb

    45 4 1,10,22 * * /etc/init.d/smb restart

实例8：每周六、周日的1 : 10重启smb

    10 1 * * 6,0 /etc/init.d/smb restart

实例9：每天18 : 00至23 : 00之间每隔30分钟重启smb

    0,30 18-23 * * * /etc/init.d/smb restart

实例10：每星期六的晚上11 : 00 pm重启smb

    0 23 * * 6 /etc/init.d/smb restart

实例11：每一小时重启smb

    * */1 * * * /etc/init.d/smb restart

实例12：晚上11点到早上7点之间，每隔一小时重启smb

    * 23-7/1 * * * /etc/init.d/smb restart


可以在crontab文件中设置如下形式，忽略日志输出:

0 */3 * * * /usr/local/apache2/apachectl restart >/dev/null 2>&1

“/dev/null 2>&1”表示先将标准输出重定向到/dev/null，然后将标准错误重定向到标准输出，由于标准输出已经重定向到了/dev/null，因此标准错误也会重定向到/dev/null，这样日志输出问题就解决了。

## 2. 命令格式 ##

    `crontab [-u user] file crontab [-u user] [ -e | -l | -r ]`

## 3. 命令参数 ##

    -u user：用来设定某个用户的crontab服务；
    file：file是命令文件的名字,表示将file做为crontab的任务列表文件并载入crontab。
	     如果在命令行中没有指定这个文件，crontab命令将接受标准输入（键盘）上键入的命令，并将它们载入crontab。
    -e：编辑某个用户的crontab文件内容。如果不指定用户，则表示编辑当前用户的crontab文件。
    -l：显示某个用户的crontab文件内容，如果不指定用户，则表示显示当前用户的crontab文件内容。
    -r：从/var/spool/cron目录中删除某个用户的crontab文件，如果不指定用户，则默认删除当前用户的crontab文件。
    -i：在删除用户的crontab文件时给确认提示。

## 4. crontab的文件格式 ##
分 时 日 月 星期 要运行的命令

- 第1列分钟1～59
- 第2列小时1～23（0表示子夜）
- 第3列日1～31
- 第4列月1～12
- 第5列星期0～7（0和7表示星期天）
- 第6列要运行的命令

## 5. 常用方法 ##
创建一个新的crontab文件

向cron进程提交一个crontab文件之前，首先要设置环境变量EDITOR。cron进程根据它来确定使用哪个编辑器编辑crontab文件。99%的UNIX和LINUX用户都使用vi，如果你也是这样，那么你就编辑$HOME目录下的. profile文件，在其中加入这样一行:

EDITOR=vi; export EDITOR

然后保存并退出。不妨创建一个名为<user> cron的文件，其中<user>是用户名，例如， davecron。在该文件中加入如下的内容。

    # (put your own initials here)echo the date to the console every
    # 15minutes between 6pm and 6am
    0,15,30,45 18-06 * * * /bin/echo 'date' > /dev/console

保存并退出。注意前面5个域用空格分隔。

在上面的例子中，系统将每隔15分钟向控制台输出一次当前时间。如果系统崩溃或挂起，从最后所显示的时间就可以一眼看出系统是什么时间停止工作的。在有些系统中，用tty1来表示控制台，可以根据实际情况对上面的例子进行相应的修改。为了提交你刚刚创建的crontab文件，可以把这个新创建的文件作为cron命令的参数:

	$ crontab davecron

现在该文件已经提交给cron进程，它将每隔15分钟运行一次。同时，新创建文件的一个副本已经被放在/var/spool/cron目录中，文件名就是用户名(即dave)。

## 6. 常用命令 ##
- 使用-l参数列出crontab文件:

	$ crontab -l

- 编辑crontab文件  
如果希望添加、删除或编辑crontab文件中的条目，而EDITOR环境变量又设置为vi，那么就可以用vi来编辑crontab文件:

    $ crontab -e

- 重启服务
也可以编辑好一个文件，用以下命令执行，或重启 crontab 服务 reload or restart 

    $ crontab /etc/crontab

可以像使用vi编辑其他任何文件那样修改crontab文件并退出。如果修改了某些条目或添加了新的条目，那么在保存该文件时， cron会对其进行必要的完整性检查。如果其中的某个域出现了超出允许范围的值，它会提示你。 我们在编辑crontab文件时，没准会加入新的条目。
最好在crontab文件的每一个条目之上加入一条注释，这样就可以知道它的功能、运行时间，更为重要的是，知道这是哪位用户的定时作业。

- 删除crontab文件

    $crontab -r

## 7. 注意事项 ##
### 7.1 crontab 没有立即生效的原因
第一种是脚本执行了，但是报错：在crontab里调度运行，结果发现没有结果，查看/var/log/message 日志，发现crontab有执行，但是失败。
手动运行都是可以的，放在crontab里边发现就不能运行了。
处理方法：脚本中不要采用相对路径，全部改为绝对路径

第二种是编辑/var/spool/cron/user   user为执行用户名，一般为root
如更改后不起效果，请重新加载cron：
处理方法： /etc/init.d/cron reload 

第三种 用crontab -e  进行编辑
use the following command add entries to crontab should take effect right away.

如还不行就从其服务：
处理方法：/etc/init.d/crond restart   

### 7.2 新创建 cron job 没有马上执行 ## 

新创建的cron job，不会马上执行，至少要过2分钟才执行。如果重启cron则马上执行。

当crontab失效时，可以尝试/etc/init.d/crond restart解决问题。或者查看日志看某个job有没有执行/报错tail -f /var/log/cron。

千万别乱运行crontab -r。它从Crontab目录（/var/spool/cron）中删除用户的Crontab文件。删除了该用户的所有crontab都没了。

在crontab中%是有特殊含义的，表示换行的意思。如果要用的话必须进行转义%，如经常用的date ‘+%Y%m%d’在crontab里是不会执行的，应该换成date ‘+%Y%m%d’。

更新系统时间时区后需要重启cron,在ubuntu中服务名为cron:

### 7.3 注意环境变量问题 ###

有时我们创建了一个crontab，但是这个任务却无法自动执行，而手动执行这个任务却没有问题，这种情况一般是由于在crontab文件中没有配置环境变量引起的。

手动引入环境变量

0 * * * * . /etc/profile;/bin/sh /var/www/java/audit_no_count/bin/restart_audit.sh    
    
### 7.4 ubuntu下启动、停止与重启cron ###

$sudo /etc/init.d/cron start
$sudo /etc/init.d/cron stop
$sudo /etc/init.d/cron restart