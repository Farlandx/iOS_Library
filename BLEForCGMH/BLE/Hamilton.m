//
//  Hamilton.m
//  BLE
//
//  Created by Farland on 2014/4/8.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "Hamilton.h"
#import "HamiltonLibrary_Commands.h"

@implementation Hamilton {
    HAMILTON_READ_STEP step;
    int mode;
    NSMutableData *mData;
}

- (id)init {
    self = [super init];
    if (self) {
        step = HAMILTON_GET_VENTILATION_MODE;
        mode = -1;
        mData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

- (void)resetMData {
    if ([mData length] > 0) {
        //[_mData replaceBytesInRange:NSMakeRange(0, [_mData length]) withBytes:nil length:0];
        [mData setLength:0];
        NSLog(@"mData reset");
    }
}

- (NSData *)getCommand:(int)cmd {
    unsigned char result[4] = {STX, cmd, ETX, CR};
    return [[NSData alloc] initWithBytes:result length:4];
}

//- (int)Bit7ToBit8:(int)by {
//    int tmp  = by & 0xFF;
//    if (tmp > 128) {
//        tmp -= 128;
//    }
//    return tmp;
//}

- (NSString *)getMode:(NSString *)code {
    switch ([code intValue]) {
        case 1:
            return @"(S)CMV";
        case 2:
            return @"SIMV";
        case 4:
            return @"Spont";
        case 16:
            return @"Ambient";
        case 17:
            return @"PSIMV";
        case 19:
            return @"PCMV";
        case 20:
            return @"APVs";
        case 21:
            return @"APVc";
        case 22:
            return @"ASV";
        case 23:
            return @"DuoPAP";
        case 24:
            return @"APRV";
        case 25:
            return @"NIV";
        case 26:
            return @"AVtS";
            
        default:
            return code;
    }
}

- (NSString *)getValue:(NSData *)data {
    NSString *result = @"";
    const char* buffer = [data bytes];
    
    //    result = [NSString stringWithFormat:@"%d%d%d%d%d",
    //              [self Bit7ToBit8:buffer[2]],
    //              [self Bit7ToBit8:buffer[3]],
    //              [self Bit7ToBit8:buffer[4]],
    //              [self Bit7ToBit8:buffer[5]],
    //              [self Bit7ToBit8:buffer[6]]];
    //    result = [NSString stringWithFormat:@"%d%d%d%d%d",
    //              buffer[2],
    //              buffer[3],
    //              buffer[4],
    //              buffer[5],
    //              buffer[6]];
    unsigned char tmp[5] ={buffer[2],  buffer[3], buffer[4], buffer[5], buffer[6]};
    result = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:tmp length:5] encoding:NSUTF8StringEncoding];
    NSLog(@"result:%@", [result substringWithRange:NSMakeRange([result length] - 1, 1)]);
    if ([[result substringWithRange:NSMakeRange([result length] - 1, 1)] isEqualToString:@"."]) {
        result = [result substringWithRange:NSMakeRange(0, [result length] - 1)];
    }
    if (![result caseInsensitiveCompare:@"9999"] || ![result caseInsensitiveCompare:@"999.9"]) {
        result = @"";
    }
    
    return [result stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//Data找到CR返回YES
- (BOOL)chkData:(NSData *)data {
    if (data != nil) {
        const char* bytes = [data bytes];
        for (int i = 0; i < [data length]; i++) {
            if (bytes[i] == CR) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)resetStep {
    step = HAMILTON_GET_VENTILATION_MODE;
}

- (HAMILTON_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation {
    [mData appendData:data];
    //    NSLog(@"data:%@", [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding]);
    if (data == nil || ![self chkData:data]) {
        return HAMILTON_WAITING;
    }
    
    NSString *strData = [self getValue:mData];
    NSLog(@"strData:%@", strData);
    
    switch (step) {
        case HAMILTON_GET_VENTILATION_MODE:
            /**
			 * VentilationMode(40)
			 */
            mode = [strData intValue];
            ventilation.VentilationMode = [NSString stringWithFormat:@"%d", mode];
            
            step = HAMILTON_GET_VENTILATION_RATE_SET;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_VENTILATION_RATE_SET]];
            break;
            
        case HAMILTON_GET_VENTILATION_RATE_SET:
            /**
			 * VentilationRateSet(41) return XXXX.
			 */
            if (mode != 2 && mode != 17) {
                ventilation.VentilationRateSet = strData;
            }
            
            step = HAMILTON_GET_SIMV_RATE_SET;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_SIMV_RATE_SET]];
            break;
            
        case HAMILTON_GET_SIMV_RATE_SET:
            /**
			 * SIMVRateSet(42) return XXX.X
			 */
            if (mode == 2 || mode == 17 || mode == 20) {
                ventilation.SIMVRateSet = [NSString stringWithFormat:@"%.1lf", [strData floatValue]];
            }
            
            step = HAMILTON_GET_TIDAL_VOLUME;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_TIDAL_VOLUME]];
            break;
            
        case HAMILTON_GET_TIDAL_VOLUME:
            /**
			 * TidalVolumeSet;VolumeTarget(43) return XXXX.
			 */
            if (mode == 1 || mode == 2) {
                ventilation.TidalVolumeSet = strData;
            }
            else if (mode == 21 || mode == 20) {
                ventilation.VolumeTarget = strData;
            }
            
            if (mode == 2 || mode == 17) {
                ventilation.MVSet = [NSString stringWithFormat:@"%.1lf", [ventilation.TidalVolumeSet floatValue] / 1000 * [ventilation.SIMVRateSet integerValue]];
            }
            else if (![ventilation.VentilationRateSet isEqualToString:@""] && ![ventilation.TidalVolumeSet isEqualToString:@""]) {
                ventilation.MVSet = [NSString stringWithFormat:@"%.1lf", [ventilation.TidalVolumeSet floatValue] / 1000 * [ventilation.VentilationRateSet integerValue]];
            }
            
            step = HAMILTON_GET_PERCENT_MIN_VOL_SET;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PERCENT_MIN_VOL_SET]];
            break;
            
        case HAMILTON_GET_PERCENT_MIN_VOL_SET:
            /**
			 * PercentMinVolSet(111)
			 */
            ventilation.PercentMinVolSet = strData;
            
            step = HAMILTON_GET_INSP_T;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_INSP_T]];
            break;
            
        case HAMILTON_GET_INSP_T:
            /**
			 * InspT(113) retuen XX.XX
			 */
            if (mode != 4) {
                ventilation.InspT = strData;
            }
            
            step = HAMILTON_GET_IE_RATION;
            [self resetMData];
            if (mode == 2) {
                [_delegate nextCommand:[self getCommand:HAMILTON_GET_SIMV_MODE_IE_RATION]];
            }
            else {
                [_delegate nextCommand:[self getCommand:HAMILTON_GET_IE_RATION]];
            }
            break;
            
        case HAMILTON_GET_IE_RATION:
            /**
			 * I:E Ratio XX.XX
			 */
            if (mode == 1 || mode == 2 || mode == 19 || mode == 21 || mode == 26) {
                if (![strData isEqualToString:@""]) {
                    ventilation.InspirationExpirationRatio = [@"1:" stringByAppendingString:strData];
                }
            }
            
            step = HAMILTON_GET_PEEP_PLOW;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PEEP_PLOW]];
            break;
            
        case HAMILTON_GET_PEEP_PLOW:
            /**
			 * PEEP;Plow(48) return XXXX.
			 */
            if (mode == 16) {
                ventilation.PEEP = @"";
                ventilation.Plow = @"";
            }
            else if (mode == 24) {
                ventilation.PEEP = @"";
                ventilation.Plow = strData;
            }
            else {
                ventilation.PEEP = strData;
                ventilation.Plow = @"";
            }
            
            step = HAMILTON_GET_PRESSURE_SUPPORT;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PRESSURE_SUPPORT]];
            break;
            
        case HAMILTON_GET_PRESSURE_SUPPORT:
            /**
			 * PressureSupport(49) return XXXX.
			 */
            ventilation.PressureSupport = strData;
            
            step = HAMILTON_GET_FIO2SET;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_FIO2SET]];
            break;
            
        case HAMILTON_GET_FIO2SET:
            /**
			 * FiO2Set(50) return XXXX.
			 */
            ventilation.FiO2Set = strData;
            
            step = HAMILTON_GET_PRESSURE_CONTROL_PHIGHT;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PRESSURE_CONTROL_PHIGHT]];
            break;
            
        case HAMILTON_GET_PRESSURE_CONTROL_PHIGHT:
            /**
			 * PressureControl;Phight(87) return XXXX.
			 */
            if (mode == 19 || mode == 17) {
                ventilation.PressureControl = strData;
                ventilation.PHigh = @"";
            }
            else if (mode == 24 || mode == 23) {
                ventilation.PressureControl = @"";
                ventilation.PHigh = strData;
            }
            
            step = HAMILTON_GET_FLOW_SETTING;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_FLOW_SETTING]];
            break;
            
        case HAMILTON_GET_FLOW_SETTING:
            /**
			 * FlowSetting(106) return XXXX.
			 */
            ventilation.FlowSetting = strData;
            
            step = HAMILTON_GET_TIDAL_VOLUME_MEASURED;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_TIDAL_VOLUME_MEASURED]];
            break;
            
        case HAMILTON_GET_TIDAL_VOLUME_MEASURED:
            /**
			 * TidalVolumeMeasured(61) return XXXX.
			 */
            ventilation.TidalVolumeMeasured = strData;
            
            step = HAMILTON_GET_VENTILATION_RATE_TOTAL;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_VENTILATION_RATE_TOTAL]];
            break;
            
        case HAMILTON_GET_VENTILATION_RATE_TOTAL:
            /**
			 * VentilationRateTotal return XXXX.
			 */
            ventilation.VentilationRateTotal = strData;
            
            step = HAMILTON_GET_FLOW_MEASURE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_FLOW_MEASURE]];
            break;
            
        case HAMILTON_GET_FLOW_MEASURE:
            /**
			 * FlowMeasured(75) return XXXX.
			 */
            if (mode != 4) {
                ventilation.FlowMeasured = strData;
            }
            
            step = HAMILTON_GET_MV_TOTAL;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_MV_TOTAL]];
            break;
            
        case HAMILTON_GET_MV_TOTAL:
            /**
			 * MVTotal(62) return XXX.X
			 */
            ventilation.MVTotal = strData;
            
            step = HAMILTON_GET_PEAK_PRESSURE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PEAK_PRESSURE]];
            break;
            
        case HAMILTON_GET_PEAK_PRESSURE:
            /**
			 * PeakPressure(66) return XXXX.
			 */
            ventilation.PeakPressure = strData;
            
            step = HAMILTON_GET_PLATEAU_PRESSURE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_PLATEAU_PRESSURE]];
            break;
            
        case HAMILTON_GET_PLATEAU_PRESSURE:
            /**
			 * PlateauPressure(69) return XXXX.
			 */
            ventilation.PlateauPressure = strData;
            
            step = HAMILTON_GET_MEAN_PRESSURE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_MEAN_PRESSURE]];
            break;
            
        case HAMILTON_GET_MEAN_PRESSURE:
            /**
			 * MeanPressure(67) return XXXX.
			 */
            if (mode != 4) {
                ventilation.MeanPressure = strData;
            }
            
            step = HAMILTON_GET_FIO2_MEAUSRE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_FIO2_MEAUSRE]];
            break;
            
        case HAMILTON_GET_FIO2_MEAUSRE:
            /**
			 * FiO2Measured(71) return XXXX.
			 */
            ventilation.FiO2Measured = strData;
            
            step = HAMILTON_GET_RESISTANCE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_RESISTANCE]];
            break;
            
        case HAMILTON_GET_RESISTANCE:
            /**
			 * Resistance(73) return XXXX.
			 */
            ventilation.Resistance = strData;
            
            step = HAMILTON_GET_COMPLIANCE;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_COMPLIANCE]];
            break;
            
        case HAMILTON_GET_COMPLIANCE:
            /**
			 * Compliance(74) return XXXX.
			 */
            ventilation.Compliance = strData;
            
            step = HAMILTON_GET_LOWER_MV;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_LOWER_MV]];
            break;
            
        case HAMILTON_GET_LOWER_MV:
            /**
			 * LowerMV(54) return XXX.X
			 */
            ventilation.LowerMV = strData;
            
            step = HAMILTON_GET_HIGH_PRESSURE_ALARM;
            [self resetMData];
            [_delegate nextCommand:[self getCommand:HAMILTON_GET_HIGH_PRESSURE_ALARM]];
            break;
            
        case HAMILTON_GET_HIGH_PRESSURE_ALARM:
            /**
			 * HighPressureAlarm(53) return XXXX.
			 */
            ventilation.HighPressureAlarm = strData;
            ventilation.VentilationMode = [self getMode:ventilation.VentilationMode];
            step = HAMILTON_DONE;
            [self resetMData];
            break;
            
        default:
            step = HAMILTON_ERROR;
            [self resetMData];
            break;
    }
    
    return step;
}

@end
