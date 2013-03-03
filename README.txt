

# cd to the fio scripts directory 

 source("fio.r")

# load up data

 m <- read.csv("data_affi_50GB120sec.csv") 
  
# set test name

 testtype = "nyl" 

# generate graphs

 source('fiop.r')
# graph all 4 main graphs
 source('fiopg.r')

# one just 8k graph

  graphit(m, i_name=testname, i_bs="8K",i_title=paste("randread",testname,"bs=8K"),i_hist=hist,i_poly=poly)

# generate report cards

 source('grade.r')
 source('gradeg.r')

# to chart all 

 source('gradeg_all.r')


Files

   old version

     fio.r   - creates  graphit(), no scaling 
     fiog.r  - for a given m, graphs 2 sets
               graphs avg,95,99.5,99 and max in one set
                      and histograms in another set

   new version

     fiop.r  - creates graphit()
     fiopg.r - has scaling graph as well

   report card

     grade.r      - creates chart_grades()
     gradeg.r     - generates grades for m
     gradeg_all.r - generates grades for many different datasets
     gradeonly.r  - only  generate the grades, no graph ?

graphit() has many options thus the "g" files are used
          to iterate through many options

chart_grades() has no options so can be run as chart_grades(m)





MBs_t1=t(subset(nio['s_MB.s'],nio['thrds'] == 1 )) 
MBs_t8=t(subset(nio['s_MB.s'],nio['thrds'] == 8 )) 
MBs_t64=t(subset(nio['s_MB.s'],nio['thrds'] == 64 )) 

IOsize=t(subset(nio['s_KB'],nio['thrds'] == 1 ))

# just dots
plot(IOsize,MBs_t64,ylab="MB/s",xlab="I/O size kb")
# lines
plot(IOsize,MBs_t64,ylab="MB/s",xlab="I/O size kb",type="o")
# no axis lines
# plot(IOsize,MBs_t64,ylab="MB/s",xlab="I/O size kb",type="o",axes=FALSE)
#  ??
# plot(IOsize,MBs_t64,ylab="MB/s",xlab="I/O size kb",type="o",ann=FALSE)
# add a line
lines(IOsize,MBs_t8,lty=2,col="red",type="o")
lines(IOsize,MBs_t1,lty=3,col="green",type="o")
axis(1, at=c(0,8,32,128,1024), lab=c("0","8k","32k","128k","1024k"))

legend(1, 800,c("1 thread","8 threads","64 threads"), cex=0.8, 
   col=c("green","red","black"), lty=3:1);

legend(1,800, g_range[3], c("1 thread","8 threads","64 threads"), cex=0.8, 
   col=c("green","red","black"), lty=3:2:1);



# barplot, but xaxis width is  proportional  to value
barplot(MBs_t1,IOsize,ylab="MB/s",xlab="I/O size kb")
# take out xaxis, and just have it count
barplot(MBs_t1,ylab="MB/s",xlab="I/O size kb")

barplot(MBs,ylab="MB/s",xlab="I/O size kb")

# makes the dots black??
segments(MBs,IOsize,MBs,IOsize,col="black",lwd=5)



plot(s_KB,r_MB.s)

# xaxt="n", don't draw x axis, because we create it below
plot(users,ms,xlim=c(1,max(users)),ylim=c(1,max(max)),ylog=TRUE, ylog=TRUE,xaxt="n",log="y");
# draw min to max
segments(users,min,users,max,col="red",lty=2,lwd=1)
# draw avg+/- std
segments(users,c(max(1,ms-std)),users,ms+std,col="grey",lwd=2)
# draw the averages
segments(users,ms,users,ms,col="black",lwd=5)
# add the axis lables from users:  axis, location, value
axis(1, c(1,8,16,32, 64),c(1,8,16,32, 64))



