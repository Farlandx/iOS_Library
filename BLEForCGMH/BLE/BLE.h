//
//  BLE.h
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "VentilationData.h"
#import "DeviceInfo.h"

typedef NS_ENUM(NSUInteger, BleReadStatus) {
    BLE_READ_NONE = 0,
    BLE_SCANNING,
    BLE_SCAN_TIMEOUT,
    BLE_CONNECTING,
    BLE_DISCONNECTED,
    BLE_CONNECT_ERROR,
    BLE_READING_DATA,
    BLE_READ_ERROR,
    BLE_READ_DONE
};

@class BLE;
@protocol BleDelegate <NSObject>

@required
- (void)recievedVentilationDataAndReadStatus:(VentilationData *)data readStatus:(BleReadStatus)status;

@end

@interface BLE : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    DeviceInfo *deviceInfo;
    VentilationData *ventilation;
    NSString *ble_version;
}

@property (assign, nonatomic) id<BleDelegate> delegate;
@property (strong, nonatomic) CBCentralManager *centralMgr;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *notifyCharacteristic;
@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong, nonatomic) NSMutableData *mData;

#pragma -mark Methods
- (NSString *)getVersion;
- (void)setConnectionString:(NSString *)connectionString;
- (void)startRead;
- (void)disconnect;

@end
