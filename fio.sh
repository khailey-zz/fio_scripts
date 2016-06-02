#!/bin/bash   

#
#  DIRECT I/O :
#
#  direct is set to 0 if it's detected that fio.sh is running on Delphix
#  but environment variable FDIO=1 will override that
#  NOTE: direct=1 doesn't seem to work on opensolaris even
#        when opensolaris is the NFS client
#


# record size to use when creating a ZFS filesystem
RECORDSIZE=128k
RECORDSIZE=8k

# caching to use when creating a ZFS filesystem, 
# metadata means only cache metadata and not file data
PRIMARYCACHE=metadata
SECONDARYCACHE=metadata

# to use compression or not when creating a ZFS filesystem
COMPRESSION=on
COMPRESSION=off
PREHEAT="NO"
# by default use DIRECT I/O
DIRECT=1
# by default  don't initialize raw devices with writes
INITIALIZE=0
# by default  don't remove the data file after the tests
REMOVE=0
BINARY=`which fio`
DIRECTORY="/domain0/fiotest"
OUTPUT="."
TESTS="all"
SECS="60"
MEGABYTES="65536"
# by default  don't force the run, ie prompt for confirmations
FORCE="n"
CREATE=0

# whether to execute commands, EVAL=0 would turn
# command execution off for debuggion
EVAL=1

CUSTOMUSERS=-1
CUSTOMBLOCKSIZE=-1
FILE=fiodata
FILENAME="filename=$FILE"
RAW=0

DTRACE=0
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
   -w  directory   work directory where fio creates a fio and reads and writes, default /domain0/fiotest
   -o  directory   output directory, where to put output files, defaults to ./
   -t  tests       tests to run, defaults to all, options are
                      readrand - IOPS test : 8k by 1,8,16,32 users 
                      read  - MB/s test : 1M by 1,8,16,32 users & 8k,32k,128k,1m by 1 user
                      write - redo test, ie sync seq writes : 1k, 4k, 8k, 128k, 1024k by 1 user 
                      randrw   - workload test: 8k read write by 1,8,16,32 users 
   -s  seconds     seconds to run each test for, default 60
   -m  megabytes   megabytes for the test I/O file to be used, default 65536 (ie 64G)
   -i              individual file per process, default size 100m (otherwise uses the -m size)
   -f              force run, ie don't ask for confirmation on options
   -c              force creation of work file otherwise if it exists we use it as is
   -u #users       test only use this many users
   -l blocksize    test only use this blocksize in KB, ie 1-1024 
   -e recordsize   use this recordsize if/when creating the zfs file system, default 8K
   -d              Use DTrace on the run
   -x              remove work file after run
   -y              initialize raw devices to "-m megabytes" with writes 
                   writes will be evenly written across multiple devices,  default is 64GB
   -z raw_sizes    size of each raw device. If multiple, colon separate, list inorder of raw_device
   -r raw_device   use raw device instead of file, multi devices colon separated
   -p preheat      performance testing need to preheat.YES or NO,default NO 
                          
       example
                  fio.sh ./fio.opensolaris /domain0/fiotest  -t rand_read -s 10 -m 1000 -f
EOF
}

while getopts hz:ycb:nr:xe:d:o:it:s:l:u:m:p:f OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BINARY=$OPTARG
             ;;
         w)
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
             #echo "MEGABYTES=$MEGABYTES"
             MB=1
             ;;
         d)
             DTRACE=1
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
         x)
             REMOVE=1
             ;;
         y)
             INITIALIZE=1
             ;;
         z)
             RAWSIZES=$OPTARG
             ;;
         p)  
             PREHEAT=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done


dtrace_begin() {
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
# output is of the form "c4t1d0"
for i in `zpool status $DOMAIN | grep ONLINE | grep -v state | grep -v pool | grep -v $DOMAIN | grep -v log | awk '{print $1}'`; do
 # append 's0'
 # :wd refers to whole disk, take it of, replace with partition
 # j=`readlink -f /dev/dsk/${i} | sed -e 's/:wd/:a/'`
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
 # output will have ",raw" at the end, but DTrace matching is without the ",raw"
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
/ lun[args[1]->dev_pathname] /
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
  @mxblock["mxblock",args[0]->b_edev] = max(args[0]->b_blkno);
  @mnblock["mnblock",args[0]->b_edev]= min(args[0]->b_blkno);
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
/*
  printf("max block %d min block %d \n",mxblock, mnblock);
*/
  printf("max block ");
  printa(@mxblock);
  printf("minn block ");
  printa(@mnblock);
}
EOF
}  # end dtrace_begin


offsets()
{
     loops=1
     OFFSET=0
     NUSERS=`echo $USERS | sed -e 's/^00*//'`
     # make sure MEGABYTES is divisible by 8K
     # divide MEGABYTES by # of users 
     BASE_IN_8K=`echo "( ($MEGABYTES * 1024) / 8 )" | bc`
     if [ $RAW -eq 1 ] ; then 
        BASEOFFSET=`echo "( ($BASE_IN_8K / $USERS)/ $NRAWDEVICES  ) * 8192 " | bc`
     else 
        BASEOFFSET=`echo "( ($BASE_IN_8K / $USERS)  ) * 8192 " | bc`
     fi
     while [[ $loops -le $NUSERS ]] ; do
            JOBNUMBER=$loops
            # job is either write, read, randread, randrw and is
            # the name of a function that outputs job information to the job file
            eval $job
            loops=$(expr $loops + 1)
            OFFSET=$(expr $OFFSET + $BASEOFFSET )
            #echo " loops:$loops" 
            #echo " OFFSET:$OFFSET" 
     done
}

offsets()
{
     NUSERS=`echo $USERS | sed -e 's/^00*//'`
     # make sure MEGABYTES is divisible by 8K
     # divide MEGABYTES by # of users 
    JOBNUMBER=$NUSERS
    # job is either write, read, randread, randrw and is
    # the name of a function that outputs job information to the job file
    eval $job
}
# if there is no filename specified
# fio will generate a file per processes (name generated by fio) 
# each generated file will get the same size 
if [ x$FILENAME == x ] ; then
    SIZE="size=100m"
    if [ x$MB == x1 ]; then
       SIZE="size=${MEGABYTES}m"
    fi
    OFFSET=0
fi


mkdir $OUTPUT > /dev/null 2>&1
if [ ! -d $OUTPUT ]; then 
  echo "directory $OUTPUT does not exist"
  exit
fi

DD=dd
if [ -f /etc/delphix/version ]  ; then 
   # /usr/bin/dd doesn't have an append option
   DD=/usr/gnu/bin/dd
   DIRECT=0
   # if running on Delphix, then collect DTrace I/O info
   DTRACE1=" sudo dtrace -c ' "
   DTRACE2=" ' -s fio.d  "
   if [ $DTRACE == 0 ] ; then
     DTRACE1=" "
     DTRACE2=" "
   fi
fi

all="randrw read write readrand"
all="write randwrite read randread"
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
echo "    performance testing preheat choice is $PREHEAT"


# if running on Delphix and not using RAW LUNs, ie using /domain0
if [ -f /etc/delphix/version ] && [ $RAW -eq 0 ] ; then 
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


if [ -f /etc/delphix/version ]  ; then  # {
   if [ $DTRACE == 1 ] ; then
     dtrace_begin > fio.d
     if [ $RAW == 1 ] ; then   #  {
        echo "readlink -f $RAWNAME " 
        dtrace_luns_raw  >> fio.d
        dtrace_luns_raw  
     else # not using RAW
        dtrace_luns  >> fio.d
        echo "results:"
        dtrace_luns   | sed -e 's/^/   /'
     fi  # } 
     dtrace_end >> fio.d
   fi  # } using DTrace 
fi # } end if on delphix


initialize()
{
    echo ""
    echo "creating 10 MB  seed file of random data"
    echo ""
    #$DD if=/dev/urandom of=/tmp/fio.$$ bs=512 count=20480
    $DD if=/dev/urandom of=/tmp/fio.$$ bs=512 count=20480
    echo ""
    echo "creating $MB_per_LUN MB of random data on $rawdev"
    echo ""
    let TENMEGABYTES=$MB_per_LUN/10
    let TENMEGABYTES=$TENMEGABYTES-1
    linesize=60
    characters=0
    loops=1
    BEG=`date +%s`
    while [[ $loops -le $TENMEGABYTES ]] ; do  # {
       let seek=$loops*10
       cmd="$DD if=/tmp/fio.$$ of=${outfile} bs=1024k seek=$seek count=10 > /tmp/fio.dd.out 2>&1"
     # was the command for file
     # cmd="$DD if=/tmp/fio.$$ of=${outfile} bs=1024k oflag=append conv=notrunc count=1 > /tmp/fio.dd.out 2>&1"
       eval $cmd
       RET=$?
       if [ $RET -eq 0 ] ; then # {
          echo -n "."
          characters=$(expr $characters + 1)
          if [ $characters -gt $linesize ] ; then # {
            END=`date +%s`
            let DELTA=$END-$BEG
            let MB_LEFT=$MB_per_LUN-$seek
            let MB_PER_SEC=($linesize*10)/$DELTA
            let SECS_LEFT=$MB_LEFT/$MB_PER_SEC
            echo " $MB_LEFT MB remaining  $MB_PER_SEC MB/s $SECS_LEFT seconds left"
            characters=0
            BEG=`date +%s`
          fi  # }
       else
          echo "RET:$RET:"
          cat /tmp/fio.dd.out
       fi # }
       loops=$(expr $loops + 1)
    done   #  }
    rm /tmp/fio.dd.out
}

# example variable values for INITIALIZE
# RAWSIZES="9216:9216"
# RAWNAME="/dev/rdsk/c4t3d0p0:/dev/rdsk/c4t4d0p0"
if [ $RAW == 1 ] ; then   #  {
   NRAWDEVICES=0
   for rawdev in `echo $RAWNAME | sed -e 's/:/ /'`; do # {
      rawname[$NRAWDEVICES]=$rawname
      NRAWDEVICES=$(expr $NRAWDEVICES + 1)
   done # }
   # take total size requested, and divide by number of LUNs 
   # initialize each LUN with this amount
   let size=$MEGABYTES/$NRAWDEVICES  
   SIZE="filesize=${size}m"
   if [ $INITIALIZE == 1 ] ; then  # {
       i=0
       for rawsize in `echo $RAWSIZES | sed -e 's/:/ /'`; do # {
         i=$(expr $i + 1)
       done # }
       if [ $NRAWDEVICES -ne $i ] ; then  # {
          echo "number of raw devices,$j, is not equal to number of raw device sizes, $i"
          exit
       fi # }
       let MB_per_LUN=$size
       echo "number of raw devices:$NRAWDEVICES"
       echo " writing $MB_per_LUN MB to each LUN"
       echo " creating 10M of random data seed file"
       for rawdev in `echo $RAWNAME | sed -e 's/:/ /'`; do # {
         outfile=$rawdev
         initialize
       done # }
       rm dd.out.$$
       rm /tmp/fio.$$
   fi # }
fi # }


# if the work file doesn't exist or force create is set 
if [ ! -f $DIRECTORY/$FILE ]  ||  [ $CREATE == 1  ]; then
   if [ $RAW == 0 ] ; then
       MB_per_LUN=$MEGABYTES
       echo "CREATE $MEGABYTES MB file $DIRECTORY/$FILE"
       outfile=$DIRECTORY/$FILE
       initialize
       echo 
       echo "file creation finished"
   fi
fi

# if we are using a work file and not RAW, get the size of the work file
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


# took time_based out because
# it made sequential read fail with offsets
#
# time_based=1
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
ramp_time=6
fadvise_hint=0
norandommap=1
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
numjobs=$JOBNUMBER
EOF
done >> $JOBFILE
}


# read random, set blocksize, vary # of  users
function randread {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=randread
bs=${RANDREADSIZE}k
numjobs=$JOBNUMBER
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
numjobs=$JOBNUMBER
EOF
done >> $JOBFILE
}

function randwrite {
for i in 1 ; do
cat << EOF
[job$JOBNUMBER]
rw=randwrite
bs=${RANDWRITESIZE}k
numjobs=$JOBNUMBER
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
             RANDWRITESIZE=$CUSTOMBLOCKSIZE
             RANDREADSIZE=$CUSTOMBLOCKSIZE
         fi
         if [ $READSIZE -le 9 ]; then
             READSIZE=000${READSIZE}
         elif [ $READSIZE -le 99 ] && [ $READSIZE -gt 9 ] ; then
             READSIZE=00${READSIZE}
         elif [ $READSIZE -le 999 ] && [ $READSIZE -gt 99 ] ; then
             READSIZE=0${READSIZE}
         else
            READSIZE=${READSIZE};
         fi
         loops=1
         OFFSET=0
         PREFIX="$OUTPUT/${job}_u${USERS}_kb${READSIZE}"
         JOBFILE=${PREFIX}.job
         init
         offsets
        # sudo dtrace -c 'fio jobfile' -s fio.d > jobfile.out
         if [ $PREHEAT == "YES" ] ; then
             cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2"
             echo $cmd
             [[ $EVAL -eq 1 ]] && eval $cmd
             cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2"
             echo $cmd
             [[ $EVAL -eq 1 ]] && eval $cmd
         fi
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
  elif [ $job ==  "readrand" ] ; then
       for USERS in `eval echo $MULTIUSERS` ; do 
         #echo "j: $USERS"
         PREFIX="$OUTPUT/${job}_u${USERS}_kb0008"
         JOBFILE=${PREFIX}.job
         # init creates the shared job file potion
         init
         # for random read, offsets shouldn't be needed
         # offsets
         OFFSET=0
         loops=1
         NUSERS=`echo $USERS | sed -e 's/^00*//'`
         while [[ $loops -le $NUSERS ]] ; do
            JOBNUMBER=$loops
            eval $jobs
            loops=$(expr $loops + 1)
         done
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
  # redo test : 1k, 4k, 8k, 128k, 1024k by 1 user 
  elif [ $job ==  "write" ] ; then
       for WRITESIZE in `eval echo $WRITESIZES` ; do 
         for USERS in `eval echo $MULTIWRITEUSERS` ; do 
           PREFIX="$OUTPUT/${job}_u${USERS}_kb${WRITESIZE}"
           JOBFILE=${PREFIX}.job
           init
           offsets
           # eval $job
           cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
           echo $cmd
           [[ $EVAL -eq 1 ]] && eval $cmd
         done
       done
  #  MB/s test : 1M by 1,8,16,32 users & 8k,32k,128k,1m by 1 user
  elif [ $job ==  "read" ] ; then
       for READSIZE in `eval echo $READSIZES` ; do 
         PREFIX="$OUTPUT/${job}_u01_kb${READSIZE}"
         JOBFILE=${PREFIX}.job
         init
         USERS=1
         OFFSET=0
         eval $job
         cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
         echo $cmd
         [[ $EVAL -eq 1 ]] && eval $cmd
       done
       for seq_read_size in $SEQREADSIZES; do 
         for USERS in `eval echo $MULTIUSERS` ; do 
           #READSIZE=$SEQREADSIZE
           READSIZE=$seq_read_size
           #echo "j: $USERS"
           PREFIX="$OUTPUT/${job}_u${USERS}_kb${seq_read_size}"
           JOBFILE=${PREFIX}.job
           init
           offsets
           cmd="$DTRACE1 $BINARY $JOBFILE $DTRACE2> ${PREFIX}.out"
           echo $cmd
           [[ $EVAL -eq 1 ]] && eval $cmd
         done
       done
  # workload test: 8k read write by 1,8,16,32 users
  elif [ $job ==  "randrw" ] ; then
    for USERS in `eval echo $MULTIUSERS` ; do 
      echo "j: $USERS"
      PREFIX="$OUTPUT/${job}_u${USERS}"
      JOBFILE=${PREFIX}.job
      init
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
# if we are asked to remove the work file and we are not using RAW, then rm work file
if [ $REMOVE == 1 ]  && [ $RAW == 0 ] ; then  # {
    cmd="rm  $DIRECTORY/$FILE "
    echo "cmd=$cmd"
    eval $cmd
fi # }
sh fioparse.sh  $OUTPUT/*out  > $OUTPUT/fio_summary.out 
cat $OUTPUT/fio_summary.out
