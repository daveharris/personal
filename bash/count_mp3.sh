#!/bin/bash
ARGS=1

if [ $# -ne "$ARGS" ]; then
  echo "Which directory would you like to count?"
  read x
  else
    dir="$1"
fi 

set count = 0
ls -1 "$dir"| grep .mp3 | while read line; 
                 do let count+=1;
                 echo $line;
                 echo $count; 
               done
echo $count files found
