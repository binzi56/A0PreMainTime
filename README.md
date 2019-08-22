
This library is used to measure the time and time of the pre-main phase more accurately.

# Build Setting
---
**Requirements**
* iOS 8.0 or later

# Installation
---
* using CocoaPods
* by cloning the project into your repository

#### Installation with CocoaPods
#### Podfile
```
platform :ios, '8.0'
pod 'A0PreMainTime'
```
#### Subspecs
There are 2 subspecs available now: `PreMainTime` and `TimeMonitor` (this means you can install only some of the A0PreMainTime modules.
Podfile example:
```
pod 'A0PreMainTime/PreMainTime'
//or
pod 'A0PreMainTime/TimeMonitor'
```

## How To Use
### Import headers in your source files
`subspecs => PreMainTime`
```
#import <A0PreMainTime/A0PreMainTime.h>
```
All parameters are placed in the ZBStartTime.h file, please refer to your own.

`subspecs => TimeMonitor`
```
#import <A0PreMainTime/ZBTimeMonitorManager.h>
```
Not：
> For each business you must first set `- (void)startWithType:(NSUInteger)type;`

### Build Project
At this point your workspace should build without error. If you are having problem, post to the Issue and the community can help you solve it.

## Author

*   [Fire Jade](https://www.jianshu.com/u/715753f68a27)

## Other
### Auto Building Shell
`autoBuild.sh` are used to automatically build the framework
```
./autoBuild.sh
```