//
//  DeviceInfo.h
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLE_DEVICE_TYPE.h"

@interface DeviceInfo : NSObject

@property (strong, nonatomic) NSString *BleMacAddress;
@property (nonatomic) DEVICE_TYPE DeviceType;

- (id)initWithDeviceInfoByBleMacAddress:(NSString *)BleMacAddress DeviceType:(NSString *)DeviceType;

@end
