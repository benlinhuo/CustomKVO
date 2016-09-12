//
//  HBLTestObservation.m
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/10.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import "HBLTestObservation.h"

@implementation HBLTestObservation

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    static HBLTestObservation *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [HBLTestObservation new];
    });
    return instance;
}

- (void)setxxxx
{
    NSLog(@"sdfsdfsdfsdf");
}

@end
