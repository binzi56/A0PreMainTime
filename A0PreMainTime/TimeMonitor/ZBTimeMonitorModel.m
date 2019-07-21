//
//  ZBTimeMonitorModel.m
//  TimeMonitor
//
//  Created by shuaibin on 2019/7/21.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import "ZBTimeMonitorModel.h"

@implementation ZBTimeMonitorModel

+ (ZBTimeMonitorModel *)timeMonitorWithTime:(double)time description:(NSString *)description
{
    ZBTimeMonitorModel *model = ZBTimeMonitorModel.new;
    model.time = time;
    model.des = description;
    return model;
}

@end
