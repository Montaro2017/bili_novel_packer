@echo off
del build /q /s /f
rd build /q /s
mkdir build
dart compile exe bin/main.dart -o ./build/bili_novel_packer-v0.2.12.exe