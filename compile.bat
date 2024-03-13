@echo off
del build /q /s /f
rd build /q /s
mkdir build
dart compile exe bin/main.dart -o ./build/bili_novel_packer-0.2.14.exe