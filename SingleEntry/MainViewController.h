//
//  MainViewController.h
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
#import "ScanApiHelper.h"
#import "FlipsideViewController.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UIPopoverControllerDelegate,ScanApiHelperDelegate>
{
    NSMutableArray* _devices;
}
@property BOOL softScannerEnabled;
@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (weak, nonatomic) IBOutlet UITextField *Entry;
@property (weak, nonatomic) IBOutlet UILabel *Status;
@property (weak, nonatomic) IBOutlet UIButton *softScannerTriggerBtn;
@property (strong, nonatomic) ScanApiHelper* ScanApi;
@property (strong, nonatomic) NSTimer* ScanApiConsumer;
@property (nonatomic) BOOL doAppDataConfirmation;
@property (strong, nonatomic) NSString *scanApiVersion;

- (IBAction)triggerSoftScan:(id)sender;

@end
