//
//  TimeMonitorManager.m
//  MZAudio
//
//  Created by shuaibin on 2019/6/14.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import "TimeMonitorManager.h"

#define DYTimeMonitorSingleton [DYTimeMonitorManager sharedInstance]

@interface TimeMonitorManager ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray<DYTimeMonitorModel *> *> *data;

@end
@implementation TimeMonitorManager

WF_DEF_SINGLETION(TimeMonitorManager);

- (void)startWithType:(DYTimeMonitorType)type
{
    [DYTimeMonitorSingleton startWithType:type];
}


- (double)recordWithDescription:(NSString *)description type:(DYTimeMonitorType)type
{
   return [DYTimeMonitorSingleton recordWithDescription:description type:type];
}

- (NSMutableArray<DYTimeMonitorModel *> *)getRecordWithType:(DYTimeMonitorType)type recordType:(DYTimeMonitorRecordType)recordType
{
   return [DYTimeMonitorSingleton getRecordWithType:type recordType:recordType];
}

- (void)resetWithType:(DYTimeMonitorType)type
{
    [DYTimeMonitorSingleton resetWithType:type];
}

- (void)resetAll
{
    [DYTimeMonitorSingleton resetAll];
}

- (void)showRecordWithType:(DYTimeMonitorType)type recordType:(DYTimeMonitorRecordType)recordType
{
    [DYTimeMonitorSingleton showRecordWithType:type recordType:recordType];
}

- (NSMutableDictionary<NSString *,NSMutableArray<DYTimeMonitorModel *> *> *)data
{
    return DYTimeMonitorSingleton.data;
}

@end
