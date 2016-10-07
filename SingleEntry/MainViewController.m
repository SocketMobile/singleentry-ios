//
//  MainViewController.m
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

#import "MainViewController.h"

// SOFTSCAN is a ScanAPI feature that uses the
// host camera as Scanner using the same API as
// any other Socket Mobile scanners.
// This feature is not activated by default, to
// activate this feature the application can do a
// set softscan status to supported and then enable
// it which will cause a device arrival to occur with
// the SoftScan info in the device info. A device removal
// occurs if the set softscan feature is set to disabled.
// since SoftScan displays a viewfinder it is required to
// give the UIViewController as reference by using the Set
// Overlay view property prior to trigger a SoftScan read.
// The application must provide a button to trigger a SoftScan
// read.
// Symbologies state can be set or retrieved by using the same
// Symbology property as any other scanner.
// Comment this line out if no SoftScan is required.
#define USE_SOFTSCAN 1

@implementation MainViewController
{
#ifdef USE_SOFTSCAN
    __weak DeviceInfo* _softScanDeviceInfo;
#endif
    __weak DeviceInfo* _deviceInfoToTrigger;
    NSDate* _lastCheck;
    NSInteger _sameSecondCount;
    int _deviceNotifications;
    __weak DeviceInfo* _lastDeviceNonSoftScanConnected;
}

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize Entry = _Entry;
@synthesize Status = _Status;
@synthesize ScanApi;
@synthesize ScanApiConsumer;
@synthesize scanApiVersion;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    _devices=[[NSMutableArray alloc]init];
    _deviceNotifications = 0;// by default we assume the device has not notifications
    _lastDeviceNonSoftScanConnected = nil;
    
    // change this to YES if you want SingleEntry to
    // confirm the decoded data
    _doAppDataConfirmation=NO;

	if(ScanApi==nil){
#ifdef USE_SOFTSCAN
        // this is useful for SoftScan to keep a handle
        // that is used in the trigger button
        _softScanDeviceInfo=nil;
#endif

        ScanApi=[[ScanApiHelper alloc]init];
        [ScanApi setDelegate:self];
        [ScanApi open];
        ScanApiConsumer=[NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    }

}

- (void)viewDidUnload
{
    [self setStatus:nil];
    [self setEntry:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    _devices=nil;
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

-(void)onTimer: (NSTimer*)theTimer{
    if(theTimer==ScanApiConsumer){
        [ScanApi doScanApiReceive];
    }
}

#pragma mark - Flipside View Controller
// this is used by the Flipside view to know if
// SoftScan is enabled
- (BOOL) isSoftScanEnabled
{
    return _softScannerEnabled;
}

-(NSString*)getScanApiVersion
{
    return scanApiVersion;
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{

#ifdef USE_SOFTSCAN
    // if the SoftScan switch has changed in the
    // Flipside view, then enable or disable SoftScan which
    // will cause a onDeviceArrival or onDeviceRemoval to occur
    // with the SoftScan deviceInfo
    // THIS CODE CAN BE IGNORED IF SOFTSCAN IS NOT NEEDED
    if(controller.hasSoftScanChanged){
        unsigned char action=kSktScanDisableSoftScan;
        _softScannerEnabled=controller.softScannerEnabled;
        if(_softScannerEnabled)
            action=kSktScanEnableSoftScan;
        [ScanApi postSetSoftScanStatus:action Target:self Response:@selector(onSetSoftScanStatus:)];
    }
    
    if(controller.hasBatteryLevelChanged){
        _deviceNotifications = controller.deviceNotifications;
        [ScanApi postSetNotificationsForDevice:_lastDeviceNonSoftScanConnected forNotifications:_deviceNotifications Target:self Response:@selector(onSetDeviceNotifications:)];
    }
#endif

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    }
}

- (int)getDeviceNofitications
{
    return _deviceNotifications;
}

- (BOOL)isLastNonSoftScanDeviceConnected
{
    return (_lastDeviceNonSoftScanConnected!=nil);
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    __weak id weakSelf = self;
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:weakSelf];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

#pragma mark - UI Handlers
// Trigger button handler mostly use for
// trigger a SoftScan read.
// This postSetTriggerDevice will fail if the
// postSetOverlayView is not done before.
// THIS CODE CAN BE IGNORED IF SOFTSCAN IS NOT NEEDED
- (IBAction)triggerSoftScan:(id)sender {
#ifdef USE_SOFTSCAN
    [ScanApi postSetTriggerDevice:_deviceInfoToTrigger Action:kSktScanTriggerStart Target:self Response:@selector(onSetTrigger:)];
#endif
}

#pragma mark - Device Info List management
-(void) updateDevicesList:(DeviceInfo*) deviceInfo Add:(BOOL)add{
    if(add==YES){
        [_devices addObject:deviceInfo];
    }
    else{
        [_devices removeObject:deviceInfo];
    }

    NSMutableString* temp=[[NSMutableString alloc]init];
    for (DeviceInfo* info in _devices) {
        [temp appendString:[info getName]];
        if(info.getBatteryLevel.length>0 ){
            [temp appendString:[NSString stringWithFormat:@" %@",[info getBatteryLevel]]];
        }
        [temp appendString:@"\n"];
    }
    if(_devices.count>0)
        [temp appendString:@"ready to scan"];
    else
        [temp appendString:@"Waiting for Scanner..."];

    _Status.text=temp ;

}

/*
-(DeviceInfo*)retrieveDeviceInfoFromHandle:(id<ISktScanDevice>)hDevice{
    DeviceInfo* result=nil;
    for (DeviceInfo* device in _devices) {
        if([device getSktScanDevice]==hDevice)
            result=device;
    }
    return result;
}
*/
#pragma mark - ScanApiHelper complete delegates
// THE 2 FOLLOWING CALLBACKS ARE FOR DEMO ONLY FOR SHOWING HOW
// TO CHECK IF A SYMBOLOGY IS ALREADY ENABLED AND IF NOT IT ENABLES
// IT RIGHT THERE. THE GOAL IS TO CONFIGURE ONCE THE SCANNER WHEN IT
// CONNECTS TO THE DEVICE. IF THERE IS NO SPECIFIC NEED TO CONFIGURE
// THE SCANNER, THESE CALLBACKS CAN BE REMOVED

// callback received when the Get Symbology Status is completed
-(void)onGetSymbologyDpm:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        DeviceInfo* deviceInfo=[ScanApi getDeviceInfoFromScanObject:scanObj];
        if(deviceInfo!=nil){
            ISktScanSymbology* symbology=[[scanObj Property]Symbology];
            if([symbology getStatus]==kSktScanSymbologyStatusDisable){
                [ScanApi postSetSymbologyInfo:deviceInfo SymbologyId:kSktScanSymbologyDirectPartMarking Status:TRUE Target:self Response:@selector(onSetSymbology:)];
            }
        }
    }
    else{
        // an error message should be displayed here
        // indicating that the DPM symbology status cannot be retrieved
    }
}

// callback received when the Set Symbology Status is completed
-(void)onSetSymbology:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(!SKTSUCCESS(result)){
        // display an error message saying a symbology cannot be set
    }
}

// callback received when the postGetNotificationsFromDevice is completed
-(void)onGetDeviceNotifications:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        _deviceNotifications = (int) [[scanObj Property] getUlong];
    }
}
// callback received when the postSetNotificationsForDevice is completed
-(void)onSetDeviceNotifications:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"SetDeviceNotifications OK");
    }
    else{
        NSLog(@"SetDeviceNotifications Error %ld",result);
        _deviceNotifications=0;// by default we reset the notifications to 0
        if(result == ESKT_NOTSUPPORTED){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"This device does not support battery level notification"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat: @"Unable to set the device notification, Error %ld", result ]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

// callback received when the postGetNotificationsFromDevice is completed
-(void)onGetBatteryLevel:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"Get Device Battery Level OK: %d",SKTBATTERY_GETCURLEVEL([[scanObj Property]getUlong]));
        DeviceInfo* deviceInfo = [ScanApi getDeviceInfoFromScanObject:scanObj];
        [deviceInfo setBatteryLevel:[NSString stringWithFormat:@"%d%%",SKTBATTERY_GETCURLEVEL([[scanObj Property]getUlong])]];
        [self updateDevicesList:deviceInfo Add:NO];
        [self updateDevicesList:deviceInfo Add:YES];
    }
    else{
        NSLog(@"Get Device Battery Level Error %ld",result);
    }
}

/**
 *
 */
-(void) onSetDataConfirmationMode:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"DataConfirmation Mode OK");
    }
    else{
        NSLog(@"DataConfirmation Mode Error %ld",result);
    }
}


/**
 *
 */
-(void) onDataConfirmation:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"Data Confirmed OK");
    }
    else{
        NSLog(@"Data Confirmed Error %ld",result);
    }
}

/**
 *
 */
-(void) onSetLocalDecodeAction:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"Local Decode Action OK");
    }
    else{
        NSLog(@"Local Decode Action Error %ld",result);
    }
}

/**
 *
 */
-(void) onGetSoftScanStatus:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        ISktScanProperty* property=[scanObj Property];
        if([property getByte]==kSktScanEnableSoftScan){
            NSLog(@"SoftScan is ENABLED");
            _softScannerEnabled=TRUE;
        }
        else{
            _softScannerEnabled=FALSE;
            NSLog(@"SoftScan is DISABLED");
        }

        NSLog(@"SoftScan status:");
    }
    else{
        NSLog(@"getting SoftScanStatus returned the error %ld",result);
    }
}

/**
 *
 */
-(void) onSetSoftScanStatus:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"SoftScan set status success");
    }
    else{
        NSLog(@"SoftScan set status returned the error %ld",result);
    }
}

/**
 *
 */
-(void) onSetTrigger:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"Trigger set success");
    }
    else{
        NSLog(@"Trigger set returned the error %ld",result);
    }
}

/**
 *
 */
-(void) onGetScanApiVersion:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        ISktScanProperty*property=[scanObj Property];
        if([property getType]==kSktScanPropTypeVersion){
            scanApiVersion=[NSString stringWithFormat:@"%lx.%lx.%lx.%ld",
                             [[property Version]getMajor],
                             [[property Version]getMiddle],
                             [[property Version]getMinor],
                             [[property Version]getBuild]];
        }
    }
    else{
        scanApiVersion=[NSString stringWithFormat:@"Get ScanAPI version Error: %ld",result];
    }
}

/**
 *
 */
#ifdef USE_SOFTSCAN
-(void) onSetOverlayView:(ISktScanObject*)scanObj{
    SKTRESULT result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        NSLog(@"Overlay view set success");
    }
    else{
        NSLog(@"Overlay view set returned the error %ld",result);
    }
}
#endif
/**
 * called each time a device connects to the host
 * @param result contains the result of the connection
 * @param newDevice contains the device information
 */
-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo{
    [self updateDevicesList:deviceInfo Add:YES];

#ifdef USE_SOFTSCAN
    // if the scanner is a SoftScan scanner
    if([deviceInfo.getTypeString compare:@"SoftScan"]==NSOrderedSame){
        _softScannerTriggerBtn.hidden=NO;
        _softScanDeviceInfo=deviceInfo;
        if(_deviceInfoToTrigger==nil)
            _deviceInfoToTrigger=deviceInfo;
        NSMutableDictionary* overlayParameter=[[NSMutableDictionary alloc]init];
        [overlayParameter setValue:self forKey:[NSString stringWithCString:kSktScanSoftScanContext encoding:NSASCIIStringEncoding]];
        [ScanApi postSetOverlayView:deviceInfo OverlayView:overlayParameter Target:self Response:@selector(onSetOverlayView:)];
    }
    else
#endif
    {
        _lastDeviceNonSoftScanConnected = deviceInfo;
        if([deviceInfo.getTypeString compare:@"CHS 8Ci Scanner"]==NSOrderedSame){
            _softScannerTriggerBtn.hidden=NO;
            _deviceInfoToTrigger=deviceInfo;
        }
        if(_doAppDataConfirmation==YES){
            // switch the comment between the 2 following lines for handling the
            // data confirmation beep from the scanner (local)
            // if none is set, the scanner will beep only once when SingleEntry actually
            // confirm the decoded data, otherwise the scanner will beep twice, one locally,
            // and one when SingleEntry will confirm the decoded data
            [ScanApi postSetDecodeActionDevice:deviceInfo DecodeAction:kSktScanLocalDecodeActionNone Target:self Response:@selector(onSetLocalDecodeAction:)];

    //        [ScanApi postSetDecodeAction:deviceInfo DecodeAction:kSktScanLocalDecodeActionBeep|kSktScanLocalDecodeActionFlash|kSktScanLocalDecodeActionRumble Target:self Response:@selector(onSetLocalDecodeAction:)];
        }

        // for demonstration only, let's make sure the DPM is enabled
        // first interrogate the scanner to see if it's already enabled
        // and in the onGetSymbologyDpm callback, if the DPM is not already set
        // then we send a Symbology property to enable it.
        [ScanApi postGetSymbologyInfo:deviceInfo SymbologyId:kSktScanSymbologyDirectPartMarking Target:self Response:@selector(onGetSymbologyDpm:)];
        
        
        // Also for demonstration only check the scanner notifications to update
        // the UI about Battery Level notifications
        [ScanApi postGetNotificationsFromDevice:deviceInfo Target:self Response:@selector(onGetDeviceNotifications:)];
        
        // Retrieve the device battery level to display the current Battery Level
        // that will then be refreshed each time a Battery Level notification is received
        // from the scanner
        [ScanApi postGetBattery:deviceInfo Target:self Response:@selector(onGetBatteryLevel:)];
        
    }

}


/**
 * called each time a device disconnect from the host
 * @param deviceRemoved contains the device information
 */
-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved{
    [self updateDevicesList:deviceRemoved Add:NO];
    if(_deviceInfoToTrigger==deviceRemoved){
        _deviceInfoToTrigger=nil;
    }
#ifdef USE_SOFTSCAN
    if(_softScanDeviceInfo==deviceRemoved){
        _softScanDeviceInfo=nil;
    }
    if(_deviceInfoToTrigger==nil)
        _deviceInfoToTrigger=_softScanDeviceInfo;
#endif
    if(_deviceInfoToTrigger==nil){
        _softScannerTriggerBtn.hidden=YES;
    }
}

/**
 * called each time ScanAPI is reporting an error
 * @param result contains the error code
 */
-(void) onError:(SKTRESULT) result{
    _Status.text=[NSString stringWithFormat:@"ScanAPI is reporting an error: %ld",result];
}

/**
 * called each time ScanAPI receives decoded data from scanner
 * @param deviceInfo contains the device information from which
 * the data has been decoded
 * @param decodedData contains the decoded data information
 */
-(void) onDecodedDataResult:(long)result device:(DeviceInfo *)device decodedData:(ISktScanDecodedData*)decodedData{
//-(void) onDecodedData:(DeviceInfo *)device decodedData:(ISktScanDecodedData*)decodedData{
    if(SKTSUCCESS(result)){
        _Entry.text=[NSString stringWithUTF8String:(const char *)[decodedData getData]];

        if(_doAppDataConfirmation==YES){
            [ScanApi postSetDataConfirmation:device goodData:true Target:self Response:@selector(onDataConfirmation:)];
        }
    }
}

/**
 * called when ScanAPI initialization has been completed
 * @param result contains the initialization result
 */
-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(SKTSUCCESS(result)){

#ifdef USE_SOFTSCAN
        // make sure we support SoftScan
        [ScanApi postSetSoftScanStatus:kSktScanSoftScanSupported Target:self Response:@selector(onSetSoftScanStatus:)];

        // check if SoftScan is enabled
        [ScanApi postGetSoftScanStatus:self Response:@selector(onGetSoftScanStatus:)];
#else
        // disable support SoftScan (Default, not really needed if it was never activated)
        [ScanApi postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:self Response:@selector(onSetSoftScanStatus:)];
#endif

        // ask for ScanAPI version (not a requirement but always nice to know)
        [ScanApi postGetScanApiVersion:self Response:@selector(onGetScanApiVersion:)];

        // configure ScanAPI for doing App Data confirmation,
        // if TRUE then SingleEntry will confirm the decoded data
        if(_doAppDataConfirmation==YES){
            [ScanApi postSetConfirmationMode:kSktScanDataConfirmationModeApp Target:self Response:@selector(onSetDataConfirmationMode:)];
        }
        _Status.text=@"Waiting for scanner...";
    }
    else{
        _Status.text=[NSString stringWithFormat:@"Error initializing ScanAPI:%ld",result];
    }
}

/**
 * called when ScanAPI has been terminated. This will be
 * the last message received from ScanAPI
 */
-(void) onScanApiTerminated{

}

/**
 * called when an error occurs during the retrieval
 * of a ScanObject from ScanAPI.
 * @param result contains the retrieval error code
 */
-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    _Status.text=[NSString stringWithFormat:@"Error retrieving ScanObject:%ld",result];
}

/**
 * called each time the device battery level changes.
 * The notification parameter contains the level of the device battery including the range min and max.
 * Most of the scanners report a range from 0 to 100, where the value can then be expressed in percentile.
 *
 */
-(void) onEventBatteryLevelResult:(long)result device:(DeviceInfo*) deviceInfo batteryLevel:(int)battery
{
    if(SKTSUCCESS(result)){
        NSLog(@"On Device Battery Level Change: %d",SKTBATTERY_GETCURLEVEL(battery));
        [deviceInfo setBatteryLevel:[NSString stringWithFormat:@"%d%%",SKTBATTERY_GETCURLEVEL(battery)]];
        [self updateDevicesList:deviceInfo Add:NO];
        [self updateDevicesList:deviceInfo Add:YES];
    }
    else{
        NSLog(@"On Device Battery Level Change: %ld",result);
    }
}
@end
