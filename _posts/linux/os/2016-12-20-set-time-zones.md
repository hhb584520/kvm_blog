# 时区

    1. 查看当前时区

            date -R

    2. 修改设置时区

       方法(1)

            tzselect

       方法(2) 仅限于RedHat Linux 和 CentOS

            timeconfig

       方法(3) 适用于Debian

            dpkg-reconfigure tzdata

     3. 复制相应的时区文件，替换系统时区文件；或者创建链接文件

            cp /usr/share/zoneinfo/$主时区/$次时区 /etc/localtime

         在中国可以使用：

            cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

 
# 时间

      1、查看时间和日期
              date
      2、设置时间和日期

           将系统日期设定成1996年6月10日的命令
              date -s 06/22/96

           将系统时间设定成下午1点52分0秒的命令

              date -s 13:52:00 
      3. 将当前时间和日期写入BIOS，避免重启后失效

              hwclock -w

 

 

# 备注：

      更详细的命令说明请参加man