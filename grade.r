

grades <- function(base, scale, grade,fct)  {
  gscale <- matrix(c(.05,"A+", .1,"A", .2,"A-", .3,"B", .4,"B-", .6,"C", .9,"C-" ), nrow=2)
  gscale <- t(gscale) 
   # =========================== lat grades ======================
   base$grade95[ base$p95_00 < as.numeric(grade[1]) ] <- grade[1,2]
   base$grade99[ base$p99_00 < as.numeric(grade[1]) ] <- grade[1,2]
   base$gradeavg[ base$lat   < as.numeric(grade[1]) ] <- grade[1,2]
   for ( i in 2:nrow(grade) ) {
      base$grade95[ base$p95_00 < as.numeric(grade[i,1])   &  
                    base$p95_00 >= as.numeric(grade[i-1,1]) ] <-  grade[i,2]
      base$grade99[ base$p99_00 < as.numeric(grade[i,1])   &  
                    base$p99_00 >= as.numeric(grade[i-1,1]) ] <-  grade[i,2]
      base$gradeavg[ base$lat   < as.numeric(grade[i,1])   &  
                    base$lat    >= as.numeric(grade[i-1,1]) ] <-  grade[i,2]
   }
   base$grade95[ base$p95_00 > as.numeric(grade[nrow(grade),1]) ] <- "D"
   base$grade99[ base$p99_00 > as.numeric(grade[nrow(grade),1]) ] <- "D"
   base$gradeavg[ base$lat   > as.numeric(grade[nrow(grade),1]) ] <- "D"

  # =========================== scale grades ======================
  base$scalelat <- ((scale['lat']   /base['lat']   )-1)/fct
  base$scale95  <- ((scale['p95_00']/base['p95_00'])-1)/fct
  base$scale99  <- ((scale['p99_00']/base['p99_00'])-1)/fct

  base$gscale95[ base$scale95    <= as.numeric(gscale[1]) ] <- gscale[1,2]
  base$gscale99[ base$scale99    <= as.numeric(gscale[1]) ] <- gscale[1,2]
  base$gscaleavg[ base$scalelat  <= as.numeric(gscale[1]) ] <- gscale[1,2]
  for ( i in 2:nrow(gscale) ) {
    base$gscale95[ base$scale95 <= as.numeric(gscale[i,1])   &  
                   base$scale95 > as.numeric(gscale[i-1,1]) ] <-  gscale[i,2]
    base$gscale99[ base$scale99 <= as.numeric(gscale[i,1])   &  
                   base$scale99 > as.numeric(gscale[i-1,1]) ] <-  gscale[i,2]
    base$gscaleavg[ base$scalelat <= as.numeric(gscale[i,1]) &  
                   base$scalelat  > as.numeric(gscale[i-1,1]) ] <-  gscale[i,2]
  }
  base$gscale95[ base$scale95 > as.numeric(gscale[nrow(gscale),1]) ] <- "D"
  base$gscale99[ base$scale99 > as.numeric(gscale[nrow(gscale),1]) ] <- "D"
  base$gscaleavg[ base$scalelat   > as.numeric(gscale[nrow(gscale),1]) ] <- "D"

  print( cbind(base['gradeavg'],
      base['grade95'],
      base['grade99'],
      base['lat'],
      base['p95_00'],
      base['p99_00'],
      base$scalelat ,
      base$scale95  ,
      base$scale99   ,
      base$gscaleavg ,
      base$gscale95  ,
      base$gscale99   
   ))
   for ( i in 1:nrow(base) ) {
      cat(sprintf(" %-2s/%-2s %4.1f/%2.1f    %-2s/%-2s %4.1f/%2.1f    %-2s/%-2s %4.1f/%2.1f \n"
                   , base[i,'gradeavg'],base[i,'gscaleavg'], base[i,'lat']   ,as.numeric(base[i,'scalelat'])
                   , base[i,'grade95'] ,base[i,'gscale95'] , base[i,'p95_00'],as.numeric(base[i,'scale95'])
                   , base[i,'grade99'] ,base[i,'gscale99'] , base[i,'p99_00'],as.numeric(base[i,'scale99'])))
   }
   return(base)
}


chart_grades <- function(m)  {
  colors <- c(
            "#00007F", # 50u   1 dark blue
            "#0000BB", # 100u  2
            "#0000F7", # 250u  3 blue
            "#00ACFF", # 500u  4 light blue
            "#00E8FF", # 1ms   5
            "#25FFD9", # 2ms   6
            "#61FF9D", # 4ms   7 cyan
            "#9DFF61", # 10ms  8 light green
            "#FFE800", # 20ms  9 yellow
            "#FFAC00", # 50ms  10 dark yellow / orange
            "#FF7000", # 100ms 11 dark orang
            "#FF3400", # 250ms 12 red 1
            "#F70000", # 500ms 13 red 2
            "#BB0000", # 1s    14 dark red 1
            "#7F0000", # 2s    15 dark red 2
            "#4F0000") # 5s    16 dark red 2
   lcolors <- c(
            "#9999FF", # 1  violet
            "#66FFFF", # 2  aqau
            "#99FFFF", # 3  cyan
            "#B0FFB0", # 4  gren
            "#FFFF99", # 5  yello
            "#FFB090", # 7  orange
            "#FFA0B0"  # 7  orange
             )
   letters <- c(
            "A+",
            "A", 
            "A-",
            "B", 
            "B-",
            "C", 
            "C-" 
             )
  #
  #
  # setup GRADING SCALES
  #
  colnames <- c("lat", "grade" )
  gscale <- matrix(c(.05,"A+", .1,"A", .2,"A-", .3,"B", .4,"B-", .6,"C", .9,"C-" ), nrow=2)
  gscale <- t(gscale) 
  colnames(gscale)=colnames
  grr <- matrix(c(2,"A+",  4,"A",  6,"A-",  8,"B", 10,"B-", 12,"C", 14,"C-"), nrow=2)
  grr <- t(grr) 
  colnames(grr)=colnames
  gsr <- matrix(c( 12 ,  "A+" , 14 ,  "A", 16 ,  "A-", 18 ,  "B", 20 ,  "B-", 22 ,  "C", 24 ,  "C-" ), nrow=2)
  gsr <- t(gsr) 
  colnames(gsr)=colnames
  gw1 <- matrix(c( 0.2,"A+" , 0.5,"A", 1,"A-", 1.5,"B", 2,"B-", 2.5,"C", 3,"C-" ), nrow=2)
  gw1 <- t(gw1) 
  colnames(gw1)=colnames
  gw128 <- matrix(c( 2 ,  "A+" , 4 ,  "A", 6 ,  "A-", 8 ,  "B", 10 ,  "B-", 12 ,  "C", 14 ,  "C-" ), nrow=2)
  gw128 <- t(gw128) 
  colnames(gw128)=colnames
  #gm <- cbind(gw128,gw1,gsr,grr)
  #gm <- rbind(gw128,gw1,gsr,grr)
  # get all the latencies
  gm <- cbind(gw128[,1],gw1[,1],gsr[,1],grr[,1])
  gmc <- rbind(colors[1],colors[3],colors[4],colors[7],colors[8],colors[9],colors[10])
  gmc <- rbind(lcolors[1],lcolors[2],lcolors[3],lcolors[4],lcolors[5],lcolors[6],lcolors[7])
  
  #
  #  EXTRACT data sets: RANDOM READ, SEQUENTIAL READ, WRITE 1K, WRITE 128K
  #
  rr8      <- subset(m,m['name'] == "randread" & m['users'] == 8 )
  rr16     <- subset(m,m['name'] == "randread" & m['users'] == 16 )
  rr32     <- subset(m,m['name'] == "randread" & m['users'] == 32 )
  #
  sr1      <- subset(m,m['name'] == "read"     & m['users'] == 1  & m['bs'] == "1M" )
  sr8      <- subset(m,m['name'] == "read"     & m['users'] == 8  & m['bs'] == "1M" )
  sr16     <- subset(m,m['name'] == "read"     & m['users'] == 16 & m['bs'] == "1M" )
  #
  w1k_1    <- subset(m,m['name'] == "write"    & m['users'] == 1  & m['bs'] == "1K" )
  w1k_4    <- subset(m,m['name'] == "write"    & m['users'] == 4  & m['bs'] == "1K" )
  w1k_16   <- subset(m,m['name'] == "write"    & m['users'] == 16 & m['bs'] == "1K" )
  #
  w128k_1  <- subset(m,m['name'] == "write"    & m['users'] == 4  & m['bs'] == "128K" )
  w128k_4  <- subset(m,m['name'] == "write"    & m['users'] == 4  & m['bs'] == "128K" )
  w128k_16 <- subset(m,m['name'] == "write"    & m['users'] == 16 & m['bs'] == "128K" )
  #
  # CALCULATE GRADES based on latency data
  # 
  rr <- grades(rr16,rr32,grr,2)
  rr$system = "randread 16 users"
  sr <- grades(sr1,sr8,gsr,8)
  sr$system = "seq read 1 users"
  w1 <-grades(w1k_4,w1k_16,gw1,4)
  w1$system = "write 1k 4 users"
  w128 <- grades(w128k_4,w128k_16,gw128,4)
  w128$system = "write 128k 4 users"
  #
  # CREATE dataset with GRADES and DATA from
  #                  from   RANDOM READ, SEQUENTIAL READ, WRITE 1K, WRITE 128K
  #
  mold <- m
  m <- rbind(w128,w1,sr,rr)
  #
  #  EXTRACT HISTOGRAMS
  #
  hist <- cbind(m['us50'],m['us100'], m['us250'],m['us500'],m['ms1'],
               m['ms2'],m['ms4'],m['ms10'],m['ms20'],m['ms50'],
               m['ms100'],m['ms250'],m['ms500'],m['s1'],m['s2'],m['s5']) 
  thist  <- t(hist)

  #
  # Set Height and Width of Graphs
  #
  ymaxwidth <- ncol(thist)  + 2
  yminwidth <- 1
  #xwidth <- nrow(thist) + 2
  xwidth <- nrow(thist) 
  #xwidth <- nrow(thist)  + 7
  xwidthg <- 2*xwidth + 5
  xwidth <- 2*xwidth + 9

  #
  #  CHART LAYOUT
  #
  nf <- layout(matrix(c(1:1)), widths = 10 , heights=10, respect = TRUE)
  #
  # left hand lables, the name of the tests, ie 
  #                  from   RANDOM READ, SEQUENTIAL READ, WRITE 1K, WRITE 128K
  #
  ylbs=as.character(m$system)
  #
  #  set margines 
  #         B  L  T  R
  par(mar=c(4, 1, 2, 6))

  #
  # GRAPHS 
  #
  background = thist*0+.98
  background = thist*0+.01
  zeros = thist*0
  cat(background)
  cat(" \n")

  for (i in 1:(ncol(thist)) ){
        ymin <-   -i + yminwidth - i*0.05
        ymax <-   -i + ymaxwidth  
        ser  <- as.numeric(thist[, i])
        back <- as.numeric(background[, i])
        zero <- as.numeric(zeros[, i])
        ser <- ser/130 

     #
     #  right side grey line
     # 
     #    sets up the plot
     #   
         bp <- barplot(c(zeros,back), horiz = FALSE, axes = TRUE,
               xlim = c(0, xwidth), ylim = c(ymin,ymax), 
               border=NA,
               col = "gray50", space = 0, yaxt = "n"  )

     # right side second set
     #
     #   middle latency graph
     #
        par(new = TRUE)
        if ( i < 5 ) {
         #
         #  color ribbon on bottom of chart
         #
         # there are 7 grades, A+,A,A-,B,B-,C,C- 
         # for each draw the coresponding color at the bottom of graph
         for ( j in 7:1  ) {
           latg=as.numeric(gm[j,(i)])
           #x=(log10(latg)*3)-4
           x1=x4=nrow(thist)+1
           x2=x3=nrow(thist)+j*2+1
           y1=y2=.1
           y3=y4=.2
           polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col=gmc[j],border=NA)
           text((x2-1),y1,latg,adj=c(0,1),col="gray60",cex=.5)
        }
      #
      #  95% line in middle graph, latency grade graph
      #
        lati=m$p95_00[i];
        delta=as.numeric(gm[7,(i)])-as.numeric(gm[6,(i)])
        min=as.numeric(gm[1,(i)])
        max=as.numeric(gm[7,(i)])
          cat("i ",i," ")
          cat("lati ",lati," ")
          cat("delta ",delta," ")
          cat("min ",min," ")
          cat("max ",max," ")
        color="black"
        if ( lati > max  ) { 
           lati = 14 ; 
           color = "red" 
        } else {
           lati=(2*(lati-min+delta))/delta 
           coltext=gmc[ceiling(lati/2)]
        }
        cat("lati ",lati,"\n")
        if ( lati < 0  )   { lati = 0 ; color="blue"}
        x1=x4=lati +     nrow(thist) +1
        x2=x3=lati + .4 +nrow(thist) +1
        y1=y2=.1
        y3=y4=.3
        #
        # latency line in middle graph
        #
        polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col=color,border=NA)

        # latency = gradex
        gradex=sprintf("%4.1f",  m[i,'p95_00'] )
        text((x2-1),(y1+.4),gradex,adj=c(0,1),col="gray60",cex=1)

        # letter grade
        text((x2-1),y1+.6,m$grade95[i],adj=c(0,1),col="gray20",cex=1,font=2)
        if ( color == "red" ) {
           arrows(14+nrow(thist),.2,15+nrow(thist),.2,col=color, length=.1)
        }
        #text(nrow(thist),.8 ,m$system[i],adj=c(.5,0),col="gray20",cex=1, font=2)
        text(7,.8 ,m$system[i],adj=c(.5,0),col="gray20",cex=1, font=2)
       }
        text(nrow(thist)+6,.8 ,"latency grade",adj=c(.5,0),col="gray20",cex=1, font=1)
        text(nrow(thist)+22,.8 ,"scale grade",adj=c(.5,0),col="gray20",cex=.75, font=1)

      #
      #  avg latency line in middle graph, latency grade graph
      #
        lati=m$lat[i];
        delta=as.numeric(gm[7,(i)])-as.numeric(gm[6,(i)])
        min=as.numeric(gm[1,(i)])
        max=as.numeric(gm[7,(i)])
        color="green"
        if ( lati > max  ) { 
           lati = 14 ; 
        } else {
           lati=(2*(lati-min+delta))/delta 
           coltext=gmc[ceiling(lati/2)]
        }
        if ( lati < 0  )   { lati = 0 }
        x1=x4=lati +     nrow(thist) +1
        x2=x3=lati + .4 +nrow(thist) +1
        y1=y2=.1
        y3=y4=.3
        polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col=color,border=NA)

     # left side backgrounds in histogram rainbow measure tape
     # 7 rows in grades, A+,A,A-,B,B-,C,C- , and column for each type which is 4 now
        if ( i < 5 ) {
         for ( j in 7:1  ) {
           latg=as.numeric(gm[j,(i)])*1000
           x=(log10(latg)*3)-4
           x1=x4=0
           x2=x3=x
           y1=y2=-0.05
           y3=y4=0
           polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col=gmc[j],border=NA)
        }
       }

       #
       #  HISTOGRAMS
       #
        par(new = TRUE)
        bp <- barplot(c(ser,zero), horiz = FALSE, axes = TRUE,
              xlim = c(0, xwidth), ylim = c(ymin,ymax), 
              border=NA,
               col = "gray40", space = 0, yaxt = "n"  )
              # col = colors, space = 0, yaxt = "n"  )
       #
       #  95% line over Histograms, black
       #    Avg line over Histograms, green
       #
        if ( i < 5 ) {
          lata=m$lat[i]*1000;
          xa=(log10(lata)*3)-4
          lat95=m$p95_00[i]*1000;
          x95=(log10(lat95)*3)-4
          x1=x4=xa
          x2=x3=xa-.1
          #y1=y2=0
          #y3=y4=-.05
          y1=y2=.75
          y3=y4=-.05
        # Avg line over Histograms, green
          polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col="green",border=NA)
          x1=x4=x95 
          x2=x3=x95 -.1
        # 95% line over Histograms, black
          polygon(c(x1,x2,x3,x4),c(y1,y2,y3,y4), col="black",border=NA)
        }
        par(new = TRUE)
  }


  #
  #  NULL PLOT, but resets the boundaries, so following commands plot in the correct location
  #
    bp <- barplot(0, horiz = FALSE, axes = TRUE,
               xlim = c(0, xwidth), ylim = c(yminwidth,ymaxwidth), 
               border=NA,
               col = colors, space = 0, yaxt = "n"  )
  #
  #  X labels
  #
  xlbs=c("us50","us100","us250","us500","ms1","ms2","ms4","ms10","ms20","ms50","ms100","ms200","ms500","s1","s2","s5" )
  for ( j in 1:length(xlbs) ) {
     axis(1,at=j, labels=xlbs[j],col="gray60",las=2,cex.axis=.75,lty=1,lwd=1)
  }
  #
  # left hand y axis labels
  #
  #
  #  GRADE STRING ex  "A/A 99.9/0.9"
  #
  grade <- rep(NA,(nrow(m)-1) )
  for ( i in 1:nrow(m) ) {
     grade[i]= sprintf(" %-2s/%-2s %4.1f/%2.1f    ",  
          m[i,'grade95'],m[i,'gscale95'],  m[i,'p95_00'],as.numeric(m[i,'scale95']))
  }

  #
  #  SCALING WIDGET
  #
  x1 =xwidthg-1.75  +1.5
  x2 =xwidthg+.25 +1.5
  x1 =xwidthg-2 +1.5
  x2 =xwidthg+1 +1.5
  for ( j in 1:(nrow(m)) ) {
     y1 = j 
     y2 = j+.05
     y1 = j+.1
     y2 = j+.15
     scale=as.numeric(m$scale95[j,])
     scalecolors = c("#A0F0A0" ,  #  1  A+
                  "#A0C060" ,    #  2  A 
                  "#A0A060" ,    #  3  A-
                  "#A08080" ,    #  4  B 
                  "#A06060" ,    #  5  B-
                  "#A03060" ,    #  6  C
                  "#A00060"      #  7  C-
                     )
     col = scalecolors[1]
     if ( scale > gscale[1,1] ) { col =scalecolors[2]} #.05 - .1   A
     if ( scale > gscale[2,1] ) { col =scalecolors[3]} # .1 - .2   A-
     if ( scale > gscale[3,1] ) { col =scalecolors[4]} # .2 - .3   B
     if ( scale > gscale[4,1] ) { col =scalecolors[5]} # .3 - .4   B-
     if ( scale > gscale[5,1] ) { col =scalecolors[6]} # .4 - .6   C
     if ( scale > gscale[6,1] ) { col =scalecolors[7]}   # .6 - .9
     if ( scale > gscale[7,1] ) { col ="red"}   # .6 - .9
     if ( scale > 1 ) { col ="red"} 

     # if scale less than 1, move left down and right up
     if (scale <= 1 ) {
       scale=scale/2
       polygon(c(x1,x2,x2,x1),c(y1,y1,y2+scale,y1), col=col,border=NA)

     # if scale more than 1, move left to the right and right up
     } else {
       scale = 1 - (1 /(scale) )
       #polygon(c(x1+scale,x2,x2,x2-scale),c(y1,y1,y2,y2), col=col,border=NA)
       polygon(c(x1+scale,x2,x2,x1),c(y1,y1,y2+.25,y1), col=col,border=NA)
     }

     scale=round(as.numeric(m$scale95[j,]),2)
     text((x1+.1),y1+.2,scale,        adj=c(-.0,1),col="gray60",cex=1)
     text((x1+.1),y1+.5,m$gscale95[j],adj=c(-.3,1),col="gray60",cex=1)
  }


  #
  #  GRAPH borders for all graphs
  #
  x=1
  onegraph=ymaxwidth/4
  cat("onegraph ",onegraph,"\n")
  for ( j in 1:length(xlbs) ) {
     x=x+1
     if ( x%%3 == 0  )  {
       colors=colors[j]
       colors="gray70"
       #segments(j,   1,           j,    2,    lwd=1,lty=1, col= colors[j])
       #segments(j,   2.1,           j,   3.1,    lwd=1,lty=1, col= colors[j])
       segments(j,   1,           j,   1.8,    lwd=1,lty=3, col= colors)
       polygon(c(0,nrow(thist),nrow(thist),0),
               c(1,1,1.8,1.8),lwd=1,lty=1, col= "gray30", density=0)
       segments(j,   2.02,           j,   2.8,    lwd=1,lty=3, col= colors)
       polygon(c(0,nrow(thist),nrow(thist),0),
               c(2.02,2.02,2.8,2.8),lwd=1,lty=1, col= "gray30", density=0)
       segments(j,   3.04,           j,   3.8,    lwd=1,lty=3, col= colors)
       polygon(c(0,nrow(thist),nrow(thist),0),
               c(3.04,3.04,3.8,3.8),lwd=1,lty=1, col= "gray30", density=0)
       segments(j,   4.05,           j,   4.8,    lwd=1,lty=3, col= colors)
       polygon(c(0,nrow(thist),nrow(thist),0),
               c(4.05,4.05,4.8,4.8),lwd=1,lty=1, col= "gray30", density=0)
       #segments(j,   -.5+onegraph,    j,  2*onegraph -.2 ,    lwd=1,lty=1, col= colors[j])
       #segments(j,   .5+2*onegraph,  j,  3*onegraph -.2 ,    lwd=1,lty=1, col= colors[j])
       #segments(j,   .51+3*onegraph,  j,  4*onegraph -.2 ,    lwd=1,lty=1, col= colors[j])
       beg=nrow(thist)+1
       end=2*nrow(thist)+1
       polygon(c(beg,end,end,beg),
               c(1,1,1.8,1.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(2.02,2.02,2.8,2.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(3.04,3.04,3.8,3.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(4.05,4.05,4.8,4.8),lwd=1,lty=1, col= "gray30", density=0)
       beg=2*nrow(thist)+3 +1.2
       end=2*nrow(thist)+6.5 +1.2
       polygon(c(beg,end,end,beg),
               c(1,1,1.8,1.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(2.02,2.02,2.8,2.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(3.04,3.04,3.8,3.8),lwd=1,lty=1, col= "gray30", density=0)
       polygon(c(beg,end,end,beg),
               c(4.05,4.05,4.8,4.8),lwd=1,lty=1, col= "gray30", density=0)
     }
  }

  #
  #  Scaling grades on the right
  #
  if ( 1 == 1 ) {
       ybeg=1
       yend=1.1
       ybegl=1
       yendl=1.1
       i=1
       # gscale <- matrix(c(.05,"A+", .1,"A", .2,"A-", .3,"B", .4,"B-", .6,"C", .9,"C-" ), nrow=2)
       #for ( col in c( "#A0F0A0", "#A0C060" , "#A0A060" , "#A05060" , "#A03060" , "#A00060" ) ) {
       # }
       for ( col in  scalecolors ) {
         cat("col ", col , "\n")
         xbeg=xwidth -.5 
         xend=xwidth+.5
         ybeg=ybeg+.1
         yend=yend+.1
         polygon(c(xbeg,xend,xend,xbeg), c(ybeg,ybeg,yend,yend), lwd=1,lty=1, col=col, border=NA)
         text(xend+.5,ybeg+.05,letters[i],adj=c(0,0),col="gray10",cex=.5)
         xbeg=xwidth-6
         xend=xwidth-7.5
         ybegl=ybegl+.1
         yendl=yendl+.1
         polygon(c(xbeg,xend,xend,xbeg), c(ybegl,ybegl,yendl,yendl), lwd=1,lty=1, col=lcolors[i], border=NA)
         text(xend+1.5,ybegl+.05,letters[i],adj=c(0,0),col="gray10",cex=.5)
         i=i+1
       }
       text(xwidth/2,5.3,mold[1,1],adj=c(0,0),col="gray10",cex=1,font=2)
  }

  
}

 # m <- read.csv("data_emc.csv") 
 #  chart_grades(m)  


