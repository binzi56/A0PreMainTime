//
//  ZBTimeMonitorManager.h
//  TimeMonitor
//
//  Created by shuaibin on 2019/7/21.
//  Copyright © 2019 shuaibin. All rights reserved.
//
//  打点使用说明:
//  startWithType:type是必须实现的方法
//

#import <Foundation/Foundation.h>
#import "ZBTimeMonitorModel.h"

typedef NS_ENUM(NSUInteger, ZBTimeMonitorRecordType) {
    ZBTimeMonitorRecordTypeMedian = 0,  //记录中间值(记录距离上次打点的时间间隔)
    ZBTimeMonitorRecordTypeContinuous,  //记录连续值(记录距离首次打点的时间间隔)
};

NS_ASSUME_NONNULL_BEGIN

@interface ZBTimeMonitorManager : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary <NSString *, NSMutableArray<ZBTimeMonitorModel *> *> *data;


/**
 单例方法
 
 @return 单例对象
 */
+ (instancetype)sharedInstance;

/**
 打点起始方法
 
 @param type 业务类型
 */

- (void)startWithType:(NSUInteger)type;

/**
 打点方法
 断言错误描述:
 -1 | 没有传入描述
 -2 | 没有设置开始打点方法(startWithType:)
 
 @param description 打点描述
 @param type 业务类型
 @return 间隔时间(默认返回距离上一次打点的时间间隔)
 */
- (double)recordWithDescription:(NSString *)description
                           type:(NSUInteger)type;

/**
 获取某个业务的打点记录
 
 @param type 业务类型
 @param recordType 打点类型
 @return 该业务所有打点
 */
- (NSMutableArray<ZBTimeMonitorModel *> *)getRecordWithType:(NSUInteger)type
                                                 recordType:(ZBTimeMonitorRecordType)recordType;

/**
 重置某个业务
 
 @param type 业务类型
 */
- (void)resetWithType:(NSUInteger)type;

/**
 重置所有业务
 */
- (void)resetAll;

/**
 展示某个业务(测试展示数据使用)
 
 @param type 业务类型
 @param recordType 记录类型
 */
- (void)showRecordWithType:(NSUInteger)type recordType:(ZBTimeMonitorRecordType)recordType;

@end

NS_ASSUME_NONNULL_END
