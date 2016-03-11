all="1 2 4 8 16 32 64 128 256 512 1024"
for i in $all; 
do
	echo $i;
	sh fio.sh -r /dev/dm-2 -s 60 -l $i -f -u 32
done
sh fioparse.sh *.out > out
python new_xls.py
