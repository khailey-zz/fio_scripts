#coding:gbk
import xlsxwriter
import re

wb = xlsxwriter.Workbook("test.xlsx")
ws = wb.add_worksheet()
randread,read,write,randwrite={},{},{},{}
title = ["100% Read; 100% random","100% Read; 0% random","0% Read; 100% random","0% Read; 0% random"]
item = ["IOPS","MBPS","Average(ms)","Max(ms)"] * 4
y_axis = ["1K","2K","4K","8K","16K","32K","64K","128K","256K","512K","1M"]

format=wb.add_format()    #����format��ʽ����
format.set_border(1)    #����format����Ԫ��߿�Ӵ�(1����)�ĸ�ʽ

format_title=wb.add_format()    #����format_title��ʽ����
format_title.set_border(1)   #����format_title����Ԫ��߿�Ӵ�(1����)�ĸ�ʽ
format_title.set_bg_color('#cccccc')   #����format_title����Ԫ�񱳾���ɫΪ
                                       #'#cccccc'�ĸ�ʽ
format_title.set_align('center')    #����format_title����Ԫ����ж���ĸ�ʽ
format_title.set_bold()    #����format_title����Ԫ�����ݼӴֵĸ�ʽ
 
format_ave=wb.add_format()    #����format_ave��ʽ����
format_ave.set_border(1)    #����format_ave����Ԫ��߿�Ӵ�(1����)�ĸ�ʽ
format_ave.set_num_format('0.00') #����format_ave����Ԫ�����������ʾ��ʽ

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
    chart.set_size({'width': 380, 'height': 287})    #����ͼ���С
    chart.set_title ({'name': title[ss.index(letter)/4]})    #����ͼ���Ϸ��������
    chart.set_y_axis({'name': item[ss.index(letter)%4]})    #����y�ᣨ��ࣩС����
    chart.set_x_axis({'name': 'blocksize'})    #����y�ᣨ��ࣩС����
    chart.add_series({
        'categories': '=Sheet1!$A$3:$A$13',    #��������һ�������ա���Ϊͼ�����ݱ�ǩ(X��)
        'values':     '=Sheet1!$%s$3:$%s$13'%(letter,letter) ,   #Ƶ��һ������������
                                                               #Ϊ��������
        'line':       {'color': 'green'},    #������ɫ����Ϊblack(��ɫ)
        #'name': '=Sheet1!$A$'+cur_row,    #����ҵ������Ϊͼ����
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
        ws.insert_chart('A%d'%(16+15*i), charts[0+i])    #��A8��Ԫ���
        ws.insert_chart('G%d'%(16+15*i), charts[4+i])    #��A8��Ԫ���
        ws.insert_chart('M%d'%(16+15*i), charts[8+i])    #��A8��Ԫ���
        ws.insert_chart('S%d'%(16+15*i), charts[12+i])    #��A8��Ԫ���
    wb.close()

if __name__ == "__main__":
    generate_data()
    generate_chart()
