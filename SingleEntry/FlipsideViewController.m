//
//  FlipsideViewController.m
//  SingleEntry
//
//  Created by Eric Glaenzer on 1/16/12.
//
// Copyright 2015 Socket Mobile, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FlipsideViewController.h"
#import "ScanApiHelper.h"

@implementation FlipsideViewController
{
    BOOL _originalSoftScanState;
    int _originalDeviceNotifications;
}
@synthesize delegate = _delegate;

- (void)awakeFromNib
{
    self.preferredContentSize = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _scanApiVersion.text=[self.delegate getScanApiVersion];
    _originalSoftScanState=[self.delegate isSoftScanEnabled];
    _originalDeviceNotifications=[self.delegate getDeviceNofitications];
    _deviceNotifications=_originalDeviceNotifications;
    _softScannerEnabled=_originalSoftScanState;
    _enableSoftScan.on=_softScannerEnabled;
    if([self.delegate isLastNonSoftScanDeviceConnected]){
    _batteryLevel.on=(_originalDeviceNotifications&kSktScanNotificationsBatteryLevelChange)==kSktScanNotificationsBatteryLevelChange;
    }
    else{
        _batteryLevel.enabled=NO;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(BOOL)hasSoftScanChanged
{
    return (_originalSoftScanState!=self.enableSoftScan.isOn);
}

-(BOOL)hasBatteryLevelChanged
{
    if([self.delegate isLastNonSoftScanDeviceConnected]){
        return (_originalDeviceNotifications!= _deviceNotifications);
    }
    else{
        return FALSE;
    }
}

#pragma mark - Actions

- (IBAction)changeBatteryLevel:(id)sender {
//    _batteryLevel.on = !_batteryLevel.on;
    if(_batteryLevel.on){
        _deviceNotifications|=kSktScanNotificationsBatteryLevelChange;
    }
    else{
        _deviceNotifications&=~kSktScanNotificationsBatteryLevelChange;
    }
}

- (IBAction)done:(id)sender
{
    _softScannerEnabled=self.enableSoftScan.isOn;
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
