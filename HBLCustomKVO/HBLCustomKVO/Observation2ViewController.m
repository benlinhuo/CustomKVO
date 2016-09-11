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

@implementation Observation2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    testObservation = [HBLTestObservation new];
    [testObservation addHBLObserver:self forKey:@"userName" context:nil];
}

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


@end
