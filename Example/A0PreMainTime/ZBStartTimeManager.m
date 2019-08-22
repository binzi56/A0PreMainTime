//
//  ZBStartTimeManager.m
//  A0PreMainTime_Example
//
//  Created by shuaibin on 2019/8/22.
//  Copyright © 2019 1533607721@qq.com. All rights reserved.
//

#import "ZBStartTimeManager.h"

@implementation ZBStartTimeManager


+ (void)printfPreMainInfo
{
#ifdef DEBUG
    NSLog(@"%@%@%@", printAttributeConstructorInfo(), printLoadInfo(), printInitializerInfo());
#endif
}

@end
