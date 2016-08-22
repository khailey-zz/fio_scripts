#!/usr/bin/python
#coding=gbk
import re,os,sys
from xlwt import *

wb = Workbook()
randread,read,write,randwrite={},{},{},{}

def style_set():
    fnt = Font()
    fnt.name = 'Arial'
    #fnt.colour_index = 2
    #fnt.bold = True
    #borders = Borders()
    borders.left = 1
    borders.right = 1
    borders.top = 1
    borders.bottom = 1
    al=Alignment()
    al.horz = Alignment.HORZ_CENTER
    al.vert = Alignment.VERT_CENTER
    style=XFStyle()
    style.font = fnt
    style.borders = borders
    style.alignment = al
    return style

def get_data():
    with open("out","r") as f:
        for i in f.readlines():
            other = [re.sub("\n","",i) for i in i.split(" ") if i ]
            if other[0].startswith("randread"):
                randread[other[2]] = other[4:]
            elif other[0].startswith("read"):
                read[other[2]] = other[4:]
            elif other[0].startswith("write"):
                write[other[2]] = other[4:]
            elif other[0].startswith("randwrite"):
                randwrite[other[2]] = other[4:]
            else:
                pass
    #print "randread: ",randread
    #print "-"*20
    #print "randwrite: ",randwrite
    #print "-"*20
    #print "write: ",write
    #print "-"*20
    #print "read: ",read


def generate_xls():
    ws = wb.add_sheet(u"性能测试结果")
    style = style_set()
    ws.write_merge(0,0,1,4,"randread",style)
    ws.write(1,1,"IOPS")
    ws.write(1,2,"MBPS")
    ws.write(1,3,"Average Response Time")
    ws.write(1,4,"Max Response Time")
    ws.write_merge(0,0,5,8,"read",style)
    ws.write(1,5,"IOPS")
    ws.write(1,6,"MBPS")
    ws.write(1,7,"Average Response Time")
    ws.write(1,8,"Max Response Time")
    ws.write_merge(0,0,9,12,"randwrite",style)
    ws.write(1,9,"IOPS")
    ws.write(1,10,"MBPS")
    ws.write(1,11,"Average Response Time")
    ws.write(1,12,"Max Response Time")
    ws.write_merge(0,0,13,16,"randwrite",style)
    ws.write(1,13,"IOPS")
    ws.write(1,14,"MBPS")
    ws.write(1,15,"Average Response Time")
    ws.write(1,16,"Max Response Time")
    ios = ["1K","2K","4K","8K","16K","32K","64K","128K","256K","512K","1M"]
    for i in range(2,13):
        #ios = randread.keys()
        key = ios[i-2]
        #import pdb
        #pdb.set_trace()
        ws.write(i,0,'%s'%key,style)
        ws.write(i,1,float(randread[key][5]))
        ws.write(i,2,float(randread[key][0]))
        ws.write(i,3,float(randread[key][2]))
        ws.write(i,4,float(randread[key][3]))
        ws.write(i,5,float(read[key][5]))
        ws.write(i,6,float(read[key][0]))
        ws.write(i,7,float(read[key][2]))
        ws.write(i,8,float(read[key][3]))
        ws.write(i,9,float(randwrite[key][5]))
        ws.write(i,10,float(randwrite[key][0]))
        ws.write(i,11,float(randwrite[key][2]))
        ws.write(i,12,float(randwrite[key][3]))
        ws.write(i,13,float(write[key][5]))
        ws.write(i,14,float(write[key][0]))
        ws.write(i,15,float(write[key][2]))
        ws.write(i,16,float(write[key][3]))
    wb.save("info.xls")

if __name__ == "__main__":
    get_data()
    generate_xls()

