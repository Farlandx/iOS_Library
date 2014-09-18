//
//  PB840.m
//  BLE
//
//  Created by Farland on 2014/9/16.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "PB840.h"
#import "PB840_Commands.h"

@implementation PB840 {
//    NSData *STX;
//    NSData *ETX;
    NSData *CR;
    PB840_READ_STEP step;
    NSMutableData *mData;
}

- (id)init {
    if (self = [super init]) {
//        STX = [@"\x02" dataUsingEncoding:NSUTF8StringEncoding];
//        ETX = [@"\x03" dataUsingEncoding:NSUTF8StringEncoding];
        CR = [@"\x13" dataUsingEncoding:NSUTF8StringEncoding];
        step = PB840_FIRST_COMMAND;
        mData = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

#pragma mark - Public Method
- (PB840_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation {
    BOOL canRead = NO;
    unsigned char* buffer = (unsigned char*)[data bytes];
    for (int i = 0; i < [data length]; i++) {
        if (buffer[i] == _STX || buffer[i] == _ETX) {
            continue;
        }
        else if (buffer[i] == _CR) {
            canRead = YES;
            break;
        }
        [mData appendBytes:(const void *)buffer[i] length:1];
    }
//    [mData appendData:data];
    if (canRead) {
        NSString *resultString = [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding];
        NSLog(@"data:%@", resultString);
        NSArray *resultArray = [resultString componentsSeparatedByString:@","];
        
        //判斷新舊型機器
        int responseCode = MISCF;
        switch (step) {
            case PB840_FIRST_COMMAND: {
                if ([((NSString *)resultArray[0]) caseInsensitiveCompare:@"MISCF"] != NSOrderedSame) {
                    step = PB840_SECOND_COMMAND;
                    return step;
                }
            }
            case PB840_SECOND_COMMAND: {
                if ([((NSString *)resultArray[0]) caseInsensitiveCompare:@"MISCA"] != NSOrderedSame) {
                    step = PB840_ERROR;
                    return  step;
                }
                responseCode = MISCA;
                break;
            }
                
            default:
                [ventilation setDefaultValue];
                return PB840_ERROR;
        }
        
        //取得Mode
        ventilation.VentilationMode = [self getValue:resultArray position:9];
        if ([ventilation.VentilationMode caseInsensitiveCompare:@"A/C"] == NSOrderedSame && responseCode == MISCF) {
            ventilation.VentilationMode = [self getValue:resultArray position:10];
        }
        
        //截取資料
        if (responseCode == MISCA) {
            [self getMISCA_Value:resultArray ventilation:ventilation];
        }
        else {
            [self getMISCF_Value:resultArray ventilation:ventilation];
        }
        
        //float format
        
        /**
         * Tidal volume setting in L
         */
        if (![ventilation.TidalVolumeSet isEqualToString:@""]) {
            ventilation.TidalVolumeSet = [NSString stringWithFormat:@"%.1lf", [ventilation.TidalVolumeSet floatValue] * 1000];
        }
        
        /**
         * Exhaled tidal volume (VTE) in L
         */
        if (ventilation.TidalVolumeMeasured) {
            ventilation.TidalVolumeMeasured = [NSString stringWithFormat:@"%.1lf", [ventilation.TidalVolumeMeasured floatValue] * 1000];
        }
        
        /**
         * Monitored PEEP in cmH2O
         */
        if (![ventilation.PEEP isEqualToString:@""]) {
            ventilation.PEEP = [NSString stringWithFormat:@"%.1lf", [ventilation.PEEP floatValue]];
        }
        
        /**
         * Low exhaled minute volume (4VE TOT) alarm setting in L/min
         */
        if (![ventilation.LowerMV isEqualToString:@""]) {
            ventilation.LowerMV = [NSString stringWithFormat:@"%.1lf", [ventilation.LowerMV floatValue]];
        }
        
        /**
         * Patient exhaled minute volume in L/min
         */
        if (![ventilation.MVTotal isEqualToString:@""]) {
            ventilation.MVTotal = [NSString stringWithFormat:@"%.1lf", [ventilation.MVTotal floatValue]];
        }
        
        /**
         * Respiratory rate setting in bpm
         */
        if (![ventilation.VentilationRateSet isEqualToString:@""]) {
            ventilation.VentilationRateSet = [NSString stringWithFormat:@"%.1lf", [ventilation.VentilationRateSet floatValue]];
        }
        
        /**
         * Respiratory rate (fTOT) in bpm
         */
        if (![ventilation.VentilationRateTotal isEqualToString:@""]) {
            ventilation.VentilationRateTotal = [NSString stringWithFormat:@"%.1lf", [ventilation.VentilationRateTotal floatValue]];
        }
        
        if ([ventilation.VentilationMode caseInsensitiveCompare:@"spont"] != NSOrderedSame) {
            /**
             * Peak flow setting in L/min
             */
            if (![ventilation.FlowSetting isEqualToString:@""]) {
                ventilation.FlowSetting = [NSString stringWithFormat:@"%.1lf", [ventilation.FlowSetting floatValue]];
            }
            
            /**
             * Mean airway pressure in cmH2O
             */
            if (![ventilation.MeanPressure isEqualToString:@""]) {
                ventilation.MeanPressure = [NSString stringWithFormat:@"%.1lf", [ventilation.MeanPressure floatValue]];
            }
            
            if (responseCode == MISCF) {
                /**
                 * Dynamic resistance in cmH2O/L/s
                 */
                if (![ventilation.Resistance isEqualToString:@""]) {
                    ventilation.Resistance = [NSString stringWithFormat:@"%.1lf", [ventilation.Resistance floatValue]];
                }
                
                /**
                 * Dynamic compliance in mL/cmH2O
                 */
                if (![ventilation.Compliance isEqualToString:@""]) {
                    ventilation.Compliance = [NSString stringWithFormat:@"%.1lf", [ventilation.Compliance floatValue]];
                }
                
                /**
                 * Peak airway pressure in cmH2O
                 */
                if (![ventilation.PeakPressure isEqualToString:@""]) {
                    ventilation.PeakPressure = [NSString stringWithFormat:@"%.1lf", [ventilation.PeakPressure floatValue]];
                }
                
                /**
                 * Plateau pressure from inspiratory pause maneuver in cmH2O
                 */
                if (![ventilation.PlateauPressure isEqualToString:@""]) {
                    ventilation.PlateauPressure = [NSString stringWithFormat:@"%.1lf", [ventilation.PlateauPressure floatValue]];
                }
            }
        }
        
        
        [self resetMData];
        step = PB840_DONE;
    }
    else {
        return PB840_WAITING;
    }
    
    return step;
}

- (void)resetStep {
    step = PB840_FIRST_COMMAND;
}

- (NSString *)getFirstCommand {
    return FIRST_COMMAND;
}

#pragma mark - Private Method
- (void)resetMData {
    if ([mData length] > 0) {
        [mData setLength:0];
    }
}

- (NSData *)getCommand:(NSString *)cmd {
    NSData *result = [[NSData alloc] init];
    
    NSData *cmdByte = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *sendByte = [[NSMutableData alloc] init];
    [sendByte appendData:cmdByte];
    [sendByte appendData:CR];
    
    return result;
}

- (NSString *)getValue:(NSArray *)data position:(int)position {
    if (data.count < 5) {
        return @"";
    }
    return [((NSString *)data[position - 5]) stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark MISCA
- (void)getMISCA_Value:(NSArray *)data ventilation:(VentilationData *)ventilation {
    
    ventilation.TidalVolumeSet = [self getValue:data position:11];
    ventilation.TidalVolumeMeasured = [self getValue:data position:35];
    ventilation.PEEP = [self getValue:data position:15];
    ventilation.FiO2Set = [self getValue:data position:13];
    ventilation.PressureSupport = [self getValue:data position:26];
    ventilation.PressureControl = [self getValue:data position:85];
    ventilation.LowerMV = [self getValue:data position:46];
    ventilation.MVTotal = [self getValue:data position:36];
    ventilation.VentilationRateSet = [self getValue:data position:10];
    ventilation.VentilationRateTotal = [self getValue:data position:34];
    ventilation.InspT = [self getValue:data position:86];
    
    
    // if mode not spont
    if ([ventilation.VentilationMode caseInsensitiveCompare:@"spont"] != NSOrderedSame) {
        ventilation.FlowSetting = [self getValue:data position:12];
        ventilation.InspirationExpirationRatio = [self getValue:data position:99];
        ventilation.FlowMeasured = [self getValue:data position:12];
        ventilation.MeanPressure = [self getValue:data position:39];
        ventilation.FlowSensitivity = [self getValue:data position:71];
    }
}

#pragma mark MISCF
- (void)getMISCF_Value:(NSArray *)data ventilation:(VentilationData *)ventilation {
    ventilation.TidalVolumeSet = [self getValue:data position:14];
    ventilation.TidalVolumeMeasured = [self getValue:data position:71];
    ventilation.PEEP = [self getValue:data position:18];
    ventilation.FiO2Set = [self getValue:data position:16];
    ventilation.PressureSupport = [self getValue:data position:31];
    ventilation.LowerMV = [self getValue:data position:37];
    ventilation.MVTotal = [self getValue:data position:72];
    ventilation.VentilationRateSet = [self getValue:data position:13];
    ventilation.VentilationRateTotal = [self getValue:data position:70];
    /**
     * MISCF ONLY
     */
    ventilation.HighPressureAlarm = [self getValue:data position:34];
    /**
     * MISCF ONLY
     */
    ventilation.FiO2Measured = [self getValue:data position:77];
    ventilation.InspT = [self getValue:data position:47];
    
    
    // if mode not spont
    if ([ventilation.VentilationMode caseInsensitiveCompare:@"spont"] != NSOrderedSame) {
        ventilation.PressureControl = [self getValue:data position:46];
        ventilation.FlowSetting = [self getValue:data position:15];
        ventilation.InspirationExpirationRatio = [self getValue:data position:76];
        /**
         * MISCF ONLY
         */
        ventilation.Resistance = [self getValue:data position:97];
        /**
         * MISCF ONLY
         */
        ventilation.Compliance = [self getValue:data position:96];
        ventilation.FlowMeasured = [self getValue:data position:98];
        /**
         * MISCF ONLY
         */
        ventilation.PeakPressure = [self getValue:data position:73];
        ventilation.MeanPressure = [self getValue:data position:74];
        /**
         * MISCF ONLY
         */
        if ([ventilation.VentilationMode caseInsensitiveCompare:@"AC"] != NSOrderedSame) {
            ventilation.PlateauPressure = [self getValue:data position:94];
            
            if ([ventilation.PlateauPressure isEqualToString:@"0"]) {
                ventilation.PlateauPressure = @"";
            }
        }
        ventilation.FlowSensitivity = [self getValue:data position:45];
        /**
         * MISCF ONLY
         */
        ventilation.VolumeTarget = [self getValue:data position:61];
    }
}

@end
