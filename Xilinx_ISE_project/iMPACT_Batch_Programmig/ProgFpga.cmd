setMode -bscan
setCable -p auto
addDevice -p 1 -file "../main.bit"
program -p 1
quit