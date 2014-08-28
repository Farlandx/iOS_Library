//
//  BLE.m
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "BLE.h"
#import "BLE_DEVICE_TYPE.h"
#import <UIKit/UIKit.h>
#import "DRAGER.h"
#import "Hamilton.h"
#import "SERVOi.h"

#ifndef BLE_h
#define BLE_h

#define SERVICE_UUID @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define NOTIFY_UUID @"49535343-1E4D-4BD9-BA61-23C647249616"
#define WRITE_UUID @"49535343-8841-43F4-A8D4-ECBE34729BB3"
#define TIMEOUT_INTERVAL 10.0f

#endif

@interface BLE ()<DRAGER_Delegate, Hamilton_Delegate, SERVOi_Delegate>

@end

@implementation BLE {
    id device;
    DEVICE_TYPE deviceType;
    BOOL isFindDevice;
    NSTimer *timeoutTimer;
}

- (id)init {
    self = [super init];
    if (self) {
        deviceType = DEVICE_TYPE_UNKNOW;
        ventilation = [[VentilationData alloc] init];
        isFindDevice = NO;
        timeoutTimer = [[NSTimer alloc] init];
        ble_version = [NSString stringWithFormat:@"BLE Library Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
    _delegate = nil;
}

#pragma mark - Bluetooth Delegate
//檢查設備是否支持BLE
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self scanDevices];
    }
}

//掃到設備
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *peripheralName = [peripheral.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSLog(@"Discovered %@, UUID:%@, RSSI:%@", peripheralName, [[peripheral identifier] UUIDString], RSSI);
    
    if (deviceInfo != nil && [peripheralName isEqualToString:deviceInfo.BleMacAddress] && !isFindDevice) {
        [timeoutTimer invalidate];
        isFindDevice = YES;
        NSArray *ary = [_centralMgr retrievePeripheralsWithIdentifiers:@[peripheral.identifier]];
        if (ary == nil || ary.count == 0) {
            [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_CONNECT_ERROR];
            return;
        }
        _peripheral = [ary objectAtIndex:0];
        [_centralMgr connectPeripheral:_peripheral options:nil];
        
        ventilation = [[VentilationData alloc] init];
    }
    else if(!isFindDevice) {
        [timeoutTimer invalidate];
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_INTERVAL target:self selector:@selector(scanStop:) userInfo:nil repeats:NO];
    }
}

//中斷連線
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (_peripheral) {
        _peripheral = nil;
        
        NSLog(@"Disconnected.");
        [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_DISCONNECTED];
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
        deviceType = deviceInfo.DeviceType;
        switch (deviceType) {
            case DEVICE_TYPE_DRAGER: {
                device = [[DRAGER alloc] init];
                ((DRAGER *)device).delegate = self;
                NSData *cmdICC = [device getICC_Command];
                [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_READING_DATA];
                [self sendData:cmdICC];
                break;
            }
                
            case DEVICE_TYPE_HAMILTON: {
                device = [[Hamilton alloc] init];
                ((Hamilton *)device).delegate = self;
                NSData *cmdFirst = [device getCommand:40];
                [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_READING_DATA];
                [self sendData:cmdFirst];
                break;
            }
                
            case DEVICE_TYPE_SERVOI: {
                device = [[SERVOi alloc] init];
                ((SERVOi *)device).delegate = self;
                NSData *cmdInit = [device getInitCommand];
                [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_READING_DATA];
                [self sendData:cmdInit];
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"peripheral error");
        return;
    }
    NSData *cmd = nil;
    switch (deviceType) {
        case DEVICE_TYPE_DRAGER:
            //傳值給DRAGER
            switch ([device run:characteristic.value VentilationData:ventilation]) {
                case DRAGER_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    
                    [timeoutTimer invalidate];
                    usleep(300000);
                    [self disconnect];
                    [device resetStep];
                    break;
                    
                case DRAGER_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [timeoutTimer invalidate];
                    [self disconnect];
                    break;
                    
                default:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READING_DATA];
                    break;
            }
            
            if (cmd != nil) {
                [self sendData:cmd];
            }
            break;
            
        case DEVICE_TYPE_HAMILTON:
            //傳值給HAMILTON
            switch ([device run:characteristic.value VentilationData:ventilation]) {
                case HAMILTON_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    
                    [timeoutTimer invalidate];
                    usleep(300000);
                    [self disconnect];
                    [device resetStep];
                    break;
                    
                case HAMILTON_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [timeoutTimer invalidate];
                    [self disconnect];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case DEVICE_TYPE_SERVOI:
            switch ([device run:characteristic.value VentilationData:ventilation]) {
                case SERVOI_DONE:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_DONE];
                    
                    [timeoutTimer invalidate];
                    usleep(300000);
                    [self disconnect];
                    [device resetStep];
                    break;
                    
                case SERVOI_ERROR:
                    [_delegate recievedVentilationDataAndReadStatus:ventilation readStatus:BLE_READ_ERROR];
                    [timeoutTimer invalidate];
                    [self disconnect];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            return;
    }
}

#pragma mark - Device Delegate
- (void)nextCommand:(NSData *)cmd {
    NSLog(@"send next command:%@", [[NSString alloc] initWithData:cmd encoding:NSUTF8StringEncoding]);
    [self sendData:cmd];
}

#pragma -mark private Methods
- (void)readValue {
    [_peripheral readValueForCharacteristic:_notifyCharacteristic];
}

- (void)sendData:(NSData *)data {
    @try {
        NSLog(@"SendData:%ld", [data length]);
        [_peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
        [timeoutTimer invalidate];
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_INTERVAL target:self selector:@selector(timeroutThread) userInfo:nil repeats:NO];
    }
    @catch (NSException *exception) {
        NSLog(@"SendData Exception: %@", exception);
    }
}

- (DeviceInfo *)getDeviceInfoByCode:(NSString *)code {
    DeviceInfo *di = [DeviceInfo alloc];
    
    if (code == nil || [code isEqualToString:@""] || [code rangeOfString:@"**"].location == NSNotFound) {
        //code和型號一定要有，否則回傳nil，mac_address不影響連線則不管他
        return nil;
    }
    else {
        NSArray *ary = [code componentsSeparatedByString:@"**"];
        di = [di initWithDeviceInfoByBleMacAddress:[ary objectAtIndex:0] DeviceType:[ary objectAtIndex:1]];
    }
    
    return di;
}

- (void)scanDevices {
    [_centralMgr scanForPeripheralsWithServices:nil options:nil];
    //五秒後停止scan
    [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_INTERVAL target:self selector:@selector(scanStop:) userInfo:nil repeats:NO];
}

#pragma mark - Timer
- (void)timeroutThread {
    NSLog(@"%s", __func__);
    [self disconnect];
}

- (void)scanStop:(NSTimer*)timer {
    if (_centralMgr != nil){
        [_centralMgr stopScan];
        if (!isFindDevice) {
            [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_SCAN_TIMEOUT];
        }
    }else{
        NSLog(@"_centralMgr is Null!");
    }
}

#pragma mark - Methods
- (NSString *)getVersion {
    if (ble_version) {
        return ble_version;
    }
    return @"";
}

//ConnectionString:BLE Name**DeviceType**MAC Address (Total 48 bytes)
- (void)setConnectionString:(NSString *)connectionString {
    [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_CONNECTING];
    
    deviceInfo = [self getDeviceInfoByCode:connectionString];
}

- (void)startRead {
    isFindDevice = NO;
    if (deviceInfo != nil) {
        if (!_centralMgr) {
            _centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
        else {
            [self scanDevices];
        }
        [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_SCANNING];
    }
    else [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_CONNECT_ERROR];
}

- (void)disconnect {
    if (_peripheral && _peripheral.state != CBPeripheralStateDisconnected) {
        if ([timeoutTimer isValid]) {
            [timeoutTimer invalidate];
        }
        [_centralMgr cancelPeripheralConnection:_peripheral];
        _notifyCharacteristic = nil;
        _writeCharacteristic = nil;
        device = nil;
        deviceType = DEVICE_TYPE_NONE;
        deviceInfo = nil;
        [_delegate recievedVentilationDataAndReadStatus:nil readStatus:BLE_DISCONNECTED];
    }
}

@end
