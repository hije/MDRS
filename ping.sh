
#!/bin/bash
#Minium Dealy Routes Selector - Restore routes

echo Ready to restore the route to default!
sleep 3
	sd=(`cat /tmp/sum.log | grep S | awk '{print $1}'`)
	#sd={`route | grep $sgw | grep 255.255.255.255`}
		for i in ${sd[*]} 
		do
			echo $i
			route del -host $i
		done
echo Showing the system route:----------------
route
echo "Please check it out,it's clear!---------"
echo Ready to delete the programe data file : /tmp/sum.log
echo You can Ctrl+C to break it. Or do nothing to keep it.
sleep 8
rm /tmp/sum.log
echo Done! see you.
