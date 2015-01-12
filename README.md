mir9-lua
================
mir9——《热血沙城》，是9秒论坛开源的一个使用Cocos2d-x-2.2.1引擎开发的45度ARPG手游Demo，源代码为c++。mir9-lua是mir9的Lua移植版，使用Quick-Cocos2d-x-2.2.5引擎开发。由于移植得比较匆忙，代码写得可能比较混乱，请见谅。<br>

已知Bug：<br>
1、Label字体在Windows上面显示模糊<br>
2、小地图在已是最左或最下的情况下，仍可以向上或或向滑动一段距离，并且不弹回原样<br>
3、切换地图后小地图还是打开状态，并且显示的是之前的小地图<br>
4、人物移出小地图当前范围后，小地图不更新不随人物当前位置更新当前显示范围<br>
5、怪物在不可见范围时，自动攻击选中怪物会发现怪物选中图片位置不对<br>
6、停止自动攻击后，还会跑去攻击一次<br>
7、A*寻路会有死循环问题，在真机上面效率也很低<br>

界面截图：<br>
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E7%99%BB%E5%BD%95.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E8%A7%92%E8%89%B2%E9%80%89%E6%8B%A9.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E5%8A%A0%E8%BD%BDing.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E4%B8%BB%E5%9F%8E.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E5%9F%8E%E9%83%8A.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E5%B0%8F%E5%9C%B0%E5%9B%BE.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E8%83%8C%E5%8C%85.png)
![image](https://github.com/zym2014/mir9-lua/blob/master/%E7%95%8C%E9%9D%A2%E6%88%AA%E5%9B%BE/%E6%8A%80%E8%83%BD%E5%88%97%E8%A1%A8.png)


Cocos2d-x2.2.1 C++原版下载地址：<br>
http://pan.baidu.com/s/1jGl8042<br>

Cocos2d-x2.2.5 C++修改版下载地址：<br>
http://pan.baidu.com/s/1bnfHdzL<br>

Lua移植版资源下载地址：<br>
http://pan.baidu.com/s/1kTqqhin<br>

开发环境：<br>
Quick-Cocos2d-x-2.2.5<br>
Cocos Code IDE<br>

注意：<br>
在Windows下面运行不能将程序放在中文目录下，否则会播放不了声音，这是引擎的Bug。另资源文件下载完后，请解压缩至项目工程的res目录下。<br>

项目地址：<br>
[https://github.com/zym2014/mir9-lua](https://github.com/zym2014/mir9-lua)

作者Blog：<br>
[http://zym.cnblogs.com/](http://zym.cnblogs.com/)<br>
[http://blog.csdn.net/zym_123456](http://blog.csdn.net/zym_123456)<br>
