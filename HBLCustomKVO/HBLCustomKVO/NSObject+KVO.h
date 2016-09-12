//
//  NSObject+KVO.h
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/6.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//- (void)observerHBLValueForKey:(NSString *)key ofObject:(id)object newValue:(id)newValue oldValue:(id)oldValue context:(NSString *)context
static NSString *const observerKeyMethod = @"observerHBLValueForKey:ofObject:newValue:oldValue:context:";

@interface NSObject (KVO)

/**
 * @param context 测试了系统原生KVO，context 作用就只是在执行 - (void)observerHBLValueForKey:(NSString *)key ofObject:(id)object newValue:(id)newValue oldValue:(id)oldValue context:(NSString *)context 方法时，用 context 和初始设置的 context 做对比做不同操作，它对给某个属性是否建立观察者没什么关系。
 * 例如：viewController1 用context1 设置观察者，ViewController2 用 context2 设置观察者，但是当我触发属性变化时， viewController2 和 viewController1 的 observerHBLValueForKey: 方法都会执行。（先出现ViewController1，然后再push ViewController2）
 */
- (void)addHBLObserver:(nonnull NSObject *)observer
                forKey:(nonnull NSString *)key
               context:(nullable NSString *)context;

- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key;


- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key
                  context:(nullable NSString *)context;

@end
