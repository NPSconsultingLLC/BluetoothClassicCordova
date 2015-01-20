//
//  ViewController.h
//  BluetoothDongle
//
//  Created by Nathan Stryker on 6/10/14.
//  Copyright (c) 2014 Nathan Stryker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDVPlugin.h>

@interface BluetoothDongle : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate>

//get the currently connected devices.
- (void)list:(CDVInvokedUrlCommand *)command;

//call to connect to a bluetooth device
- (void)connect:(CDVInvokedUrlCommand *)command;

//close the connection
- (void)closeSession:(CDVInvokedUrlCommand *)command;

//call to disconnect to bt device
- (void)disconnect:(CDVInvokedUrlCommand *)command;

//Returns indicating if we are connected to a BT device
- (void)isConnected:(CDVInvokedUrlCommand*)command;

//get dongle version
-(void)version:(CDVInvokedUrlCommand *)command;

//subscribe to data stream
- (void)subscribe:(CDVInvokedUrlCommand *)command;

//reflash the dongle with a new firmware
- (void)reflash:(CDVInvokedUrlCommand *)command;

@end



