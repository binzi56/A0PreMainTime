
#import "DYStartTime.h"
#include <unistd.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <vector>

#include <mach/mach_time.h>
#import <objc/message.h>


DYStartTimeInitializerInfo *initializerTimeInfo = nil;

@interface DYInitializerInfo(){
    @package
    CFAbsoluteTime _start;
    CFAbsoluteTime _end;
    NSString *_funcName;
}

@end
@implementation DYInitializerInfo

- (CFAbsoluteTime)duration {
    return _end - _start;
}

- (NSString *)funcName
{
    return _funcName;
}

@end

@interface DYStartTimeInitializerInfo ()
@property (assign, nonatomic) NSTimeInterval start;
@property (assign, nonatomic) NSTimeInterval end;
@property (assign, nonatomic) NSTimeInterval duration;
@property (copy, nonatomic) NSMutableArray  <DYInitializerInfo *>*infos;
@end
@implementation DYStartTimeInitializerInfo

/**
 此处保证mutableCopy进行
 https://blog.csdn.net/souprock/article/details/81128144
 
 */
- (void)setInfos:(NSMutableArray<DYInitializerInfo *> *)infos
{
    if (_infos != nil) {
        _infos = nil;
    }

    _infos = [infos mutableCopy];
}

@end

using namespace std;
#ifndef __LP64__
typedef uint32_t MemoryType;
#else /* defined(__LP64__) */
typedef uint64_t MemoryType;
#endif /* defined(__LP64__) */


static std::vector<MemoryType> *g_initializer;
static int g_cur_index;
static MemoryType g_aslr;



struct MyProgramVars
{
    const void*        mh;
    int*            NXArgcPtr;
    const char***    NXArgvPtr;
    const char***    environPtr;
    const char**    __prognamePtr;
};

typedef void (*OriginalInitializer)(int argc, const char* argv[], const char* envp[], const char* apple[], const MyProgramVars* vars);

static BOOL myInitFuncIsFirst = YES;
void myInitFunc_Initializer(int argc, const char* argv[], const char* envp[], const char* apple[], const struct MyProgramVars* vars){
    ++g_cur_index;
    OriginalInitializer func = (OriginalInitializer)g_initializer->at(g_cur_index);
    
    CFTimeInterval start = CFAbsoluteTimeGetCurrent();
    if (myInitFuncIsFirst) {
        //获取Initializer开始时间
        initializerTimeInfo.start = [[NSDate date] timeIntervalSince1970];
        myInitFuncIsFirst = NO;
    }
    
    func(argc,argv,envp,apple,vars);
    
    CFTimeInterval end = CFAbsoluteTimeGetCurrent();
    initializerTimeInfo.duration += (end-start);
    NSString *cost = [NSString stringWithFormat:@"%p",func];
    

    DYInitializerInfo *info = [DYInitializerInfo new];
    info->_start = start;
    info->_end = end;
    info->_funcName = cost;

    [initializerTimeInfo.infos addObject:info];
}

static void hookModInitFunc(){
    Dl_info info;
    dladdr((const void *)hookModInitFunc, &info);

#ifndef __LP64__
    /**
     选用博客原文解释:(https://www.jianshu.com/p/c14987eee107)
     因为我们是在一个独立的动态库中做函数地址替换，替换后的函数地址都是我们动态库中的，并没有在其他 image 中，所以当其他 image 执行到这个判断时，就抛出了异常。这个问题好像无解，所以我们的C++ Static Initializers 时间统计稍有不足。
     */
    
    //const struct mach_header *mhp = _dyld_get_image_header(0);  // 工程中其他image有可能会执行,所以摒弃该方法
    const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
    unsigned long size = 0;
    MemoryType *memory = (uint32_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#else /* defined(__LP64__) */
    const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
    unsigned long size = 0;
    MemoryType *memory = (uint64_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#endif /* defined(__LP64__) */
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
        MemoryType original_ptr = memory[idx];
        g_initializer->push_back(original_ptr);
        memory[idx] = (MemoryType)myInitFunc_Initializer;
    }

//    [sInitInfos addObject:[NSString stringWithFormat:@"ASLR=%p",mhp]];
    g_aslr = (MemoryType)mhp;
}

@interface DYStartTimeInitializer : NSObject @end
@implementation DYStartTimeInitializer


//static uint64_t loadTime;
//static mach_timebase_info_data_t timebaseInfo;
//
//static inline NSTimeInterval MachTimeToSeconds(uint64_t machTime) {
//    return ((machTime / 1e9) * timebaseInfo.numer) / timebaseInfo.denom;
//}
//
//
//unsigned int cls_count;
//const char **classes;
//
//NSMutableArray *objc_load_infos;


+ (void)load{
//    loadTime = mach_absolute_time();
//    mach_timebase_info(&timebaseInfo);
//
//    objc_load_infos = [[NSMutableArray alloc] init];
//
//    int imageCount = (int)_dyld_image_count();
//
//    for(int iImg = 0; iImg < imageCount; iImg++) {
//
//        const char* path = _dyld_get_image_name((unsigned)iImg);
//        NSString *imagePath = [NSString stringWithUTF8String:path];
//
//        NSBundle* mainBundle = [NSBundle mainBundle];
//        NSString* bundlePath = [mainBundle bundlePath];
//
//        if ([imagePath containsString:bundlePath] && ![imagePath containsString:@".dylib"]) {
//            classes = objc_copyClassNamesForImage(path, &cls_count);
//
//            for (int i = 0; i < cls_count; i++) {
//                NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
//                if (![className isEqualToString:@""] && className) {
//                    Class cls = object_getClass(NSClassFromString(className));
//
//                    SEL originalSelector = @selector(load);
//                    SEL swizzledSelector = @selector(LDAPM_Load);
//
//                    Method originalMethod = class_getClassMethod(cls, originalSelector);
//                    Method swizzledMethod = class_getClassMethod([self class], swizzledSelector);
//
//                    BOOL hasMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
//
//                    if (!hasMethod) {
//                        BOOL didAddMethod = class_addMethod(cls,
//                                                            swizzledSelector,
//                                                            method_getImplementation(swizzledMethod),
//                                                            method_getTypeEncoding(swizzledMethod));
//
//                        if (didAddMethod) {
//                            swizzledMethod = class_getClassMethod(cls, swizzledSelector);
//
//                            method_exchangeImplementations(originalMethod, swizzledMethod);
//                        }
//                    }
//
//                }
//            }
//        }
//    }
    
    initializerTimeInfo = [DYStartTimeInitializerInfo new];
    initializerTimeInfo.infos = [NSMutableArray array];
    
    g_initializer = new std::vector<MemoryType>();
    g_cur_index = -1;
    g_aslr = 0;
    
    hookModInitFunc();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //此方法在main函数创建完主线程之后执行
        //设置静态函数初始化结束时间
        initializerTimeInfo.end = initializerTimeInfo.start + initializerTimeInfo.duration;
//        printForLoadInfo();
    });
}

//void printForLoadInfo(void) {
//    NSMutableArray *infos = [NSMutableArray array];
//    double sum = 0;
//    for (NSDictionary *info in objc_load_infos) {
//        sum += [info[@"interval_second"] doubleValue];
//        [infos addObject:info];
//    }
//
//#ifdef DEBUG
//    printf("\n======================= DYTimeMonitor measure for Load time ============================\n\t\t\t\t\t\t\tTotal for Load time: %f milliseconds(%lu)\n", sum * 1000.0, (unsigned long)objc_load_infos.count);
//    for (NSDictionary *info in infos) {
//        NSString *name = info[@"name"];
//        printf("%40s for Load time time: %f milliseconds(%.2f%%)\n", [name cStringUsingEncoding:NSUTF8StringEncoding], [info[@"interval_second"] doubleValue] * 1000.0, (double)([info[@"interval_second"] doubleValue] / sum) * 100.0);
//    }
//    printf("\n\n");
//#endif
//}
//
//
//+ (void)LDAPM_Load {
//    
//    CFAbsoluteTime start = mach_absolute_time();
//    [self LDAPM_Load];
//    CFAbsoluteTime end = mach_absolute_time();
//    NSDictionary *infoDic = @{@"st":@(start),
//                              @"et":@(end),
//                              @"interval_second":@(MachTimeToSeconds(end - start)),
//                              @"name":NSStringFromClass([self class])
//                              };
//    
//    [objc_load_infos addObject:infoDic];
//}

@end
