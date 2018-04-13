#!/bin/bash
# whether to execute commands, EVAL=0 would turn
# command execution off for debuggion
EVAL=1

#Optional parameters and default value
BINARY="./fio"
DD=dd
OUTPUT=`pwd`/output
TESTNAME="Unknown"
TESTS="read write randread randwrite"
DIRECT=0
#for random read/write
MULTIUSERS="001 002 004 008 016 032 064"

IOENGINE="linuxaio"
BSSIZES="0128 0256 0512 1024 2048 4096"
SECS="60"
FILENAME="./tmpfile"
MEGABYTES="1024"

usage()
{
cat << EOF
usage: $0  [options]

run a set of I/O benchmarks

OPTIONS:
   -h              show this message
   -d              use non-buffered I/O (usually O_DIRECT).
   -b  binary      name of fio binary, defaults to ./fio, only support version 2.0.7
   -n  testname    testname, such as device or file system type, default: Unknown
   -f  filename    testfile, such as a block device or a regular file, defaults to ./tmpfile
   -m  megabytes   megabytes for the test I/O file to be used, default 1024 (ie 1G)
   -o  directory   output directory name, where to put output files, defaults to ./output
   -t  tests       tests to run, defaults to "read write randread randwrite", options are
                      read - block-size test ie : 4k,16k,64k,256k,1m,4m by 1 user
                      write - block-size test ie : 4k,16k,64k,256k,1m,4m by 1 user
                      randread - multi-user test ie : 4k randread by 1,2,4,8 users
                      randwrite - multi-user test ie : 4k randwrite by by 1,2,4,8 users
   -s  seconds     seconds to run each test for, default 60
       example
                  ./fio.sh -t "read randread" -f /dev/sda1 -m 1024 -d -o mytest
EOF
}

while getopts hn:yb:f:o:t:s:dm: OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         n)
             TESTNAME=$OPTARG
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

#prepare
which ${BINARY} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "${BINARY} command does not exist"
    exit 
fi
${BINARY} -v | grep "2.0.7"
if [ $? -ne 0 ]
then
    echo "Only supports version 2.0.7 of fio"
    exit
fi
which Rscript > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Rscript command does not exist"
    exit
fi
touch $FILENAME
truncate -s ${MEGABYTES}m $FILENAME  > /dev/null 2>&1

RPLOTS="$OUTPUT/RPLOTS/"
CSV="$OUTPUT/CSV/"
mkdir -p $RPLOTS $CSV
if [ ! -d $OUTPUT ]; then 
    echo "directory $OUTPUT does not exist"
    exit
fi

jobs=$TESTS
echo "configuration: "
echo "    binary=$BINARY"
echo "    testname=$TESTNAME"
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
ioengine=$IOENGINE
end_fsync=1
EOF
done > $JOBFILE
}

#sequential read
function read {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
name=$TESTNAME
rw=read
iodepth=4
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
name=$TESTNAME
rw=write
iodepth=4
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
name=$TESTNAME
rw=randread
iodepth=$USERS
bs=4k
numjobs=1
EOF
done >> $JOBFILE
}

#random write
function randwrite {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
name=$TESTNAME
rw=randwrite
iodepth=$USERS
bs=4k
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
  # randread: 4k by 1,2,4,8 users
       for USERS in `eval echo $MULTIUSERS` ; do
         PREFIX="$OUTPUT/${job}_u${USERS}_kb0004"
         JOBFILE=${PREFIX}.job
         # init creates the shared job file potion
         init
         # for random read, offsets shouldn't be needed
         OFFSET=0
         if [ $IOENGINE == "sync" -o $IOENGINE == "psync" ] ; then
             loops=1
             NUSERS=`echo $USERS | sed -e 's/^00*//'`
             while [[ $loops -le $NUSERS ]] ; do
                JOBNUMBER=$loops
                eval $job
                loops=$(expr $loops + 1)
             done
         else #aio
            eval $job
         fi
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  elif [ $job == "randwrite" ] ; then
  # randwrite: 4k by 1,2,4,8 users
       for USERS in `eval echo $MULTIUSERS` ; do
         #echo "j: $USERS"
         PREFIX="$OUTPUT/${job}_u${USERS}_kb0004"
         JOBFILE=${PREFIX}.job 
         # init creates the shared job file potion
         init
         # for random write, offsets shouldn't be needed
         OFFSET=0
         if [ $IOENGINE == "sync" -o $IOENGINE == "psync" ] ; then
            loops=1
            NUSERS=`echo $USERS | sed -e 's/^00*//'`
            while [[ $loops -le $NUSERS ]] ; do
                JOBNUMBER=$loops
                eval $job
                loops=$(expr $loops + 1)
            done
         else #aio
            eval $job
         fi
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  elif [ $job == "write" ] ; then
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
  elif [ $job == "read" ] ; then
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

./fioparse.sh -f rplots -d $OUTPUT $OUTPUT/*.out  > $RPLOTS/${TESTNAME}.r
./fioparse.sh -f csv $OUTPUT/*.out  > $CSV/${TESTNAME}.csv
cat $CSV/${TESTNAME}.csv
#Generate visual IO performance pictures
for job in $jobs; do
    Rscript `pwd`/fiop.r $RPLOTS/${TESTNAME}.r $job
done
