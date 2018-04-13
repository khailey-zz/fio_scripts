测试工具说明：
现在主流的I/O性能分析软件有：IOZone、Bonnie++、FIO前面两个支持以图形化方式呈现测试结果，
而FIO不直接支持图形化呈现但是凭借测试参数完全自定义化从而成为了社区最热门的I/O测试软件;

这里提供的测试方法原理是先使用FIO测试工具搜集I/O性能的信息，该过程由测试脚本自动完成，
然后将搜集到的所有I/O性能信息通过R分析软件（功能类似商业软件Matlab）生成可视化的图形；


约束与限制：
    1. 由于不同版本的fio输出的测试报告格式不统一，因此该工具只支持fio-2.0.7版本
    2. 依赖fio、Rscript命令，默认提供了fio 2.0.7工具，位于fio_scripts/fio
    3. 一次只能对一个对象进行测试，对象可以是块设备文件、普通文件
    4. 测试报告默认保存在./output目录，包含read、write、randread、randwrite、CSV
    5. 整个测试过程大约需要花费4个小时时间，请保持电源正常供电
    
Example:
    # sudo apt-get install r-base
    # ./fio.sh -f /dev/sdb -m 10240 -d -n myssd
    # tar czvf myssd.tar.gz output/
    

参考：
https://sites.google.com/site/oraclemonitor/i-o-graphics#TOC-Percentile-Latency
https://github.com/khailey/fio_scripts
