#!/bin/bash
seint=eth2 #interface
pings=5	#time
delay_cha=20 #延迟差，ms
lost_cha=20 #丢包率差，%

pingt(){

	#默认出口
	echo -
	ping -4 -q -c $pings -W 1 -A $1 > /tmp/ping_tmp
	lost_or=`cat /tmp/ping_tmp | sed -n '4p' | awk '{print $7}'| awk -F % '{print $1}' `
	delay_or=`cat /tmp/ping_tmp | sed -n '$p' | awk -F / '{print $4}' | awk -F . '{print $1}' `

	printf "%-4s" $lost_or
	[ -z $delay_or ] && delay_or=10000
	printf "%-4s"  $delay_or	
	
	
	echo --
	
	#第二网关出口
	ping -I $seint -4 -q -c $pings -W 1 -A $1 > /tmp/ping_tmp
	lost=`cat /tmp/ping_tmp | sed -n '4p' | awk '{print $7}'| awk -F % '{print $1}' `
	delay=`cat /tmp/ping_tmp | sed -n '$p' | awk -F / '{print $4}' | awk -F . '{print $1}' `

	printf "%-4s" $lost
	[ -z $delay ] && delay=10000
	printf "%-4s"  $delay	
	
	echo ---
	
	#计算差值，以准备与全局参数比较
	l=(`expr $lost_or - $lost`)
	printf "%-4s" $l
	d=(`expr $delay_or - $delay`)
	printf "%-4s" $d
	#如果丢包率大则不优，因此主路由丢包率小则不处理，
	#如果主丢包率>次丢包率：次优，写路由
	#如果主丢包率=次丢包率：比较延迟：
	#							主延迟200-次延迟100>差值100>50：次优，写路由
	#							主延迟100-次延迟200<=差值-100<50：主优，无操作
	echo ----
	
	if [ $lost_or -gt $lost ];then #源丢包率大于次丢包率>0，且不可能相等
	
	#echo or_big #次优
	
			if [ $d -gt -100 ];then #延迟差是否超过20，否则不处理
			printf "\033[31m%-4s\033[0m" S 
			
			else
			printf "%-4s" M
			fi
	
	
	elif [ $lost_or -eq $lost ];then #如果相对，还是看延迟：
	#echo look_delay	
		if [ $d -gt 20 ];then #延迟差是否超过20，否则不处理
			printf "\033[31m%-4s\033[0m" S 
			else
			printf "%-4s" M
		fi
	else	 #不相等，且次丢包率大，则不处理
	
	#echo se_big #不做处理
	printf "%-4s" M
	fi
	
	
}

#echo `pingt passmind.tk`
printf "%4s %4s %4s %4s %4s %4s %4s %4s\n" `pingt 182.254.21.82`


#route add -host 8.8.8.8 gw 192.168.1.1
#route del -host 8.8.8.8

