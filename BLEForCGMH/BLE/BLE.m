//
//  BLE.m
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "BLE.h"
#import <UIKit/UIKit.h>
#import "DRAGER.h"
#import "Hamilton.h"
#import "SERVOi.h"

#ifndef BLE_h
#define BLE_h

#define SERVICE_UUID @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define NOTIFY_UUID @"49535343-1E4D-4BD9-BA61-23C647249616"
#define WRITE_UUID @"49535343-8841-43F4-A8D4-ECBE34729BB3"

#endif

typedef NS_ENUM(NSUInteger, DEVICE_TYPE) {
    DEVICE_TYPE_NONE = 0,
    DEVICE_TYPE_UNKNOW,
    DEVICE_TYPE_DRAGER,
    DEVICE_TYPE_SERVOI,
    DEVICE_TYPE_HAMILTON
};

@implementation BLE {
    id device;
    DEVICE_TYPE deviceType;
}

- (id)init {
    self = [super init];
    if (self) {
        deviceType = DEVICE_TYPE_UNKNOW;
        ventilation = [[VentilationData alloc] init];
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

#pragma -mark Bluetooth Delegate
//簡查設備是否支持BLE
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        //藍牙沒有打開
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@ connected.", peripheral.name);
    
    if(_peripheral != nil) {
        //NSLog(@"Connect To Peripheral with name: %@\nwith UUID:%@\n",peripheral.name,CFUUIDCreateString(nil, peripheral.UUID));
        
        peripheral.delegate = self;
        
        //執行"discoverService"功能去尋找可用的Service
        [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];//藍牙棒Service UUID
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        return;
    }
    
    for (CBService *service in peripheral.services) {
        if (service.characteristics) {
            [self peripheral:peripheral didDiscoverCharacteristicsForService:service error:nil]; //already discovered characteristic before, DO NOT do it again
        }
        else {
            [peripheral discoverCharacteristics:nil forService:service]; //need to discover characteristics
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NOTIFY_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            _notifyCharacteristic = characteristic;
            NSLog(@"[notify]didDiscoverCharacteristicsForService");
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_UUID]]) {
            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
            _writeCharacteristic = characteristic;
            NSLog(@"[write]didDiscoverCharacteristicsForService");
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    if (_peripheral.state != CBPeripheralStateDisconnected && _notifyCharacteristic != nil && _writeCharacteristic != nil) {
        if ([deviceInfo.DeviceName isEqualToString:@"DRAGER"]) {
            deviceType = DEVICE_TYPE_DRAGER;
            device = [[DRAGER alloc] init];
            NSData *cmdICC = [device getICC_Command];
            [self sendData:cmdICC];
        }
        else if ([deviceInfo.DeviceName isEqualToString:@"HAMILTON"]) {
            deviceType = DEVICE_TYPE_HAMILTON;
            device = [[Hamilton alloc] init];
        }
        else if ([deviceInfo.DeviceName isEqualToString:@"SERVOI"]) {
            deviceType = DEVICE_TYPE_SERVOI;
            device = [[SERVOi alloc] init];
            NSData *cmdInit = [device getInitCommand];
            [self sendData:cmdInit];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        return;
    }
    NSData *cmd = nil;
    
    switch (deviceType) {
        case DEVICE_TYPE_DRAGER:
            //傳值給DRAGER
            switch ([device run:characteristic.value VentilationData:ventilation command:cmd]) {
                case DRAGER_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    [self sendData:cmd];
                    [device resetStep];
                    cmd = nil;
                    
                    usleep(300000);
                    [self disconnect];
                    break;
                    
                case DRAGER_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [self disconnect];
                    break;
                    
                default:
                    break;
            }
            
            if (cmd != nil) {
                [self sendData:cmd];
            }
            break;
            
        case DEVICE_TYPE_HAMILTON:
            //傳值給HAMILTON
            switch ([device run:characteristic.value VentilationData:ventilation command:cmd]) {
                case HAMILTON_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    [device resetStep];
                    cmd = nil;
                    
                    usleep(300000);
                    [self disconnect];
                    
                    break;
                    
                case HAMILTON_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [self disconnect];
                    break;
                    
                default:
                    break;
            }
            
            if (cmd != nil) {
                [self sendData:cmd];
            }
            break;
            
        case DEVICE_TYPE_SERVOI:
            switch ([device run:characteristic.value VentilationData:ventilation command:cmd]) {
                case SERVOI_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    [device resetStep];
                    cmd = nil;
                    
                    usleep(300000);
                    [self disconnect];
                    break;
                    
                case SERVOI_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [self disconnect];
                    break;
                    
                default:
                    break;
            }
            
            if (cmd != nil) {
                [self sendData:cmd];
            }
            break;
            
        default:
            return;
    }
}

#pragma -mark private Methods

- (void)readValue {
    [_peripheral readValueForCharacteristic:_notifyCharacteristic];
}

- (void)sendData:(NSData *)data {
    @try {
        NSLog(@"SendData:%ld", [data length]);
        [_peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    @catch (NSException *exception) {
        NSLog(@"SendData Exception: %@", exception);
    }
}

- (void)disconnect {
    [_centralMgr cancelPeripheralConnection:_peripheral];
    _notifyCharacteristic = nil;
    _writeCharacteristic = nil;
    device = nil;
    deviceType = DEVICE_TYPE_NONE;
    deviceInfo = nil;
    NSLog(@"Disconnect.");
}

- (DeviceInfo *)getDeviceInfoByCode:(NSString *)code {
    DeviceInfo *di = [DeviceInfo alloc];
    
    if (code == nil || [code isEqualToString:@""] || [code rangeOfString:@"**"].location == NSNotFound) {
        //code和型號一定要有，否則回傳nil
        return nil;
    }
    else {
        NSArray *ary = [code componentsSeparatedByString:@"**"];
        di = [di initWithDeviceInfo:[ary objectAtIndex:0] :[ary objectAtIndex:1]];
    }
    
    return di;
}

#pragma -mark Methods
- (void)startReadByConnectionString:(NSString *)connectString {
    [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_CONNECTING];
    
    deviceInfo = [self getDeviceInfoByCode:connectString];
    
    if (deviceInfo != nil) {
        _centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:deviceInfo.DeviceUUID];
        
        NSArray *ary = [_centralMgr retrievePeripheralsWithIdentifiers:@[uuid]];
        _peripheral = [ary objectAtIndex:0];

        [_centralMgr connectPeripheral:_peripheral options:nil];
        
        ventilation = [[VentilationData alloc] init];
    }
}

@end
