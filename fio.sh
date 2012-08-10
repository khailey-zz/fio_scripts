#!/bin/bash  

#
#  DIRECT I/O :
#
#  direct is set to 0 if it's detected that fio.sh is running on Delphix
#  environment variable FDIO=1
#  will direct=1 ven when trunning on Delphix O/S
#  direct=1 doesn't seem to work on opensolaris even
#  when opensolaris is the NFS client
#

RECORDSIZE=128k
RECORDSIZE=8k

PRIMARYCACHE=metadata
SECONDARYCACHE=metadata

COMPRESSION=on
COMPRESSION=off

SEEDFILE=fio_random.dat 

DIRECT=1
BINARY="./fio"
DIRECTORY="/domain0/fiotest"
OUTPUT="."
TESTS="all"
SECS="60"
MEGABYTES="8192"
FORCE="n"
CREATE=0
EVAL=1
CUSTOMUSERS=-1
CUSTOMBLOCKSIZE=-1
FILE=fiodata
FILENAME="filename=$FILE"
RAW=0

DTRACE1=""
DTRACE2=""

MULTIUSERS="01 08 16 32 64"
READSIZES="0008 0032 0128"
SEQREADSIZES="0128 1024"
SEQREADSIZES="1024"

WRITESIZES="0001 0004 0008 0016 0032 0064 0128"
MULTIWRITEUSERS="01 02 04 08 16"
WRITESIZES="0001 0008 0128"
MULTIWRITEUSERS="01 04 16"

usage()
{
cat << EOF
usage: $0  [options]

run a set of I/O benchmarks

OPTIONS:
   -h              Show this message
   -b  binary      name of fio binary, defaults to ./fio
   -d  directory   work directory where fio creates a fio and reads and writes, default /domain0/fiotest
   -o  directory   results directory, where to put output files, defaults to ./
   -t  tests       tests to run, defaults to all, options are
                      readrand - IOPS test : 8k by 1,8,16,32 users 
                      read  - MB/s test : 1M by 1,8,16,32 users & 8k,32k,128k,1m by 1 user
                      write - redo test, ie sync seq writes : 1k, 4k, 8k, 128k, 1024k by 1 user 
                      randrw   - workload test: 8k read write by 1,8,16,32 users 
   -s  seconds     seconds to run each test for, default 60
   -m  megabytes   megabytes for the test I/O file to be used, default 8192 (ie 8G)
   -i              individual file per process, default size 100m (otherwise uses the -m size)
   -f              force run, ie don't ask for confirmation on options
   -c              force creation of work file otherwise if it exists we use it as is
   -r raw_device   use named raw device instead of file
   -u #users       force test to only use this many users
   -l blocksize    force test to only use this blocksize in KB, ie 1-1024 
   -e recordsize   use this recordsize if/when creating the zfs file system, default 8K

       example
                  fio.sh ./fio.opensolaris /domain0/fiotest  -t rand_read -s 10 -m 1000 -f
EOF
}

while getopts hb:r:e:d:o:it:s:l:u:m:f OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BINARY=$OPTARG
             ;;
         d)
             DIRECTORY=$OPTARG
             ;;
         o)
             OUTPUT=$OPTARG
             ;;
         e)
             RECORDSIZE="${OPTARG}k"
             ;;
         r)
             FILENAME="filename=$OPTARG"
             RAWNAME="$OPTARG"
             DIRECTORY="/"
             RAW=1
             ;;
         i)
             FILENAME=""
             ;;
         u)
             CUSTOMUSERS=$OPTARG
             ;;
         l)
             CUSTOMBLOCKSIZE=$OPTARG
             ;;
         s)
             SECS=$OPTARG
             ;;
         m)
             MEGABYTES=$OPTARG
             echo "MEGABYTES=$MEGABYTES"
             MB=1
             ;;
         f)
             FORCE=1
             ;;
         c)
             CREATE=1
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



dtrace_begin()
{
cat << EOF
#pragma D option quiet
#pragma D option defaultargs

dtrace:::BEGIN
{
    lun["foo"]=1;
EOF
}

dtrace_luns()
{
# output in for is of the form "c4t1d0"
for i in `zpool status $DOMAIN | grep ONLINE | grep -v state | grep -v pool | grep -v $DOMAIN | grep -v log | awk '{print $1}'`; do
 # append 's0'
 # :wd refers to whole disk, take it of, replace with partition
 #j=`readlink -f /dev/dsk/${i} | sed -e 's/:wd/:a/'`
 j=`readlink -f /dev/dsk/${i} | sed -e 's/:.*//'`
 lun=`echo $j | sed -e 's/$/:a'/`
 echo "lun[\"$lun\"] = 1;"
 lun=`echo $j | sed -e 's/$/:wd'/`
 echo "lun[\"$lun\"] = 1;"
 lun=`echo $j | sed -e 's/$/:q'/`
 echo "lun[\"$lun\"] = 1;"
done
}

dtrace_luns_raw()
{
 #j=`readlink -f $RAWNAME`
 #  output will have ",raw" at the end, but DTrace matching is without the ",raw"
 for rawdev in `echo $RAWNAME | sed -e 's/:/ /'`; do 
   j=`readlink -f $rawdev |  sed -e 's/,raw/'/`
   echo "lun[\"$j\"] = 1;"
 done
}

dtrace_end()
{
cat << EOF
  start=timestamp;
}

io:::start
/
    lun[args[1]->dev_pathname]
/
{
  this->type =  args[0]->b_flags & B_READ ? "R," : "W,";
  tm_io[ args[0]->b_edev, args[0]->b_blkno] = timestamp;

  @sz[this->type,"size_distribution"]=quantize(args[0]->b_bcount);
  @avgsize[this->type,"dtrace_avgsize,"]=avg(args[0]->b_bcount);
  @totsz[this->type,"dtrace_bytes,"]=sum(args[0]->b_bcount);
}

io:::done
/     tm_io[ args[0]->b_edev, args[0]->b_blkno]   /
{
  this->type =  args[0]->b_flags & B_READ ? "R," : "W,";
  @name[this->type, args[1]->dev_pathname]=count();
  this->delta = (timestamp - tm_io[ args[0]->b_edev, args[0]->b_blkno] )/1000;
  @latency[this->type,"latency_distribution"]=quantize(this->delta);
  @avglatency[this->type,"dtrace_avglat,"]=avg(this->delta);
  @ct[this->type,"dtrace_iop,"] = count();
  tm_io[args[0]->b_edev, args[0]->b_blkno] = 0;
}

END
{
  delta=timestamp-start;

  printf("dtrace_secs,  %d\n",delta/(1000*1000*1000));

  printf("dtrace_size_start");
  printa(@sz);
  printf("dtrace_size_end");

  /* dtrace_avgsize */
  printa(@avgsize);

  /* dtrace_avglat */
  printa(@avglatency);

  /* dtrace_bytes */
  printa(@totsz);

  printf("dtrace_latency_start");
  printa(@latency);
  printf("dtrace_latency_end");

  /* dtrace_iop */
  printa(@ct);

  printa(@name);
}

EOF
}

offsets()
{
     loops=1
     OFFSET=0
     NUSERS=`echo $USERS | sed -e 's/^00*//'`
     #if [ $USERS > 1 ] ; then
        # make sure MEGABYTES is divisible by 8K
        # divide MEGABYTES by # of users 
        # multiply by 1024*1024 to get bytes
        BASEOFFSET=`echo "( ( $MEGABYTES / 8) / ( $USERS ) ) * 8196 *1024 " | bc`
     #else
     #   BASEOFFSET=0
     #fi
     #echo "loops $loops -le $NUSERS NUSERS"
     while [[ $loops -le $NUSERS ]] ; do
            JOBNUMBER=$loops
            eval $j
            loops=$(expr $loops + 1)
            OFFSET=$(expr $OFFSET + $BASEOFFSET )
     done
}

# if there is no filename specified
# then fio will use a file per processes 
# instead of a single file
# the filenames will be generated
# each generated file will get the same size 
if [ x$FILENAME == x ] ; then
    SIZE="size=100m"
    if [ x$MB == x1 ]; then
       SIZE="size=${MEGABYTES}m"
    fi
   OFFSET=0
fi
#
#  Looks like RAW will determine the
#  device size and not use the size
#  given in the input
#
#if [ $RAW -eq 1 ] ; then 
#       SIZE="size=${MEGABYTES}m"
#fi


mkdir $OUTPUT > /dev/null 2>&1
if [ ! -d $OUTPUT ]; then 
  echo "directory $OUTPUT does not exist"
  exit
fi

if [ -f /etc/delphix/version ]  ; then 
   DIRECT=0
   # if running on Delphix, then collect DTrace I/O info
   DTRACE1=" sudo dtrace -c ' "
   DTRACE2=" ' -s fio.d  "
fi

all="randrw read write readrand"
all="readrand write read "
if [ $TESTS = "all" ] ; then
  jobs=$all
else 
  jobs=$TESTS
fi

DIRECT=${FDIO:-$DIRECT}

echo "configuration: "
echo "    binary=$BINARY"
echo "    work directory=$DIRECTORY"
echo "    output directory=$OUTPUT"
echo "    tests=$jobs"
echo "    direct=$DIRECT"
echo "    seconds=$SECS"
echo "    megabytes=$MEGABYTES"
echo "    custom users=$CUSTOMUSERS"
echo "    custom blocksize=$CUSTOMBLOCKSIZE"
echo "    recordsize =$RECORDSIZE"
echo "    filename (blank if multiple files)=\"$FILENAME\""
echo "    size per file of multiple files=\"$SIZE\""

if [ -f /etc/delphix/version ] && [ $RAW -eq 0 ] ; then 
   if [  -f fio.d ]; then 
     if [ ! -f fio.d ]; then
       mv fio.d fio.d.orig
     fi
   fi

   # DIRECTORY=/domain0/fiotest
   FILESYSTEM=`echo $DIRECTORY | sed -e 's;^/;;' `
   DOMAIN=`echo $FILESYSTEM    | sed -e 's;/.*;;' `
   echo "DIRECTORY=$DIRECTORY"
   echo "FILESYSTEM=$FILESYSTEM"
   echo "DOMAIN=$DOMAIN"

   # setting up  a filesystem on  Delphix for iotesting
   # primarycache can be set to all, metadata or none
   if [  -d $DIRECTORY ]; then 
      echo "$DIRECTORY already exists"
      echo "suggest running the following commands: "
      echo "  sudo umount $DIRECTORY "
      echo "  sudo rm -rf $DIRECTORY "
      echo "  sudo zfs destroy $FILESYSTEM "
      echo "  sudo zpool  destroy $FILESYSTEM"
      if [ $FORCE = "n" ] ; then
         echo "drop fs [default=n] ? (y/n) "
         read response
         if [ "$response" == "y" ]; then
               echo "run the following commands to drop filesystem:"
               echo "  sudo umount $DIRECTORY "
               echo "  sudo rm -rf $DIRECTORY "
               echo "  sudo zfs destroy $FILESYSTEM "
               echo "exiting..."
               #sudo zpool  destroy $FILESYSTEM
               #echo "Exiting program."
               exit 1
         fi
     fi
   fi
   if [ !  -d $DIRECTORY ]; then 
      echo "directory:$DIRECTORY, does not exit"
      echo "trying to create zfs filesystem:$FILESYSTEM"
      cmd="sudo zfs create $FILESYSTEM"
      echo $cmd
      eval $cmd
      cmd="sudo zfs set primarycache=$PRIMARYCACHE $FILESYSTEM"
      echo $cmd
      eval $cmd
      cmd="sudo zfs set compression=$COMPRESSION $FILESYSTEM"
      echo $cmd
      eval $cmd
      cmd="sudo zfs set secondarycache=$SECONDARYCACHE $FILESYSTEM"
      echo $cmd
      eval $cmd
      cmd="sudo zfs set recordsize=$RECORDSIZE $FILESYSTEM"
      echo $cmd
      eval $cmd
      cmd="sudo chmod 777 $DIRECTORY"
      echo $cmd
      eval $cmd
   fi
   for i in 1 ; do
     echo "running the following commands: "
     cmd="   sudo  zfs get primarycache $DIRECTORY"
      echo "   $cmd"
      eval $cmd >  $OUTPUT/setup.txt
     cmd="   sudo  zfs get secondarycache $DIRECTORY"
      echo "   $cmd"
      eval $cmd >>  $OUTPUT/setup.txt
     cmd="   sudo  zfs get recordsize $DIRECTORY"
      echo "   $cmd"
      eval $cmd >>  $OUTPUT/setup.txt
     cmd="   sudo  zfs get compression $DIRECTORY"
      echo "   $cmd"
      eval $cmd >>  $OUTPUT/setup.txt
   done 
   echo "results:"
   cat $OUTPUT/setup.txt | grep -v PROPERTY | sed -e 's/^/   /' 
fi 

if [ ! -d $DIRECTORY ]; then 
  echo "directory $DIRECTORY does not exist"
  exit
fi

if [ $FORCE = "n" ] ; then
  echo "proceed?"
  read readit
  if [ ! $readit = "y" ] ; then
    exit
  fi
fi

if [ -f /etc/delphix/version ]  ; then 
   dtrace_begin > fio.d
   if [ $RAW == 1 ] ; then 
      dtrace_luns_raw  >> fio.d
      echo "readlink -f $RAWNAME "
      dtrace_luns_raw  
   else 
      echo "running following to find LUN names: zpool status $DOMAIN "
      for i in `zpool status $DOMAIN | grep ONLINE | grep -v state | grep -v pool | grep -v $DOMAIN | grep -v log | awk '{print $1}'`; do
         echo "    readlink -f /dev/dsk/${i} | sed -e 's/:wd/:a'/"
      done
      dtrace_luns  >> fio.d
      echo "results:"
      dtrace_luns   | sed -e 's/^/   /'
   fi 
   dtrace_end   >> fio.d
fi



 if [ ! -f $DIRECTORY/$FILE ]  ||  [ $CREATE == 1  ]; then
   # tar cvf - /opt/delphix/server > /domain0/fiotest/fiodata
   if [ $RAW == 0 ] ; then
    echo "CREATE=$DIRECTORY/$FILE"
    if [ -f $SEEDFILE ] ; then 
       echo "seed file found, using $SEEDFILE"
       loops=0
       while [[ $loops -le $MEGABYTES ]] ; do
          dd if=fio_random.dat  of=$DIRECTORY/$FILE bs=1024k oflag=append conv=notrunc count=1 > dd.out.$$ 2>&1
          RET=$?
          if [ $RET -eq 0 ] ; then
             echo -n "."
          else
             echo "RET:$RET:"
             cat dd.out.$$
          fi
          loops=$(expr $loops + 1)
       done
       rm dd.out.$$
     else 
       echo "seed file, $SEEDFILE,  not found, using /dev/urandom"
       rm /tmp/$FILE /tmp/fio.$$ > /dev/null 2>&1
       # create 512kB file of random data
       echo "creating 1M of random data"
       dd if=/dev/urandom of=/tmp/fio.$$ bs=512 count=2048
       loops=1
       echo "creating $MEGABYTES MB of random data"
       while [[ $loops -le $MEGABYTES ]] ; do
          dd if=/tmp/fio.$$ of=$DIRECTORY/$FILE bs=1024k oflag=append conv=notrunc count=1 > dd.out.$$ 2>&1
          RET=$?
          if [ $RET -eq 0 ] ; then
             echo -n "."
          else
             echo "RET:$RET:"
             cat dd.out.$$
          fi
          loops=$(expr $loops + 1)
       done
       rm dd.out.$$
       rm /tmp/fio.$$
   fi
   echo 
   echo "file creation finished"
  fi
 fi

if [ $RAW -eq 0 ]; then
   cmd="ls -l $DIRECTORY/$FILE "
   echo "running "
   echo "    $cmd"
   echo "results:"
   eval $cmd | sed -e 's/^/   /'
fi

if [ $FORCE = "n" ] ; then
  echo "created datafile, proceed?"
  read readit
  if [ ! $readit = "y" ] ; then
    exit
  fi
fi


# following functions 
#    init
#    read
#    write
#    randread
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
$SIZE
$FILENAME
directory=$DIRECTORY
direct=$DIRECT
runtime=$SECS
randrepeat=0
end_fsync=1
group_reporting=1
ioengine=psync
fadvise_hint=0
time_based=1
EOF
done > $JOBFILE
}

# read/write randomm, set block size, vary #  users
function randrw {
for i in 1 ; do
cat << EOF
[job]
rw=randrw
rwmixread=80
bs=8k
sync=0
numjobs=$USERS
EOF
done >> $JOBFILE
}

# read sequential, vary both blocksizes and # of users
function read {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=read
bs=${READSIZE}k
numjobs=1
offset=$OFFSET
EOF
done >> $JOBFILE
}


# read random, set blocksize, vary # of  users
function readrand {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=randread
bs=8k
numjobs=1
offset=$OFFSET
EOF
done >> $JOBFILE
}

# write sync, set 1 user, vary blocksizes
function write {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=write
bs=${WRITESIZE}k
numjobs=1
offset=$OFFSET
sync=1
direct=0
EOF
done >> $JOBFILE
}

#while [ 1 == 1 ]; do
for j in $jobs; do
  # default values if thet don't get set otherwise
  USERS=1
  WRITESIZE=008
  READSIZE=008
  # followng executes when it's a custom test
  if [ $CUSTOMUSERS -gt 0 ] || [ $CUSTOMBLOCKSIZE -gt 0 ] ; then
         echo "CUSTOM, users:$CUSTOMUSERS: blocksize:$CUSTOMBLOCKSIZE" 
         if [ $CUSTOMUSERS -gt  0 ] ; then
             echo "CUSTOM, users:$CUSTOMUSERS: " 
         fi
         if  [  $CUSTOMBLOCKSIZE -gt  0 ] ; then
             echo "CUSTOM,  blocksize:$CUSTOMBLOCKSIZE" 
         fi
         if [ $CUSTOMUSERS > -1 ] ; then
            USERS=$CUSTOMUSERS
         fi
         if [  $CUSTOMBLOCKSIZE > -1 ] ; then
             WRITESIZE=$CUSTOMBLOCKSIZE
             READSIZE=$CUSTOMBLOCKSIZE
         fi
         loops=1
         OFFSET=0
         PREFIX="$OUTPUT/${j}_u${USERS}_kb${READSIZE}"
         JOBFILE=${PREFIX}.job
         init
         offset
        # sudo dtrace -c 'fio jobfile' -s fio.d > jobfile.out
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
  elif [ $j ==  "readrand" ] ; then
       for USERS in `eval echo $MULTIUSERS` ; do 
         #echo "j: $USERS"
         PREFIX="$OUTPUT/${j}_u${USERS}_kb0008"
         JOBFILE=${PREFIX}.job
         init
         offsets
         #eval $j
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  # redo test : 1k, 4k, 8k, 128k, 1024k by 1 user 
  elif [ $j ==  "write" ] ; then
       for WRITESIZE in `eval echo $WRITESIZES` ; do 
         for USERS in `eval echo $MULTIWRITEUSERS` ; do 
           PREFIX="$OUTPUT/${j}_u${USERS}_kb${WRITESIZE}"
           JOBFILE=${PREFIX}.job
           init
           offsets
           # eval $j
           cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
           echo $cmd
           [[ $EVAL -eq 1 ]] && eval $cmd
         done
       done
  #  MB/s test : 1M by 1,8,16,32 users & 8k,32k,128k,1m by 1 user
  elif [ $j ==  "read" ] ; then
       for READSIZE in `eval echo $READSIZES` ; do 
         PREFIX="$OUTPUT/${j}_u01_kb${READSIZE}"
         JOBFILE=${PREFIX}.job
         init
         USERS=1
         OFFSET=0
         eval $j
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
       for seq_read_size in $SEQREADSIZES; do 
         for USERS in `eval echo $MULTIUSERS` ; do 
           #READSIZE=$SEQREADSIZE
           READSIZE=$seq_read_size
           #echo "j: $USERS"
           PREFIX="$OUTPUT/${j}_u${USERS}_kb${seq_read_size}"
           JOBFILE=${PREFIX}.job
           init
           offsets
           cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
           echo $cmd
           [[ $EVAL -eq 1 ]] && eval $cmd
         done
       done
  # workload test: 8k read write by 1,8,16,32 users
  elif [ $j ==  "randrw" ] ; then
    for USERS in `eval echo $MULTIUSERS` ; do 
      echo "j: $USERS"
      PREFIX="$OUTPUT/${j}_u${USERS}"
      JOBFILE=${PREFIX}.job
      init
      eval $j
      cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
      echo $cmd
      [[ $EVAL -eq 1 ]] && eval $cmd
    done
  else 
    PREFIX="$OUTPUT/$j"
    JOBFILE=${PREFIX}.job
    init
    eval $j
    cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
    echo $cmd
    [[ $EVAL -eq 1 ]] && eval $cmd
  fi
done
./fioparse.sh  $OUTPUT/*out  > $OUTPUT/fio_summary.out 
cat $OUTPUT/fio_summary.out
