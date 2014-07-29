//
//  VentilationData.h.m
//  BLE
//
//  Created by Farland on 2014/3/3.
//  Copyright (c) 2014年 Yuekang. All rights reserved.
//

#import "VentilationData.h"

@implementation VentilationData


#pragma -mark Property
@synthesize MeasureId;
@synthesize ChtNo;
@synthesize RecordTime;
@synthesize RecordIp;
@synthesize RecordOper;
@synthesize RecordDevice;
@synthesize RecordClientVersion;
@synthesize VentNo;
@synthesize RawData;

@synthesize VentilationMode;
@synthesize TidalVolumeSet;
@synthesize VolumeTarget;
@synthesize TidalVolumeMeasured;
@synthesize VentilationRateSet;
@synthesize SIMVRateSet;
@synthesize VentilationRateTotal;
@synthesize InspT;
@synthesize THigh;
//I:E Ratio
@synthesize InspirationExpirationRatio;
@synthesize Tlow;
@synthesize AutoFlow;
@synthesize FlowSetting;
@synthesize FlowMeasured;
@synthesize Pattern;
//Minute Volume Set
@synthesize MVSet;
@synthesize PercentMinVolSet;
@synthesize MVTotal;
@synthesize PeakPressure;
@synthesize PlateauPressure;
@synthesize MeanPressure;
@synthesize PEEP;
@synthesize Plow;
@synthesize PressureSupport;
@synthesize PressureControl;
@synthesize PHigh;
@synthesize FiO2Set;
@synthesize FiO2Measured;
@synthesize Resistance;
@synthesize Compliance;
@synthesize BaseFlow;
@synthesize FlowSensitivity;
@synthesize LowerMV;
@synthesize HighPressureAlarm;
@synthesize Temperature;
@synthesize ReliefPressure;
@synthesize PetCo2;
@synthesize SpO2;
@synthesize RR;
@synthesize TV;
@synthesize MV;
@synthesize MaxPi;
@synthesize Mvv;
@synthesize Rsbi;
@synthesize EtSize;
@synthesize Mark;
@synthesize CuffPressure;
@synthesize BreathSounds;
@synthesize Pr;
@synthesize Cvp;
@synthesize BpS;
@synthesize BpD;
@synthesize Xrem;
@synthesize AutoPEEP;
@synthesize PlateauTimeSetting;

//以下參數顯示用,不須上傳
@synthesize RecordOperName;
@synthesize VentilatorModel;
@synthesize BedNo;
@synthesize ErrorMsg;
@synthesize checked;

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaultValue];
    }
    return self;
}

- (NSString *)modeToString:(VENTILATION_MODE)mode {
    switch (mode) {
        case AC:
            return @"A/C";
            
        case CPPV:
            return @"CPPV";
            
        case SIMV:
            return @"SIMV";
            
        case SIMVPS:
            return @"SIMV+PS";
            
        case PS:
            return @"PS";
            
        case CPAP:
            return @"CPAP";
            
        case PCV:
            return @"PCV";
            
        case PLV:
            return @"PLV";
            
        case VS:
            return @"VS";
            
        case PRVC:
            return @"PRVC";
            
        case PAC:
            return @"P A/C";
            
        case PSIMV:
            return @"PSIMV";
            
        case APVC:
            return @"APVc";
            
        case APVS:
            return @"APVs";
            
        case ASV:
            return @"ASV";
            
        case APRV:
            return @"APRV";
            
        case BIPAP:
            return @"BiPAP";
            
        case _NIV:
            return @"NIV";
    }
    return @"";
}

- (void)setDefaultValue {
    MeasureId = 0;
    ChtNo = @"";
    RecordTime = @"";
    RecordIp = @"";
    RecordOper = @"";
    RecordDevice = @"";
    RecordClientVersion = @"";
    VentNo = @"";
    RawData = @"";
    VentilationMode = @"";
    TidalVolumeSet = @"";
    VolumeTarget = @"";
    TidalVolumeMeasured = @"";
    VentilationRateSet = @"";
    SIMVRateSet = @"";
    VentilationRateTotal = @"";
    InspT = @"";
    THigh = @"";
    InspirationExpirationRatio = @"";
    Tlow = @"";
    AutoFlow = @"";
    FlowSetting = @"";
    FlowMeasured = @"";
    Pattern = @"";
    MVSet = @"";
    PercentMinVolSet = @"";
    MVTotal = @"";
    PeakPressure = @"";
    PlateauPressure = @"";
    MeanPressure = @"";
    PEEP = @"";
    Plow = @"";
    PressureSupport = @"";
    PressureControl = @"";
    PHigh = @"";
    FiO2Set = @"";
    FiO2Measured = @"";
    Resistance = @"";
    Compliance = @"";
    BaseFlow = @"";
    FlowSensitivity = @"";
    LowerMV = @"";
    HighPressureAlarm = @"";
    Temperature = @"";
    ReliefPressure = @"";
    PetCo2 = @"";
    SpO2 = @"";
    RR = @"";
    TV = @"";
    MV = @"";
    MaxPi = @"";
    Mvv = @"";
    Rsbi = @"";
    EtSize = @"";
    Mark = @"";
    CuffPressure = @"";
    BreathSounds = @"";
    Pr = @"";
    Cvp = @"";
    BpS = @"";
    BpD = @"";
    Xrem = @"";
    AutoPEEP = @"";
    PlateauTimeSetting = @"";
    RecordOperName = @"";
    VentilatorModel = @"";
    BedNo = @"";
    ErrorMsg = @"";
    checked = NO;
}

- (void) clearVentilationData {
    RecordTime = @"";
    VentNo = @"";
    RawData = @"";
    VentilationMode = @"";
    TidalVolumeSet = @"";
    VolumeTarget = @"";
    TidalVolumeMeasured = @"";
    VentilationRateSet = @"";
    SIMVRateSet = @"";
    VentilationRateTotal = @"";
    InspT = @"";
    THigh = @"";
    InspirationExpirationRatio = @"";
    Tlow = @"";
    AutoFlow = @"";
    FlowSetting = @"";
    FlowMeasured = @"";
    Pattern = @"";
    MVSet = @"";
    PercentMinVolSet = @"";
    MVTotal = @"";
    PeakPressure = @"";
    PlateauPressure = @"";
    MeanPressure = @"";
    PEEP = @"";
    Plow = @"";
    PressureSupport = @"";
    PressureControl = @"";
    PHigh = @"";
    FiO2Set = @"";
    FiO2Measured = @"";
    Resistance = @"";
    Compliance = @"";
    BaseFlow = @"";
    FlowSensitivity = @"";
    LowerMV = @"";
    HighPressureAlarm = @"";
    Temperature = @"";
    ReliefPressure = @"";
}

@end
