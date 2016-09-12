//
//  Observation1ViewController.m
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/11.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import "Observation1ViewController.h"
#import "NSObject+KVO.h"
#import "HBLTestObservation.h"
#import "Observation2ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>


@interface Observation1ViewController () {
    
    __weak IBOutlet UITextField *propertyTextTextField;
    __weak IBOutlet UITextField *afterObservationTextTextField;
    
    HBLTestObservation *testObservation;
}

@end

static void *ktestObserv = &ktestObserv;

@implementation Observation1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    testObservation = [HBLTestObservation shared];
//    [testObservation addHBLObserver:self forKey:@"userName" context:@"testObservation"];
    
    [testObservation addObserver:self forKeyPath:@"userName" options:NSKeyValueObservingOptionNew context:ktestObserv];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    
    if (context == ktestObserv) {
        NSLog(@"same");
    }
    NSLog(@"对象 testObservation 的属性 userName 发生变化啦！");

    NSLog(@"isa= %s", object_getClassName(object)); // 获取 isa 指针所指向的类

    NSLog(@"class=%@", [object class]);
    
    NSLog(@"superClass = %@", class_getSuperclass(object_getClass(object)));
}

- (void)dealloc
{
    [testObservation removeObserver:self forKeyPath:@"userName"];
}


- (void)observerHBLValueForKey:(NSString *)key ofObject:(NSObject *)object newValue:(id)newValue oldValue:(id)oldValue context:(NSString *)context
{
    NSLog(@"oldValue = %@, newValue = %@", oldValue, newValue);
    NSString *newName = [NSString stringWithFormat:@"%@", newValue];
    afterObservationTextTextField.text = newName;
    
    NSLog(@"isa= %s", object_getClassName(object)); // 获取 isa 指针所指向的类
    
    NSLog(@"class=%@", [object class]);
    
    
}

- (IBAction)changeUserNameBtnClicked:(id)sender
{
    NSArray *names = @[@"张三", @"李四", @"王五", @"若兰", @"秋枫", @"怀云"];
    NSUInteger index = arc4random_uniform((u_int32_t)names.count);
    propertyTextTextField.text = names[index];
    testObservation.userName = names[index];
}

- (IBAction)removeObservationBtnClicked:(id)sender
{
     [testObservation removeHBLObserver:self forKey:@"userName"];
}

- (IBAction)goNewPageBtnClicked:(id)sender
{
    Observation2ViewController *vc = [Observation2ViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
