#!/bin/bash
read -p "Enter Day: " day
read -p "Enter starttime ,stoptime, cronstart, cronstop in the given sequence" starttime stoptime cronstart cronstop
string="{\"$day\":[{"\"start\"":\"$starttime\"}, {"\"stop\"":\"$stoptime\"}, {"\"cronstart\"":\"$cronstart\"},{"\"cronstop\"":\"$cronstop\"}],"
for i in {1..6}
do
read -p "Enter Day: " day
read -p "Enter starttime ,stoptime, cronstart, cronstop in the given sequence" starttime stoptime cronstart cronstop
string+="\"$day\":[{"\"start\"":\"$starttime\"}, {"\"stop\"":\"$stoptime\"}, {"\"cronstart\"":\"$cronstart\"},{"\"cronstop\"":\"$cronstop\"}],"
done
string+="}"

#storing input in json format
echo $string | sed 's/,\(.\)$/\1/' > weekly.json
