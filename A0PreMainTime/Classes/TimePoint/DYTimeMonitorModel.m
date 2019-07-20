//
//  DYTimeMonitorModel.m
//  MZAudio
//
//  Created by shuaibin on 2019/6/12.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import "DYTimeMonitorModel.h"

@implementation DYTimeMonitorModel

+ (DYTimeMonitorModel *)timeMonitorWithTime:(double)time description:(NSString *)description
{
    DYTimeMonitorModel *model = DYTimeMonitorModel.new;
    model.time = time;
    model.des = description;
    return model;
}

@end
