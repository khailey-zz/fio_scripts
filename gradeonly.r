

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


grade_only <- function(m)  {
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
  print(m)
  #cat(m,"\n"); 
  #cat(thist,"\n"); 

}

 m <- read.csv("data_colorado.csv") 
 grade_only(m)  

