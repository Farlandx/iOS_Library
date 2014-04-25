//
//  SERVOi.m
//  BLE
//
//  Created by Farland on 2014/4/10.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "SERVOi.h"

@implementation SERVOi {
    SERVOI_READ_STEP step;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        step = SERVOI_INIT;
    }
    return self;
}

- (NSString *)getVentilationMode:(NSString *)mode {
    switch ([mode integerValue]) {
        case 1:
			return @"Value not used";
		case 2:
			return @"Pressure Control";
		case 3:
			return @"Voulme Control";
		case 4:
			return @"Pressure Reg. Volume Control";
		case 5:
			return @"Volume Support";
		case 6:
			return @"SIMV + Pressure Support";
		case 7:
			return @"SIMV + Pressure Support";
		case 8:
			return @"Pressure Support / CPAP";
		case 9:
			return @"Ventilation mode not supported by CIE";
		case 10:
			return @"SIMV + Pressure Support";
		case 11:
			return @"Bivent";
		case 12:
			return @"Pressure Control in NIV";
		case 13:
			return @"Pressure Support in NIV";
		case 14:
			return @"Nasal CPAP";
		case 15:
			return @"NAVA";
		case 16:
			return @"Value not used";
		case 17:
			return @"NIV NAVA";
		case 18:
			return @"Pressure Control";
		case 19:
			return @"Volume Control";
		case 20:
			return @"Pressure Reg";
		case 21:
			return @"Pressure Support";
		case 22:
			return @"Volume Support";
		case 23:
			return @"Volume Support";
		default:
			return @"";
    }
}

- (NSString *) getValue:(int)position value:(NSString *)value {
    position -= 1;
    NSString *res;
    @try {
        res = [[value substringWithRange:NSMakeRange(position * 4, 4)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([res isEqualToString:@"9999"]) {
            res = @"";
        }
    }
    @catch (NSException *exception) {
        res = @"";
    }
    return res;
}

- (NSString *)getCalculateValue:(NSString *)value scale:(float) scale {
    if ([value isEqualToString:@""]) {
        return @"";
    }
    else {
        float cal = (float)(([value floatValue] - 2048) * 4.8883 / scale);
        return [NSString stringWithFormat:@"%f", cal];
    }
}

- (const char *)getChkStr:(int)sum {
    NSString *sumString = [NSString stringWithFormat:@"%02X", sum];
    sumString = [sumString substringWithRange:NSMakeRange([sumString length] - 2, 2)];
    return [sumString UTF8String];
    
}

- (NSData *)getBasicCommand:(NSString *)cmd {
    return [cmd dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)getExtendCommand:(NSString *)cmd {
    NSData *data = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    int size = (int)[data length] + 3;
    unsigned char buffer[size];
    
    const char *bytes = [data bytes];
    unsigned char chk = 0x00;
    for (int i = 0; i < [data length]; i++) {
        buffer[i] = bytes[i];
        chk = (unsigned)(chk ^ bytes[i]);
    }
    
    const char *chkStr = [self getChkStr:chk];
    buffer[size - 3] = chkStr[0];
    buffer[size - 2] = chkStr[1];
    buffer[size - 1] = 4;
    
    return [NSData dataWithBytes:buffer length:size];
}

- (NSData *)getInitCommand {
    return [self getBasicCommand:@"HO"];
}

- (void)resetStep {
    step = SERVOI_INIT;
}

- (BOOL)chkStopByte:(NSData *)data {
    if (data != nil) {
        const char* bytes = [data bytes];
        for (int i = 0; i < [data length]; i++) {
            if (bytes[i] == STOP_BYTE) {
                return YES;
            }
        }
    }
    return NO;
}

- (SERVOI_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation command:(NSData *)cmd {
    if (![self chkStopByte:data]) {
        return SERVOI_WAITING;
    }
    
    switch (step) {
        case SERVOI_INIT:
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] rangeOfString:@"900PCI"].location > -1) {
                
                step = SERVOI_RESISTANCE_DB31;
                cmd = [self getBasicCommand:@"DB31"];
            }
            
            break;
            
        case SERVOI_RESISTANCE_DB31:
            step = SERVOI_RESISTANCE_RB;
            cmd = [self getBasicCommand:@"RB"];
            break;
            
        case SERVOI_RESISTANCE_RB: {
            NSString *basicResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *val = [self getValue:1 value:basicResult];
            
            if (![val isEqualToString:@""]) {
                ventilation.Resistance = [self getCalculateValue:val scale:20.0f];
            }
            
            step = SERVOI_RCTY;
            cmd = [self getExtendCommand:@"RCTY"];
            break;
        }
            
        case SERVOI_RCTY:
            /*
			 * 設定要讀取的數值(Setting)1: 310 (VentilationMode)2: 334 (TidalVolumeSet)
			 * 3: 300 (VentilationRateSet)4: 343 (InspT)5: 348 (FlowSetting)6:
			 * 305 (MVSet)7: 306 (PressureControl)8: 307 (PressureSupport)9: 323
			 * (FiO2Set)10: 314 (LowerMV)11: 315 (HighPressureAlarm)12: 308
			 * (PEEP) (Plow when mode=11)13: 303 (SIMVRateSet)14: 333 (I:E Ratio
			 * Set)15: 339 (THight when mode=11)16: 340 (Tlow when mode=11)17:
			 * 338 (PHigh when mode=11)18: 341 (PressureSupport when mode=11)
			 */
            step = SERVOI_SDADS;
            cmd = [self getExtendCommand:@"SDADS310334300343348305306307323314315308303333339340338341"];
            
            break;
            
        case SERVOI_SDADS:
            step = SERVOI_RADAS;
            cmd = [self getExtendCommand:@"RADAS"];
            
            break;
            
        case SERVOI_RADAS: {
            NSString *settings = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            // VentilationMode(310)
            ventilation.VentilationMode = [self getValue:1 value:settings];
            
            // TidalVolumeSet(334)
            ventilation.TidalVolumeSet = [self getValue:2 value:settings];
            
            // VentilationRateSet(300)
            ventilation.VentilationRateSet = [self getValue:3 value:settings];
            if (![ventilation.VentilationRateSet isEqualToString:@""]) {
                ventilation.VentilationRateSet = [NSString stringWithFormat:@"%f", [ventilation.VentilationRateSet floatValue] / 10.0f];
                
            }
            
            // InspT(343)
            ventilation.InspT = [self getValue:4 value:settings];
            if (![ventilation.InspT isEqualToString:@""]) {
                ventilation.InspT = [NSString stringWithFormat:@"%f", [ventilation.InspT floatValue] / 100.0f];
            }
            
            // FlowSetting(348)
            ventilation.FlowSetting = [self getValue:5 value:settings];
            
            // MVSet(305)
            ventilation.MVSet = [self getValue:6 value:settings];
            if (![ventilation.MVSet isEqualToString:@""]) {
                ventilation.MVSet = [NSString stringWithFormat:@"%f", [ventilation.MVSet floatValue] / 100.0f];
            }
            
            // PressureControl(306)
            ventilation.PressureControl = [self getValue:7 value:settings];
            if (![ventilation.PressureControl isEqualToString:@""]) {
                ventilation.PressureControl = [NSString stringWithFormat:@"%f", [ventilation.PressureControl floatValue] / 10.0f];
            }
            
            // FiO2Set(323)
            ventilation.FiO2Set = [self getValue:9 value:settings];
            if (![ventilation.FiO2Set isEqualToString:@""]) {
                ventilation.FiO2Set = [NSString stringWithFormat:@"%f", [ventilation.FiO2Set floatValue] / 10.0f];
            }
            
            // LowerMV(314)
            ventilation.LowerMV = [self getValue:10 value:settings];
            if (![ventilation.LowerMV isEqualToString:@""]) {
                ventilation.LowerMV = [NSString stringWithFormat:@"%f", [ventilation.LowerMV floatValue] / 10.0f];
            }
            
            // HighPressureAlarm Set(315)
            ventilation.HighPressureAlarm = [self getValue:11 value:settings];
            
            // PEEP Set(308)
            ventilation.PEEP = [self getValue:12 value:settings];
            if (![ventilation.PEEP isEqualToString:@""]) {
                ventilation.PEEP = [NSString stringWithFormat:@"%f", [ventilation.PEEP floatValue] / 10.0f];
            }
            
            // SIMVRateSet(303)
            ventilation.SIMVRateSet = [self getValue:13 value:settings];
            if (![ventilation.SIMVRateSet isEqualToString:@""]) {
                ventilation.SIMVRateSet = [NSString stringWithFormat:@"%f", [ventilation.SIMVRateSet floatValue] / 10.0f];
            }
            
            // I:E Ratio Set(333)
            ventilation.InspirationExpirationRatio = [self getValue:14 value:settings];
            if (![ventilation.InspirationExpirationRatio isEqualToString:@""]) {
                float tmp = [ventilation.InspirationExpirationRatio floatValue];
                ventilation.InspirationExpirationRatio = [NSString stringWithFormat:@"%f", tmp / 100.0f];
                
                if (tmp >= 1.0f) {
                    ventilation.InspirationExpirationRatio = [ventilation.InspirationExpirationRatio stringByAppendingString:@":1"];
                }
                else {
                    ventilation.InspirationExpirationRatio = [@"1:" stringByAppendingString:[NSString stringWithFormat:@"%.1f", 1 / tmp]];
                }
            }
            
            // 依模式不同取值
            if ([ventilation.VentilationMode caseInsensitiveCompare:@"11"]) {
                // THigh(339)
                ventilation.THigh = [self getValue:15 value:settings];
                if (![ventilation.THigh isEqualToString:@""]) {
                    ventilation.THigh = [NSString stringWithFormat:@"%f", [ventilation.THigh floatValue] / 100.0f];
                }
                // Tlow(340)
                ventilation.Tlow = [self getValue:16 value:settings];
                if (![ventilation.Tlow isEqualToString:@""]) {
                    ventilation.Tlow = [NSString stringWithFormat:@"%f", [ventilation.Tlow floatValue] / 100.0f];
                }
                // Plow(308)
                ventilation.Plow = ventilation.PEEP;
                
                // PHigh(338)
                ventilation.PHigh = [self getValue:17 value:settings];
                if (![ventilation.PHigh isEqualToString:@""]) {
                    ventilation.PHigh = [NSString stringWithFormat:@"%f", [ventilation.PHigh floatValue] / 10.0f];
                }
                
                // PressureSupport(341)
                ventilation.PressureSupport = [self getValue:18 value:settings];
            }
            else {
                // PressureSupport(307)
                ventilation.PressureSupport = [self getValue:8 value:settings];
            }
            
            if (![ventilation.PressureSupport isEqualToString:@""]) {
                ventilation.PressureSupport = [NSString stringWithFormat:@"%f", [ventilation.PressureSupport floatValue] / 10.0f];
            }
            
            /*
			 * 設定要讀取的數值(Measured) 1: 201 (TidalVolumeMeasured) 2: 200
			 * (VentilationRateTotal) 3: 204 (MVTotal) 4: 205 (PeakPressure) 5:
			 * 207 (PlateauPressure) 6: 206 (MeanPressure) 7: 209 (FiO2Measured)
			 * 8: 241 (Compliance) 9: 233 (FlowMeasured)
			 */
            step = SERVOI_SDADB;
            cmd = [self getExtendCommand:@"SDADB201200204205207206209241233"];
            
            break;
        }
            
        case SERVOI_SDADB:
            step = SERVOI_RADAB;
            cmd = [self getExtendCommand:@"RADAB"];
            break;
            
        case SERVOI_RADAB: {
            NSString *measureds = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            // TidalVolumeMeasured(201)
            ventilation.TidalVolumeMeasured = [self getValue:1 value:measureds];
            
            // Measured breath frequency(200)
            ventilation.VentilationRateTotal = [self getValue:2 value:measureds];
            if (![ventilation.VentilationRateTotal isEqualToString:@""]) {
                ventilation.VentilationRateTotal = [NSString stringWithFormat:@"%f", [ventilation.VentilationRateTotal floatValue] / 10.0f];
            }
            
            // MVTotal(204)
            ventilation.MVTotal = [self getValue:3 value:measureds];
            if (![ventilation.MVTotal isEqualToString:@""]) {
                ventilation.MVTotal = [NSString stringWithFormat:@"%f", [ventilation.MVTotal floatValue] / 10.0f];
            }
            
            // Peak pressure(205)
            ventilation.PeakPressure = [self getValue:4 value:measureds];
            if (![ventilation.PeakPressure isEqualToString:@""]) {
                ventilation.PeakPressure = [NSString stringWithFormat:@"%f", [ventilation.PeakPressure floatValue] / 10.0f];
            }
            
            // PlateauPressure(207)
            ventilation.PlateauPressure = [self getValue:5 value:measureds];
            if (![ventilation.PlateauPressure isEqualToString:@""]) {
                ventilation.PlateauPressure = [NSString stringWithFormat:@"%f", [ventilation.PeakPressure floatValue] / 10.0f];
            }
            
            // MeanPressure(206)
            ventilation.MeanPressure = [self getValue:6 value:measureds];
            if (![ventilation.MeanPressure isEqualToString:@""]) {
                ventilation.MeanPressure = [NSString stringWithFormat:@"%f", [ventilation.MeanPressure floatValue] / 10.0f];
            }
            
            // FiO2Measured(209)
            ventilation.FiO2Measured = [self getValue:7 value:measureds];
            
            // Static Compliance(241)
            ventilation.Compliance = [self getValue:8 value:measureds];
            
            // FlowMeasured(233)
            ventilation.FlowMeasured = [self getValue:9 value:measureds];
            
            ventilation.VentilatorModel = [self getVentilationMode:ventilation.VentilatorModel];
            
            step = SERVOI_DONE;
            break;
        }
            
        default:
            step = SERVOI_ERROR;
            break;
    }
    return step;
}

@end
