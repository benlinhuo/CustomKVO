//
//  HBLObservationInfo.h
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/7.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HBLObservationInfo : NSObject

@property (nonatomic, weak) NSObject *object; // 哪个类的属性key
@property (nonatomic, weak) NSObject *observer; // weak 表示不引用该对象
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *context;

- (instancetype)initWithObject:(id)object observer:(id)observer key:(NSString *)key context:(NSString *)context;

@end
