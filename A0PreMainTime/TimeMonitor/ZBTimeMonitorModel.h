//
//  ZBTimeMonitorModel.h
//  TimeMonitor
//
//  Created by shuaibin on 2019/7/21.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBTimeMonitorModel : NSObject

@property (nonatomic, assign) double  time;
@property (nonatomic, strong) NSString  *des;

+ (ZBTimeMonitorModel *)timeMonitorWithTime:(double)time description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
