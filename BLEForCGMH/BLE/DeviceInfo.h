//
//  DeviceInfo.h
//  BLE
//
//  Created by Farland on 2014/3/4.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceInfo : NSObject

@property (strong, nonatomic) NSString *DeviceUUID;
@property (strong, nonatomic) NSString *DeviceName;

- (id)initWithDeviceInfo:(NSString *)uuid :(NSString *)name;

@end
