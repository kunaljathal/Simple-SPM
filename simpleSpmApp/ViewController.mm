//
//  ViewController.m
//  simpleSpmApp
//
//  Created by Kunal Jathal on 8/8/15.
//  Copyright (c) 2015 Kunal Jathal. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "ViewController.h"
#include <algorithm>
#include "spmCalculator.hpp"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *spmLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchStartAcc;
@property (weak, nonatomic) IBOutlet UILabel *switchLabel;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic) BOOL logData;
@property (nonatomic) int CountDown;
@property (strong, nonatomic) NSTimer *timer;
@end

// ==========================================================================
// These are the variables you can tweak to try out different configurations.
// ==========================================================================

// How long you want the delay to be before the SPM analysis even begins (this is the 'X second' hardcoded delay)
const int countDownInSeconds = 10;

// Accelerometer Sampling Frequency (in Hz)
const int accelerometerSamplingFrequency = 100;

// The length of the window over which the SPM analysis should be carried out. Or, in other words, how long you're willing to wait
// before getting an SPM answer. Try starting with 5, and go up to 10 if you want.
const int spmAnalysisWindowLengthInSeconds = 5;

// Accelerometer Data Arrays.
// The length of the 3 arrays here MUST be equal to the accelerometerSamplingFrequency * spmAnalysisWindowLength.
// In this setup, I'm using accelerometerSamplingFrequency = 100, and a 5 second window. So the array lengths are 5 * 100 = 500.

const int windowLengthInSamples = accelerometerSamplingFrequency * spmAnalysisWindowLengthInSeconds;

double accelerometerLogX[windowLengthInSamples];
double accelerometerLogY[windowLengthInSamples];
double accelerometerLogZ[windowLengthInSamples];


// Global counter. You don't really need to touch this.
int accelerometerCounter = 0;


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // We're not logging data upon app launch, so chill.
    self.logData = NO;
    self.CountDown = countDownInSeconds;
    
    // Set up accelerometer & it's callback.
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1/accelerometerSamplingFrequency;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                                 [self outputAccelerationData:accelerometerData.acceleration];
                                                 if(error){
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleSwitch:(UISwitch *)sender {    
    // If the switch is turned ON, start the countdown. The logging will happen automatically when the countdown
    // is over, for spmAnalysisWindowLength seconds, after which the SPM will be displayed and the switch will reappear.
    if ([sender isOn])
    {
        self.spmLabel.text = @"10";
        
        // Start a 10 second timer
        self.timer = [NSTimer scheduledTimerWithTimeInterval:(1)
                                                      target: self
                                                    selector:@selector(onTimer)
                                                    userInfo: nil repeats: YES];
        
        [self.switchStartAcc setHidden:YES];
        self.switchLabel.text = @"";
    }
}

// Timer callback
-(void)onTimer
{
    self.CountDown--;
    self.spmLabel.text = [NSString stringWithFormat:@"%i", self.CountDown];
    
    if (self.CountDown  == 0)
    {
        // Start logging accelerometer data and stop the timer!
        [self stopTimer];
        self.spmLabel.text = @"";
        self.logData = YES;
    }
}

-(void)stopTimer
{
    if (self.timer != nil)
    {
        [self.timer invalidate];
        self.timer = nil;
        self.CountDown = countDownInSeconds;
    }
    
}

-(void)stopLoggingData
{
    // Set logging flag to NO
    self.logData = NO;

    // Clear arrays
    std::fill(accelerometerLogX, accelerometerLogX + windowLengthInSamples, 0);
    std::fill(accelerometerLogY, accelerometerLogY + windowLengthInSamples, 0);
    std::fill(accelerometerLogZ, accelerometerLogZ + windowLengthInSamples, 0);
    
    // Reset counter
    accelerometerCounter = 0;
    
}

-(void)outputAccelerationData:(CMAcceleration)acceleration
{
    if (self.logData)
    {
        // Record accelerometer data to array
        accelerometerLogX[accelerometerCounter] = acceleration.x;
        accelerometerLogY[accelerometerCounter] = acceleration.y;
        accelerometerLogZ[accelerometerCounter] = acceleration.z;
        
        accelerometerCounter++;
        
        if (accelerometerCounter == windowLengthInSamples)
        {
            // We now have a 5 second window of data! Send this to the library....
            int spm = spmCalculator::spmCalculate(accelerometerLogX, accelerometerLogY, accelerometerLogZ, accelerometerSamplingFrequency, spmAnalysisWindowLengthInSeconds);
            self.spmLabel.text = [NSString stringWithFormat:@"%i", spm];
            
            // Done! Stop logging data.
            [self stopLoggingData];
            [self.switchStartAcc setOn:NO animated:YES];
            [self.switchStartAcc setHidden:NO];
            self.switchLabel.text = @"Begin Countdown";
        }
    }
    
}



@end
