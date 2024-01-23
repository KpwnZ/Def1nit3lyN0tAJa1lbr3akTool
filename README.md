# Def1nit3lyN0tAJa1lbr3akTool

An incomplete jailbreak tool for iOS 15.7 and iOS 16.5, iPhone X. I build it just for fun.

It can not be done without kfd, kfund, Dopamine and jailbreak community.

## How to build

- Run `TRUSTCACHEVERSION=1 make` in every subdirectory of `basebin/` if you are building for iOS 15.7, or run `TRUSTCACHEVERSION=2 make` if you are building for iOS 16.5. 
- Compile the project with Xcode, you might need to download the bootstrap first.

## Current status

Tested on: 
- iPhone X, iOS 16.5, iOS 16.4.1, iOS 16.3.1, iOS 16.0.2
- iPhone 8, iOS 16.5, iOS 16.4, iOS 16.0
- iPad 6, iOS 16.5

## Known issues

- Sideloading would break something, please build with Xcode or use Trollstore.
- Userspace reboot is not supported now.
