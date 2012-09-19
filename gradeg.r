
 dir <- "C:\\Temp\\"

 m <- read.csv("data_emc.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()


 m <- read.csv("data_pg8.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_pg512.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_ssd.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_skytap.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_dtv.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_pharos.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("ptsmt.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_mlna.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_phs.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file)
 chart_grades(m)  
 dev.off()

