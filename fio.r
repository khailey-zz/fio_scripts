


graphit <- function(m,i_name="undefined",i_users=0,i_bs="undefined") {

  colors <- c(
            "#00007F", # 50u   1 blue
            "#0000BB", # 100u  5
            "#0000F7", # 250u
            "#00ACFF", # 500u  6
            "#00E8FF", # 1ms   7
            "#25FFD9", # 2ms   8
            "#61FF9D", # 4ms   9 
            "#9DFF61", # 10ms  10
            #"#D9FF25", # 10ms  11
            "#FFE800", # 20ms  12 yellow
            "#FFAC00", # 50ms  13 orange
            "#FF7000", # 100ms 14 dark orang
            "#FF3400", # 250ms 15 red 1
            "#F70000", # 500ms 16 red 2
            "#BB0000", # 1s    17 dark red 1
            "#7F0000", # 2s    18 dark red 2
            "#4F0000") # 5s    18 dark red 2

  # transpose input matrix
  tm <- t(m)
  m <-tm

  # add column names to imput matrix
  colnames <- c("name","users","bs","MB","lat","min","max","std","iops",
               "us50","us100","us250","us500","ms1","ms2","ms4","ms10","ms20","ms50","ms100","ms250","ms500","s1","s2","s5")
  colnames(m)=colnames

  #  make the matrix a data.frame
  m <- data.frame(m)

  # rr will be the subset of m that is graphed
  rr <- m ;

  # filter by test name, if no test name make it 8K random read by default
  if ( i_name != "undefined" ) {
    rr <- subset(rr,rr['name'] == i_name )
    cat("rr filtered for name=",i_name,"\n");
    print(rr)
  } else {
    rr <- subset(rr,rr['name'] == "randread" )
    i_bs = "8K"
    cat("no name\n");
  }

  # if i_users > 0 then it's an input value
  # which means users stays constant at I/O sizes, ie i_bs, (block size)
  # changes
  # the title of the different columns will be the different I/O sizes
  if ( i_users > 0 ) {
    rr <- subset(rr,rr['users'] == i_users )
    cat("rr filterd for users=",i_users,"\n");
    print(rr)
  } else {
    cat("no users\n");
  }

  # if i_bs (block size, the I/O request size) is defined then it's an input value
  # which means bs stays constant and the # of users will change
  # the title of the different columns will be the number of users
  if ( i_bs != "undefined" ) {
    rr <- subset(rr,rr['bs'] == i_bs )
    cat("rr filterd for bs=",i_bs,"\n");
    print(rr)
  } else {
    cat("no block sise\n");
  }

  # extract the histogram latency values out of rr
  hist <- cbind(rr['us50'],rr['us100'], rr['us250'],rr['us500'],rr['ms1'],
               rr['ms2'],rr['ms4'],rr['ms10'],rr['ms20'],rr['ms50'],
               rr['ms100'],rr['ms250'],rr['ms500'],rr['s1'],rr['s2'],rr['s5']) 

  # thist is used by the latency graph
  thist  <- t(hist)
  # fhist is used by the MB/s bars
  fhist   <- apply(hist, 1,as.numeric)
  fhist   <- fhist/100
 
  # extract various columns from the data (in rr)
  lat   <- as.numeric(t(rr['lat']))
  users <- as.numeric(t(rr['users']))
  bs    <- as.character(t(rr['bs']))
  min   <- as.numeric(t(rr['min']))
  max   <- as.numeric(t(rr['max']))
  std   <- as.numeric(t(rr['std']))
  MB    <- as.numeric(t(rr['MB']))
  cols  <- 1:length(lat)

  # if users is defined then columns are the block sizes
  if ( i_users > 0 ) {
    titles <- bs 
    cat("users > 0, title are blocksises, titles=",titles,"\n") ;
  }
  # if block size is defined then columns are the user counts
  if ( i_bs != "undefined" ) {
    titles <- users
    cat("bs defined, title are users, title=",titles,"\n") ;
  }

  # create a layout with large squarish graph on top
  # for latency
  # shorter rectangle graph on bottom for MB/s
  nf <- layout(matrix(c(2,1),2,1,byrow = TRUE), widths = 13,
  heights = c(10, 3), respect = TRUE)
  par(mar=c(2, 4, 1, 4))
  layout.show(nf)
  par("pin")
  par(new = FALSE)

  MBbars <- t(t(fhist)*MB)
  colnames(MBbars) = titles

  op <- barplot(MBbars,col=colors,ylab="MB/s",border=NA,space=2)
  text(op, 0,MB,adj=c(0,0),cex=.75)

  par(mar=c(0, 4, 1, 4))

  xmaxwidth <- length(lat)+1
  xminwidth <- .5

  barcol <- "grey90"

  pts <- 1:nrow(thist)
  ylims <-   c(.025,5000)
  for (i in 1:ncol(thist)){
          xmin <-   -i + xminwidth 
          xmax <-   -i + xmaxwidth 
          ser <- as.numeric(thist[, i])
          ser <- ser/100 
          col=ifelse(ser==0,"white","grey") 
          bp <- barplot(ser, horiz = TRUE, axes = FALSE, 
                xlim = c(xmin, xmax), ylim = c(0,nrow(thist)), 
                border = NA, col = colors, space = 0, yaxt = "n")
          par(new = TRUE)
  }

  cat(" --> 1 \n") ;
  
  par(new = TRUE)
  # average latency 
  plot(cols, lat, type = "p", xaxs = "i", lty = 1, col = "black", lwd = 5, bty = "l", ylab = "ms", xlab="size",
       xlim = c(xminwidth,xmaxwidth), ylim = ylims,  log = "y", yaxt = "n" , xaxt ="n") 

  cat(" --> 2 \n") ;
  par(new = TRUE)
  # average latency 
  plot(cols, lat, type = "l", xaxs = "i", lty = 1, col = "black", lwd = 1, bty = "l", 
       xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
  text(cols,lat,round(lat,1),adj=c(1,2))


  # max latency 
  #par(new = TRUE)
  #plot(cols, max, type = "l", xaxs = "i", lty = 2, col = "red", lwd = 1, bty = "l", 
  #     xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , log = "y", xlab="",yaxt = "n" , xaxt ="n") 
  #text(cols,max,round(max,1),adj=c(-1,-1))

  # min latency 
  #par(new = TRUE)
  #plot(cols, pmax(min,0.1), type = "l", xaxs = "i", lty = 2, col = "green", lwd = 1, bty = "l", 
  #     xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , log = "y", yaxt = "n" , xlab="",xaxt ="n") 
  #text(cols,min,round(min,1),adj=c(-1,-1))


  ypts  <- c(.05,.100,.250,.500,1,2,4,10,20,50,100,200,500,1000,2000,5000) 
  ylbs=c("us50","us100","us250","us500","ms1","ms2","ms4","ms10","ms20","ms50","ms100","ms200","ms500","s1","s2","s5" )
  axis(4,at=ypts, labels=ylbs,las=1,cex.axis=.75,lty=0,lwd=0)

  ypts  <- c(.05,.250,.500,2,4,20,50,200,500,2000) 
  ylbs=c(".05",".25",".5","2","4","20","50","200","500","s2" )

  ypts  <-  c(0.100,    1,       10,    100,  1000, 5000);
  ylbs  <-  c("100u"   ,"1m",  "10m", "100m",  "1s","5s");
  axis(2,at=ypts, labels=ylbs)


  cat(" --> 3 \n") ;
  for ( i in  c(10)  )  {
     segments(0,   i, xmaxwidth,  i,  col="orange",   lwd=1,lty=2)
  }

  #for ( i in  c(.05,.100,.250,.500,1,2,4,10,20,50,100,200,500,1000,2000,5000)  )  {
  #    segments(0,   i, xmaxwidth,  i,    lwd=1,lty=2, col= "lightpink")
  # }

}


i_m <- matrix(c(
    "read",  1,  "8K",  28.299,    0.271, 0.1,       19,    0.5, 3622 , 0, 0,65,32, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
,    "read",  1, "32K",  56.731,    0.546, 0.2,      116,    1.5, 1815 , 0, 0, 1,68,27, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
,    "read",  1,"128K",  78.634,    1.585, 0.7,      146,    3.3,  629 , 0, 0, 0, 0,26,65, 2, 3, 1, 0, 0, 0, 0, 0, 0, 0
,    "read",  1,  "1M",  91.763,   10.890, 2.0,      121,    9.5,   91 , 0, 0, 0, 0, 0, 0,14,61,14, 8, 0, 0, 0, 0, 0, 0
,    "read",  8,  "1M",  50.784,  156.160,10.0,     1327,  222.9,   50 , 0, 0, 0, 0, 0, 0, 0, 0, 3,25,31,25, 8, 4, 2, 0
,    "read", 16,  "1M",  52.895,  296.290,13.0,     1359,  392.2,   52 , 0, 0, 0, 0, 0, 0, 0, 0, 2,24,23,19, 8,10,11, 0
,    "read", 32,  "1M",  55.120,  551.610,17.0,     1344,  507.5,   55 , 0, 0, 0, 0, 0, 0, 0, 0, 0,13,20, 7,14,12,30, 0
,    "read", 64,  "1M",  58.072, 1051.970,24.0,     2448,  481.5,   58 , 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 6, 2, 0,20,66, 0
,"randread",  1,  "8K",   0.176,   44.370, 0.0,      189,   37.7,   22 , 0, 0, 0, 1, 0, 0, 4, 2,15,42,20,10, 0, 0, 0, 0
,"randread",  8,  "8K",   2.763,   22.558, 0.6,      209,   21.6,  353 , 0, 0, 0, 0, 0, 0, 2,27,30,30, 6, 1, 0, 0, 0, 0
,"randread", 16,  "8K",   3.284,   37.708, 0.6,      672,   67.1,  420 , 0, 0, 0, 0, 0, 0, 2,23,28,27,11, 4, 1, 0, 0, 0
,"randread", 32,  "8K",   3.393,   73.070, 1.0,      754,  136.1,  434 , 0, 0, 0, 0, 0, 0, 1,20,24,25,12, 6, 4, 4, 0, 0
,"randread", 64,  "8K",   3.734,  131.950, 1.0,      817,  186.0,  478 , 0, 0, 0, 0, 0, 0, 1,17,16,18,11,14, 9, 9, 0, 0
,   "write",  1,  "1K",   2.588,    0.373, 0.1,       21,    0.4, 2650 , 0, 0,33,49,15, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
,   "write",  1,  "8K",  26.713,    0.289, 0.2,       33,    0.4, 3419 , 0, 0,49,48, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
,   "write",  1,"128K",  11.952,   10.451, 0.5,     2070,   86.3,   95 , 0, 0, 0, 0,51,12, 0,16, 7,10, 0, 0, 0, 0, 0, 0
,   "write",  4,  "1K",   6.684,    0.581, 0.2,       62,    0.9, 6844 , 0, 0,12,39,37, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
,   "write",  4,  "8K",  15.513,    2.003, 0.2,      118,    4.7, 1985 , 0, 0, 0,23,44,16, 1,10, 1, 0, 0, 0, 0, 0, 0, 0
,   "write",  4,"128K",  34.005,   14.647, 0.7,      251,   18.5,  272 , 0, 0, 0, 0, 0,15,18,13,25,22, 3, 0, 0, 0, 0, 0
,   "write", 16,  "1K",   7.939,    1.711, 0.2,     1114,   11.8, 8130 , 0, 0, 0, 6,38,44, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0
,   "write", 16,  "8K",  10.235,   12.177, 0.4,     1345,   66.9, 1310 , 0, 0, 0, 0, 5,33, 8,27,15, 5, 2, 0, 0, 0, 0, 0
,   "write", 16,"128K",  13.212,  150.080, 3.0,     2335,  363.1,  105 , 0, 0, 0, 0, 0, 0, 0, 0, 3,10,55,25, 0, 0, 0, 2
),nrow=25)

# graphit <- function(m,i_name="undefined",i_users=0,i_bs="undefined") {

graphit(i_m, i_name="randread", i_bs="8K")
