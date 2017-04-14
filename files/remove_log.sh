#!/bin/bash

# --- WARNNING: This script's configure.
#This configure must copy to the /etc/crontab MANUAL to execute this script automatically.
#machine's name.
machine_name=`uname -n`
#log address.(/share/xvs/results).
log_folder_addr="/share/xvs/results"
#log's root address.(/)
root_addr="/"
#up_line percentage.
#the up_line percentage storage space can used(60%).
up_line_per=60
#min log number.
min_log_num=30

mail_receiver="haibin.huang@intel.com"
mail_CC="haibin.huang@intel.com"
#mail content file.
#They will be removed after executed so just make sure that these files does NOT exist at first.
mail_file_temp="/root/jenkins/mail_file"
mail_file_final="/root/jenkins/mail_file1"

#this function is for the situation that log number is less than(equal) 30.
function log_num_too_small()
{
#There once existed a bug here. mail_subject cannot be in the form of variable. 
#   local mail_subject="WARNNING: $machine_name's log number is too small"
    echo "WARNNING: $machine_name's storage space has been used too much(>60%)" >> $mail_file_final
    echo "                           but the log cannot be remove because it's number is too small(=30)" >> $mail_file_final
#for the e-mail form.
    echo -e "\n" >> $mail_file_final

    local remove_log_num=`cat $mail_file_temp | wc -l`
    echo "Number of removed logs before this message this time: ${remove_log_num}. Here are the moved logs:" >> $mail_file_final
    cat $mail_file_temp >> $mail_file_final

    mail -s "WARNNING: $machine_name's log number is too small" -c $mail_CC $mail_receiver < $mail_file_final
    
    rm -rf $mail_file_temp
    rm -rf $mail_file_final
    exit 0

}

#this function is for the situation that log number is normal.
function mail_log_num_normal()
{
#   local mail_subject="$machine_name: some log has been removed due to the storage space"
    local remove_log_num=`cat $mail_file_temp | wc -l`
    echo "Number of removed logs before this message this time: ${remove_log_num}. Here are the moved logs:" >> $mail_file_final
    cat $mail_file_temp >> $mail_file_final

    mail -s "$machine_name: some log has been removed due to the storage space" -c $mail_CC $mail_receiver < $mail_file_final

    rm -rf $mail_file_temp
    rm -rf $mail_file_final
    exit 0

}

#main functon.
function remove_log()
{
	#recreate mail file.
    rm -rf $mail_file_temp
    touch $mail_file_temp
    rm -rf $mail_file_final
    touch $mail_file_final

	#flag of whether mail need to send.
	#0: there is no change in "results" folder. Mail do not need to send.
	#1: some logs have been removed.
    local mail_change_flag=0

	#storage space been used in "/".
    local real_per_ptr=`df -hl | eval grep ' ${root_addr}$' | awk '{print $5}'`
    local real_per=`echo ${real_per_ptr%%%} | bc`

	#loop to remove the log if storage been used larger than(equal) up_line.
    while [ $real_per -ge $up_line_per ]
    do 
        mail_change_flag=1
		#calculate the log num
		local log_num=`ls -ltr $log_folder_addr | grep '^d' | awk '{print $9}' | grep '^s20' | wc -l | bc` 

		#if log's number is less than(equal) min_number, execute the "log_num_too_small" function.
		#it will exit in this function.
        if [ $log_num -le $min_log_num ];then
            log_num_too_small
        fi

		#sort the log by time(ls -ltr) and choose the oldest one(first one).
        local oldest_log_name=`ls -ltr $log_folder_addr | grep '^d' | awk '{print $9}' | grep '^s20' | sed -n '1p'`
        local oldest_log_addr=${log_folder_addr}/${oldest_log_name}
        
		#record the log name(for e-mail content) and remove it.
        echo $oldest_log_name >> $mail_file_temp
        rm -rf $oldest_log_addr

		#recalculate the storage space been used.
        real_per_ptr=`df -hl | eval grep ' ${root_addr}$' | awk '{print $5}'`
        real_per=`echo ${real_per_ptr%%%} | bc`      
    done

#mail it if necessary
    if [ $mail_change_flag -eq 1 ];then
        mail_log_num_normal
    fi
}

remove_log