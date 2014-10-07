//
//  PB840.h
//  BLE
//
//  Created by Farland on 2014/9/16.
//  Copyright (c) 2014年 Farland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VentilationData.h"

@protocol PB840_Delegate <NSObject>

- (void)nextCommand:(NSData *)cmd;

@end

@interface PB840 : NSObject

typedef NS_ENUM(NSUInteger, PB840_READ_STEP) {
    PB840_FIRST_COMMAND,
    PB840_READ_FIRST_DATA,
    PB840_SECOND_COMMAND,
    PB840_READ_SECOND_DATA,
    PB840_ERROR,
    PB840_WAITING,
    PB840_DONE
};

@property (assign, nonatomic) id<PB840_Delegate> delegate;

- (PB840_READ_STEP)run:(NSData *)data VentilationData:(VentilationData *)ventilation;
- (void)resetStep;
- (NSData *)getFirstCommand;
- (NSData *)getSecondCommand;

@end
