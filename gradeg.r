
 dir <- "C:\\Temp\\"
 file <- paste(dir,m$system[1],"_grade_",".png",sep="")
 ppi <- 300
 png(filename=file, width=6*ppi, height=6*ppi, res=ppi )
 chart_grades(m)  
 dev.off()
 chart_grades(m)  
