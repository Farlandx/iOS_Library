//
//  SERVOi.h
//  BLE
//
//  Created by Farland on 2014/4/10.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SERVOi_Commands.h"
#import "VentilationData.h"

@interface SERVOi : NSObject

typedef NS_ENUM(NSUInteger, SERVOI_READ_STEP) {
    SERVOI_INIT,
    SERVOI_RESISTANCE_DB31,
    SERVOI_RESISTANCE_RB,
    SERVOI_RCTY,
    SERVOI_SDADS,
    SERVOI_RADAS,
    SERVOI_SDADB,
    SERVOI_RADAB,
    SERVOI_ERROR,
    SERVOI_WAITING,
    SERVOI_DONE
};

- (SERVOI_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation command:(NSData *)cmd;
- (void)resetStep;
- (NSData *)getInitCommand;

@end
