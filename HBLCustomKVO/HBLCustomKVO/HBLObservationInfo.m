//
//  HBLObservationInfo.m
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/7.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import "HBLObservationInfo.h"

@implementation HBLObservationInfo

- (instancetype)initWithObject:(id)object observer:(id)observer key:(NSString *)key context:(NSString *)context
{
    self = [super init];
    if (self) {
        self.object = object;
        self.observer = observer;
        self.key = key;
        self.context = context;
    }
    return self;
}

@end
