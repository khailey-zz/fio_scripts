
fio_scripts
===========

Thses scripts are for facilitating running the I/O benchmark tool
fio, parsing the fio data and graphing the output.
There are a lot of I/O benchmarking tools out there, most noteably
iozone and bonnie++, but fio seems to be the most flexible with
 the most active user community

* fio project: http://freecode.com/projects/fio
* download: http://brick.kernel.dk/snaps/fio-2.0.7.tar.gz
* man page: http://linux.die.net/man/1/fio
* how to: http://www.bluestop.org/fio/HOWTO.txt
* mail list subscription: http://vger.kernel.org/vger-lists.html
* mail list archives : http://www.spinics.net/lists/fio/


files in this project

+ fio.sh - run sets of I/O benchmarks using fio
+ fioparse.sh - parse the output files from fio.sh runs
+ fio.r - create a function called graphit() in R
+ fiog.r  - run graphit on different combinations of data from fioparse.sh
+ example data from fioparse.sh

	> data_emc.r   
	> data_ssd.r   
	> data_pharos.r   

Running fio.sh
---------------------------
First run fio.sh.
The script fio.sh will run a series of I/O benchmarks.
The series of I/O benchmarks are aimed at simulating the typical workload
of an Oracle database.
There are 3 types of I/O run

* random small reads
* sequential large reads
* sequential writes

for each of these the number of users is varied and the I/O request size is 
varied.


	usage: ./fio.sh  [options]
	
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
	   -m  megabytes   megabytes for the test I/O file to be used, default 8000 (ie 8G)
	   -i              individual file per process, default size 100m (overrides -m )
	   -f              force run, ie don't ask for confirmation on options
	   -c              force creation of work file otherwise if it exists we use it as is
	   -r raw_device   use named raw device instead of file
	   -u #users       force test to only use this many users
	   -l blocksize    force test to only use this blocksize in KB, ie 1-1024 
	   -e recordsize   use this recordsize if/when creating the zfs file system, default 8K
	
	       example
	                  fio.sh -b ./fio.opensolaris

Running fioparse.sh
---------------------------
Once the benchmarks have been run, use fioparse.sh to extract a consise
set of statistics from the output files.

	./fioparse.sh -v  *out
	test  users size         MB       ms  IOPS    50us   1ms   4ms  10ms  20ms  50ms   .1s    1s    2s   2s+
	    read  1   8K r   28.299    0.271  3622           99     0     0     0
	    read  1  32K r   56.731    0.546  1815           97     1     1     0     0           0
	    read  1 128K r   78.634    1.585   629           26    68     3     1     0           0
	    read  1   1M r   91.763   10.890    91                 14    61    14     8     0     0
	    read  8   1M r   50.784  156.160    50                              3    25    31    38     2
	    read 16   1M r   52.895  296.290    52                              2    24    23    38    11
	    read 32   1M r   55.120  551.610    55                              0    13    20    34    30
	    read 64   1M r   58.072 1051.970    58                                    3     6    23    66     0
	randread  1   8K r    0.176   44.370    22      0     1     5     2    15    42    20    10
	randread  8   8K r    2.763   22.558   353            0     2    27    30    30     6     1
	randread 16   8K r    3.284   37.708   420            0     2    23    28    27    11     6
	randread 32   8K r    3.393   73.070   434                  1    20    24    25    12    15
	randread 64   8K r    3.734  131.950   478                  1    17    16    18    11    33
	   write  1   1K w    2.588    0.373  2650           98     1     0     0     0
	   write  1   8K w   26.713    0.289  3419           99     0     0     0     0
	   write  1 128K w   11.952   10.451    95           52    12    16     7    10     0     0           0
	   write  4   1K w    6.684    0.581  6844           90     9     0     0     0     0
	   write  4   8K w   15.513    2.003  1985           68    18    10     1     0     0     0
	   write  4 128K w   34.005   14.647   272            0    34    13    25    22     3     0
	   write 16   1K w    7.939    1.711  8130           45    52     0     0     0     0     0     0
	   write 16   8K w   10.235   12.177  1310            5    42    27    15     5     2     0     0
	   write 16 128K w   13.212  150.080   105                  0     0     3    10    55    26     0     2

The above output is for human consumption, but when run with "-r" the output
will be given in R format:

	./fioparse.sh -r *out
	
	m <- NULL
	m <- matrix(c(
	    "read",  1,  "8K",  35.647,    0.217, 0.2,        8,    0.1, 4562 , 0, 0,92, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.266,0.438,0.506,0.572,0.756,4.080
	,    "read",  1, "32K",  98.439,    0.315, 0.1,       22,    0.2, 3150 , 0, 0, 4,94, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.418,0.490,0.604,0.772,0.948,3.632
	,    "read",  1,"128K", 223.127,    0.556, 0.3,       40,    0.3, 1785 , 0, 0, 0,21,78, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.652,0.692,0.748,1.112,1.816,11.328
	,    "read",  1,  "1M", 388.821,    2.567, 0.3,       16,    0.7,  388 , 0, 0, 0, 4, 0, 1,93, 0, 0, 0, 0, 0, 0, 0, 0, 0,2.768,3.376,4.832,10.432,15.424,16.192
	,    "read",  8,  "1M", 265.195,   18.608, 0.3,       33,    5.8,  265 , 0, 0, 0, 5, 0, 0, 2, 0,19,71, 0, 0, 0, 0, 0, 0,21.376,22.144,24.448,29.056,29.568,33.536
	,    "read", 16,  "1M", 239.514,   35.450, 3.0,       41,    6.0,  239 , 0, 0, 0, 0, 0, 0, 0, 0, 4,94, 0, 0, 0, 0, 0, 0,38.144,38.656,38.656,41.728,41.728,41.728
	,    "read", 32,  "1M", 288.621,   48.080, 0.3,       76,   26.3,  288 , 0, 0, 0,10, 0, 0, 3, 0, 5,24,54, 0, 0, 0, 0, 0,74.240,75.264,75.264,75.264,76.288,77.312
	,    "read", 64,  "1M", 326.718,   65.409, 0.3,      132,   43.0,  326 , 0, 0, 0,10, 1, 0, 2, 5, 1, 9,44,23, 0, 0, 0, 0,132.096,132.096,132.096,132.096,132.096,132.096
	,"randread",  1,  "8K",  28.188,    0.274, 0.0,       19,    0.2, 3608 ,11,34, 2,44, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.506,0.524,0.524,0.628,0.740,1.640
	,"randread",  8,  "8K", 369.144,    0.166, 0.0,       12,    0.2,47250 , 0,63,20, 2,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.636,0.788,0.852,1.208,1.512,2.640
	,"randread", 16,  "8K", 482.962,    0.254, 0.0,       16,    0.3,61819 , 0,20,57, 5,14, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.820,1.192,1.784,4.128,5.408,9.024
	,"randread", 32,  "8K", 511.212,    0.480, 0.0,       53,    0.9,65435 , 0,14,52, 6,15, 6, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0,1.912,4.384,5.536,8.640,10.304,17.792
	,"randread", 64,  "8K", 525.351,    0.904, 0.0,     1040,    6.6,67244 , 0, 8,47,11,16, 9, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0,2.384,8.640,16.768,71.168,121.344,309.248
	,   "write",  1,  "1K",  11.306,    0.084, 0.1,        2,    0.0,11577 , 0,91, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.106,0.124,0.133,0.197,0.510,1.144
	,   "write",  1,  "8K",  67.812,    0.113, 0.1,       15,    0.1, 8679 , 0,37,62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.149,0.183,0.205,0.964,0.988,1.128
	,   "write",  1,"128K", 270.647,    0.458, 0.4,       22,    0.2, 2165 , 0, 0, 0,95, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.478,1.160,1.192,1.272,1.448,6.304
	,   "write",  4,  "1K",  27.946,    0.102, 0.1,       12,    0.1,28617 , 0,68,30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.147,0.193,0.213,0.980,1.080,1.384
	,   "write",  4,  "8K", 145.804,    0.158, 0.1,       16,    0.1,18662 , 0, 0,96, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.239,0.314,1.032,1.144,1.208,3.920
	,   "write",  4,"128K", 373.462,    0.999, 0.4,       40,    0.7, 2987 , 0, 0, 0, 0,73,24, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,1.352,3.312,4.512,6.496,9.536,39.680
	,   "write", 16,  "1K",  44.294,    0.195, 0.1,       30,    0.2,45357 , 0, 0,91, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.306,0.422,0.572,1.336,2.224,5.472
	,   "write", 16,  "8K", 210.676,    0.329, 0.1,       13,    0.3,26966 , 0, 0,42,51, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0.524,1.256,1.368,2.992,4.960,8.384
	,   "write", 16,"128K", 317.903,    3.517, 0.4,       85,    5.1, 2543 , 0, 0, 0, 0, 0, 8,83, 5, 0, 1, 0, 0, 0, 0, 0, 0,4.576,38.144,43.264,55.552,58.624,62.720
	),nrow=31)
	tm <- t(m)
	m <-tm
	colnames <- c("name","users","bs","MB","lat","min","max","std","iops"
	, "us50","us100","us250","us500","ms1","ms2","ms4","ms10","ms20"
	, "ms50","ms100","ms250","ms500","s1","s2","s5"
	,"p95_00", "p99_00", "p99_50", "p99_90", "p99_95", "p99_99"
	)
	colnames(m)=colnames
	m <- data.frame(m)
	

Graphing in R
-----------------------------------------
To get started with R see: http://scs.math.yorku.ca/index.php/R:_Getting_started_with_R
QUICK START: To install R, you can go to http://cran.r-project.org/ and follow the instructions.

Start R and load up the above in R and it creates the dataframe "m"

	> m
	       name users   bs      MB    lat min  max   std  iops us50 us100 us250 us500 ms1 ms2 ms4 ms10 ms20 ms50 ms100 ms250 ms500 s1 s2 s5 p95_00 p99_00  p99_50   p99_90   p99_95   p99_99
	1      read     1   8K   14.67  0.529 0.2    4   0.1  1877    0     0     3    26  70   0   0    0    0    0     0     0     0  0  0  0  0.644  0.708    0.74    1.032    1.416    3.152
	2      read     1  32K   7.183  4.345 0.3  100   9.8   229    0     0     0    12  59   5   2    8    5    5     0     0     0  0  0  0  24.96  49.92  58.112   80.384   82.432    99.84
	3      read     1 128K  13.277  9.408 0.6  222  17.3   106    0     0     0     0  29  32   2    8   10   13     2     0     0  0  0  0 41.728 80.384  90.624  166.912  222.208  222.208
	4      read     1   1M  64.841  15.41   3  227  24.9    64    0     0     0     0   0   0  34   44    1   10     8     1     0  0  0  0     65    116     145      227      227      227
	5      read     8   1M 129.512  38.45   3  395  48.7   129    0     0     0     0   0   0   0   30   33    5    18     9     0  0  0  0    139    219     265      306      396      396
	6      read    16   1M 140.513  63.47   3  597  71.3   140    0     0     0     0   0   0  10   19    9    9    31    16     3  0  0  0    194    338     371      594      594      594
	7      read    32   1M 179.886  96.23   3 1546 114.7   179    0     0     0     0   0   0   4   10   14    9    25    28     6  0  0  0    293    515     676     1483     1549     1549
	8      read    64   1M 261.523  111.7   3 1270 114.6   261    0     0     0     0   0   0   0    1    7   32    15    32     8  1  0  0    318    545     685      857      865     1270
	9  randread     1   8K   0.553 14.114 0.2  296  15.3    70    0     0     0     3  14   0   1   15   44   17     1     0     0  0  0  0 32.384  60.16  68.096   296.96   296.96   296.96
	10 randread     8   8K    3.77 16.489 0.2  257  15.7   482    0     0     0     2   4   0   2   21   44   20     2     0     0  0  0  0 39.168 73.216  97.792  191.488   220.16  257.024
	11 randread    16   8K   6.628 18.684 0.2  285    18   848    0     0     0     2   4   0   2   18   40   27     3     0     0  0  0  0 46.848 87.552 117.248  201.728  238.592  284.672
	12 randread    32   8K   8.957   27.3 0.2  377  22.5  1146    0     0     0     0   0   0   1    8   32   48     7     1     0  0  0  0     65    117     143      241      306      367
	13 randread    64   8K   9.989 44.843 0.2  348    24  1278    0     0     0     0   0   0   0    0    5   64    26     2     0  0  0  0     85    137     161      258      281      310
	14    write     1   1K    1.51  0.643 0.2  106     2  1546    0     0     2    25  71   0   0    0    0    0     0     0     0  0  0  0  0.716  1.032    4.64    24.96   38.656  102.912
	15    write     1   8K  13.922  0.557 0.2    4   0.1  1782    0     0     0    27  71   0   0    0    0    0     0     0     0  0  0  0  0.708  0.844   0.908    1.416    1.816    4.048
	16    write     1 128K  62.081  2.009 0.7  547   8.4   496    0     0     0     0  39  51   0    5    2    0     0     0     0  0  0  0   9.92 10.176  20.096   40.192    49.92  544.768
	17    write     4   1K   6.694  0.434 0.1  283   2.1  6855    0     0    26    54  18   0   0    0    0    0     0     0     0  0  0  0    0.7  0.828   1.384   15.296   23.424   71.168
	18    write     4   8K  56.823  0.409 0.2    8   0.1  7273    0     0     1    88   9   0   0    0    0    0     0     0     0  0  0  0  0.692  0.788   0.852    1.848     2.48     4.32
	19    write     4 128K  63.777  4.002 0.7 4650  95.1   510    0     0     0     0   8  84   0    3    2    0     0     0     0  0  0  0   9.92  19.84  20.352   40.192    49.92 4620.288
	20    write    16   1K  14.483    0.6 0.2  815   3.7 14831    0     0     8    78  10   0   0    0    0    0     0     0     0  0  0  0  0.708   5.92  12.224   33.536    47.36  124.416
	21    write    16   8K 179.438  0.387 0.2  691     2 22968    0     0     0    95   2   0   0    0    0    0     0     0     0  0  0  0  0.454  0.644   0.804     9.92    19.84   40.192
	22    write    16 128K   67.58 16.606 0.7 5325 227.1   540    0     0     0     0   0   1  84    3    4    4     0     0     0  0  0  0 20.096  49.92   60.16 5341.184 5341.184 5341.184
	
In R we can now source "fio.r" which creates a function "graphit(m)"

	source("fio.r")
	graphit(m)

By default it will graph 8K random reads.
If you source "fiog.r" it will run through a series of different combinations graphing them and saving the output.
The output is save to png files in the directory 

Three different example data files are included

* data_emc.r
* data_ssd.r
* data_pharos.r

collected from different systems. The EMC data is one single spindle. The pharos data is striped but
shared filer. THe ssd data is from two striped SSD devices.
In order to tests these datasets, simple source them

	source("data_ssd.r")

Then graph them

	source("fiog.r")

NOTE: to source files they have to be in R's working directory.
You can get the working directory with

	getwd()

you can set working directory with

	setwd("C:\\Temp\\")

for example to set it to C:\Temp

