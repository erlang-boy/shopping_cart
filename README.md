# 购物车

## 一、 项目说明：

考虑到查看笔试的面试官，手头没有erlang的环境，所以将项目编译为一个脚本的形式，脚本的名字叫 **ShoppingCart** 。

## 二、脚本的使用方式：
linux 环境下执行

```
    cd tests; ./ShoppingCart -c goods.config input.txt
```

goods.config为配置文件，内容如下：

```
    lhd@lhd:~/workspace/mypro/worktest/shoppingcart/tests$ cat goods.config 
    %% -*- coding: utf-8 -*-
    
    {<<"电子"/utf8>>, [<<"ipad">>,<<"iphone">>,<<"显示器"/utf8>>,<<"笔记本电脑"/utf8>>,<<"键盘"/utf8>>]}.
    {<<"食品"/utf8>>, [<<"面包"/utf8>>,<<"饼干"/utf8>>,<<"蛋糕"/utf8>>,<<"牛肉"/utf8>>,<<"鱼"/utf8>>, <<"蔬菜"/utf8>>]}.
    {<<"日用品"/utf8>>, [<<"餐巾纸"/utf8>>,<<"收纳箱"/utf8>>,<<"咖啡杯"/utf8>>,<<"雨伞"/utf8>>]}.
    {<<"酒类"/utf8>>, [<<"啤酒"/utf8>>,<<"白酒"/utf8>>,<<"伏特加"/utf8>>]}.
```

input.txt为输入的文件，内容如下：

```
    lhd@lhd:~/workspace/mypro/worktest/shoppingcart/tests$ cat input.txt 
    2013.11.12 | 0.8 | 电子
    2013.11.13 | 1 | 电子
    s
    
    1 * ipad : 2399.00
    1 * 显示器 : 1799.00
    12 * 啤酒 : 25.00
    5 * 面包 : 9.00
    
    2013.11.13
    2014.3.2 1000 200
```

goods.config和input.txt编码格式为utf8，其他格式可能有问题(erlang对中文的支持不是很好)

程序的帮助信息

```
    lhd@lhd:~/workspace/mypro/worktest/shoppingcart/tests$ ./ShoppingCart 
    Usage: ./ShoppingCart [-?] [-c <config>] [-v <verbose>] [<input_file>]
    
      -?, --help     Show the program options
      -c, --config   config file
      -v, --verbose  Verbosity level
      <input_file>   input file
```

## 三、自动化测试脚本
由于生成的是脚本，通过文件中内容的更换，可以很容易的进行测试，当然这只是手工测试，
此处简单的写了个脚本进行，

``` 
    lhd@lhd:~/workspace/mypro/worktest/shoppingcart/tests$ cat autotest.sh 
    #! /bin/bash
    
    ./ShoppingCart -c goods.config input.txt
    ./ShoppingCart -c goods.config input2.txt
    ./ShoppingCart -c goods.config input3.txt
    ./ShoppingCart -c goods.config input4.txt
    ./ShoppingCart -c goods.config input5.txt
    
    lhd@lhd:~/workspace/mypro/worktest/shoppingcart/tests$ ./autotest.sh 
    Sum: 3083.60
    Sum: 43.54
    no balance date
    Sum: 4343.00
    "bad format in inputfile"

```  
    
input4：

     2013.11.13 | 0.7 | 电子
     2013.11.12 | 0.7 | 电子
     
     1 * ipad : 2399.00
     1 * 显示器 : 1799.00
     12 * 啤酒 : 25.00
     5 * 面包 : 9.00
     
     2013.11.11
     2014.3.2 1000 200 
         
这种情况下，按照结算日期对应的来计算，不算格式错误


## 程序简要说明

程序中用了大量的尾递归，去解析文本文件。erlang不太期望用try catch这种结构，除非必要。

##### Author(s)

* liu.huidong <liuhd@mycomm.cn>

##### Copyright

Copyright (c) 2015 liu.huidong <liuhd@mycomm.cn>.  All rights reserved.
