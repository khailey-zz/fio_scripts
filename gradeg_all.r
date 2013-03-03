
 ppi <- 300
 dir <- "C:\\Temp\\"

 m <- read.csv("data_affi_50GB120sec.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_affi_50GB60sec.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_affi_5GB120sec.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_affi_66GB60sec_cooked.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_colorado.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_dtv.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_emc.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_gap.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_mlna.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_pg8.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_pg512.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_pharos.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_phs.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_ptsmt.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_nyl.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_skytap.csv") 
 m <- read.csv("data_ssd.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_skytap.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

 m <- read.csv("data_tjx.csv") 
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()

