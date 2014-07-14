//
//  Hamilton.h
//  BLE
//
//  Created by Farland on 2014/4/8.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VentilationData.h"

@protocol Hamilton_Delegate <NSObject>

- (void)nextCommand:(NSData *)cmd;

@end

@interface Hamilton : NSObject

typedef NS_ENUM(NSUInteger, HAMILTON_READ_STEP) {
    HAMILTON_GET_VENTILATION_MODE = 40,
    HAMILTON_GET_VENTILATION_RATE_SET = 41,
    HAMILTON_GET_SIMV_RATE_SET = 42,
    HAMILTON_GET_TIDAL_VOLUME = 43,
    HAMILTON_GET_PERCENT_MIN_VOL_SET = 111,
    HAMILTON_GET_INSP_T = 113,
    HAMILTON_GET_SIMV_MODE_IE_RATION = 65,
    HAMILTON_GET_IE_RATION = 105,
    HAMILTON_GET_PEEP_PLOW = 48,
    HAMILTON_GET_PRESSURE_SUPPORT = 49,
    HAMILTON_GET_FIO2SET = 50,
    HAMILTON_GET_PRESSURE_CONTROL_PHIGHT = 87,
    HAMILTON_GET_FLOW_SETTING = 106,
    HAMILTON_GET_TIDAL_VOLUME_MEASURED = 61,
    HAMILTON_GET_VENTILATION_RATE_TOTAL = 63,
    HAMILTON_GET_FLOW_MEASURE = 75,
    HAMILTON_GET_MV_TOTAL = 62,
    HAMILTON_GET_PEAK_PRESSURE = 66,
    HAMILTON_GET_PLATEAU_PRESSURE = 69,
    HAMILTON_GET_MEAN_PRESSURE = 67,
    HAMILTON_GET_FIO2_MEAUSRE = 71,
    HAMILTON_GET_RESISTANCE = 73,
    HAMILTON_GET_COMPLIANCE = 74,
    HAMILTON_GET_LOWER_MV = 54,
    HAMILTON_GET_HIGH_PRESSURE_ALARM = 53,
    HAMILTON_ERROR = 404,
    HAMILTON_WAITING = 405,
    HAMILTON_DONE = 406
};

@property (assign, nonatomic) id<Hamilton_Delegate> delegate;

- (HAMILTON_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation command:(NSData *)cmd;
- (NSData *)getCommand:(int)cmd;
- (void)resetStep;

@end
