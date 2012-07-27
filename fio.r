


graphit <- function(m,i_name="undefined",i_users=0,i_bs="undefined", i_title="default title",i_hist=1,i_poly=1) {

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
    p95_00 <- as.numeric(t(rr['p95_00']))
    p99_00 <- as.numeric(t(rr['p99_00']))
    p99_50 <- as.numeric(t(rr['p99_50']))
    p99_90 <- as.numeric(t(rr['p99_90']))
    p99_95 <- as.numeric(t(rr['p99_95']))
    p99_99 <- as.numeric(t(rr['p99_90']))
    cols  <- 1:length(lat)

  # if users is defined then columns are the block sizes
    if ( i_users > 0 ) {
      col_lables <- bs 
      cat("users > 0, title are blocksises, col_lables=",col_lables,"\n") ;
    }
  # if block size is defined then columns are the user counts
    if ( i_bs != "undefined" ) {
      col_lables <- users
      cat("bs defined, title are users, title=",col_lables,"\n") ;
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

  # draw the MB/s bars in bottom graph
     MBbars <- t(t(fhist)*MB)
     colnames(MBbars) = col_lables
     op <- barplot(MBbars,col=colors,ylab="MB/s",border=NA,space=2)
     text(op, 0,MB,adj=c(-1,0),cex=.75)
  # reset the margins to the default
     par(mar=c(0, 4, 1, 4))

  # widths used for overlaying the histograms
    xmaxwidth <- length(lat)+1
    xminwidth <- .5
    pts <- 1:nrow(thist)
    ylims <-   c(.025,5000)

  # average latency  line
    plot(cols, lat, type = "l", xaxs = "i", lty = 2, col = "black", lwd = 1, bty = "l", 
       xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
    text(cols,lat,round(lat,1),adj=c(1,2))
    title(main=i_title)

 # polygons showing the 95%, 99%, 99.99%  curves
   if ( i_poly == 1 ) {
     polygon(c(cols,rev(cols)),c(   lat,rev(p95_00)), col="gray80",border=NA)
     polygon(c(cols,rev(cols)),c(p95_00,rev(p99_00)), col="gray90",border=NA)
     polygon(c(cols,rev(cols)),c(p99_00,rev(p99_99)), col="gray95",border=NA)
   }

 # plotting histograms over line graphs
    if ( i_hist == 1 ) {
      par(new = TRUE )
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
    }

  # average latency  point
    #par(new = TRUE)
    #plot(cols, lat, type = "p", xaxs = "i", lty = 1, col = "black", lwd = 5, bty = "l", ylab = "ms", xlab="size",
    #     xlim = c(xminwidth,xmaxwidth), ylim = ylims,  log = "y", yaxt = "n" , xaxt ="n") 

  # average latency  line
    par(new = TRUE)
    plot(cols, lat, type = "l", xaxs = "i", lty = 1, col = "gray30", lwd = 1, bty = "l", 
         xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
    text(cols,lat,round(lat,1),adj=c(1,2))
    # title(main=i_title)

  # line types , lty,  5, 2, 3 from most complete to least

  # 95% latency 
    par(new = TRUE)
    plot(cols, p95_00, type = "l", xaxs = "i", lty = 5, col = "grey40", lwd = 1, bty = "l", 
       xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
    #text(cols,p95_00,round(p95_00,1),adj=c(0,0),col="gray70")
    text(tail(cols,n=1),tail(p95_00, n=1),"95%",adj=c(0,0),col="gray20",cex=.7)

  # 99% latency 
    par(new = TRUE)
    plot(cols, p99_00, type = "l", xaxs = "i", lty = 2, col = "grey60", lwd = 1, bty = "l", 
         xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
    #text(cols,p99_00,round(p99_00,1),adj=c(0,0),col="gray70")
    text(tail(cols,n=1),tail(p99_00, n=1),"99%",adj=c(0,0),col="gray20",cex=.7)

  # 99.99% latency 
    par(new = TRUE)
    plot(cols, p99_99, type = "l", xaxs = "i", lty = 3, col = "grey70", lwd = 1, bty = "l", 
        xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , xlab="",log = "y", yaxt = "n" , xaxt ="n") 
    text(cols,p99_99,round(p99_99,0),adj=c(1,0),col="gray70")
    text(tail(cols,n=1),tail(p99_99, n=1),"99.99%",adj=c(0,0),col="gray20",cex=.7)

  # max latency 
    par(new = TRUE)
    plot(cols, max, type = "l", xaxs = "i", lty = 3, col = "red", lwd = 1, bty = "l", 
       xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , log = "y", xlab="",yaxt = "n" , xaxt ="n") 
    text(cols,max,round(max,1),adj=c(1,-1))

  # min latency 
    #par(new = TRUE)
    #plot(cols, pmax(min,0.1), type = "l", xaxs = "i", lty = 2, col = "green", lwd = 1, bty = "l", 
    #     xlim = c(xminwidth,xmaxwidth), ylim = ylims, ylab = "" , log = "y", yaxt = "n" , xlab="",xaxt ="n") 
    #text(cols,min,round(min,1),adj=c(-1,-1))

  # right hand tick lables
    if ( i_hist == 1 ) {
      ypts  <- c(.05,.100,.250,.500,1,2,4,10,20,50,100,200,500,1000,2000,5000) 
      ylbs=c("us50","us100","us250","us500","ms1","ms2","ms4","ms10","ms20","ms50","ms100","ms200","ms500","s1","s2","s5" )
      #axis(4,at=ypts, labels=ylbs,las=1,cex.axis=.75,lty=0,lwd=0)
      for ( j in 1:length(ypts) ) {
         axis(4,at=ypts[j], labels=ylbs[j],col=colors[j],las=1,cex.axis=.75,lty=1,lwd=5)
      }
   }

  # left hand tick lables
    ypts  <-  c(0.100,    1,       10,    100,  1000, 5000);
    ylbs  <-  c("100u"   ,"1m",  "10m", "100m",  "1s","5s");
    axis(2,at=ypts, labels=ylbs)

  # reference dashed line at 10ms
    for ( i in  c(10)  )  {
     segments(0,   i, xmaxwidth,  i,  col="orange",   lwd=1,lty=2)
    }

  # reference dashed lines for all thie histogram buckets
     #j=1
     #for ( i in  c(.05,.100,.250,.500,1,2,4,10,20,50,100,200,500,1000,2000,5000)  )  {
     #    #cat("colors[",j,"] =",colors[j],"\n")
     #    segments(0,   i, xmaxwidth,  i,    lwd=4,lty=2, col= colors[j])
     #    j = j + 1
     #}

}

