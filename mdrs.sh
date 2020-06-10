#!/bin/bash
#Minium Dealy Routes Selector
seint=eth2 #interface 第二网关接口，ifconfig
sgw=192.168.1.1 #second GW ip，第二网关地址
pings=5	#times,测试ping次数
delay_cha=20 #延迟差，ms
lost_cha=20 #丢包率差，%

sleep_time=1 #循环刷新时间s
show_lines=14 #显示详细的后几行，全部连接请cat /tmp/sum.log
power_saving_mode=1 #凌晨1-7点是否进行低刷新率模式
show_act_links=0	#是否显示当前活动连接

pingt(){	#先声明函数再使用

	#默认出口
	ping -4 -q -c $pings -W 1 -A $1 > /tmp/ping_tmp
	lost_or=`cat /tmp/ping_tmp | sed -n '4p' | awk '{print $7}'| awk -F % '{print $1}' `
	delay_or=`cat /tmp/ping_tmp | sed -n '$p' | awk -F / '{print $4}' | awk -F . '{print $1}' `

	printf "%-4s" $lost_or
	[ -z $delay_or ] && delay_or=999
	printf "%-4s"  $delay_or	
	
	
	
	#第二网关出口
	ping -I $seint -4 -q -c $pings -W 1 -A $1 > /tmp/ping_tmp
	lost=`cat /tmp/ping_tmp | sed -n '4p' | awk '{print $7}'| awk -F % '{print $1}' `
	delay=`cat /tmp/ping_tmp | sed -n '$p' | awk -F / '{print $4}' | awk -F . '{print $1}' `

	printf "%-4s" $lost
	[ -z $delay ] && delay=999
	printf "%-4s"  $delay	
	
	#计算差值，以准备与全局参数比较
	l=(`expr $lost_or - $lost`)
	printf "%-5s" $l
	d=(`expr $delay_or - $delay`)
	printf "%-5s" $d
	#如果丢包率大则不优，因此主路由丢包率小则不处理，
	#如果主丢包率>次丢包率：次优，写路由
	#如果主丢包率=次丢包率：比较延迟：
	#							主延迟200-次延迟100>差值100>50：次优，写路由
	#							主延迟100-次延迟200<=差值-100<50：主优，无操作
								
	
	if [ $lost_or -gt $lost ];then #源丢包率大于次丢包率>0，且不可能相等
	
	#echo or_big #次优
	
			if [ $d -gt -100 ];then #延迟差是否超过20，否则不处理
				printf "\e[31mS\e[0m"
				route add -host $1 gw $sgw
			else
				printf "%-4s" M
			fi
	
	
	elif [ $lost_or -eq $lost ];then #如果相对，还是看延迟：
	#echo look_delay	
		if [ $d -gt 20 ];then #延迟差是否超过20，否则不处理
			printf "\e[31mS\e[0m"
			route add -host $1 gw $sgw
		else
			printf "%-4s" M
		fi
	else	 #不相等，且次丢包率大，则不处理
	
	#echo se_big #不做处理
	printf "%-4s" M
	fi
	
	
}


#clear
#创建空文件
if [ ! -f "/tmp/sum.log" ]; then
	:>/tmp/sum.log
fi

while true
do
	sd=(`netstat -ntu | grep -e tcp -e udp | grep -v :: | awk '{print $5}' | awk -F : '{print $1}' | sort | uniq -c | awk '{print $2}'`)
	#原始数据#()表示是一个数组
	#echo --------Active Links---Total：${#b[@]}-----
		#开始逐条搜索去除私网地址
		for i in ${!sd[*]} 
		do
			qz=(${sd[$i]})	
			#去除私网地址	# == 等于号旁边需要空格
			if [ ${qz:0:3} == "10."  -o ${qz:0:3} == "127"  -o ${qz:0:7} == "192.168" \
															-o ${qz:0:7} == "172.16." \
															-o ${qz:0:7} == "172.17." \
															-o ${qz:0:7} == "172.18." \
															-o ${qz:0:7} == "172.19." \
															-o ${qz:0:7} == "172.20." \
															-o ${qz:0:7} == "172.21." \
															-o ${qz:0:7} == "172.22." \
															-o ${qz:0:7} == "172.23." \
															-o ${qz:0:7} == "172.24." \
															-o ${qz:0:7} == "172.25." \
															-o ${qz:0:7} == "172.26." \
															-o ${qz:0:7} == "172.27." \
															-o ${qz:0:7} == "172.28." \
															-o ${qz:0:7} == "172.29." \
															-o ${qz:0:7} == "172.30." \
															-o ${qz:0:7} == "172.31." ]
			then
				#符合匹配条件则删除数组记录:
				unset sd[$i]
			fi			
			#echo ${b[$i]}			
		done
		
		
		
		
			#qzd=(`echo ${b[*]}`)		#去私网后数组复制 数组赋值使用括号（） 赋值=不能有空格
			qzd=(${sd[*]})
			echo -e "-- MDRS V1.0-by HIJE - Now \e[36m`date +%Y年%m月%d日%H时%M分%S秒`\e[0m in Active Links：${#qzd[*]} --"
			[ $show_act_links -eq 1 ] && echo Showing Active Links:
			:>/tmp/new.log	#创建空文件
			for i in ${qzd[*]} 
			do
				#
				[ $show_act_links -eq 1 ] && echo $i
				echo $i >> /tmp/new.log	#记录新连接到文件
			done
			

			#echo ------new-----
			#${qzd[*]}
			#差集赋值，获取与记录不重复的连接
			
			:>/tmp/dif.log
			cat /tmp/sum.log | awk '{print $1}' >/tmp/sum_t.log
			sort /tmp/new.log /tmp/sum_t.log /tmp/sum_t.log | uniq -u >/tmp/dif.log
			#新连接中没有记录的进行ping测试：
			c=(`cat /tmp/dif.log`)
			if [ ${#c[*]} -gt 0 ] ;then
				echo -e "\e[33;31mWorking...\e[0mand Testing ${#c[*]} new records:\n"
				for i in ${c[*]} 
				do
					#echo -e $i "\t\t"ok >> /tmp/sum.log
					#echo Working in progress
					#进行pingt函数后打印详情增加记录到sum记录。
					printf "%-15s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%10s\n" $i `pingt $i` `date +%m%d%H%M%S` >> /tmp/sum.log
					tail -n 1 /tmp/sum.log
				done
			
			else
			echo -e "\e[33;32mIdle......\e[0mand Showing the tail of the records:"
			fi
			
			
			
			#打印标题栏

			#cat /tmp/dif.log >> /tmp/sum.log			
			echo -e ".\n.."
			tail -n $show_lines /tmp/sum.log
			printf "\e[33;32m%-15s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%10s\e[0m\n" Links M_lost M_delay S_lost S_delay Lost- Delay- Sign AddTime
			#			Links   M_lost M_delay S_lost S_delay Lost- Delay- Sign AddTime
			echo -e "\nSign: M = Main GW is better, \e[31mS\e[0m = Second GW is better and written to system route table.\nUse 'cat /tmp/sum.log' to see the detail. Use 'route' to see the written routes."
			total_link=(`cat /tmp/sum.log | awk '{print $1}'`) 	# |wc -l`
			total_S=(`cat /tmp/sum.log | grep S | awk '{print $1}'`)
			rate=`echo "scale=4; ${#total_S[*]} / ${#total_link[*]} *100" | bc`
			echo Total：${#total_link[*]} Links Recorded. S Sign counts: ${#total_S[*]} . Rate: ${rate:0:5}"%"
			
			time=$(date "+%H")
			#echo $time	凌晨1-7点进行低刷新率模式
			if [ $time -le 7 -a $time -ge 1 -a $power_saving_mode -eq 1 ];then
				sleep 5
			else
				sleep $sleep_time
			fi
	clear
done
