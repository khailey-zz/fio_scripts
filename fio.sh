#!/bin/bash
# whether to execute commands, EVAL=0 would turn
# command execution off for debuggion
EVAL=1

#Optional parameters and default value
BINARY="/usr/bin/fio"
DD=dd
OUTPUT=`pwd`/output
TESTS="read write randread randwrite"
DIRECT=0
MULTIUSERS="001 002 004 008 016 032 064 128 256 512"
BSSIZES="0004 0008 0016 0032 0064 0128 0256 0512 1024 2048 4096"
SECS="60"
FILENAME="/dev/null"
MEGABYTES="1024"

usage()
{
cat << EOF
usage: $0  [options]

run a set of I/O benchmarks

OPTIONS:
   -h              Show this message
   -b  binary      name of fio binary, defaults to fio
   -f  filename    fio normally makes up a file name based on the job name, thread number, and file number.
   -m  megabytes   megabytes for the test I/O file to be used, default 1024 (ie 1G)
   -o  directory   output directory, where to put output files, defaults to ./output
   -t  tests       tests to run, defaults to "read write randread randwrite", options are
                      read  - block-size test ie : 4k,16k,64k,256k,1m,4m by 1 user
                      write - block-size test ie : 4k,16k,64k,256k,1m,4m by 1 user
                      randread - multi-user test ie : 8k randread by 1,4,16,64,256 users
                      randwrite - multi-user test ie : 8k randwrite by 1,4,16,64,256 users
   -s  seconds     seconds to run each test for, default 60
   -d  direct      If 1, use non-buffered I/O (usually O_DIRECT).  Default: 0.
       example
                  ./fio.sh -t "read randread" -f /dev/sda1 -m 1024 -d -o mytest
EOF
}

while getopts hyb:nf:o:t:s:dm: OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BINARY=$OPTARG
             ;;
         o)
             OUTPUT=$OPTARG
             ;;
         f)
             FILENAME=$OPTARG
             ;;
         s)
             SECS=$OPTARG
             ;;
         d)
             DIRECT=1
             ;;
         m)
             MEGABYTES=$OPTARG
             ;;
         t)
             TESTS=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done


mkdir $OUTPUT > /dev/null 2>&1
if [ ! -d $OUTPUT ]; then 
  echo "directory $OUTPUT does not exist"
  exit
fi

jobs=$TESTS
echo "configuration: "
echo "    binary=$BINARY"
echo "    output directory=$OUTPUT"
echo "    filename=$FILENAME"
echo "    megabytes=$MEGABYTES"
echo "    tests=$jobs"
echo "    direct=$DIRECT"
echo "    seconds=$SECS"

# following functions 
#    init
#    read
#    write
#    randread
#    randwrite
#    randrw
# create the fio job files
# init is always used to initialize the job file 
# with the default information
# then the other funtions are called to add in test
# specific lines

function init
{
for i in 1 ; do
cat << EOF
[global]
filename=$FILENAME
filesize=${MEGABYTES}m
direct=$DIRECT
runtime=$SECS
thread=1
group_reporting=1
ioengine=posixaio
iodepth=1
fadvise_hint=1
randrepeat=1
end_fsync=0
EOF
done > $JOBFILE
}

#sequential read
function read {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=read
bs=${READSIZE}k
numjobs=1
EOF
done >> $JOBFILE
}

#sequential write
function write {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=write
bs=${WRITESIZE}k
numjobs=1
EOF
done >> $JOBFILE
}

#random read
function randread {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=randread
bs=8k
numjobs=1
EOF
done >> $JOBFILE
}

#random write
function randwrite {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=randwrite
bs=8k
numjobs=1
EOF
done >> $JOBFILE
}

echo " "
echo " "
for job in $jobs; do # {
  # default values if thet don't get set otherwise
  USERS=1
  WRITESIZE=008
  READSIZE=008

  if [ $job ==  "randread" ] ; then
  # randread: 8k by 1,8,16,32,64 users
       for USERS in `eval echo $MULTIUSERS` ; do 
         #echo "j: $USERS"
         PREFIX="$OUTPUT/${job}_u${USERS}_kb0008"
         JOBFILE=${PREFIX}.job
         # init creates the shared job file potion
         init
         # for random read, offsets shouldn't be needed
         OFFSET=0
         loops=1
         NUSERS=`echo $USERS | sed -e 's/^00*//'`
         while [[ $loops -le $NUSERS ]] ; do
            JOBNUMBER=$loops
            eval $job
            loops=$(expr $loops + 1)
         done
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  elif [ $job ==  "randwrite" ] ; then
  # randwrite: 8k by 1,8,16,32,64 users
       for USERS in `eval echo $MULTIUSERS` ; do 
         #echo "j: $USERS"
         PREFIX="$OUTPUT/${job}_u${USERS}_kb0008"
         JOBFILE=${PREFIX}.job 
         # init creates the shared job file potion
         init
         # for random write, offsets shouldn't be needed
         OFFSET=0
         loops=1
         NUSERS=`echo $USERS | sed -e 's/^00*//'`
         while [[ $loops -le $NUSERS ]] ; do
            JOBNUMBER=$loops
            eval $job
            loops=$(expr $loops + 1)
         done
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  elif [ $job ==  "write" ] ; then
  # write: 8k,64k,512k,1m,4m by 1 user
       for WRITESIZE in `eval echo $BSSIZES` ; do 
         PREFIX="$OUTPUT/${job}_u01_kb${WRITESIZE}"
         JOBFILE=${PREFIX}.job
         init
         USERS=1
         eval $job
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  elif [ $job ==  "read" ] ; then
  # read: 8k,64k,512k,1m,4m by 1 user
       for READSIZE in `eval echo $BSSIZES` ; do 
         PREFIX="$OUTPUT/${job}_u01_kb${READSIZE}"
         JOBFILE=${PREFIX}.job
         init
         USERS=1
         eval $job
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  else 
    PREFIX="$OUTPUT/$job"
    JOBFILE=${PREFIX}.job
    init
    eval $job
    cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
    echo $cmd
    [[ $EVAL -eq 1 ]] && eval $cmd
  fi
done  # }

./fioparse.sh  $OUTPUT/*out  > $OUTPUT/fio_summary.out 
cat $OUTPUT/fio_summary.out

