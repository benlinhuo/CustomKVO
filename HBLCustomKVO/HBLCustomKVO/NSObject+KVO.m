//
//  NSObject+KVO.m
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/6.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+KVO.h"
#import "HBLObservationInfo.h"


static NSString *const kHBLKVOClassNamePrefix = @"HBLKVONotifying_";
static void * kHBLObservationInfo = &kHBLObservationInfo;

typedef void (*_VIMP) (id, SEL, ...);

#pragma mark - static method
/**
 * 默认类 class 的具体实现为：
 * - (Class)class {    return object_getClass(self);  }
 * 如果我们想要将新类的 class 返回它的父类（isa 指针指向父类），就需要做如下的更改
 */
static Class new_class(id self)
{
    return class_getSuperclass(object_getClass(self));
}


@implementation NSObject (KVO)

#pragma mark - public methods
- (void)addHBLObserver:(nonnull NSObject *)observer
                forKey:(nonnull NSString *)key
               context:(nullable NSString *)context
{
    NSString *setterString = [self setterByGetter:key];
    SEL setterSelector = NSSelectorFromString(setterString);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        // 虽然抛出异常会造成 app crash，但是不应该隐藏错误
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason userInfo:nil];
    }
    
    // 上述准备就绪，下面开始操作
    // 1. 创建一个新类，继承于原来的类
    Class originalClass = object_getClass(self);
    Class newClass = object_getClass(self); // object_getClass 获取一个实例的类
    NSString *originalClassName = NSStringFromClass(originalClass);
    
    if (![originalClassName hasPrefix:kHBLKVOClassNamePrefix]) {
        newClass = [self generateNewClassByOriginalClassName:originalClassName];
        // 将 self 对象设置新类类型 newClass
        // 通过将 isa 的指向更改为 newClass
        object_setClass(self, newClass);
    }
    
    
    // 3. 改写 setter 方法
    if (![self hasSelector:setterSelector]) {
        // IMP 获取
        IMP setterImp = nil;
        uint methodCount;
        // class_copyMethodList 获取所有的方法，而不仅仅是 .h 中的方法，但是不包括父类方法，包括 category 中方法
        // 为了获取 newSetterWithnewValue: 方法的实现，我们从 NSObject 中来获取
        Method *methodList = class_copyMethodList([NSObject class], &methodCount);
        for (int i = 0; i < methodCount; i++) {
            Method method = methodList[i];
            SEL selector = method_getName(method);
            if (selector == @selector(newSetterWithnewValue:)) {
                setterImp = method_getImplementation(method);
                break;
            }
        }
        free(methodList);
        
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(newClass, setterSelector, setterImp, types);
    }
    
    HBLObservationInfo *info = [[HBLObservationInfo alloc] initWithObject:self observer:observer key:key context:context];
    [self setObjectsWithObservationInfo:info];
}


- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key
{
    [self removeObserver:observer key:key context:nil];
}


- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key
                  context:(nullable NSString *)context
{
    [self removeObserver:observer key:key context:context];
}


#pragma mark - private methods

/**
 * @param      getter ，如 count
 * @descption  将 getter 方法字符串转成 setter 方法字符串
 */
- (NSString *)setterByGetter:(NSString *)getter
{
    if (getter.length > 0) {
        NSString *firstChar = [[getter substringToIndex:1] uppercaseString];
        NSString *thenString = [getter substringFromIndex:1];
        NSString *setterString = [NSString stringWithFormat:@"set%@%@:", firstChar, thenString];
        return setterString;
    }
    return nil;
}

/**
 * @param      setter ，如 setCount: 或者 setCount
 * @descption  将 setter 方法字符串转成 getter 方法字符串
 */
- (NSString *)getterBySetter:(NSString *)setter
{
    if (setter.length > 0 && [setter hasPrefix:@"set"]) {
        NSRange range = NSMakeRange(3, setter.length - 3); // 不考虑最后的冒号
        if ([setter hasSuffix:@":"]) {
            range = NSMakeRange(3, setter.length - 4);
        }
        NSString *getterString = [setter substringWithRange:range];
        // 首字母改小写
        NSString *firstChar = [[getterString substringToIndex:1] lowercaseString];
        getterString = [getterString stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                             withString:firstChar];
        return getterString;
    }
    return nil;
}

/**
 * 生成新类的新 setter 方法：在设置新值的时候记得通知监控变化的方法
 * @param _cmd 代表本方法名
 */
- (void)newSetterWithnewValue:(id)newValue
{
    id object = self; // [object class] 为 HBLTestObservation
    SEL selector = _cmd;
    NSString *setterName = NSStringFromSelector(selector);
    NSString *getterName = [self getterBySetter:setterName];
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
    }
    
    
    id oldValue = [object valueForKey:getterName];
    // 执行父类的 setter 方法
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(object))
    };
    // cast our pointer so the compiler won't complain
    // 在 Xcode 6 里，新的 LLVM 会对 objc_msgSendSuper 以及 objc_msgSend 做严格的类型检查，如果不做类型转换。Xcode 会抱怨有 too many arguments 的错误。（在 WWDC 2014 的视频 What new in LLVM 中有提到过这个问题。）
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    // call super's setter, which is original class's setter method
    // 调用新类的父类的该 set 方法，且用新值
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    // 执行监控 key 值的方法
    // 多个 observations 情况
    NSArray *observations = [self getObservationInfoWithkey:getterName];
    for (int i = 0; i < observations.count; i++) {
        HBLObservationInfo *info = observations[i];
        uint methodCount;
        Class observationClass = [info.observer class];
        Method *methodList = class_copyMethodList(observationClass, &methodCount);
        
        for (int j = 0; i < methodCount; j++) {
            Method thisMethod = methodList[j];
            SEL thisSel = method_getName(thisMethod);
            const char *charName = sel_getName(thisSel);
            NSString *nameString = [[NSString alloc] initWithUTF8String:charName];
            NSString *constantString = [NSString stringWithFormat:@"%@", observerKeyMethod];
            
            // 监控到实现的方法，执行之(且只执行第一个，也就是多个只有第一个管用)
            if ([nameString isEqualToString:constantString]) {
                //获取方法实现
                _VIMP thisImp = (_VIMP)method_getImplementation(thisMethod);
                
                thisImp(info.observer, thisSel, getterName, object, newValue, oldValue, info.context);
                
                break;
            }
        }
        
        free(methodList);
    }
    
}


/**
 * 依原来的类作为父类，生成对应的新类。且重写原来类的 class 方法
 */
- (Class)generateNewClassByOriginalClassName:(NSString *)originalClassName
{
    NSString *newClassName = [kHBLKVOClassNamePrefix stringByAppendingString:originalClassName];
    Class newClass = NSClassFromString(newClassName);
    if (newClass) {
        return newClass;
    }
    // 重新创建新类
    Class originalClass = NSClassFromString(originalClassName);
    newClass = objc_allocateClassPair(originalClass, newClassName.UTF8String, 0);
    
    // 2. 重写该新类的 class 方法。需要先获取之前类的 class 方法
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    // 获取 method 方法的参数和返回值描述符
    const char *types = method_getTypeEncoding(classMethod);
    // 为新类添加方法 class（重写父类的该方法），用于外界调用者还以为自己调用的是它之前的类，实际上已经被替换成它的子类了。所以 kvo_class 返回的就是他的父类 class 方法实现
    class_addMethod(newClass, @selector(class), (IMP)new_class, types);
    
    // 让 runtime 知道这个新类的存在，之前就只是创建了这个新类
    objc_registerClassPair(newClass);
    
    return newClass;
}

- (BOOL)hasSelector:(SEL)selector
{
    BOOL isHas = NO;
    Class clazz = object_getClass(self);
    uint methodCount;
    Method *methodList = class_copyMethodList(clazz, &methodCount);
    for (int i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        SEL currSelector = method_getName(method);
        if (selector == currSelector) {
            isHas = YES;
        }
    }
    free(methodList);
    return isHas;
}

#pragma mark - getter / setter

/**
 * 直接使用 key 值，因为我们每个类 object 都有一个数组去存储该类添加的观察者 observer，所以当有多个观察者使用 key 值去匹配，应该获取多个观察者对应的 - (void)observeValueForKey:(NSString *)key ofObject:(id)object newValue:(id)newValue oldValue:(id)oldValue context:(NSString *)context 该方法实现 （Observation2ViewController 可以用于测试）
 */
- (NSString *)combinationKey:(NSString *)key
{
    NSString *combinationKey = [NSString stringWithFormat:@"%@_", key];
    return combinationKey;
}

- (void)setObjectsWithObservationInfo:(HBLObservationInfo *)info
{
    NSMutableDictionary *infosDic = objc_getAssociatedObject(self, kHBLObservationInfo);
    if (!infosDic) {
        infosDic  = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kHBLObservationInfo, infosDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // 因为同一个对象属性，可以给其添加多次观察者
    NSString *combinationKey = [self combinationKey:info.key];
    NSMutableArray *observations = [infosDic objectForKey:combinationKey];
    if (!observations) {
        observations = [NSMutableArray array];
    }
    [observations addObject:info];
    [infosDic setObject:observations forKey:combinationKey];
}

- (NSArray<HBLObservationInfo *> *)getObservationInfoWithkey:(NSString *)key
{
    NSString *combinationKey = [self combinationKey:key];
    NSMutableDictionary *infosDic = objc_getAssociatedObject(self, kHBLObservationInfo);
    if (infosDic) {
        NSArray *observations = [infosDic objectForKey:combinationKey];
        return observations;
    }
    return nil;
}

- (void)removeObserver:(NSObject *)observer key:(NSString *)key context:(NSString *)context
{
    NSString *combinationKey = [self combinationKey:key];
    NSMutableDictionary *infosDic = objc_getAssociatedObject(self, kHBLObservationInfo);
    if (infosDic) {
        NSMutableArray *observations = [infosDic objectForKey:combinationKey];
        
        for (int i = 0; i < observations.count; i++) {
            HBLObservationInfo *info = observations[i];
            if ([observer isEqualToSpecificObject:info.observer]) {
                if (context && context.length > 0 && [info.context isEqualToString:context]) {
                    [observations removeObject:info];
                    
                    
                } else {
                    [observations removeObject:info];
                }
                [infosDic setObject:observations forKey:combinationKey];
            }
            
        }
    }
    
}

/**
 * 和某个指定类是否相同
 * 同一个类，指针相同才可以
 */
- (BOOL)isEqualToSpecificObject:(NSObject *)object
{
    if (object == self && [object class] == [self class]) {
        return YES;
    }
    return NO;
}


@end





