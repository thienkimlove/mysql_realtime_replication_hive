#!/bin/bash
hcp=$(hadoop classpath)
#echo $hcp
arr=(${hcp//:/ })
len=${#arr[@]}
let len-=1
echo $len
j=0
export CLASSPATH=/usr/local/hadoop/etc/hadoop
for i in ${arr[@]}
do
  #    echo $i
   if [ $j -eq 0 ]; then
       export CLASSPATH=$i
   elif [ $j -eq $len ]; then
       echo $i
   else
        export CLASSPATH=$CLASSPATH:$i
   fi
   let j+=1
done
