

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

   old version

     fio.r   - creates  graphit(), no scaling 
     fiog.r  - for a given m, graphs 2 sets
               graphs avg,95,99.5,99 and max in one set
                      and histograms in another set

   new version

     fiop.r  - creates graphit()
     fiopg.r - has scaling graph as well

   report card

     grade.r    creates chart_grades()
     gradeg.r - generates grades for many different datasets
     gradeonly.r -  only  generate the grades, no graph ?

graphit() has many options thus the "g" files are used
          to iterate through many options

chart_grades() has no options so can be run as chart_grades(m)






