//
//  ZBStartTime.h
//
//  Created by shuaibin on 2019/6/12.
//  Copyright © 2019 shuaibin. All rights reserved.
//
//***********  冷启动大致流程  ************************************************************************
//      -------         -----------        --------         ------        ------        -------------
//     | exe() |  =>   | load dyld |  =>  | Rebase |  =>   | Bind |  =>  | Objc |  =>  | initializer |
//     -------         -----------        --------         ------        ------        -------------
//  developer可处理阶段:
//  initializer阶段  --->  load , initializer
//
//  主要流程点顺序说明:
//  load -> attribute((constructor)) -> main -> initialize
//***************************************************************************************************
//   1. 主要获取 pre-main阶段load, initializer, __attribute__((constructor))时间;
//   2. 所有数值都以秒为单位;
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/******************** initializer *************************/
@interface ZBInitializerInfo : NSObject
@property (assign, nonatomic, readonly) CFAbsoluteTime start;
@property (assign, nonatomic, readonly) CFAbsoluteTime end;
@property (assign, nonatomic, readonly) CFAbsoluteTime duration;
@property (copy, nonatomic, readonly) NSString *funcName;
@end

@interface ZBStartTimeInitializerInfo : NSObject
@property (assign, nonatomic, readonly) NSTimeInterval start;
@property (assign, nonatomic, readonly) NSTimeInterval end;
@property (assign, nonatomic, readonly) NSTimeInterval duration;
@property (copy, nonatomic, readonly) NSMutableArray<ZBInitializerInfo *>*infos;
@end

/********************* load ***************************/
@interface ZBLoadInfo : NSObject
@property (assign, nonatomic, readonly) SEL sel;   //load方法SEL
@property (copy, nonatomic, readonly) NSString *clsname;   //类名
@property (copy, nonatomic, readonly) NSString *catname;   //分类名 比如:NSObject + cat;(后面的cat为分类名)
@property (assign, nonatomic, readonly) CFAbsoluteTime start;
@property (assign, nonatomic, readonly) CFAbsoluteTime end;
@property (assign, nonatomic, readonly) CFAbsoluteTime duration;
@end

@interface ZBLoadInfoWrapper : NSObject
@property (assign, nonatomic, readonly) Class cls;
@property (copy, nonatomic, readonly) NSArray <ZBLoadInfo *> *infos;
@end

@interface ZBStartTimeLoadInfo : NSObject
@property (assign, nonatomic, readonly) NSTimeInterval start;
@property (assign, nonatomic, readonly) NSTimeInterval end;
@property (assign, nonatomic, readonly) NSTimeInterval duration;
@property (copy, nonatomic, readonly) NSMutableArray <ZBLoadInfoWrapper *> *infos;
@end

/********************* __attribute__((constructor)) ***************************/
@interface ZBStartTimeAttributeConstructorInfo : NSObject
@property (assign, nonatomic, readonly) NSTimeInterval start;
@property (assign, nonatomic, readonly) NSTimeInterval end;
@property (assign, nonatomic, readonly) NSTimeInterval duration;
@end

/******************** 外层暴露方法 ****************************/
//load
extern const ZBStartTimeLoadInfo *loadInfo;
//initializer
extern ZBStartTimeInitializerInfo *initializerTimeInfo;
//__attribute__((constructor))
extern ZBStartTimeAttributeConstructorInfo *attributeConstructorInfoTimeInfo;

//exe(进程开始时间)
extern NSTimeInterval exeStartTime;

//exe -> __attribute__((constructor))时间间隔
extern NSTimeInterval exeToRunImageInitializerTime;

/******************** 自定义打印一些相关信息 ****************************/
//load
extern NSString *printLoadInfo(void);
//initializer
extern NSString *printInitializerInfo(void);
//__attribute__((constructor))
extern NSString *printAttributeConstructorInfo(void);

@interface ZBStartTime : NSObject

+ (NSTimeInterval)processStartTime;

@end

NS_ASSUME_NONNULL_END
