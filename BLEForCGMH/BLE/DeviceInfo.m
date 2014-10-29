//
//  DeviceInfo.m
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "DeviceInfo.h"

@implementation DeviceInfo

- (id)init {
    return [self initWithDeviceInfoByBleMacAddress:@"" DeviceType:@"NONE"];
}

- (id)initWithDeviceInfoByBleMacAddress:(NSString *)BleMacAddress DeviceType:(NSString *)DeviceType {
    self = [super init];
    if (self) {
        self.BleMacAddress = BleMacAddress;
        
        if (![DeviceType caseInsensitiveCompare:@"DRAGER"] || ![DeviceType caseInsensitiveCompare:@"DR"]) {
            self.DeviceType = DEVICE_TYPE_DRAGER;
        }
        else if (![DeviceType caseInsensitiveCompare:@"HAMILTON"] || ![DeviceType caseInsensitiveCompare:@"HA"]) {
            self.DeviceType = DEVICE_TYPE_HAMILTON;
        }
        else if (![DeviceType caseInsensitiveCompare:@"SERVOI"] || ![DeviceType caseInsensitiveCompare:@"SV"]) {
            self.DeviceType = DEVICE_TYPE_SERVOI;
        }
        else if (![DeviceType caseInsensitiveCompare:@"SERVO300"] || ![DeviceType caseInsensitiveCompare:@"S3"]) {
            self.DeviceType = DEVICE_TYPE_SERVO300;
        }
        else if (![DeviceType caseInsensitiveCompare:@"PB840"] || ![DeviceType caseInsensitiveCompare:@"P8"]) {
            self.DeviceType = DEVICE_TYPE_PB840;
        }
        else if (![DeviceType caseInsensitiveCompare:@"NONE"]) {
            self.DeviceType = DEVICE_TYPE_NONE;
        }
        else {
            self.DeviceType = DEVICE_TYPE_UNKNOW;
        }
    }
    return self;
}

@end
