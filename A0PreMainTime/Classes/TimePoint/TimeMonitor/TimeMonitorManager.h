//
//  TimeMonitorManager.h
//  MZAudio
//
//  Created by shuaibin on 2019/6/14.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DYTimeMonitor/DYTimeMonitor.h>

typedef NS_ENUM(NSUInteger, DYTimeMonitorType) {
    DYTimeMonitorTypeAppInit,    //App启动
    DYTimeMonitorTypeTypeHome,   //首页
    DYTimeMonitorTypeTypeRoom,   //房间
    DYTimeMonitorTypeTypeOthers  //其他
};

NS_ASSUME_NONNULL_BEGIN

@interface TimeMonitorManager : NSObject

/**
 打点的所有数据
 */
@property (nonatomic, strong, readonly) NSMutableDictionary <NSString *, NSMutableArray<DYTimeMonitorModel *> *> *data;

WF_AS_SINGLETION(TimeMonitorManager);

/**
 打点起始方法

 @param type 业务类型
 */

- (void)startWithType:(DYTimeMonitorType)type;

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
                           type:(DYTimeMonitorType)type;

/**
 获取某个业务的打点记录

 @param type 业务类型
 @param recordType 打点类型
 @return 该业务所有打点
 */
- (NSMutableArray<DYTimeMonitorModel *> *)getRecordWithType:(DYTimeMonitorType)type
                                                 recordType:(DYTimeMonitorRecordType)recordType;

/**
 重置某个业务

 @param type 业务类型
 */
- (void)resetWithType:(DYTimeMonitorType)type;

/**
 重置所有业务
 */
- (void)resetAll;

/**
 展示某个业务(测试展示数据使用)

 @param type 业务类型
 @param recordType 记录类型
 */
- (void)showRecordWithType:(DYTimeMonitorType)type recordType:(DYTimeMonitorRecordType)recordType;


@end

NS_ASSUME_NONNULL_END
