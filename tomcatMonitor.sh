#!/bin/bash

# tomcat启动命令脚本
tomcatStsartCmd=/usr/apache-tomcat-9.0.41/bin/startup.sh

# 日志
tomcatDeamonLog=$(pwd)/tomcatDeamon.log 

# jmap标记，保证在cpu使用率大于90%时仅记录一次dump文件
jmapFlag=1

# 守护tomcat进程
tomcatProcessDeamon(){
    while [true]
    do 
        tomcatPid=$(ps -ef | grep tomcat | grep -w 'apache-tomcat-9.0.41' | grep -v 'grep' | awk 'NR==1{print $2}')
        # 若tomcat进程存在，监视tomcat进程，否则启动tomcat进程
        if [$tomcatPid]
        then 
            #  echo "[info] $(date +'%F %H:%M:%S') the tomcat pid is $tomcatPid"
            # 若tomcat的cpu使用率大于90%，则打印日志
            cpuPer=$(top -n 1 | grep $tomcatPid | awk 'NR==1{print $3}');
            y_or_n=`echo $cpuPer 90 | awk '{if($1 > 90) print 1; else print 0;}'`
            if [ $y_or_n -eq 1]
            then 
                # 记录cpu使用情况
                echo "[warn] $(date +'%F %H:%M:%S') cpu use $cpuPer"

                # 记录jvm gc信息
                echo "[warn] $(date +'%F %H:%M:%S') the jvm gc info is:"
                jstat -gc $tomcatPid

                # 记录jvm堆栈信息
                echo "[warn] $(date +'%F %H:%M:%S') the jvm stack info is: "
                jstack -l $tomcatPid

                echo "\n---------------------------------------------------------\n\n"

                # 在cpu使用率大于90%时仅记录一次dump信息
                if [ $jmapFlag -eq 1 ] 
                then 
                    dumpFile="$(pwd)/$(date +'%Y%m%d_%H%M%S').bin"
                    jmap -dump:format=b,file=$dumpFile $tomcatPid
                    
                    # 设置jmap记录标记为false，保证本次不再记录dump信息
                    jmapFlag=0
                fi
                       else
                # 设置jmap记录标记为true
                jmapFlag=1
            fi
        else
            echo "[warn] $(date +'%F %H:%M:%S') the tomcat process is not exit, prepare to start tomcat..."
            $tomcatStartCmd
            echo "\n---------------------------------------------------------\n\n"
        fi
        # 休眠线程5s
        sleep 5s
    done
}

tomcatProcessDeamon >> $tomcatDeamonLog