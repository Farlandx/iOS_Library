//
//  SERVO300.h
//  BLE
//
//  Created by Farland on 2014/10/7.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SERVOi_Commands.h"
#import "VentilationData.h"

@protocol SERVO300_Delegate <NSObject>

- (void)nextCommand:(NSData *)cmd;

@end

@interface SERVO300 : NSObject

typedef NS_ENUM(NSUInteger, SERVO300_READ_STEP) {
    SERVO300_INIT,
    SERVO300_RESISTANCE_DB31,
    SERVO300_RESISTANCE_RB,
    SERVO300_RCTY,
    SERVO300_SDADS,
    SERVO300_RADAS,
    SERVO300_SDADB,
    SERVO300_RADAB,
    SERVO300_ERROR,
    SERVO300_WAITING,
    SERVO300_DONE
};

@property (assign, nonatomic) id<SERVO300_Delegate> delegate;

- (SERVO300_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation;
- (void)resetStep;
- (NSData *)getInitCommand;

@end
