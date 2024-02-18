# Def1nit3lyN0tAJa1lbr3akTool

A jailbreak tool for iOS 16.0 to iOS 16.6.1. I built it just for fun.

This could not have been possible without kfd, kfund, Dopamine and the jailbreak community.

## How to build

- Run `TRUSTCACHEVERSION=1 make` in every subdirectory of `basebin/` if you are building for iOS 15.7, or run `TRUSTCACHEVERSION=2 make` if you are building for iOS 16.5. 
- Compile the project with Xcode, you might need to download the bootstrap first.

## Current status

Tested on: 
- iPhone X:
  - iOS 16.6.1  
  - iOS 16.6 
  - iOS 16.6 Beta 1 (20G5026e)
  - iOS 16.5.1
  - iOS 16.5
  - iOS 16.4.1
  - iOS 16.3.1
  - iOS 16.2
  - iOS 16.1.2
  - iOS 16.1.1
  - iOS 16.1
  - iOS 16.0.2
- iPhone 8
  - iOS 16.6.1  
  - iOS 16.6 Beta 1 (Build 20G5026e)
  - iOS 16.5
  - iOS 16.4
  - iOS 16.1.2
  - iOS 16.0
- iPhone SE 2nd Gen (2020)
  - iOS 16.6 Beta 1 (Build 20G5026e)
- iPad 6
  - iOS 16.5

## Known issues

- Sideloading would break something, please build with Xcode or use Trollstore.
- Userspace reboot is not supported now.
- On iPhone SE 2nd Gen (2020) you may have to enable airplane mode to get it to be successful. Also must install Trollstore with TrollStar (installed via altstore then use trollstore to install bootstrap and this tool)
