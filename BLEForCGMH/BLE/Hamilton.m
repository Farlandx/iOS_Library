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
}

- (id)init {
    self = [super init];
    if (self) {
        step = HAMILTON_GET_VENTILATION_MODE;
        mode = -1;
    }
    return self;
}

- (NSData *)getCommand:(int)cmd {
    unsigned char result[4] = {STX, cmd, ETX, CR};
    return [[NSData alloc] initWithBytes:result length:sizeof(result)];
}

- (int)Bit7ToBit8:(int)by {
    int tmp  = by & 0xFF;
    if (tmp > 128) {
        tmp -= 128;
    }
    return tmp;
}

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
    
    result = [NSString stringWithFormat:@"%d%d%d%d%d",
              [self Bit7ToBit8:buffer[2]],
              [self Bit7ToBit8:buffer[3]],
              [self Bit7ToBit8:buffer[4]],
              [self Bit7ToBit8:buffer[5]],
              [self Bit7ToBit8:buffer[6]]];
    
    if (![[result substringWithRange:NSMakeRange([result length] - 1, [result length])] isEqualToString:@"."]) {
        result = [result substringWithRange:NSMakeRange(0, [result length] - 1)];
    }
    if (![result caseInsensitiveCompare:@"9999"] || ![result caseInsensitiveCompare:@"999.9"]) {
        result = @"";
    }
    
    return [result stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//Data結尾是CR返回YES
- (BOOL)chkData:(NSData *)data {
    const char* buffer = [data bytes];
    int len = sizeof(buffer);
    if (len > 0 && buffer[len - 1] == CR) {
        return YES;
    }
    return NO;
}

- (void)resetStep {
    step = HAMILTON_GET_VENTILATION_MODE;
}

- (HAMILTON_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation command:(NSData *)cmd {
    if (data == nil || ![self chkData:data]) {
        return HAMILTON_WAITING;
    }
    
    NSString *strData = [self getValue:data];
    
    switch (step) {
        case HAMILTON_GET_VENTILATION_MODE:
            /**
			 * VentilationMode(40)
			 */
            mode = [strData intValue];
            ventilation.VentilationMode = [NSString stringWithFormat:@"%d", mode];
            
            step = HAMILTON_GET_VENTILATION_RATE_SET;
            cmd = [self getCommand:HAMILTON_GET_VENTILATION_RATE_SET];
            break;
            
        case HAMILTON_GET_VENTILATION_RATE_SET:
            /**
			 * VentilationRateSet(41) return XXXX.
			 */
            if (mode != 17) {
                ventilation.VentilationRateSet = strData;
            }
            
            step = HAMILTON_GET_SIMV_RATE_SET;
            cmd = [self getCommand:HAMILTON_GET_SIMV_RATE_SET];
            break;
            
        case HAMILTON_GET_SIMV_RATE_SET:
            /**
			 * SIMVRateSet(42) return XXX.X
			 */
            if (mode == 2 || mode == 17 || mode == 20) {
                ventilation.SIMVRateSet = strData;
            }
            
            step = HAMILTON_GET_TIDAL_VOLUME;
            cmd = [self getCommand:HAMILTON_GET_TIDAL_VOLUME];
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
            
            if (![ventilation.VentilationRateSet isEqualToString:@""] && ![ventilation.TidalVolumeSet isEqualToString:@""]) {
                ventilation.MVSet = [NSString stringWithFormat:@"%f", [ventilation.TidalVolumeSet floatValue] / 1000 * [ventilation.VentilationRateSet integerValue]];
            }
            
            step = HAMILTON_GET_PERCENT_MIN_VOL_SET;
            cmd = [self getCommand:HAMILTON_GET_PERCENT_MIN_VOL_SET];
            break;
            
        case HAMILTON_GET_PERCENT_MIN_VOL_SET:
            /**
			 * PercentMinVolSet(111)
			 */
            ventilation.PercentMinVolSet = strData;
            
            step = HAMILTON_GET_INSP_T;
            cmd = [self getCommand:HAMILTON_GET_INSP_T];
            break;
            
        case HAMILTON_GET_INSP_T:
            /**
			 * InspT(113) retuen XX.XX
			 */
            ventilation.InspT = strData;
            step = HAMILTON_GET_IE_RATION;
            cmd = [self getCommand:HAMILTON_GET_IE_RATION];
            break;
            
        case HAMILTON_GET_IE_RATION:
            /**
			 * I:E Ratio XX.XX
			 */
            if (mode == 1 || mode == 19 || mode == 21 || mode == 26) {
                if (![strData isEqualToString:@""]) {
                    ventilation.InspirationExpirationRatio = [@"1:" stringByAppendingString:strData];
                }
            }
            
            step = HAMILTON_GET_PEEP_PLOW;
            cmd = [self getCommand:HAMILTON_GET_PEEP_PLOW];
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
            cmd = [self getCommand:HAMILTON_GET_PRESSURE_SUPPORT];
            break;
            
        case HAMILTON_GET_PRESSURE_SUPPORT:
            /**
			 * PressureSupport(49) return XXXX.
			 */
            ventilation.PressureSupport = strData;
            
            step = HAMILTON_GET_FIO2SET;
            cmd = [self getCommand:HAMILTON_GET_FIO2SET];
            break;
            
        case HAMILTON_GET_FIO2SET:
            /**
			 * FiO2Set(50) return XXXX.
			 */
            ventilation.FiO2Set = strData;
            
            step = HAMILTON_GET_PRESSURE_CONTROL_PHIGHT;
            cmd = [self getCommand:HAMILTON_GET_PRESSURE_CONTROL_PHIGHT];
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
            cmd = [self getCommand:HAMILTON_GET_FLOW_SETTING];
            break;
            
        case HAMILTON_GET_FLOW_SETTING:
            /**
			 * FlowSetting(106) return XXXX.
			 */
            ventilation.FlowSetting = strData;
            
            step = HAMILTON_GET_TIDAL_VOLUME_MEASURED;
            cmd = [self getCommand:HAMILTON_GET_TIDAL_VOLUME_MEASURED];
            break;
            
        case HAMILTON_GET_TIDAL_VOLUME_MEASURED:
            /**
			 * TidalVolumeMeasured(61) return XXXX.
			 */
            ventilation.TidalVolumeMeasured = strData;
            
            step = HAMILTON_GET_VENTILATION_RATE_TOTAL;
            cmd = [self getCommand:HAMILTON_GET_VENTILATION_RATE_TOTAL];
            break;
            
        case HAMILTON_GET_VENTILATION_RATE_TOTAL:
            /**
			 * VentilationRateTotal return XXXX.
			 */
            ventilation.VentilationRateTotal = strData;
            
            step = HAMILTON_GET_FLOW_MEASURE;
            cmd = [self getCommand:HAMILTON_GET_FLOW_MEASURE];
            break;
            
        case HAMILTON_GET_FLOW_MEASURE:
            /**
			 * FlowMeasured(75) return XXXX.
			 */
            ventilation.FlowMeasured = strData;
            
            step = HAMILTON_GET_MV_TOTAL;
            cmd = [self getCommand:HAMILTON_GET_MV_TOTAL];
            break;
            
        case HAMILTON_GET_MV_TOTAL:
            /**
			 * MVTotal(62) return XXX.X
			 */
            ventilation.MVTotal = strData;
            
            step = HAMILTON_GET_PEAK_PRESSURE;
            cmd = [self getCommand:HAMILTON_GET_PEAK_PRESSURE];
            break;
            
        case HAMILTON_GET_PEAK_PRESSURE:
            /**
			 * PeakPressure(66) return XXXX.
			 */
            ventilation.PeakPressure = strData;
            
            step = HAMILTON_GET_PLATEAU_PRESSURE;
            cmd = [self getCommand:HAMILTON_GET_PLATEAU_PRESSURE];
            break;
            
        case HAMILTON_GET_PLATEAU_PRESSURE:
            /**
			 * PlateauPressure(69) return XXXX.
			 */
            ventilation.PlateauPressure = strData;
            
            step = HAMILTON_GET_MEAN_PRESSURE;
            cmd = [self getCommand:HAMILTON_GET_MEAN_PRESSURE];
            break;
            
        case HAMILTON_GET_MEAN_PRESSURE:
            /**
			 * MeanPressure(67) return XXXX.
			 */
            ventilation.MeanPressure = strData;
            
            step = HAMILTON_GET_FIO2_MEAUSRE;
            cmd = [self getCommand:HAMILTON_GET_FIO2_MEAUSRE];
            break;
            
        case HAMILTON_GET_FIO2_MEAUSRE:
            /**
			 * FiO2Measured(71) return XXXX.
			 */
            ventilation.FiO2Measured = strData;
            
            step = HAMILTON_GET_RESISTANCE;
            cmd = [self getCommand:HAMILTON_GET_RESISTANCE];
            break;
            
        case HAMILTON_GET_RESISTANCE:
            /**
			 * Resistance(73) return XXXX.
			 */
            ventilation.Resistance = strData;
            
            step = HAMILTON_GET_COMPLIANCE;
            cmd = [self getCommand:HAMILTON_GET_COMPLIANCE];
            break;
            
        case HAMILTON_GET_COMPLIANCE:
            /**
			 * Compliance(74) return XXXX.
			 */
            ventilation.Compliance = strData;
            
            step = HAMILTON_GET_LOWER_MV;
            cmd = [self getCommand:HAMILTON_GET_LOWER_MV];
            break;
            
        case HAMILTON_GET_LOWER_MV:
            /**
			 * LowerMV(54) return XXX.X
			 */
            ventilation.LowerMV = strData;
            
            step = HAMILTON_GET_HIGH_PRESSURE_ALARM;
            cmd = [self getCommand:HAMILTON_GET_HIGH_PRESSURE_ALARM];
            break;
            
        case HAMILTON_GET_HIGH_PRESSURE_ALARM:
            /**
			 * HighPressureAlarm(53) return XXXX.
			 */
            ventilation.HighPressureAlarm = strData;
            
            step = HAMILTON_DONE;
            break;
            
        default:
            step = HAMILTON_ERROR;
            break;
    }
    
    return step;
}

@end
