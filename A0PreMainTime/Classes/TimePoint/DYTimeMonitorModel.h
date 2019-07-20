//
//  DYTimeMonitorModel.h
//  MZAudio
//
//  Created by shuaibin on 2019/6/12.
//  Copyright © 2019 XYWL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYTimeMonitorModel : NSObject

@property (nonatomic, assign) double  time;
@property (nonatomic, strong) NSString  *des;

+ (DYTimeMonitorModel *)timeMonitorWithTime:(double)time description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
