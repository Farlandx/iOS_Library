//
//  DRAGER.h
//  BLE
//
//  Created by Farland on 2014/3/21.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VentilationData.h"

@interface DRAGER : NSObject

typedef NS_ENUM(NSUInteger, DRAGER_READ_STEP) {
    DRAGER_ICC = 0,
    DRAGER_AFTER_ICC_CONFIG_COMMAND,
    DRAGER_GET_MODE,
    DRAGER_AFTER_GET_MODE_CONFIG_COMMAND,
    DRAGER_CURRENT_DEVICE_SETTING,
    DRAGER_AFTER_DEVICE_SETTING_CONFIG_COMMAND,
    DRAGER_CURRENT_MEASURED_DATA_PAGE1,
    DRAGER_AFTER_CURRENT_MEASURED_DATA_PAGE1,
    DRAGER_GET_LOWERMV,
    DRAGER_ERROR,
    DRAGER_WAITING,
    DRAGER_DONE
};

@property (strong, nonatomic) NSMutableData *mData;

- (DRAGER_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation command:(NSData *)cmd;
- (NSData *)getICC_Command;
- (void)resetStep;

@end
