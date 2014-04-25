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
    return [self initWithDeviceInfo:@"" :@""];
}

- (id)initWithDeviceInfo:(NSString *)uuid :(NSString *)name {
    self = [super init];
    if (self) {
        self.DeviceUUID = uuid;
        self.DeviceName = name;
    }
    return self;
}

@end
