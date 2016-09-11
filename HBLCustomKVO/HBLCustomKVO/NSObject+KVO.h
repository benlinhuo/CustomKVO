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

- (void)addHBLObserver:(nonnull NSObject *)observer
                forKey:(nonnull NSString *)key
               context:(nullable NSString *)context;

- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key;


- (void)removeHBLObserver:(nonnull NSObject *)observer
                   forKey:(nonnull NSString *)key
                  context:(nullable NSString *)context;

@end
