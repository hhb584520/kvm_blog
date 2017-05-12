
# 1. create core dump file #

Check the ouput of ulimit -c, if it output 0, this is why you don't have core dumped.

Use

ulimit -c unlimited

to allow core creation (maybe replace unlimited by a real size limit to be more secure) .

Activate your coredumps by:

ulimit -c unlimited
Also check:

$ sysctl kernel.core_pattern
to see where your dumps are created (%e will be the process name, and %t will be the system time).

You can change it in /etc/sysctl.conf and then reload by sysctl -p.

You can test it by:

sleep 10 &
killall -SIGSEGV sleep
If core dumping is successful, you will see “(core dumped)” after the segmentation fault indication.

See also:

http://stackoverflow.com/questions/77005/how-to-generate-a-stacktrace-when-my-gcc-c-app-crashes