# DEPRECATED ⛔️
This sample app uses ScanAPI SDK which is EOL and has been replaced by our
Capture SDK which offer the same features and is easier to use.

Please check https://github.com/SocketMobile/capturesingleentry-ios and
https://github.com/SocketMobile/capturesingleentryswift-ios

The new Capture SDK supports all of our Socket Mobile devices.

SingleEntry for iOS
This simple iOS app is a sample code for using ScanAPI SDK.

## IMPORTANT
When using/installing CocoaPods in a new project, the project workspace file
should be used instead of the project file.

Our Barcode Bluetooth Scanners are using External Accessory Framework. It is
very important to make sure your application info plist file contains in the
Supported External Accessory protocol string array our Scanner protocol string
which is `com.socketmobile.chs`. In the previous version of Xcode it used to
give an error message in the traces but that is no longer the case with the most
recent version of Xcode.

## Prerequisites
This SDK uses CocoaPods. If it needs to be installed please check the CocoaPods
website for the most current instructions:
https://cocoapods.org/

The Socket Mobile ScanAPI SDK is also required in order to compile this sample.

## Installation
Unzip the ScanApiSDK-10.x.x.zip file at the same root as the clone of this app.

ie:
```
/Documents
        /SingleEntry
        /ScanApiSDK-10.x.x
```
Edit the SingleEntry/Podfile and make sure the ScanAPI version matches with the
one that has been unzipped.

From a Terminal window, type pod install in the SingleEntry directory.

Load the SingleEntry workspace (NOT PROJECT) in Xcode and compile and run.

## Documentation
The ScanAPI documentation can be found at:
http://www.socketmobile.com/docs/default-source/developer-documentation/scanapi.pdf?sfvrsn=2

## Description
SingleEntry displays a scanner connection status. When a scanner is connected,
its friendly name is displayed.
The edit box receives the decoded data from the scanner.

There is a information button at the bottom of the screen (iPhone/iPod version),
at the top left corner of the screen (iPad), that shows a secondary view. This
view displays the version of ScanAPI and a switch to turn ON or OFF the
SoftScan.

## Implementation
In this simple example the ScanApiHelper is "attached" to the main view
controller. This main view controller derives from the ScanApiHelperDelegate
protocol and implements some of the delegate methods.

### main view controller viewDidLoad
create and initialize a ScanApiHelper instance and a ScanApiConsumer timer.
open ScanApiHelper

### ScanApiHelperDelegate onScanApiInitializeConplete
This part is optional, but this SingleEntry app does support SoftScan. So it is
enabled here by doing a postSeftSoftScanStatus.

Ask for the ScanAPI version.

### handle for ScanAPI version
As example, when a ScanApiHelper set or get function is used it returns
immediately and the response will be received in the provided selector.
For getting the ScanAPI version the onGetScanApiVersion selector is invoked with
the result and response. The version is then saved to be ready to display in the
Flipside view.

### onDeviceArrival
This ScanApiHelperDelegate method is called when a scanner is successfully
detected on the host. The scanner can be SoftScan or any other Socket Mobile
scanners supported by ScanAPI.
In this particular case the connection status is updated with the name of the
new device. If the device is SoftScan then the trigger button is enable and
visible.
As an example, the status of the Direct Part Marking symbogy is requested.

### onDeviceRemoval
When a scanner is no longer available (disconnected), this delegate is invoked.
In this particular case, the connection status is updated and if the device is
SoftScan then the trigger button is hidden from the interface.

### onDecodedData(Result)
There are actually 2 onDecodedData delegates defined in ScanApiHelperDelegate.
The second one has the result as arguments and is the recommended one to use.

The code updates the text box with the decoded data received after checking if
the result is successful.

## ScanApiHelper
ScanApiHelper is provided as source code. It provides a set of very basic
features like enabling disabling barcode symbologies.

If a needed feature is not implemented by ScanApiHelper, the recommendation is
to create an extension of ScanApiHelper and copy paste a feature similar from
ScanApiHelper to the extended one.

Following this recommendation will prevent to loose the modifications at the
next update.
