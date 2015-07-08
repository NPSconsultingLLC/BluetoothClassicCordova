//
//  BTConnectionManager.m
//
//  Created by Nathan Stryker on 11/26/14.
//  Copyright (c) 2014 Nathan Stryker. All rights reserved.
//

#import "BluetoothSerial.h"

@interface BluetoothSerial()

@property (nonatomic, strong) EASession             *session;
@property (nonatomic, strong) NSMutableData         *readData;
@property (nonatomic, strong) NSMutableData         *writeData;
@property (nonatomic, strong) EAAccessory           *accessory;
@property (nonatomic, strong) NSMutableArray        *accessoriesList;
@property (nonatomic, strong) NSMutableString       *concatString;
@property (nonatomic, strong) CDVInvokedUrlCommand  *sessionCommand;
@property (nonatomic, strong) CDVInvokedUrlCommand  *reflashCommand;
@property (nonatomic)         NSUInteger             offset;
@property (nonatomic)         NSInteger              dataLength;
@property (nonatomic)         NSInteger              percentComplete;
@property (nonatomic)         BOOL                   isReflashing;

@end

@implementation BluetoothSerial

#define EAD_INPUT_BUFFER_SIZE 2048

- (void)accessoryConnected:(NSNotification *)notification
{
    
    NSLog(@"EAController::accessoryConnected");
    //return data string from Connected device.
    
    if(!_session){
        [self openSessionForProtocol:@"com.uk.tsl.rfid"];
    }
}

- (void)accessoryDisconnected:(NSNotification *)notification{
    NSLog(@"accessory disconnected");
    [self closeSession:nil];
}

// low level read method - read data while there is data and space available in the input buffer
- (void)readReceivedData{
    
    uint8_t buf[EAD_INPUT_BUFFER_SIZE];
    
    while ([[_session inputStream] hasBytesAvailable])
    {
        NSInteger bytesRead = [[_session inputStream] read:buf maxLength:EAD_INPUT_BUFFER_SIZE];
        if (_readData == nil) {
            _readData = [[NSMutableData alloc] init];
            
        }
        [_readData appendBytes:(void *)buf length:bytesRead];
    }
    
    CDVPluginResult *pluginResult = nil;
    
    uint8_t *s = (uint8_t*)self.readData.bytes;
    
    NSString *debugString = [[NSString alloc] init];
    
    for(unsigned int i = 0; i < _readData.length; i++){
        debugString = [debugString stringByAppendingFormat:@"%02x", s[i]];
        debugString = [debugString stringByAppendingFormat:@""];
    }

    NSString* newStr = [[NSString alloc] initWithData:_readData encoding:NSUTF8StringEncoding];
    NSLog(@"read data = %@", newStr);
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:debugString];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_sessionCommand.callbackId];
    _readData = nil;
    
}

- (EASession *)openSessionForProtocol:(NSString *)protocolString{
    
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
    EAAccessory *accessory = nil;
    for (EAAccessory *obj in accessories) {
        if ([[obj protocolStrings] containsObject:protocolString]){
            accessory = obj;
            break;
        }
    }
    
    if (accessory){
        _session = [[EASession alloc] initWithAccessory:accessory
                                            forProtocol:protocolString];
        if (_session) {
            [[_session inputStream] setDelegate:self];
            [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                              forMode:NSDefaultRunLoopMode];
            [[_session inputStream] open];
            
            [[_session outputStream] setDelegate:self];
            [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                               forMode:NSDefaultRunLoopMode];
            [[_session outputStream] open];
        }
    }
    
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_sessionCommand.callbackId];
    
    
    return _session;
}

// Handle communications from the streams.
- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent
{
    
    switch (streamEvent)
    {
        case NSStreamEventHasBytesAvailable:
            // Process the incoming stream data.
            [self readReceivedData];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            
            break;
            
        case NSStreamEventEndEncountered:
            break;
        default:
            break;
    }
    
}

#pragma mark method calls for hybrid app

//get the currently connected devices.
- (void)list:(CDVInvokedUrlCommand *)command{
    
    _accessoriesList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    CDVPluginResult *pluginResult = nil;
    
    NSMutableArray *dictArray = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [_accessoriesList count]; i++){
        EAAccessory *accessory = [_accessoriesList objectAtIndex:i];
        NSMutableDictionary *accessoryDict = [[NSMutableDictionary alloc] init];
        
        [accessoryDict setValue:[NSNumber numberWithBool:accessory.connected] forKeyPath:@"connected"];
        [accessoryDict setValue:[NSNumber numberWithLong:accessory.connectionID] forKeyPath:@"connectionID"];
        [accessoryDict setValue:accessory.name forKey:@"name"];
        [accessoryDict setValue:accessory.manufacturer forKeyPath:@"manufacturer"];
        [accessoryDict setValue:accessory.modelNumber forKeyPath:@"modelNumber"];
        [accessoryDict setValue:accessory.serialNumber forKeyPath:@"serialNumber"];
        [accessoryDict setValue:accessory.firmwareRevision forKeyPath:@"firmwareRevision"];
        [accessoryDict setValue:accessory.hardwareRevision forKeyPath:@"hardwareRevision"];
        [accessoryDict setValue:accessory.protocolStrings forKeyPath:@"protocols"];
        
        [dictArray insertObject:accessoryDict atIndex:i];
    }
    
    if(_accessoriesList > 0){
        NSArray *array = [NSArray arrayWithArray:dictArray];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

//call to connect to a bluetooth device
- (void)connect:(CDVInvokedUrlCommand *)command{
    
    if(_session){
        [self closeSession:nil];
    }
    
    _concatString = [[NSMutableString alloc] init];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryDisconnected:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    
    //return data string from Connected device.
    _sessionCommand = [[CDVInvokedUrlCommand alloc] init];
    _sessionCommand = command;
    
    [self openSessionForProtocol:@"com.uk.tsl.rfid"];
}

//call to disconnect to bt device
- (void)disconnect:(CDVInvokedUrlCommand *)command{
    _sessionCommand = [[CDVInvokedUrlCommand alloc] init];
    _sessionCommand = command;
    
    [self closeSession:command];
    
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
//return connection status
- (void)isConnected:(CDVInvokedUrlCommand*)command{
    
    _accessoriesList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    CDVPluginResult *pluginResult = nil;
    
    if(_accessoriesList >0 && _session){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

//subscribe to data stream
- (void)subscribe:(CDVInvokedUrlCommand *)command{
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    //return data string from Connected device.
    _sessionCommand = [[CDVInvokedUrlCommand alloc] init];
    _sessionCommand = command;
    
    if(_session){
        [[_session outputStream] open];
        
    }else{
        //no data available.
    }
    
}

// close the session with the accessory.
- (void)closeSession:(CDVInvokedUrlCommand *)command{
    
    [[_session inputStream] close];
    [[_session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[_session inputStream] setDelegate:nil];
    [[_session outputStream] close];
    [[_session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[_session outputStream] setDelegate:nil];
    
    _session = nil;
    _readData = nil;
}

//send request to
-(void)write:(CDVInvokedUrlCommand *)command{

    CDVPluginResult *pluginResult = nil;
    
//    while (([[_session outputStream] hasSpaceAvailable])){
//        
//        NSInteger bytesWritten = [[_session outputStream] write:[prepareData bytes] maxLength:[prepareData length]];
//        
//        if (bytesWritten <= 0 ){
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//            break;
//        }
//        else if (bytesWritten > 0){
//            [_writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
//        }
//    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end
