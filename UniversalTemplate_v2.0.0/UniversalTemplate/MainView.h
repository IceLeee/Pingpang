//
//  MainView.h
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TitleView;
@class StatisticsView;
@class TabViewController;
@class SNView;

#if INSTANT_PUDDING == 1
@class PDCA;
#endif

#if NI_VISA == 1
@class visaGeneral;
#endif

#if DUT_TEST == 1
@class ORSSerialPort;
@class ORSSerialPortManager;
#endif

@class AlertWindowController;
@class Reachability;

@interface MainView : NSView
{
    NSString *_swName;
    NSString *_swVersion;
    NSString *_strProduct;
    NSString *_strFactory;
    NSString *_strStationID;
    NSString *_strCurrentCB;
    //NSString *_percentChrange;
    
    NSArray *_arrayCheckX2BCB;
    NSArray *_arrayCheckX2ACB;
    NSArray *_arrayCheckCBName;

    TitleView *_titleView;
    StatisticsView *_statisticsView;
    TabViewController *_tabViewController;
    NSSegmentedControl *_segmentedController;
    NSTextField *_statusTextView;
    //NSTextField *_editFSN;
    
#if DUT_TEST == 1
    NSMutableArray *_arrayDUTs; //待测物
    NSMutableArray <ORSSerialPort *> *_arrCommDUT;
#endif
    
#if FIXTURE_TEST == 1
    NSMutableArray *_arrayFIXTUREs; //控制板
    NSMutableArray <ORSSerialPort *> *_arrCommFIXTURE;
#endif
    
#if (INST_TEST == 1) && (NI_VISA == 1)
    NSMutableArray *_arrayInsts; //仪器
    NSMutableArray <visaGeneral *> *_arrCommInst;
#endif
    
    NSString *_strPortStatus;
    
    NSMutableArray <SNView *> *_arrSNView;
    NSMutableArray <NSString *> *_arrSN;
    NSMutableArray <NSString *> *_arrStartTime;
    NSMutableArray <NSString *> *_arrStopTime;
    NSMutableArray <NSMutableString *> *_arrTotalResBuffer;
    
    NSMutableArray <NSString *> *_arrBlobPath;
    
    NSArray *_infoData;
    NSMutableArray *_arrCommandData[MULTIPLE_NUMBERS];

#if INSTANT_PUDDING == 1
    NSMutableArray <PDCA *> *_arrPDCA;
#endif
    
    BOOL _bInitPudding[MULTIPLE_NUMBERS];
    BOOL _bTestResult[MULTIPLE_NUMBERS];
    BOOL _bFailedAtLeastOneTest[MULTIPLE_NUMBERS];
    BOOL _bEUSetting[MULTIPLE_NUMBERS];
    BOOL _bTesting[MULTIPLE_NUMBERS];
    
    NSButton *_scPudding;
//    NSButton *_scCheckProcess;
    NSButton *_scAuditMode;
    BOOL _bPudding;
    BOOL _bAuditMode;
    
    NSString *_strSFCUrl;
    
    Reachability *_reachNetwork;
    
    ORSSerialPortManager *_dutPortManager;
    NSString *_strSpamPID;
    NSString *_strChargingCablePID;
    NSMutableArray *_arrLocationIDPreFix;
    NSMutableArray *_arrMatchFixtureAndModem;
}

- (void)close;

@end
