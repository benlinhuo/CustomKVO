//
//  Observation2ViewController.m
//  HBLCustomKVO
//
//  Created by benlinhuo on 16/9/10.
//  Copyright © 2016年 Benlinhuo. All rights reserved.
//

#import "Observation2ViewController.h"
#import "HBLTestObservation.h"
#import "NSObject+KVO.h"


@interface Observation2ViewController () {
    
    __weak IBOutlet UITextField *showNameTextField;
    __weak IBOutlet UITextField *afterObservationTextField;
    
    HBLTestObservation *testObservation;

}

@end

static void *ktestContext  = &ktestContext;

@implementation Observation2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    testObservation = [HBLTestObservation shared];
    [testObservation addHBLObserver:self forKey:@"userName" context:@"testContext"];
    
//    [testObservation addObserver:self forKeyPath:@"userName" options:NSKeyValueObservingOptionNew context:ktestContext];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
//{
//    if (context == ktestContext) {
//        NSLog(@"same");
//    }
//    NSLog(@"sdfsdf");
//}

- (void)observerHBLValueForKey:(NSString *)key ofObject:(NSObject *)object newValue:(id)newValue oldValue:(id)oldValue context:(NSString *)context
{
    NSLog(@"oldValue = %@, newValue = %@", oldValue, newValue);
    NSString *newName = [NSString stringWithFormat:@"%@", newValue];
    afterObservationTextField.text = newName;

}


- (IBAction)changedTextFiledClicked:(id)sender
{
    NSArray *names = @[@"Lisa", @"MeiMei", @"Elan", @"LiLy", @"Peter", @"Tony"];
    NSUInteger index = arc4random_uniform((u_int32_t)names.count);
    showNameTextField.text = names[index];
    testObservation.userName = names[index];
}

- (IBAction)removeObservationClicked:(id)sender
{
    [testObservation removeHBLObserver:self forKey:@"userName"];
}

- (void)dealloc
{
//    [testObservation removeObserver:self forKeyPath:@"userName"];
}

@end
