<h1 align="center">轻小说打包器</h1>

<p align="center">
    <img alt="GitHub" src="https://img.shields.io/github/license/Montaro2017/bili_novel_packer">
    <img alt="Static Badge" src="https://img.shields.io/badge/language-Dart-britness">
    <a href='https://gitee.com/Montaro2017/bili_novel_packer/'><img src='https://gitee.com/Montaro2017/bili_novel_packer/badge/star.svg?theme=dark' alt='star'></img></a>
    <a target="_blank" href='https://github.com/Montaro2017/bili_novel_packer'>
		<img src="https://img.shields.io/github/stars/Montaro2017/bili_novel_packer?logo=GitHub" alt="github star"/>
	</a>
</p>

<p align="center">
    <a href="https://gitee.com/Montaro2017/bili_novel_packer">Gitee</a> / <a href="https://github.com/Montaro2017/bili_novel_packer">GitHub</a>
</p>

<hr/>

## 介绍

轻小说打包器，可以将支持的轻小说网站中的小说打包成EPUB格式，包含插图和目录。

### 目前支持的轻小说网站
 - [哔哩轻小说](https://www.linovelib.com)
 - [轻小说文库](https://www.wenku8.net/login.php)
 - 如果你希望添加其他网站支持，请提Issue

## 下载

[点此下载](https://gitee.com/Montaro2017/bili_novel_packer/releases)

## 使用
双击exe或者使用命令提示符都可。

![01](./images/img.png)

![02](./images/img_1.png)


### 多看阅读

**多看阅读插图支持交互模式，点击可全屏查看**

![DuoKan-1](./images/duokan-1.jpg)

![DuoKan-2](./images/duokan-2.jpg)

![DuoKan-3](./images/duokan-3.jpg)

### Koodo Reader

![Koodo-1](./images/koodo-1.png)

## 编译

由于Dart暂不支持交叉编译，因此仅提供windows版本的编译产物，如需在其他系统上使用，请自行下载编译。

### windows
执行目录下的[**compile.bat**](./compile.bat)即可。

或者执行
```
dart compile exe bin/main.dart -o ./build/bili_novel_packer.exe
```

### 其他系统
同windows，修改打包后的文件名即可
```
dart compile exe bin/main.dart -o ./build/bili_novel_packer
```