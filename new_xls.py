#coding:gbk
import xlsxwriter
import re

wb = xlsxwriter.Workbook("test.xlsx")
ws = wb.add_worksheet()
randread,read,write,randwrite={},{},{},{}
title = ["100% Read; 100% random","100% Read; 0% random","0% Read; 100% random","0% Read; 0% random"]
item = ["IOPS","MBPS","Average(ms)","Max(ms)"] * 4
y_axis = ["1K","2K","4K","8K","16K","32K","64K","128K","256K","512K","1M"]

format=wb.add_format()    #定义format格式对象
format.set_border(1)    #定义format对象单元格边框加粗(1像素)的格式

format_title=wb.add_format()    #定义format_title格式对象
format_title.set_border(1)   #定义format_title对象单元格边框加粗(1像素)的格式
format_title.set_bg_color('#cccccc')   #定义format_title对象单元格背景颜色为
                                       #'#cccccc'的格式
format_title.set_align('center')    #定义format_title对象单元格居中对齐的格式
format_title.set_bold()    #定义format_title对象单元格内容加粗的格式
 
format_ave=wb.add_format()    #定义format_ave格式对象
format_ave.set_border(1)    #定义format_ave对象单元格边框加粗(1像素)的格式
format_ave.set_num_format('0.00') #定义format_ave对象单元格数字类别显示格式

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

def chart_series(letter):
    ss = ['B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q']
    chart = wb.add_chart({'type':'line'})
    chart.set_size({'width': 380, 'height': 287})    #设置图表大小
    chart.set_title ({'name': title[ss.index(letter)/4]})    #设置图表（上方）大标题
    chart.set_y_axis({'name': item[ss.index(letter)%4]})    #设置y轴（左侧）小标题
    chart.set_x_axis({'name': 'blocksize'})    #设置y轴（左侧）小标题
    chart.add_series({
        'categories': '=Sheet1!$A$3:$A$13',    #将“星期一至星期日”作为图表数据标签(X轴)
        'values':     '=Sheet1!$%s$3:$%s$13'%(letter,letter) ,   #频道一周所有数据作
                                                               #为数据区域
        'line':       {'color': 'green'},    #线条颜色定义为black(黑色)
        #'name': '=Sheet1!$A$'+cur_row,    #引用业务名称为图例项
    })
    return chart


def generate_data():
    ws.merge_range('B1:E1',title[0],format_title)
    ws.merge_range('F1:I1',title[1],format_title)
    ws.merge_range('J1:M1',title[2],format_title)
    ws.merge_range('N1:Q1',title[3],format_title)

    ws.write_column('A3',y_axis,format_title)
    ws.write_row('B2',item,format_title)

    get_data()

    for i in range(3,14):
        key = y_axis[i-3]
        x_axis = [ float(randread[key][j]) for j in [5,0,1,3] ]
        x_axis = x_axis + [ float(read[key][j]) for j in [5,0,1,3]]
        x_axis = x_axis + [ float(randwrite[key][j]) for j in [5,0,1,3]]
        x_axis = x_axis + [ float(write[key][j]) for j in [5,0,1,3]]
        ws.write_row('B%d'%i,x_axis,format)

def generate_chart():
    charts = []
    for letter in ['B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q']:
        chart = chart_series(letter)   
        charts.append(chart)
    for i in range(4):
        ws.insert_chart('A%d'%(16+15*i), charts[0+i])    #在A8单元格插
        ws.insert_chart('G%d'%(16+15*i), charts[4+i])    #在A8单元格插
        ws.insert_chart('M%d'%(16+15*i), charts[8+i])    #在A8单元格插
        ws.insert_chart('S%d'%(16+15*i), charts[12+i])    #在A8单元格插
    wb.close()

if __name__ == "__main__":
    generate_data()
    generate_chart()
