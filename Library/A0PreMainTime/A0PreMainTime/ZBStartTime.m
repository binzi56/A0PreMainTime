//
//  ZBStartTime.m
//
//  Created by shuaibin on 2019/6/12.
//  Copyright © 2019 shuaibin. All rights reserved.
//

#import "ZBStartTime.h"
#include <objc/message.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <objc/runtime.h>
#include <mach-o/getsect.h>
//获取系统开始时间戳
#import <sys/sysctl.h>
#import <mach/mach.h>

ZBStartTimeLoadInfo *loadInfo = nil;
ZBStartTimeAttributeConstructorInfo *attributeConstructorInfoTimeInfo = nil;

NSTimeInterval exeStartTime;
NSTimeInterval exeToRunImageInitializerTime;

@interface ZBLoadInfoWrapper () {
    @package
    NSMutableArray <ZBLoadInfo *> *_infos;
}
- (instancetype)initWithClass:(Class)cls;
@end

@implementation ZBLoadInfoWrapper
- (instancetype)initWithClass:(Class)cls {
    if (self = [super init]) {
        _infos = [NSMutableArray array];
        _cls = cls;
    }
    return self;
}

- (void)insertLoadInfo:(ZBLoadInfo *)info {
    [_infos insertObject:info atIndex:0];
}
@end

@interface ZBLoadInfo () {
    @package
    SEL _sel;
    CFAbsoluteTime _start;
    CFAbsoluteTime _end;
}

- (instancetype)initWithClass:(Class)cls;
- (instancetype)initWithCategory:(Category)cat;
@end

@implementation ZBLoadInfo
- (instancetype)initWithClass:(Class)cls {
    if (!cls) return nil;
    if (self = [super init]) {
        // DO NOT use cat->cls! cls may be cat->cls->isa instead
        // 对于 category ，既然无法 remapClass (私有函数) ，就直接拿 cat->cls->isa 的 name
        // 对于 class ，为了和 category 统一，直接取 meta class name
        // 由于 meta name 和 name 相同，反射时再根据 meta name 取 class
        _clsname = [NSString stringWithCString:object_getClassName(cls) encoding:NSUTF8StringEncoding];
    }
    return self;
}
- (instancetype)initWithCategory:(Category)cat {
    if (!cat) return nil;
    Class cls = (__bridge Class)((void *)cat + sizeof(char *));
    if (self = [self initWithClass:cls]) {
        _catname = [NSString stringWithCString:*(char **)cat encoding:NSUTF8StringEncoding];
    }
    return self;
}
- (CFAbsoluteTime)duration {
    return _end - _start;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(%@) duration: %f milliseconds", _clsname, _catname, (_end - _start) * 1000];
}
@end

@interface ZBStartTimeLoadInfo ()
@property (assign, nonatomic) NSTimeInterval start;
@property (assign, nonatomic) NSTimeInterval end;
@property (assign, nonatomic) NSTimeInterval duration;
@property (copy, nonatomic) NSMutableArray <ZBLoadInfoWrapper *> *infos;

@end
@implementation ZBStartTimeLoadInfo

- (void)setInfos:(NSMutableArray<ZBLoadInfoWrapper *> *)infos
{
    if (_infos != nil) {
        _infos = nil;
    }
    
    _infos = [infos mutableCopy];
}

@end

@interface ZBStartTimeAttributeConstructorInfo()
@property (assign, nonatomic) NSTimeInterval start;
@property (assign, nonatomic) NSTimeInterval end;
@property (assign, nonatomic) NSTimeInterval duration;
@end
@implementation ZBStartTimeAttributeConstructorInfo
@end

static SEL getRandomLoadSelector(void);
static bool shouldRejectClass(NSString *name);
static bool isSelfDefinedImage(const char *imageName);
static void hookAllLoadMethods(ZBLoadInfoWrapper *infoWrapper);
static void swizzleLoadMethod(Class cls, Method method, ZBLoadInfo *info);
static NSArray <ZBLoadInfo *> *getNoLazyArray(const struct mach_header *mhdr);
static const struct mach_header **copyAllSelfDefinedImageHeader(unsigned int *outCount);
static NSArray <ZBLoadInfoWrapper *> *prepareMeasureForImageHeader(const struct mach_header *mhdr);
static void *getDataSection(const struct mach_header *mhdr, const char *sectname, size_t *bytes);
static NSDictionary <NSString *, ZBLoadInfoWrapper *> *groupNoLazyArray(NSArray <ZBLoadInfo *> *noLazyArray);

static void *getDataSection(const struct mach_header *mhdr, const char *sectname, size_t *bytes) {
    void *data = getsectiondata((void *)mhdr, "__DATA", sectname, bytes);
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_CONST", sectname, bytes);
    }
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_DIRTY", sectname, bytes);
    }
    
    return data;
}

static bool isSelfDefinedImage(const char *imageName) {
    return !strstr(imageName, "/Xcode.app/") &&
    !strstr(imageName, "/Library/PrivateFrameworks/") &&
    !strstr(imageName, "/System/Library/") &&
    !strstr(imageName, "/usr/lib/");
}

static const struct mach_header **copyAllSelfDefinedImageHeader(unsigned int *outCount) {
    unsigned int imageCount = _dyld_image_count();
    unsigned int count = 0;
    const struct mach_header **mhdrList = NULL;
    
    if (imageCount > 0) {
        mhdrList = (const struct mach_header **)malloc(sizeof(struct mach_header *) * imageCount);
        for (unsigned int i = 0; i < imageCount; i++) {
            const char *imageName = _dyld_get_image_name(i);
            if (isSelfDefinedImage(imageName)) {
                const struct mach_header *mhdr = _dyld_get_image_header(i);
                mhdrList[count++] = mhdr;
            }
        }
        mhdrList[count] = NULL;
    }
    
    if (outCount) *outCount = count;
    
    return mhdrList;
}

__unused static const struct mach_header *getImageHeaderForName(const char *name) {
    unsigned int count = _dyld_image_count();
    for (unsigned int i = 0; i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!strcmp(name, imageName)) {
            return _dyld_get_image_header(i);
        }
    }
    return NULL;
}

static SEL getRandomLoadSelector(void) {
    return NSSelectorFromString([NSString stringWithFormat:@"_lh_hooking_%x_load", arc4random()]);
}

static bool shouldRejectClass(NSString *name) {
    if (!name) return true;
    NSArray *rejectClses = @[@"__ARCLite__"];
    return [rejectClses containsObject:name];
}

static NSArray <ZBLoadInfo *> *getNoLazyArray(const struct mach_header *mhdr) {
    NSMutableArray *noLazyArray = [NSMutableArray new];
    unsigned long bytes = 0;
    Class *clses = (Class *)getDataSection(mhdr, "__objc_nlclslist", &bytes);
    for (unsigned int i = 0; i < bytes / sizeof(Class); i++) {
        ZBLoadInfo *info = [[ZBLoadInfo alloc] initWithClass:clses[i]];
        if (!shouldRejectClass(info.clsname)) [noLazyArray addObject:info];
    }
    
    bytes = 0;
    Category *cats = getDataSection(mhdr, "__objc_nlcatlist", &bytes);
    for (unsigned int i = 0; i < bytes / sizeof(Category); i++) {
        ZBLoadInfo *info = [[ZBLoadInfo alloc] initWithCategory:cats[i]];
        if (!shouldRejectClass(info.clsname)) [noLazyArray addObject:info];
    }
    
    return noLazyArray;
}

static NSDictionary <NSString *, ZBLoadInfoWrapper *> *groupNoLazyArray(NSArray <ZBLoadInfo *> *noLazyArray) {
    NSMutableDictionary *noLazyMap = [NSMutableDictionary dictionary];
    for (ZBLoadInfo *info in noLazyArray) {
        ZBLoadInfoWrapper *infoWrapper = noLazyMap[info.clsname];
        if (!infoWrapper) {
            Class cls = objc_getClass([info.clsname cStringUsingEncoding:NSUTF8StringEncoding]);
            infoWrapper = [[ZBLoadInfoWrapper alloc] initWithClass:cls];
        }
        [infoWrapper insertLoadInfo:info];
        noLazyMap[info.clsname] = infoWrapper;
    }
    return noLazyMap;
}

static BOOL swizzleLoadIsFirst = YES;
static void swizzleLoadMethod(Class cls, Method method, ZBLoadInfo *info) {
retry:
    do {
        SEL hookSel = getRandomLoadSelector();
        Class metaCls = object_getClass(cls);
        
        IMP hookImp = imp_implementationWithBlock(^ {
            if (swizzleLoadIsFirst) {
                //获取load开始时间
                loadInfo.start = [[NSDate date] timeIntervalSince1970];
                swizzleLoadIsFirst = NO;
            }
            info->_start = CFAbsoluteTimeGetCurrent();
            ((void (*)(Class, SEL))objc_msgSend)(cls, hookSel);
            info->_end = CFAbsoluteTimeGetCurrent();
        });
        
        BOOL didAddMethod = class_addMethod(metaCls, hookSel, hookImp, method_getTypeEncoding(method));
        if (!didAddMethod) goto retry;
        
        info->_sel = hookSel;
        Method hookMethod = class_getInstanceMethod(metaCls, hookSel);
        method_exchangeImplementations(method, hookMethod);
    } while(0);
}

static void hookAllLoadMethods(ZBLoadInfoWrapper *infoWrapper) {
    unsigned int count = 0;
    Class metaCls = object_getClass(infoWrapper.cls);
    Method *methodList = class_copyMethodList(metaCls, &count);
    
    for (unsigned int i = 0, j = 0; i < count; i++) {
        Method method = methodList[i];
        SEL sel = method_getName(method);
        const char *name = sel_getName(sel);
        if (!strcmp(name, "load")) {
            ZBLoadInfo *info = nil;
            if (j > infoWrapper.infos.count - 1) {
                info = [[ZBLoadInfo alloc] initWithClass:infoWrapper.cls];
                [infoWrapper insertLoadInfo:info];
            } else {
                info = infoWrapper.infos[j];
            }
            ++j;
            
            swizzleLoadMethod(infoWrapper.cls, method, info);
        }
    }
    free(methodList);
}

static NSArray <ZBLoadInfoWrapper *> *prepareMeasureForImageHeader(const struct mach_header *mhdr) {
    NSArray <ZBLoadInfo *> *infos = getNoLazyArray(mhdr);
    NSDictionary <NSString *, ZBLoadInfoWrapper *> *groupedInfos = groupNoLazyArray(infos);
    
    for (NSString *clsname in groupedInfos.allKeys) {
        ZBLoadInfoWrapper *infoWrapper = groupedInfos[clsname];
        hookAllLoadMethods(infoWrapper);
    }
    
    return groupedInfos.allValues;
}

__attribute__((constructor)) static void LoadMeasure_Initializer(void) {
    loadInfo = [[ZBStartTimeLoadInfo alloc] init];
    loadInfo.infos = [NSMutableArray array];
    attributeConstructorInfoTimeInfo = [[ZBStartTimeAttributeConstructorInfo alloc] init];
    
    //设置初始化开始时间
    attributeConstructorInfoTimeInfo.start = [[NSDate date] timeIntervalSince1970];
    
    unsigned int count = 0;
    const struct mach_header **mhdrList = copyAllSelfDefinedImageHeader(&count);
    NSMutableArray <ZBLoadInfoWrapper *> *allInfoWappers = [NSMutableArray array];
    
    for (unsigned int i = 0; i < count; i++) {
        const struct mach_header *mhdr = mhdrList[i];
        NSArray <ZBLoadInfoWrapper *> *infoWrappers = prepareMeasureForImageHeader(mhdr);
        [allInfoWappers addObjectsFromArray:infoWrappers];
    }
    
    free(mhdrList);
    loadInfo.infos = allInfoWappers;
    
    //设置初始化结束时间
    attributeConstructorInfoTimeInfo.end = [[NSDate date] timeIntervalSince1970];
    //设置系统执行开始时间
    exeStartTime = [ZBStartTime processStartTime] / 1000.0;
    //设置exe -> __attribute__((constructor))时间间隔
    exeToRunImageInitializerTime = attributeConstructorInfoTimeInfo.start - exeStartTime;
    //设置initializer加载时间
    attributeConstructorInfoTimeInfo.duration = attributeConstructorInfoTimeInfo.end - attributeConstructorInfoTimeInfo.start;
    

    
    dispatch_async(dispatch_get_main_queue(), ^{
        //此方法在main函数创建完主线程之后执行
        NSMutableArray *infos = [NSMutableArray array];
        for (ZBLoadInfoWrapper *infoWrapper in loadInfo.infos) {
            [infos addObjectsFromArray:infoWrapper.infos];
        }
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:NO];
        [infos sortUsingDescriptors:@[descriptor]];
        
        CFAbsoluteTime totalDuration = 0;
        for (ZBLoadInfo *info in infos) {
            totalDuration += info.duration;
        }
        
        //设置load加载时间
        loadInfo.duration = totalDuration;
        
        //获取load结束时间
        loadInfo.end = [NSString stringWithFormat:@"%.f", loadInfo.start + loadInfo.duration].doubleValue;
    });
}

NSString *printAttributeConstructorInfo(void){
    NSMutableString *resultStr = [NSMutableString string];
    [resultStr appendFormat:@"\n======================= ZBTimeMonitor measure __attribute__((constructor)) time ============================\n\t\t\t\tTotal __attribute__((constructor)) time: %f milliseconds\n", attributeConstructorInfoTimeInfo.duration * 1000.0];
    [resultStr appendFormat:@"\t\t\t\t\t\t\t\tstart time: %f \n", attributeConstructorInfoTimeInfo.start];
    [resultStr appendFormat:@"\t\t\t\t\t\t\t\tend time: %f \n\n", attributeConstructorInfoTimeInfo.end];
    return resultStr;
}

NSString *printLoadInfo(void){
    NSMutableArray *infos = [NSMutableArray array];
    for (ZBLoadInfoWrapper *infoWrapper in loadInfo.infos) {
        [infos addObjectsFromArray:infoWrapper.infos];
    }
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:NO];
    [infos sortUsingDescriptors:@[descriptor]];
    
    CFAbsoluteTime totalDuration = 0;
    for (ZBLoadInfo *info in infos) {
        totalDuration += info.duration;
    }
    
    NSMutableString *resultStr = [NSMutableString string];
    [resultStr appendFormat:@"\n======================= ZBTimeMonitor measure load time ============================\n\t\t\t\t\t\t\tTotal load time: %f milliseconds(%ld)\n", totalDuration * 1000, (unsigned long)infos.count];
    for (ZBLoadInfo *info in infos) {
        NSString *clsname = [NSString stringWithFormat:@"%@", info.clsname];
        if (info.catname) clsname = [NSString stringWithFormat:@"%@(%@)", clsname, info.catname];
        [resultStr appendFormat:@"%40s load time: %f milliseconds(%.2f%%)\n", [clsname cStringUsingEncoding:NSUTF8StringEncoding], info.duration * 1000, (double)(info.duration / totalDuration) * 100.0];
    }
    [resultStr appendFormat:@"\n\n"];
    return resultStr;
}


@interface ZBStartTime ()

@end
@implementation ZBStartTime

#pragma mark - 获取进程开始时间
+ (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo
{
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

+ (NSTimeInterval)processStartTime
{
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        return kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    }
    else {
        NSAssert(NO, @"无法取得进程的信息");
        return 0;
    }
}

@end
