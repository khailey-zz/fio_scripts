

# cd to the fio scripts directory 

 source("fio.r")

# load up data

 m <- read.csv("data_colorado.csv") 
  
# set test name

 testtype = "colorado" 

# generate graphs

 source('fiop.r')
 source('fiopg.r')

# generte report cards

 source('grade.r')
 chart_grades(m) 


Files

   fio.r  - graphs just avg,95,99.5,99 and max in one set
                   and histograms in another set
                   no scaling 
   fiog.r 

   fiop.r  - graphs histograms nad 95% and 99% in one graph
   fiopg.r

   grade.r
   gradeg.r - generates grades for many different datasets
   gradeonly.r -  only  generate the grades, no graph ?


