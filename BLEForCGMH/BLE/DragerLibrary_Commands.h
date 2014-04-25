//
//  DragerLibrary_Commands.h
//  DragerLibrary
//
//  Created by Farland on 2014/3/3.
//  Copyright (c) 2014年 Yuekang. All rights reserved.
//

#ifndef DragerLibrary_Commands_h
#define DragerLibrary_Commands_h

//escape"
#define ESC 0x1B
//carriage return
#define CR 0x0D
//Start of Header
#define SOH 0x01

/*
 * Control Commands
 */
//No Operation
#define NOP 0x30
//Initialize Communication
#define ICC 0x51
//Stop Communication
#define STOP 0x55

/*
 * Data Request Commands
 */
//Request current Alarms
#define REQUEST_CURRENT_ALARMS_PAGE3 0x23
//Request current Alarms
#define REQUEST_CURRENT_MEASURED_DATA_PAGE1 0x24
//Request current low Alarm Limits
#define REQUEST_LOW_ALARM_LIMITS_PAGE1 0x25
//	Request current high Alarm Limits
#define REQUEST_HIGHT_ALARM_LIMITS_PAGE1 0x26
//Request current Alarms
#define REQUEST_CURRENT_ALARM_PAGE1 0x27
//Request current Date and Time
#define REQUEST_CURRENT_DATE_AND_TIME 0x28
//Request current Device Setting
#define REQUEST_CURRENT_DEVICE_SETTING 0x29
//Request current Text Messages
#define REQUEST_CURRENT_TEXT_MESSAGES 0x2A
//Request current measured Data
#define REQUEST_CURRENT_MEASURED_DATA_PAGE2 0x2B
//Request current low Alarm Limits
#define REQUEST_LOW_ALARM_LIMITS_PAGE2 0x2C
//	Request current high Alarm Limits
#define REQUEST_HIGHT_ALARM_LIMITS_PAGE2 0x2D
//Request current Alarms
#define REQUEST_CURRENT_ALARM_PAGE2 0x2E
//Request Device Identification
#define REQUEST_DEVICE_IDENTIFICATION 0x52
//Request Trend Data Status
#define REQUEST_TREND_DATA_STATUE 0x6C
//Request Trend Data
#define REQUEST_TREND_DATA 0x6D
//Request Realtime Configuration
#define REQUEST_REALTIME_CONFIGURATION 0x53

/*
 * Miscellaneous Commands
 */
//Time changed
#define TIME_CHANGED 0x49
//Configure Data Response Command
#define CONFIGURE_DATA_RESPONSE_COMMAND 0x4A

#endif
