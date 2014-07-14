//
//  DRAGER.m
//  BLE
//
//  Created by Farland on 2014/3/21.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import "DRAGER.h"
#import "DragerLibrary_Commands.h"

@implementation DRAGER {
    DRAGER_READ_STEP step;
}

- (id)init {
    self = [super init];
    if (self) {
        step = DRAGER_ICC;
        _mData = [[NSMutableData alloc] init];
    };
    return  self;
}

- (void)dealloc {
    _delegate = nil;
}

//CHECKSUM Least significant 8-bit sum of all preceding bytes beginning with "ESC" in ASCII HEX format
- (const char *)getChkSum:(int)sum {
    NSString *sumString = [NSString stringWithFormat:@"%02X", sum];
    sumString = [sumString substringWithRange:NSMakeRange([sumString length] - 2, 2)];
    return [sumString UTF8String];
    
}

- (NSData *)getICC_Command {
    step = DRAGER_ICC;
    int esc = ESC, icc = ICC, cr = CR;
    const char *chkSum = [self getChkSum:(esc + icc)];
    
    unsigned char cmd[5] = {esc, icc, chkSum[0], chkSum[1], cr};
    
    return [NSData dataWithBytes:cmd length:sizeof(cmd)];
}

- (BOOL)dataCheck:(NSData *)data header:(int)header command:(int)cmd {
    NSUInteger len = [data length];
    const char *buffer = [data bytes];
    BOOL headerFound = NO, cmdFound = NO;
    if (len > 2) {
        for(int i = 0; i < len; i++) {
            if(!headerFound && buffer[i] == header) {
                headerFound = YES;
                continue;
            }
            else if(headerFound && !cmdFound && buffer[i] == cmd) {
                cmdFound = YES;
                continue;
            }
            else if(headerFound && cmdFound && buffer[i] == CR) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)resetMData {
    if ([_mData length] > 0) {
        //[_mData replaceBytesInRange:NSMakeRange(0, [_mData length]) withBytes:nil length:0];
        [_mData setLength:0];
        NSLog(@"mData reset");
    }
}

- (NSData *)getBasicCommand:(int)header cmdCode:(int)cmdCode {
    unsigned char result[5];
    result[0] = header;
    result[1] = cmdCode;
    
    const char *chkSum = [self getChkSum:(header + cmdCode)];
    result[2] = chkSum[0];
    result[3] = chkSum[1];
    result[4] = CR;
    
    return [[NSData alloc]initWithBytes:result length:sizeof(result)];
}

- (NSData *)getConfigDataCommand:(int)cmdCode dataType:(int)dataType dataCode:(NSString *)dataCode {
    NSData *data = [dataCode dataUsingEncoding:NSUTF8StringEncoding];
    int i, sum = 0, size = 6 + (int)[data length];
    unsigned char buffer[size];
    buffer[0] = ESC;
    buffer[1] = cmdCode;
    buffer[2] = dataType;
    
    const char *bytes = [data bytes];
    for (i = 0; i < [data length]; i++) {
        buffer[i + 3] = bytes[i];
    }
    for (i = 0; i < sizeof(buffer) - 3; i++) {
        sum += buffer[i];
    }
    
    const char *chkSum = [self getChkSum:sum];
    buffer[size - 3] = chkSum[0];
    buffer[size - 2] = chkSum[1];
    buffer[size - 1] = CR;
    
    return [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
}

- (NSString *)getMode:(NSString *)code {
    code = [code stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (![code caseInsensitiveCompare:@"01"]) {
        return @"IPPV";
    } else if (![code caseInsensitiveCompare:@"02"]) {
        return @"IPPV/ASSIST";
    } else if (![code caseInsensitiveCompare:@"06"]) {
        return @"SIMV";
    } else if (![code caseInsensitiveCompare:@"07"]) {
        return @"SIMV/ASB";
    } else if (![code caseInsensitiveCompare:@"0E"]) {
        return @"BiPAP";
    } else if (![code caseInsensitiveCompare:@"2D"]) {
        return @"BIPAP/ASB";
    } else if (![code caseInsensitiveCompare:@"2E"]) {
        return @"SIMV/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"2F"]) {
        return @"SIMV/ASB/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"30"]) {
        return @"IPPV/ASSIST/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"31"]) {
        return @"IPPV/ASSIST/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"1A"]) {
        return @"APRV";
    } else if (![code caseInsensitiveCompare:@"0C"]) {
        return @"MMV";
    } else if (![code caseInsensitiveCompare:@"0D"]) {
        return @"MMV/ASB";
    } else if (![code caseInsensitiveCompare:@"32"]) {
        return @"MMV/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"33"]) {
        return @"MMV/ASB/AutoFlow";
    } else if (![code caseInsensitiveCompare:@"0A"]) {
        return @"CPAP";
    } else if (![code caseInsensitiveCompare:@"0B"]) {
        return @"CPAP/ASB";
    } else if (![code caseInsensitiveCompare:@"11"]) {
        return @"APNEA VENTILATION";
    } else if (![code caseInsensitiveCompare:@"35"]) {
        return @"CPAP/PPS";
    } else if (![code caseInsensitiveCompare:@"0F"]) {
        return @"SYNCHRON MASTER";
    } else if (![code caseInsensitiveCompare:@"10"]) {
        return @"SYNCHRON SLAVE";
    } else if (![code caseInsensitiveCompare:@"47"]) {
        return @"BIPAP/ASSIST";
    } else if (![code caseInsensitiveCompare:@"20"]) {
        return @"Adults";
    } else if (![code caseInsensitiveCompare:@"3A"]) {
        return @"Pediatrics";
    } else if (![code caseInsensitiveCompare:@"21"]) {
        return @"Neonates";
    } else if (![code caseInsensitiveCompare:@"48"]) {
        return @"IV";
    } else if (![code caseInsensitiveCompare:@"49"]) {
        return @"NIV";
    } else if (![code caseInsensitiveCompare:@"1E"]) {
        return @"STANDBY";
    } else if (![code caseInsensitiveCompare:@"22"]) {
        return @"mmHg";
    } else if (![code caseInsensitiveCompare:@"23"]) {
        return @"kPa";
    } else if (![code caseInsensitiveCompare:@"24"]) {
        return @"%";
    }
    
    return code;
}

- (void)parseSet:(NSString *)values VentilationData:(VentilationData *)refData {
    NSString *strSetting = [values substringWithRange:NSMakeRange(2, [values length] - 2)];
    NSInteger size = [strSetting length] / 7;
    NSString *code, *value;
    
    for (int i = 0; i < size; i++) {
        code = [strSetting substringWithRange:NSMakeRange((i * 2) + (i * 5), 2)];
        value = [[strSetting substringWithRange:NSMakeRange((i * 2) + (i * 5) + 2, 5)] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![code caseInsensitiveCompare:@"01"]) {
            // _XXX_
            refData.FiO2Set = value;
        } else if (![code caseInsensitiveCompare:@"02"]) {
            // XXX.X
            refData.FlowSetting = value;
        } else if (![code caseInsensitiveCompare:@"04"]) {
            // X.XXX
            refData.TidalVolumeSet = [NSString stringWithFormat:@"%.2lf", [value floatValue] * 1000];
        } else if (![code caseInsensitiveCompare:@"05"]) {
            // XX.XX
            refData.InspT = value;
        } else if (![code caseInsensitiveCompare:@"07"]) {
            // XXX.X
            refData.InspirationExpirationRatio = value;
        } else if (![code caseInsensitiveCompare:@"08"]) {
            refData.InspirationExpirationRatio = [@"1:" stringByAppendingString:value];
        } else if (![code caseInsensitiveCompare:@"09"]) {
            // XXX.X
            refData.VentilationRateSet = value;
        } else if (![code caseInsensitiveCompare:@"0A"]) {
            
        } else if (![code caseInsensitiveCompare:@"0B"]) {
            // _XX.X
            refData.PEEP = value;
        } else if (![code caseInsensitiveCompare:@"0C"]) {
            
        } else if (![code caseInsensitiveCompare:@"0D"]) {
            // __XX_
            refData.Plow = value;
        } else if (![code caseInsensitiveCompare:@"0E"]) {
            // __XX_
            refData.PHigh = value;
        } else if (![code caseInsensitiveCompare:@"0F"]) {
            // _XX.X
            refData.Tlow = value;
        } else if (![code caseInsensitiveCompare:@"10"]) {
            // _XX.X
            refData.THigh = value;
        } else if (![code caseInsensitiveCompare:@"11"]) {
            
        } else if (![code caseInsensitiveCompare:@"12"]) {
            // _XX.X
            refData.PressureSupport = value;
        } else if (![code caseInsensitiveCompare:@"13"]) {
            // XXX.X
            refData.PressureControl = value;
        } else if (![code caseInsensitiveCompare:@"15"]) {
            
        } else if (![code caseInsensitiveCompare:@"16"]) {
            
        } else if (![code caseInsensitiveCompare:@"17"]) {
            
        } else if (![code caseInsensitiveCompare:@"29"]) {
            
        } else if (![code caseInsensitiveCompare:@"2E"]) {
            
        } else if (![code caseInsensitiveCompare:@"3C"]) {
            // XXXXX
            refData.FlowSensitivity = [NSString stringWithFormat:@"%.1lf", [value floatValue] / 10];
        } else if (![code caseInsensitiveCompare:@"3D"]) {
            // XXXXX
            refData.BaseFlow = [NSString stringWithFormat:@"%.1lf", [value floatValue] / 10];
        } else if (![code caseInsensitiveCompare:@"4E"]) {
            
        }
    }
}

- (void)parseMeadused:(NSString *)values VentilationData:(VentilationData *)refData {
    NSString *strMeasure = [values substringWithRange:NSMakeRange(2, [values length] - 2)];
    int size = (int)[strMeasure length] / 6;
    NSString *code, *value;
    for (int i = 0; i < size; i++) {
        code = [strMeasure substringWithRange:NSMakeRange((i * 2) + (i * 4), 2)];
        value = [[strMeasure substringWithRange:NSMakeRange((i * 2) + (i * 4) + 2, 4)] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![code caseInsensitiveCompare:@"06"]) {
            // XX.X
            refData.Compliance = value;
        } else if (![code caseInsensitiveCompare:@"07"]) {
            
        } else if (![code caseInsensitiveCompare:@"0B"]) {
            // XX.X
            refData.Resistance = value;
        } else if (![code caseInsensitiveCompare:@"08"]) {
            
        } else if (![code caseInsensitiveCompare:@"71"]) {
            
        } else if (![code caseInsensitiveCompare:@"72"]) {
            
        } else if (![code caseInsensitiveCompare:@"73"]) {
            // XXX_
            refData.MeanPressure = value;
        } else if (![code caseInsensitiveCompare:@"74"]) {
            // XXX_
            refData.PlateauPressure = value;
        } else if (![code caseInsensitiveCompare:@"78"]) {
            
        } else if (![code caseInsensitiveCompare:@"79"]) {
            
        } else if (![code caseInsensitiveCompare:@"7D"]) {
            // XXX_
            refData.PeakPressure = value;
        } else if (![code caseInsensitiveCompare:@"81"]) {
            
        } else if (![code caseInsensitiveCompare:@"82"]) {
            
        } else if (![code caseInsensitiveCompare:@"88"]) {
            // _XXX
            refData.TidalVolumeMeasured = value;
        } else if (![code caseInsensitiveCompare:@"B5"]) {
            
        } else if (![code caseInsensitiveCompare:@"B7"]) {
            
        } else if (![code caseInsensitiveCompare:@"7A"]) {
            
        } else if (![code caseInsensitiveCompare:@"B8"]) {
            
        } else if (![code caseInsensitiveCompare:@"B9"]) {
            // XX.X
            refData.MVTotal = value;
        } else if (![code caseInsensitiveCompare:@"C1"]) {
            
        } else if (![code caseInsensitiveCompare:@"D6"]) {
            // XXX_
            refData.VentilationRateTotal = value;
        } else if (![code caseInsensitiveCompare:@"8B"]) {
            
        } else if (![code caseInsensitiveCompare:@"8D"]) {
            
        } else if (![code caseInsensitiveCompare:@"C9"]) {
            
        } else if (![code caseInsensitiveCompare:@"09"]) {
            
        } else if (![code caseInsensitiveCompare:@"89"]) {
            
        } else if (![code caseInsensitiveCompare:@"8A"]) {
            
        } else if (![code caseInsensitiveCompare:@"DB"]) {
            
        } else if (![code caseInsensitiveCompare:@"E3"]) {
            
        } else if (![code caseInsensitiveCompare:@"E6"]) {
            
        } else if (![code caseInsensitiveCompare:@"F0"]) {
            // XXX_
            refData.FiO2Measured = value;
        } else if (![code caseInsensitiveCompare:@"E1"]) {
            
        } else if (![code caseInsensitiveCompare:@"EB"]) {
            
        }
    }
}

- (void)resetStep {
    step = DRAGER_ICC;
}

- (DRAGER_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation {
    if (data != nil) {
        const char *buffer = [data bytes];
        if (step == DRAGER_ICC && [data length] > 5 && buffer[0] == ESC && buffer[1] == ICC && buffer[2] == 0x36 && buffer[3] == 0x43 && buffer[4] == CR) {
            return DRAGER_WAITING;
        }
        [_mData appendData:data];
    }
    
    if ([_mData length] > 0) {
        const char *bytes = [_mData bytes];
        NSUInteger dataLen = [_mData length];
        
        if (dataLen > 5) {
            //尾碼是Q6C就斷線
            if (bytes[dataLen - 5] == ESC && bytes[dataLen - 4] == ICC && bytes[dataLen - 3] == 0x36 && bytes[dataLen - 2] == 0x43 && bytes[dataLen - 1] == CR) {
                step = DRAGER_ICC;
                [self resetMData];
                return DRAGER_ERROR;
            }
        }
        NSLog(@"data:%@", [[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding]);
        switch (step) {
            case DRAGER_ICC: //初始化中
                if ([self dataCheck:_mData header:SOH command:ICC]) {
                    NSLog(@"ICC OK");
                    step = DRAGER_AFTER_ICC_CONFIG_COMMAND;
                    [self resetMData];
                    
                    [_delegate nextCommand:[self getConfigDataCommand:CONFIGURE_DATA_RESPONSE_COMMAND dataType:REQUEST_CURRENT_TEXT_MESSAGES dataCode:@"010206070E2D2E2F30311A0C0D32330A0B11350F1047203A2148491E222324"]];
                }
                break;
                
            case DRAGER_AFTER_ICC_CONFIG_COMMAND: //取得模式設定
                if ([self dataCheck:_mData header:SOH command:CONFIGURE_DATA_RESPONSE_COMMAND]) {
                    step = DRAGER_GET_MODE;
                    [self resetMData];
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:REQUEST_CURRENT_TEXT_MESSAGES]];
                }
                break;
                
            case DRAGER_GET_MODE: //取得模式
                if ([self dataCheck:_mData header:SOH command:REQUEST_CURRENT_TEXT_MESSAGES]) {
                    NSString *strMode = [[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding];
                    int index = (int)[strMode rangeOfString:@"*"].location + 1;
                    ventilation.VentilationMode = [strMode substringWithRange:NSMakeRange(index, 2)];
                    if (![ventilation.VentilationMode caseInsensitiveCompare:@"2E"]
                        || ![ventilation.VentilationMode caseInsensitiveCompare:@"2F"]
                        || ![ventilation.VentilationMode caseInsensitiveCompare:@"30"]
                        || ![ventilation.VentilationMode caseInsensitiveCompare:@"31"]
                        || ![ventilation.VentilationMode caseInsensitiveCompare:@"32"]
                        || ![ventilation.VentilationMode caseInsensitiveCompare:@"33"]) {
                        ventilation.AutoFlow = @"Yes";
                    }
                    else {
                        ventilation.AutoFlow = @"No";
                    }
                    ventilation.VentilationMode = [self getMode:ventilation.VentilationMode];
                    NSLog(@"取得模式 pass.");
                    
                    step = DRAGER_AFTER_GET_MODE_CONFIG_COMMAND;
                    [self resetMData];
                    
                    //取得設備設定設定值
                    [_delegate nextCommand:[self getConfigDataCommand:CONFIGURE_DATA_RESPONSE_COMMAND dataType:REQUEST_CURRENT_DEVICE_SETTING dataCode:@"010204050708090B0D0E0F1011121316292E3C3D4E"]];
                }
                break;
                
            case DRAGER_AFTER_GET_MODE_CONFIG_COMMAND: //設備設定設定值
                if ([self dataCheck:_mData header:SOH command:CONFIGURE_DATA_RESPONSE_COMMAND]) {
                    step = DRAGER_CURRENT_DEVICE_SETTING;
                    [self resetMData];
                    
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:REQUEST_CURRENT_DEVICE_SETTING]];
                }
                break;
                
            case DRAGER_CURRENT_DEVICE_SETTING: //設備設定
                if ([self dataCheck:_mData header:SOH command:REQUEST_CURRENT_DEVICE_SETTING]) {
                    NSString *resultSetting = [[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding];
                    [self parseSet:resultSetting VentilationData:ventilation];
                    
                    if (![ventilation.TidalVolumeSet isEqualToString:@""] && ![ventilation.VentilationRateSet isEqualToString:@""]) {
                        ventilation.MVSet = [NSString stringWithFormat:@"%.1lf", [ventilation.TidalVolumeSet floatValue] * [ventilation.VentilationRateSet floatValue] / 1000];
                    }
                    else
                    {
                        NSLog(@"mvset missed");
                    }
                    
                    if (ventilation.PressureSupport != nil && ![ventilation.PressureSupport isEqualToString:@""] && ventilation.PEEP != nil && ![ventilation.PEEP isEqualToString:@""]) {
                        //PressureSupport = PressureSupport - PEEP
                        ventilation.PressureSupport = [NSString stringWithFormat:@"%.1lf", [ventilation.PressureSupport floatValue] - [ventilation.PEEP floatValue]];
                    }
                    
                    step = DRAGER_AFTER_DEVICE_SETTING_CONFIG_COMMAND;
                    [self resetMData];
                    
                    //取得量測值
                    NSLog(@"取得量測值");
                    [_delegate nextCommand:[self getConfigDataCommand:CONFIGURE_DATA_RESPONSE_COMMAND dataType:REQUEST_CURRENT_MEASURED_DATA_PAGE1 dataCode:@"060B73747D88B9D6F0"]];
                }
                break;
                
            case DRAGER_AFTER_DEVICE_SETTING_CONFIG_COMMAND://取得量測值設定值
                if ([self dataCheck:_mData header:SOH command:CONFIGURE_DATA_RESPONSE_COMMAND]) {
                    step = DRAGER_CURRENT_MEASURED_DATA_PAGE1;
                    [self resetMData];
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:REQUEST_CURRENT_MEASURED_DATA_PAGE1]];
                }
                break;
                
            case DRAGER_CURRENT_MEASURED_DATA_PAGE1:
                if ([self dataCheck:_mData header:SOH command:REQUEST_CURRENT_MEASURED_DATA_PAGE1]) {
                    NSString *values = [[NSString alloc] initWithString:[[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding]];
                    [self parseMeadused:values VentilationData:ventilation];
                    step = DRAGER_GET_LOWERMV_CONFIG_COMMAND;
                    [self resetMData];
                    //LowerMV
                    NSLog(@"LowerMV");
                    [_delegate nextCommand:[self getConfigDataCommand:CONFIGURE_DATA_RESPONSE_COMMAND dataType:REQUEST_LOW_ALARM_LIMITS_PAGE1 dataCode:@"B9"]];
                }
                break;
                
            case DRAGER_GET_LOWERMV_CONFIG_COMMAND:
                if ([self dataCheck:_mData header:SOH command:CONFIGURE_DATA_RESPONSE_COMMAND]) {
                    step = DRAGER_GET_LOWERMV;
                    [self resetMData];
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:REQUEST_LOW_ALARM_LIMITS_PAGE1]];
                }
                break;
                
            case DRAGER_GET_LOWERMV:
                if ([self dataCheck:_mData header:SOH command:REQUEST_LOW_ALARM_LIMITS_PAGE1]) {
                    NSString *values = [[NSString alloc] initWithString:[[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding]];
                    NSString *strMeasure = [values substringWithRange:NSMakeRange(2, [values length] - 2)];
                    if ([strMeasure isEqualToString:@""]) {
                        return DRAGER_WAITING;
                    }
                    ventilation.LowerMV = [[strMeasure substringWithRange:NSMakeRange(2, 4)] stringByReplacingOccurrencesOfString:@" " withString:@""];
                    step = DRAGER_AFTER_CURRENT_MEASURED_DATA_PAGE1;
                    [self resetMData];
                    
                    //HightPerssureAlarm
                    NSLog(@"HightPerssureAlarm");
                    [_delegate nextCommand:[self getConfigDataCommand:CONFIGURE_DATA_RESPONSE_COMMAND dataType:REQUEST_HIGHT_ALARM_LIMITS_PAGE1 dataCode:@"7D"]];
                }
                break;
                
            case DRAGER_AFTER_CURRENT_MEASURED_DATA_PAGE1:
                if ([self dataCheck:_mData header:SOH command:CONFIGURE_DATA_RESPONSE_COMMAND]) {
                    step = DRAGER_LAST;
                    [self resetMData];
                    NSLog(@"REQUEST_LOW_ALARM_LIMITS_PAGE1");
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:REQUEST_HIGHT_ALARM_LIMITS_PAGE1]];
                }
                break;
                
            case DRAGER_LAST:
                NSLog(@"DRAGER_LAST");
                if ([self dataCheck:_mData header:SOH command:REQUEST_HIGHT_ALARM_LIMITS_PAGE1]) {
                    NSString *values = [[NSString alloc] initWithString:[[NSString alloc] initWithData:_mData encoding:NSUTF8StringEncoding]];
                    NSString *strMeasure = [values substringWithRange:NSMakeRange(2, [values length] - 2)];
                    ventilation.HighPressureAlarm = [[strMeasure substringWithRange:NSMakeRange(2, 4)] stringByReplacingOccurrencesOfString:@" " withString:@""];
                    step = DRAGER_DONE;
                    [self resetMData];
                    NSLog(@"done");
                    [_delegate nextCommand:[self getBasicCommand:ESC cmdCode:STOP]];
                }
                break;
                
            default:
                break;
        }
    }
    
    return step;
}

@end
