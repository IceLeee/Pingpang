//
//  MainView.m
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import "MainView.h"
#import "GlobalDef.h"
#import "TitleView.h"
#import "StatisticsView.h"
#import "TabViewController.h"
#import "RuntimeView.h"
#import "SNView.h"
#import "CSVCreateFile.h"

#if INSTANT_PUDDING == 1
#import "PDCA.h"
#endif

#if (DUT_TEST == 1)||(FIXTURE_TEST == 1)
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#endif

#if (INST_TEST == 1) && (NI_VISA == 1)
#import "visaGeneral.h"
#endif

#import "InputPasswordWindow.h"
#import "AlertWindowController.h"
#import "Reachability.h"
#import "DES.h"

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/serial/ioss.h>
#include <IOKit/IOBSD.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#define kChargeLabelViewTag     108
extern NSString* const MESSAGE_INPUTSN;
extern NSString* const MESSAGE_SAVESETTING;
//5.14 add
extern NSString * const ORSConnectedSerialPortsLocationIDKey;
extern NSString * const ORSConnectedSerialPortsSerialNumberKey;

@implementation MainView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
            _arrCommandData[i] = [[NSMutableArray alloc] initWithCapacity:4];
        }

#if DUT_TEST == 1
        _arrayDUTs = [[NSMutableArray alloc] initWithCapacity:3];
        _arrCommDUT = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
#if FIXTURE_TEST == 1
        _arrayFIXTUREs = [[NSMutableArray alloc] initWithCapacity:3];
        _arrCommFIXTURE = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
#if (INST_TEST == 1) && (NI_VISA == 1)
        _arrayInsts = [[NSMutableArray alloc] initWithCapacity:3];
        _arrCommInst = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
        _strPortStatus = [[NSString alloc] initWithFormat:@""];
        
        _strStationID = [self getComputerNameForTestFixture];
        
#if INSTANT_PUDDING == 1
        _arrPDCA = [[NSMutableArray alloc] initWithCapacity:4];
        for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
            PDCA *pdca = [[PDCA alloc] init];
            [_arrPDCA addObject:pdca];
        }
#endif
        
        _strSFCUrl = [self getSFCURL];
        
//        _arrayCheckX2ACB = [self getControlBitsArray];
        _arrayCheckCBName = [self getControlBitsNameArray];
        
        _arrSNView = [[NSMutableArray alloc] initWithCapacity:4];
        //5.14 add
        _arrLocationIDPreFix = [[NSMutableArray alloc] initWithCapacity:4];
        _arrMatchFixtureAndModem = [[NSMutableArray alloc] initWithCapacity:4];
        
        _arrSN = [[NSMutableArray alloc] initWithCapacity:4];
        _arrStartTime = [[NSMutableArray alloc] initWithCapacity:4];
        _arrStopTime = [[NSMutableArray alloc] initWithCapacity:4];
        _arrTotalResBuffer = [[NSMutableArray alloc] initWithCapacity:4];

        _arrBlobPath = [[NSMutableArray alloc] initWithCapacity:4];
        
        for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
            [_arrSN addObject:@""];
            [_arrStartTime addObject:@""];
            [_arrStopTime addObject:@""];
            
            NSMutableString *strTotalResBuffer = [[NSMutableString alloc] initWithCapacity:3];
            [_arrTotalResBuffer addObject:strTotalResBuffer];

            [_arrBlobPath addObject:@""];
            
#if DUT_TEST == 1
            ORSSerialPort *serialDUT = [[ORSSerialPort alloc] init];
            [_arrCommDUT addObject:serialDUT];
#endif
            
#if FIXTURE_TEST == 1
            ORSSerialPort *serialFIXTURE = [[ORSSerialPort alloc] init];
            [_arrCommFIXTURE addObject:serialFIXTURE];
#endif
            
#if (INST_TEST == 1) && (NI_VISA == 1)
            ORSSerialPort *visaInst = [[visaGeneral alloc] init];
            [_arrCommInst addObject:visaInst];
#endif
        }
        
        _dutPortManager = [ORSSerialPortManager sharedSerialPortManager];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
        [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];

    }
    return self;
}

- (void)close
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_INPUTSN object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_SAVESETTING object:self];
    [self removeResponseObserver];
    
#if DUT_TEST == 1
    for (ORSSerialPort *comm in _arrCommDUT) {
        if([comm isOpen]) {
            [comm close];
        }
    }
#endif
    
#if FIXTURE_TEST == 1
    for (ORSSerialPort *comm in _arrCommFIXTURE) {
        if([comm isOpen]) {
            [comm close];
        }
    }
#endif
    
#if (INST_TEST == 1) && (NI_VISA == 1)
    for (visaGeneral *comm in _arrCommInst) {
        if([comm isOpen]) {
            [comm close];
        }
    }
#endif
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    static int iFisrt = 0;
    
    if (iFisrt == 0) {
        [self initTestConfigFile];
        [self setSpamFixturePorts];
        [self initTestScriptFile];
        [self initAllControllers];
        [self initAllDevices];
        //        [self initProductDevice];
        [self initDefaultStatus];
        
        [self runningHIDControl];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSaveSetting:)
                                                     name:MESSAGE_SAVESETTING
                                                   object:nil];
        
        //注册网络通知，监测网络通断状态
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
        
        _reachNetwork = [Reachability reachabilityForInternetConnection];
        
        [_reachNetwork startNotifier];

        iFisrt++;
    }
}

- (NSString *)getComputerNameForTestFixture
{
    return [[NSHost currentHost] localizedName];
}

- (void)initAllDevices
{
    dispatch_queue_t queue = dispatch_queue_create("open devices", nil);
    dispatch_async(queue, ^{
        NSString *strTmp = @"Initial all device !";
        _strPortStatus = @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusTextView setTextColor:[NSColor blueColor]];
            [_statusTextView setStringValue:strTmp];
        });
        
        
//        [NSThread sleepForTimeInterval:0.5f];
        for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
//#if DUT_TEST == 1
//            [self initDUTDevice:i];
//#endif
#if FIXTURE_TEST == 1
            [self initFIXTUREDevice:i];
            [self getChargeValue:(int)i];
#endif
#if (INST_TEST == 1) && (NI_VISA == 1)
            [self initInstDevice:i];
#endif
        }

        //回到主线程
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([NSThread isMainThread]) {
                NSLog(@"It is main thread");
                NSString *strStatusTmp = @"";
                
                if ([_strPortStatus length] > 0) {
                    strStatusTmp = [NSString stringWithFormat:@"Open %@ error !!! Please reopen the App !!!",  _strPortStatus];
                    [_statusTextView setTextColor:[NSColor redColor]];
                    //        [self showAlertViewWarning:[NSString stringWithFormat:@"Open %@ failed!", strStatus]];
                } else {
                    strStatusTmp = @"Open SerialPort, FIXTURE succeed!!!";
                    [_statusTextView setTextColor:[NSColor blueColor]];
                }
                
                [_statusTextView setStringValue:strStatusTmp];
                
                // setBackgroundColor
                if(_bAuditMode) {
                    [self.window setBackgroundColor:[NSColor colorWithCalibratedRed:((float)255.0/255.0) green:((float)0.0/255.0) blue:((float)255.0/255.0) alpha:1.0]];
                } else {
                    if([_reachNetwork isReachable]) {
                        [self.window setBackgroundColor:[NSColor controlColor]];
                    }
                    else {
                        [self.window setBackgroundColor:[NSColor redColor]];
                    }
                }
            }
        });
        
        //dispatch_release(queue);
    });
    
}
#if DUT_TEST == 1
- (BOOL)initDUTDevice:(int)index
{
    BOOL bRet = NO;
    
    if ([_arrMatchFixtureAndModem count] > index) {
        if ([_arrCommDUT[index] isOpen]) {
            [_arrCommDUT[index] close];
            [NSThread sleepForTimeInterval:1.0f];
            //            _arrCommDUT[index] = nil;
        }
        
        ORSSerialPort *tmp = [ORSSerialPort serialPortWithPath:[_arrMatchFixtureAndModem[index] objectForKey:@"DUTPort"]/*_arrayDUTs[index]*/];
        if (tmp == nil)
        {
            if ([_strPortStatus length] > 0)
            {
                _strPortStatus = [_strPortStatus stringByAppendingString:@","];
            }
            _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" SerialPort %d ", index+1]];
            dispatch_async(dispatch_get_main_queue(), ^{
                //                [_arrSNView[index].editInputFSN setEnabled:NO];
            });
            
        }
        else
        {
            tmp.allowsNonStandardBaudRates = YES;
            tmp.baudRate = @115200;
            tmp.delegate = self;
            [tmp open];
            _arrCommDUT[index] = tmp;
            if(![_arrCommDUT[index] isOpen])
            {
                if (_strPortStatus > 0) {
                    _strPortStatus = [_strPortStatus stringByAppendingString:@","];
                }
                _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" SerialPort %d ", index+1]];
                //                [_arrSNView[index].editInputFSN setEnabled:NO];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                //                if (!_bTesting[index]) {
                //                    [_arrSNView[index].editInputFSN setEnabled:YES];
                //                }
            });
            bRet = YES;
        }
    }
    
    return bRet;
}
#endif

#if FIXTURE_TEST == 1
- (BOOL)initFIXTUREDevice:(int)index
{
    BOOL bRet = NO;
    
    if ([_arrMatchFixtureAndModem count] > index) {
//        if ([_arrCommFIXTURE count] > index)
        {
            if ([_arrCommFIXTURE[index] isOpen]) {
                [_arrCommFIXTURE[index] close];
                //            _arrCommDUT[index] = nil;
                [NSThread sleepForTimeInterval:1.0f];
            }
        }
        
        ORSSerialPort *tmp = [ORSSerialPort serialPortWithPath:[_arrMatchFixtureAndModem[index] objectForKey:@"FixturePort"]/*_arrayFIXTUREs[index]*/];
        if (tmp == nil)
        {
            if ([_strPortStatus length] > 0)
            {
                _strPortStatus = [_strPortStatus stringByAppendingString:@","];
            }
            _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" FIXTURE %d ", index+1]];
        }
        else
        {
            tmp.allowsNonStandardBaudRates = YES;
            tmp.baudRate = @115200;
            tmp.delegate = self;
            [tmp open];
            _arrCommFIXTURE[index] = tmp;
            if(![_arrCommFIXTURE[index] isOpen])
            {
                if (_strPortStatus > 0) {
                    _strPortStatus = [_strPortStatus stringByAppendingString:@","];
                }
                _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" SerialPort %d ", index+1]];
            }
            bRet = YES;
        }
    }
    
    return bRet;
}
#endif

#if (INST_TEST == 1) && (NI_VISA == 1)
- (BOOL)initInstDevice:(int)index
{
    BOOL bRet = NO;
    
    if ([_arrayInsts count] > index) {
        if ([_arrCommInst count] > index) {
            if ([_arrCommInst[index] isOpen]) {
                [_arrCommInst[index] close];
                //            _arrCommDUT[index] = nil;
            }
        }
        
        _arrCommInst[index] = [[visaGeneral alloc] init];
        
        if (![_arrCommInst[index] open:_arrayInsts[index]]) {
            if ([_strPortStatus length] > 0) {
                _strPortStatus = [_strPortStatus stringByAppendingString:@","];
            }
            _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" Instrument %d ", index+1]];
        } else {
            bRet = YES;
        }
    } else {
        if ([_strPortStatus length] > 0) {
            _strPortStatus = [_strPortStatus stringByAppendingString:@","];
        }
        _strPortStatus = [_strPortStatus stringByAppendingString:[NSString stringWithFormat:@" Instrument %d ", index+1]];
    }
    
    return bRet;
}
#endif

- (void)initAllControllers
{
    [self initTitleView];
//    [self initStatisticsView];
    [self initTabViewController];
    [self initSegmentedController];
    [self initStatusView];
    
    [self initSNView];
    
#if INSTANT_PUDDING == 1
    [self initCheckPuddingButton];
    [self initAuditModeButton];
#endif
}

- (void)initTestConfigFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TestConfig" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    _swName = [dict objectForKey:@"SW_Name"];
    _swVersion = [dict objectForKey:@"SW_Version"];
    _strProduct = [dict objectForKey:@"Product"];
    _strFactory = [dict objectForKey:@"Factory"];
#if DUT_TEST == 1
    //_arrayDUTs = [dict objectForKey:@"DUTPorts"];
#endif
#if FIXTURE_TEST == 1
    _arrayFIXTUREs = [dict objectForKey:@"FIXTUREPorts"];
#endif
#if (INST_TEST == 1) && (NI_VISA == 1)
    _arrayInsts = [dict objectForKey:@"InstPorts"];
#endif
    _arrayCheckX2BCB = [dict objectForKey:@"CheckX2BCB"];
    _arrayCheckX2ACB = [dict objectForKey:@"CheckX2ACB"];
#if INSTANT_PUDDING == 1
    _bPudding = [[dict objectForKey:@"Pudding"] boolValue];
    _bAuditMode = [[dict objectForKey:@"Audit"] boolValue];
#endif
    
    _strSpamPID = [dict objectForKey:@"SpamPID"];
    _strChargingCablePID = [dict objectForKey:@"ChargingCablePID"];

}

- (void)initTestScriptFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TestScript" ofType:@"plist"];
    
#if DES_MODE == 1
    NSString *strContent = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
    if ([strContent length] == 0) {
        return;
    }
    
    NSString *desStr = [DES decryptString:strContent];
    if ([desStr length] == 0) {
        return;
    }
    
    NSData *desData = [desStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *error;
    NSPropertyListFormat format;
    
    _infoData = [NSPropertyListSerialization propertyListFromData:desData
                                                 mutabilityOption:NSPropertyListImmutable
                                                           format:&format
                                                 errorDescription:&error];
#elif DES_MODE == 0
    _infoData = [NSArray arrayWithContentsOfFile:path];
#endif

    for (int j = 0; j < MULTIPLE_NUMBERS; j++) {
        int index = 1;
        
        for (int i = 0; i < [_infoData count]; i++) {
            NSMutableDictionary *comdict = [[NSMutableDictionary alloc] initWithCapacity:10];
            
            NSString *strHideOrShow = [[_infoData objectAtIndex:i] objectForKey:@"HideOrShow"];
            [comdict setObject:strHideOrShow  forKey:@"HideOrShow"];
            
            if ([strHideOrShow isEqualToString:@"show"]) {
                NSString *strID = [NSString stringWithFormat:@"%d", index];
                [comdict setObject:strID  forKey:@"ID"];
                
                NSString *strTestItem = [[_infoData objectAtIndex:i] objectForKey:@"TestItem"];
                [comdict setObject:strTestItem  forKey:@"TestItem"];
                
                NSString *strTestLower = [[_infoData objectAtIndex:i] objectForKey:@"Lower"];
                [comdict setObject:strTestLower  forKey:@"Lower"];
                
                NSString *strTestUpper = [[_infoData objectAtIndex:i] objectForKey:@"Upper"];
                [comdict setObject:strTestUpper  forKey:@"Upper"];
                
                NSString *strTestUnit = [[_infoData objectAtIndex:i] objectForKey:@"Unit"];
                [comdict setObject:strTestUnit  forKey:@"Unit"];
                
                [comdict setObject:[NSNumber numberWithBool:NO] forKey:@"Status"];
                
                NSString *strPDCAName = [[_infoData objectAtIndex:i] objectForKey:@"PDCA"];
                [comdict setObject:strPDCAName  forKey:@"PDCA"];
                
                NSString *strPDCAType = [[_infoData objectAtIndex:i] objectForKey:@"PDCA_TYPE"];
                [comdict setObject:strPDCAType  forKey:@"PDCA_TYPE"];
                
                NSString *strAttributeName = [[_infoData objectAtIndex:i] objectForKey:@"AttributeName"];
                if ([strAttributeName length] > 0) {
                    [comdict setObject:strAttributeName  forKey:@"AttributeName"];
                }
                
                [_arrCommandData[j] addObject:comdict];
                
                index++;
            }
        }
    }
}

- (void)initTitleView
{
    NSRect titleFrame = NSMakeRect(TITLEVIEW_X, TITLEVIEW_Y, TITLEVIEW_WIDTH, TITLEVIEW_HEIGHT);
    _titleView = [[TitleView alloc] initWithFrame:titleFrame];
    [self addSubview:_titleView];
}

- (void)initStatisticsView
{
    NSRect statisticsFrame = NSMakeRect(TITLEVIEW_X, TITLEVIEW_Y + TITLEVIEW_HEIGHT - 10, TITLEVIEW_WIDTH, 70);
    _statisticsView = [[StatisticsView alloc] initWithFrame:statisticsFrame];
    [self addSubview:_statisticsView];
}

- (void)initTabViewController
{
    //设置tableView的Frame
    NSRect tabViewFrame = NSMakeRect(TABVIEW_X, TABVIEW_Y, TABVIEW_WIDTH, TABVIEW_HEIGHT);
    
    _tabViewController = [[TabViewController alloc] initWithFrame:tabViewFrame];
    int index = 0;
    for (TableViewController *tableViewController in _tabViewController.arrTableView)
    {
        tableViewController.listData = _arrCommandData[index];//[[NSMutableArray alloc] initWithArray:_arrCommandData[index] copyItems:YES];
        index++;
    }
    [self addSubview:_tabViewController];
}

- (void)initSegmentedController
{
    //设置seg的Frame
//    NSRect segFrame = NSMakeRect((TABVIEW_WIDTH - 200)/2 + 20, SCREEN_HEIGHT - 76, 240, 40);
    NSRect segFrame = NSMakeRect(SEGMENTEDCONTROL_X, SEGMENTEDCONTROL_Y, SEGMENTEDCONTROL_WIDTH, SEGMENTEDCONTROL_HEIGHT);
    
    _segmentedController = [[NSSegmentedControl alloc] initWithFrame:segFrame];
    [_segmentedController setSegmentStyle:NSSegmentStyleTexturedSquare];
    [_segmentedController setSegmentCount:3];
    [_segmentedController setLabel:@"Function" forSegment:0];
    [_segmentedController setLabel:@"Log" forSegment:1];
    [_segmentedController setLabel:@"Settings" forSegment:2];
    [_segmentedController setFont:[NSFont systemFontOfSize:15.0]];
    [_segmentedController setSelectedSegment:0];
    //    [[_segmentedController cell] setTag:201 forSegment:0];
    //    [[_segmentedController cell] setTag:202 forSegment:1];
    [_segmentedController setTarget:self];
    [_segmentedController setAction:@selector(segControlClicked:)];
    [_segmentedController setBounds:segFrame];
    [self addSubview:_segmentedController];
    //[_segmentedController release];
}

- (void)initStatusView
{
    NSRect statusFrame = NSMakeRect(FIXTURESTATUSVIEW_X, FIXTURESTATUSVIEW_Y, FIXTURESTATUSVIEW_WIDTH, FIXTURESTATUSVIEW_HEIGHT);
    _statusTextView = [[NSTextField alloc] initWithFrame:statusFrame];
    [_statusTextView setBackgroundColor:[NSColor controlHighlightColor]];
    [_statusTextView setFont:[NSFont systemFontOfSize:14.0]];
    [_statusTextView setEditable:NO];
    [self addSubview:_statusTextView];
}

- (void)initSNView
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        NSRect frame = NSMakeRect(15+SNVIEW_X+i*SNVIEW_WIDTH, SNVIEW_Y, SNVIEW_WIDTH, SNVIEW_HEIGHT);
//        NSRect frame = NSMakeRect(35+i*SNVIEW_WIDTH, SNVIEW_Y, SNVIEW_WIDTH, SNVIEW_HEIGHT);
        _arrSNView[i] = [[SNView alloc] initWithFrame:frame index:i];

        [self addSubview:_arrSNView[i]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInputSN:)
                                                     name:MESSAGE_INPUTSN
                                                   object:_arrSNView[i]];
    }
    
    //焦点落在输入框内
    //[_arrSNView[0].editInputFSN selectText:_arrSNView[0].editInputFSN];
}

#if INSTANT_PUDDING == 1
- (void)initCheckPuddingButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(20, SCREEN_HEIGHT - 66, 120, 26);
    
    //创建一个设置按钮
    _scPudding = [[NSButton alloc]initWithFrame:btnFrame];
    [_scPudding setButtonType:NSSwitchButton];
    [_scPudding setTitle:@"Pudding"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_scPudding setFont:[NSFont systemFontOfSize:14.0]];
    [_scPudding setTarget:self];
    [self addSubview:_scPudding];
    [_scPudding setEnabled:NO];
    //    [btn release];
}

//- (void)initCheckProcessButton
//{
//    //设置button的Frame
//    NSRect btnFrame = NSMakeRect(SNVIEW_X, SNVIEW_Y + 160, 120, 26);
//    
//    //创建一个设置按钮
//    _scCheckProcess = [[NSButton alloc]initWithFrame:btnFrame];
//    [_scCheckProcess setButtonType:NSSwitchButton];
//    [_scCheckProcess setTitle:@"CheckProcess"];
//    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
//    [_scCheckProcess setFont:[NSFont systemFontOfSize:14.0]];
//    [_scCheckProcess setTarget:self];
//    [self addSubview:_scCheckProcess];
//    [_scCheckProcess setEnabled:NO];
//    //    [btn release];
//}

- (void)initAuditModeButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(200, SCREEN_HEIGHT - 66, 120, 26);
    
    //创建一个设置按钮
    _scAuditMode = [[NSButton alloc]initWithFrame:btnFrame];
    [_scAuditMode setButtonType:NSSwitchButton];
    [_scAuditMode setTitle:@"AuditMode"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_scAuditMode setFont:[NSFont systemFontOfSize:14.0]];
    [_scAuditMode setTarget:self];
    [self addSubview:_scAuditMode];
    [_scAuditMode setEnabled:NO];
    //    [btn release];
}
#endif

- (void)initDefaultStatus
{
#if INSTANT_PUDDING == 1
    [_scPudding setState:_bPudding];
    [_scAuditMode setState:_bAuditMode];
#endif
}

#pragma mark -
#pragma mark target action

- (void)segControlClicked:(id)sender
{
    int clickedSegment = (int)[sender selectedSegment];
    
    switch (clickedSegment) {
        case 0:
            [_tabViewController.tableViews setHidden:NO];
            [_tabViewController.messageViews setHidden:YES];
            [_tabViewController.settingsViews setHidden:YES];
            break;
        case 1:
            [_tabViewController.tableViews setHidden:YES];
            [_tabViewController.messageViews setHidden:NO];
            [_tabViewController.settingsViews setHidden:YES];
            break;
//        case 2:
//        {
//            //input password
//            InputPasswordWindow *inputPassword;
//            inputPassword = [[InputPasswordWindow alloc] initWithWindowNibName:@"InputPasswordWindow"];
//            [inputPassword.window center];
//            [NSApp runModalForWindow:[inputPassword window]];
//            
//            if (inputPassword.fConfirm) {
//                [_tabViewController.tableViews setHidden:YES];
//                [_tabViewController.messageViews setHidden:YES];
//                [_tabViewController.settingsViews setHidden:NO];
//            } else {
//                [_segmentedController setSelectedSegment:0];
//            }
//        }
            break;
            
        default:
            break;
    }
}

#pragma mark --
- (void)handleInputSN:(NSNotification*)notification
{
    @autoreleasepool {
        if([[notification name] isEqualToString:MESSAGE_INPUTSN]) {
            SNView *snViewTmp = (SNView *)notification.object;
            int index = 0;
            
            for (SNView *tmp in _arrSNView) {
                if (tmp == snViewTmp) {
                    break;
                }
                index++;
            }
            
            [self startTestWithIndex:index];
        }
    }
}

- (void)handleSaveSetting:(NSNotification*)notification
{
    @autoreleasepool {
        if([[notification name] isEqualToString:MESSAGE_SAVESETTING]) {
            //重新加载设置
            [self initTestConfigFile];
            [self initAllDevices];
            [self initDefaultStatus];
            
            // setBackgroundColor
            if(_bAuditMode) {
                [self.window setBackgroundColor:[NSColor colorWithCalibratedRed:((float)255.0/255.0) green:((float)0.0/255.0) blue:((float)255.0/255.0) alpha:1.0]];
            } else {
                if([_reachNetwork isReachable]) {
                    [self.window setBackgroundColor:[NSColor controlColor]];
                }
                else {
                    [self.window setBackgroundColor:[NSColor redColor]];
                }
            }
        }
    }
}

- (void)startTestWithIndex:(int)index
{
    _bTesting[index] = YES;
    _arrSN[index] = [_arrSNView[index].editFSN stringValue];
    //_arrSN[index] = [_arrSNView[index].editInputFSN stringValue];
    //[_arrSNView[index].editInputFSN setEnabled:NO];
    //[_arrSNView[index].editFSN setStringValue:@""];
    _arrStartTime[index] = [self getCurrentTime];
    [_arrSNView[index] setRuntime:YES];
    //            _commFIXTURE1.bWaitingSignal = NO;
    
    
    [self setStatusEditWithIndex:index withState:1];
    [self clearOutputDataWithIndex:index];
    
    //jason add
    //[self initFIXTUREDevice:index];
    
    BOOL bExit = NO;
    for (int i = index; i <= MULTIPLE_NUMBERS; i++) {
        if (i == MULTIPLE_NUMBERS) {
            i = 0;
            for (int j = 0; j < MULTIPLE_NUMBERS; j++) {
                if ([_arrSNView[j].editInputFSN isEnabled]) {
                    [_arrSNView[j].editInputFSN selectText:_arrSNView[i].editInputFSN];
                    break;
                }
            }
            bExit = YES;
        }
        
        if ([_arrSNView[i].editInputFSN isEnabled] || bExit) {
            [_arrSNView[i].editInputFSN selectText:_arrSNView[i].editInputFSN];
            break;
        }
    }
    
    dispatch_queue_t queue = dispatch_queue_create("Perform Commands", nil);
    dispatch_async(queue, ^{
        [self getChargeValue:(int)index];
        [self performCommandsWithIndex:index];
        
        //回到主线程
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([NSThread isMainThread]) {
                [self createCSVFileWithIndex:index];
                [self createCSVFileInOneWithIndex:index];
                [self createLogFileWithIndex:index];
                
                [self stopTestWithIndex:index];
            }
        });
    });
}

- (void)stopTestWithIndex:(int)index
{
    BOOL bTestResult = NO;
    
    _bTesting[index] = NO;
    bTestResult = _bTestResult[index];
    [_arrSNView[index] setRuntime:NO];
    [_arrSNView[index].editFSN setStringValue:_arrSN[index]];
    [_arrSNView[index].editInputFSN setStringValue:@""];
    [_arrSNView[index].editInputFSN setEnabled:YES];
    
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        if ([_arrSNView[i].editInputFSN isEnabled]) {
            [_arrSNView[i].editInputFSN selectText:_arrSNView[i].editInputFSN];
            break;
        }
    }
    
    _arrStopTime[index] = [self getCurrentTime];
    
    if (bTestResult)
    {
        [self setStatusEditWithIndex:index withState:2]; //PASS
        _statisticsView.passCount++;
        [_statisticsView reflashStatistics];
    }
    else
    {
        [self setStatusEditWithIndex:index withState:3]; //FAIL
        _statisticsView.failCount++;
        [_statisticsView reflashStatistics];
    }
    
#if INSTANT_PUDDING == 1
    //上传PDCA
    if (_bPudding) {
        [self uploadToPDCAWithIndex:index];
    }
    
    //释放
//    if (_bPudding)
//        [_arrPDCA[index] UUTRelease];
#endif
}

- (void)setStatusEditWithIndex:(int)index withState:(int)iState
{
    [_arrSNView[index] setTestState:iState];
}

- (void)clearOutputDataWithIndex:(int)index
{
    TableViewController *tableViewTmp = nil;
    NSTextView *textEditTmp = nil;
    
    tableViewTmp = _tabViewController.arrTableView[index];
    textEditTmp = _tabViewController.arrMessageView[index].textEdit;
    
    for (int i = 0; i < [_tabViewController.arrTableView[index].listData count]; i++) {
        NSDictionary *item =[_tabViewController.arrTableView[index].listData objectAtIndex:i];
        NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
        //        [newItem removeObjectForKey:@"TestValue"];
        [newItem removeObjectForKey:@"TestResult"];
        [newItem setObject:[NSNumber numberWithBool:NO] forKey:@"Status"];
        [_tabViewController.arrTableView[index].listData setObject:newItem atIndexedSubscript:i];
    }
    
    [tableViewTmp.listView reloadData];
    [tableViewTmp setNeedsDisplay:YES];
    [[[textEditTmp textStorage] mutableString] setString:@""];
}

//david add

- (void)getChargeValue:(int)index
{
    NSString *result = nil ;
    NSString *strEnd = @":-)";
    NSString *strStart = @"dev -k gasgauge -p";
    float fTimeOut = 10.0;
    BOOL bRead1 = NO;
//    NSString *strResSpec = @"";
//    int indexFixture = 0;
    
    ORSSerialPort *commTmp = _arrCommFIXTURE[index];
    if (![commTmp isOpen])
    {
        [self initFIXTUREDevice:index];
    }
        [NSThread sleepForTimeInterval:0.3f];
        [self write:@"dev -k gasgauge -p" SerialPort:commTmp];
        //[NSThread sleepForTimeInterval:0.3f];
        
        bRead1 = [self read:&result From:strStart To:strEnd Timeout:fTimeOut SerialPort:commTmp];
        
        //bRead = [self read:&result From:@"dev -k gasgauge -p" To:@":-)" Timeout:10 SerialPort:commTmp];

        if (bRead1) {
            NSString *strTemp = [self getData:result startSet:@"charge-percentage: \"" endSet:@"\""];
            //NSTextField *textCharge = (NSTextField*)[self._arrSNView[index].label];
            
            if ([strTemp intValue] > 30) {
                [_arrSNView[index].label setTextColor:[NSColor blackColor]];
            } else {
                [_arrSNView[index].label setTextColor:[NSColor redColor]];
            }
            
            [_arrSNView[index].label setStringValue:[NSString stringWithFormat:@"charge-percentage: %@", strTemp]];
        }
}
- (void)performCommandsWithIndex:(int)indexFixture
{
    @autoreleasepool {
        int index = 0;
        int i = 0;
        
        id performTmp = nil;
        _bInitPudding[indexFixture] = NO;
        BOOL bReturnStatus = NO; //是否跳出循环
        
        _bFailedAtLeastOneTest[indexFixture] = NO;
        
        for (; i < [_infoData count]; i++) {
            NSString *strTestItem = [[_infoData objectAtIndex:i] objectForKey:@"TestItem"];
            NSString *typePort = [[_infoData objectAtIndex:i] objectForKey:@"Device"];
            
            NSString *strCommand = [[_infoData objectAtIndex:i] objectForKey:@"Command"];
            BOOL bNeedLoop = NO;
            if ([strCommand length] > 0 ) {
                //如果指令NG，需要整个loop，则定义loop Flag
                if ([strCommand rangeOfString:@"loop"].length > 0) {
                    bNeedLoop = YES;
                }
                strCommand = [self getData:strCommand startSet:@"{" endSet:@"}"];
            }

            NSString *strParam = [[_infoData objectAtIndex:i] objectForKey:@"Param"];
            NSString *strLower = [[_infoData objectAtIndex:i] objectForKey:@"Lower"];
            NSString *strUpper = [[_infoData objectAtIndex:i] objectForKey:@"Upper"];
            NSString *strUnit = [[_infoData objectAtIndex:i] objectForKey:@"Unit"];
            NSString *strResultShowType = [[_infoData objectAtIndex:i] objectForKey:@"ResultShowType"];
            NSString *strResType = [[_infoData objectAtIndex:i] objectForKey:@"ResultType"];
            NSString *strInterceptMethod = [[_infoData objectAtIndex:i] objectForKey:@"InterceptMethod"];
            
            NSString *strResSpec = [[_infoData objectAtIndex:i] objectForKey:@"ResultSpec"];
            if ([strResSpec length] > 0) {
                strResSpec = [self getData:strResSpec startSet:@"{" endSet:@"}"];
            }
            
            NSString *strFromString = [[_infoData objectAtIndex:i] objectForKey:@"FromString"];
            if ([strFromString length] > 0) {
                strFromString = [self getData:strFromString startSet:@"{" endSet:@"}"];
            }

            NSString *strToString = [[_infoData objectAtIndex:i] objectForKey:@"ToString"];
            if ([strToString length] > 0) {
                strToString = [self getData:strToString startSet:@"{" endSet:@"}"];
            }
            
            NSString *strFromIndex = [[_infoData objectAtIndex:i] objectForKey:@"FromIndex"];
            if ([strFromIndex length] > 0) {
                strFromIndex = [self getData:strFromIndex startSet:@"{" endSet:@"}"];
            }
            
            NSString *strToIndex= [[_infoData objectAtIndex:i] objectForKey:@"ToIndex"];
            if ([strToIndex length] > 0) {
                strToIndex = [self getData:strToIndex startSet:@"{" endSet:@"}"];
            }
            
            NSString *strHideOrShow = [[_infoData objectAtIndex:i] objectForKey:@"HideOrShow"];
            BOOL bBreakOut = [[[_infoData objectAtIndex:i] objectForKey:@"BreakOut"] boolValue];
            float fTimeOut = [[[_infoData objectAtIndex:i] objectForKey:@"TimeOut"] floatValue];
            int iInRetryTimes = [[[_infoData objectAtIndex:i] objectForKey:@"RetryTimes"] intValue];
            int iOutRetryTimes = [[[_infoData objectAtIndex:i] objectForKey:@"RetryTimes"] intValue];
            float fRetrySleep = [[[_infoData objectAtIndex:i] objectForKey:@"RetrySleep"] floatValue];
            BOOL bSkip = [[[_infoData objectAtIndex:i] objectForKey:@"Skip"] boolValue];
            
            bReturnStatus = NO;
            
            if ([strTestItem isEqualToString:@"Initial Bauxite status check"]) {
                NSLog(@"====");
            }
            
            //skip
            if (bSkip) {
                [self executeCommandDataWithIndex:index WithResult:@"Skip" WithStatus:YES withIndexFixture:indexFixture];
                [NSThread sleepForTimeInterval:0.1f];
                
                if ([strHideOrShow isEqualToString:@"show"]) {
                    [self NeedToReflashTableViewSelect:index withIndex:indexFixture];
                    index++;
                }
                
                continue;
            }
            
            if ([typePort isEqualToString:@"SELF"]) {
                if ([strParam isEqualToString:@"Write"]) {
                    NSArray *arrCommand = [strCommand componentsSeparatedByString:@";"];
                    
                    //loop双重循环嵌套
                    do {
                        for (NSString *strTmpCmd in arrCommand) {
                            do {
                                if ([strTmpCmd length] > 0) {
                                    NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Write command:\n%@", [self getCurrentTime], strTmpCmd];
                                    [self outputMessageTextView:strNewLine withIndex:indexFixture];
                                }
                                
                                //自定义指令处理：Wait等
                                if ([strTmpCmd rangeOfString:@"wait:"].length > 0) {
                                    float waitTime = [[self getData:strCommand startSet:@":" endSet:@"s"] floatValue];
                                    [NSThread sleepForTimeInterval:waitTime];
                                    bReturnStatus = YES;
                                    break;
                                } else if ([strCommand rangeOfString:@"breakpoint"].length > 0) {
                                    [_tabViewController.arrTableView[indexFixture] showAlertView:strTestItem];
                                    if ([strCommand rangeOfString:@"auto"].length > 0) {
                                        NSString *strDutCmd = [self getData:strCommand startSet:@"(" endSet:@","];
                                        NSString *strDutSpec = [self getData:strCommand startSet:@"," endSet:@")"];
                                        
                                        NSMutableDictionary *notify = [[NSMutableDictionary alloc] initWithCapacity:2];
                                        [notify setObject:strDutCmd forKey:@"Command"];
                                        [notify setObject:strDutSpec forKey:@"Spec"];
                                        [notify setObject:[NSString stringWithFormat:@"%f", fTimeOut] forKey:@"TimeOut"];
                                        [notify setObject:[NSString stringWithFormat:@"%d", indexFixture] forKey:@"Index"];
                                        
                                        [self performSelectorInBackground:@selector(getAutoAlertViewResult:) withObject:notify];
                                    }
                                    
                                    while (YES) {
                                        if (!_tabViewController.arrTableView[indexFixture].alertView.bAlert) {
                                            break;
                                        }
                                    }
                                    
                                    if (!_tabViewController.arrTableView[indexFixture].alertView.bAlert) {
                                        bReturnStatus = YES;
                                    }
                                } else if ([strCommand rangeOfString:@"openDutPort"].length > 0) {
//                                    bReturnStatus = [self initDUTDevice:indexFixture];
                                    bReturnStatus = [self OpenModemPort:indexFixture];
                                } else if ([strCommand rangeOfString:@"closeDutPort"].length > 0) {
                                    bReturnStatus = [self closeDutPort:indexFixture];
                                } else if ([strCommand rangeOfString:@"finishWorkHandler"].length > 0) {
                                    bReturnStatus = YES;
                                }
                                
                                //如果成功后直接跳出
                                if (bReturnStatus) {
                                    break;
                                }
                                
                                [NSThread sleepForTimeInterval:fRetrySleep];
                                iInRetryTimes--;
                            } while (iInRetryTimes >= 0);
                            
                            if (!bReturnStatus) {
                                if (bNeedLoop) {
                                    //Retry次数重置
                                    iInRetryTimes = [[[_infoData objectAtIndex:i] objectForKey:@"RetryTimes"] intValue];
                                }
                                //Retry多次后仍NG，跳出for循环
                                break;
                            }
                        }
                        
                        //如果成功后直接跳出
                        if (bReturnStatus) {
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:fRetrySleep];
                        iOutRetryTimes--;
                    } while ((iOutRetryTimes >= 0) && (iInRetryTimes >= 0));

                    //针对hide项，如果NG了，那么下一show项判定NG。
                    if (_bFailedAtLeastOneTest[indexFixture] && !bBreakOut) {
                        bReturnStatus = NO;
                    }
                    
                    if (!bReturnStatus)
                        _bFailedAtLeastOneTest[indexFixture] = YES;
                    
                    if (bReturnStatus)
                        [self executeCommandDataWithIndex:index WithResult:@"OK" WithStatus:YES withIndexFixture:indexFixture];
                    else
                        [self executeCommandDataWithIndex:index WithResult:@"NG" WithStatus:NO withIndexFixture:indexFixture];
                } else if ([strParam isEqualToString:@"Read"]) {
                    //保留
                    NSLog(@"_strTotalResBuffer1 = %@", _arrTotalResBuffer[indexFixture]);
                    
                    NSString *strResult = nil;
                    
                    if ([_arrTotalResBuffer[indexFixture] length] > 0) {
                        //待处理
                        //判断是按字符串截取，还是索引截取,如果是索引截取需加处理
                        if ([strInterceptMethod isEqualToString:@"index"]) {
                            int iLengthTmp = [strToIndex intValue] - [strFromIndex intValue];
                            strResult = [self getData:_arrTotalResBuffer[indexFixture] startIndex:[strFromIndex intValue] iLength:iLengthTmp];
                        } else if ([strInterceptMethod isEqualToString:@"string"]) {
                            strResult = [[self getData:_arrTotalResBuffer[indexFixture] startSet:strFromString endSet:strToString] uppercaseString];
                        }
                        
                        if ([strResType isEqualToString:@"value"]) {
                            strResult = [NSString stringWithFormat:@"%d", [strResult intValue]];
                            bReturnStatus = [self compareValue:strResult withMax:strUpper andMin:strLower];
                        } else if ([strResType isEqualToString:@"string"]) {
                            if ([strResSpec length] > 0) {
                                //针对“!”，"&&","||"需做特殊处理
                                if ([strResSpec rangeOfString:@"!"].length > 0) {
                                    NSString *strTmpRet = [strResSpec stringByReplacingOccurrencesOfString:@"!" withString:@""];
                                    
                                    if ([strTmpRet rangeOfString:@"("].length > 0) {
                                        strTmpRet = [strTmpRet stringByReplacingOccurrencesOfString:@"(" withString:@""];
                                        strTmpRet = [strTmpRet stringByReplacingOccurrencesOfString:@")" withString:@""];
                                        
                                        NSArray *arraySpec = [strTmpRet componentsSeparatedByString:@"||"];
                                        
                                        for (NSString *strTmp in arraySpec) {
                                            if ([strResult rangeOfString:strTmp].length == 0) {
                                                bReturnStatus = YES;
                                            }
                                        }
                                    } else {
                                        if ([strResult rangeOfString:strTmpRet].length == 0) {
                                            //如果不包含则返回YES
                                            bReturnStatus = YES;
                                        }
                                    }
                                } else if ([strResSpec rangeOfString:@"&&"].length > 0) {
                                    NSArray *arraySpec = [strResSpec componentsSeparatedByString:@"&&"];
                                    
                                    BOOL bArrayStatus = YES;
                                    for (NSString *strTmp in arraySpec) {
                                        if ([strResult rangeOfString:strTmp].length == 0) {
                                            bArrayStatus = NO;
                                            break;
                                        }
                                    }
                                    
                                    if (bArrayStatus) {
                                        bReturnStatus = YES;
                                    } else {
                                        bReturnStatus = NO;
                                    }
                                    
                                } else if ([strResSpec rangeOfString:@"||"].length > 0) {
                                    NSArray *arraySpec = [strResSpec componentsSeparatedByString:@"||"];
                                    
                                    for (NSString *strTmp in arraySpec) {
                                        if ([strResult rangeOfString:strTmp].length > 0) {
                                            bReturnStatus = YES;
                                        }
                                    }
                                } else {
                                    if ([strResult rangeOfString:strResSpec].length > 0 ||
                                        [strResSpec rangeOfString:strResult].length > 0) {
                                        bReturnStatus = YES;
                                    }
                                }
                            } else {
                                if ([strResult length] > 0) {
                                    bReturnStatus = YES;
                                } else {
                                    bReturnStatus = NO;
                                }
                            }
                            
//                            if ([strResSpec length] > 0) {
//                                if ([strResult rangeOfString:strResSpec].length > 0)
//                                    bReturnStatus = YES;
//                            } else {
//                                bReturnStatus = YES;
//                            }
                        }
                    }
                    
                    //针对hide项，如果NG了，那么下一show项判定NG。
                    if (_bFailedAtLeastOneTest[indexFixture] && !bBreakOut) {
                        bReturnStatus = NO;
                    }
                    
                    if (!bReturnStatus)
                        _bFailedAtLeastOneTest[indexFixture] = YES;
                    
                    [self executeTestResult:strResult withType:strResultShowType withCol:index withStatus:bReturnStatus withIndexFixture:indexFixture];
                } else if ([strParam isEqualToString:@"WriteAndRead"]) {
                    NSArray *arrCommand = [strCommand componentsSeparatedByString:@";"];
                    NSString *strResult = nil;
                    
                    //loop双重循环嵌套
                    do {
                        for (NSString *strTmpCmd in arrCommand) {
                            do {
                                if ([strTmpCmd length] > 0) {
                                    NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Write command:\n%@", [self getCurrentTime], strTmpCmd];
                                    [self outputMessageTextView:strNewLine withIndex:indexFixture];
                                }
                                
                                //自定义指令处理：Wait等
                                if ([strTmpCmd rangeOfString:@"wait:"].length > 0) {
                                    float waitTime = [[self getData:strCommand startSet:@":" endSet:@"s"] floatValue];
                                    [NSThread sleepForTimeInterval:waitTime];
                                    bReturnStatus = YES;
                                    break;
                                }
                                
                                if ([strTmpCmd rangeOfString:@"CheckPudding"].length > 0) {
                                    if ([_arrSN[indexFixture] length] > 0) {
#if INSTANT_PUDDING == 1
                                        //检查AmiOK

                                        if (_arrPDCA[indexFixture] != nil) {
                                            if (_bPudding) {
                                                //待处理
                                                [_arrPDCA[indexFixture] UUTStartTest];
                                                [_arrPDCA[indexFixture] AddAttribute:@IP_ATTRIBUTE_STATIONSOFTWARENAME AttributeValue:_swName];
                                                [_arrPDCA[indexFixture] AddAttribute:@IP_ATTRIBUTE_STATIONSOFTWAREVERSION AttributeValue:_swVersion];
                                                [_arrPDCA[indexFixture] AddAttribute:@IP_ATTRIBUTE_SERIALNUMBER AttributeValue:_arrSN[indexFixture]];
                                                
                                                if ([self getQuerySFCON]) {
                                                    if(![_arrPDCA[indexFixture] checkBobcat:_arrSN[indexFixture]])
                                                    {
                                                        strResult = _arrPDCA[indexFixture].ErrorInfo;
                                                    }
                                                    else
                                                        bReturnStatus = YES;
                                                } else {
                                                    bReturnStatus = YES;
                                                }
                                                
                                            }
                                        }
#else
                                        bReturnStatus = YES;
#endif
                                    }
                                } else if ([strCommand rangeOfString:@"addAttributeToSFC"].length > 0) {
                                    //自行添加处理上传内容
                                    if ([self getQuerySFCON]) {
                                        
                                        NSString *strParam = [NSString stringWithFormat:@"c=ADD_RECORD&sn=%@&tsid=%@", _arrSN[indexFixture], _strStationID];
                                        NSString *strReturn = [self sendRequestSync:_strSFCUrl withParam:strParam TimeOut:5.0f];
                                        
                                        if ([strReturn length] > 0) {
                                            if ([strReturn rangeOfString:@"SFC_OK"].length > 0) {
                                                bReturnStatus = YES;
                                            }
                                        }
                                    } else {
                                        bReturnStatus = YES;
                                    }
                                }if ([strCommand rangeOfString:@"runDisableBoost"].length > 0) {
                                    NSString *strPythoneFileName = [self getData:strCommand startSet:@"run" endSet:@""];
                                    
                                    strResult =[self startRunShellScript:strPythoneFileName Content:@"cd /vault/tmp\npython ./b237Tool.py " Param:[NSString stringWithFormat:@"-disableBoost -setBoostOff -serialPort %@", [_arrMatchFixtureAndModem[indexFixture] objectForKey:@"DUTPort"]/*_arrayDUTs[indexFixture]*/]withIndex:indexFixture];
                                    //strResult = [self startRunShellScript:strPythoneFileName Content:@"cd /Users/david/Desktop/pingpongTest/tmp1\npython ./b237Tool.py " Param:[NSString stringWithFormat:@"-disableBoost -setBoostOff -serialPort %@", [_arrMatchFixtureAndModem[indexFixture] objectForKey:@"DUTPort"]/*_arrayDUTs[indexFixture]*/]withIndex:indexFixture];
                                    if ([strResSpec length] > 0) {
                                        if ([strResult rangeOfString:strResSpec].length > 0) {
                                            bReturnStatus = YES;
                                        }
                                    } else {
                                        bReturnStatus = YES;
                                    }
                                }
                                    if ([strCommand rangeOfString:@"runSerialIdentify"].length > 0) {
                                    NSString *strPythoneFileName = [self getData:strCommand startSet:@"run" endSet:@""];
                                    
                                    strResult =[self startRunShellScript:strPythoneFileName Content:@"cd /vault/tmp\npython ./b237Tool.py " Param:[NSString stringWithFormat:@"-serial -identify -max_timeout -ilimit 1500 -info -serialPort %@", [_arrMatchFixtureAndModem[indexFixture] objectForKey:@"DUTPort"]/*_arrayDUTs[indexFixture]*/]withIndex:indexFixture];
                                     // strResult = [self startRunShellScript:strPythoneFileName Content:@"cd /Users/david/Desktop/pingpongTest/tmp1\npython ./b237Tool.py " Param:[NSString stringWithFormat:@"-serial -identify -max_timeout -ilimit 1500 -info -serialPort %@", [_arrMatchFixtureAndModem[indexFixture] objectForKey:@"DUTPort"]/*_arrayDUTs[indexFixture]*/]withIndex:indexFixture];
                                    if ([strResSpec length] > 0) {
                                        if ([strResult rangeOfString:strResSpec].length > 0) {
                                            bReturnStatus = YES;
                                        }
                                    } else {
                                        bReturnStatus = YES;
                                    }
                                    }else {
                                        //执行read 处理
                                        NSLog(@"_strTotalResBuffer1 = %@", _arrTotalResBuffer[indexFixture]);
                                        
                                        NSString *strResult = nil;
                                        
                                        if ([_arrTotalResBuffer[indexFixture] length] > 0) {
                                            //待处理
                                            //判断是按字符串截取，还是索引截取,如果是索引截取需加处理
                                            if ([strInterceptMethod isEqualToString:@"index"]) {
                                                int iLengthTmp = [strToIndex intValue] - [strFromIndex intValue];
                                                strResult = [self getData:_arrTotalResBuffer[indexFixture] startIndex:[strFromIndex intValue] iLength:iLengthTmp];
                                            } else if ([strInterceptMethod isEqualToString:@"string"]) {
                                                strResult = [[self getData:_arrTotalResBuffer[indexFixture] startSet:strFromString endSet:strToString] uppercaseString];
                                            }
                                            
                                            if ([strResType isEqualToString:@"value"]) {
                                                strResult = [NSString stringWithFormat:@"%d", [strResult intValue]];
                                                bReturnStatus = [self compareValue:strResult withMax:strUpper andMin:strLower];
                                            } else if ([strResType isEqualToString:@"string"]) {
                                                if ([strResSpec length] > 0) {
                                                    if ([strResult rangeOfString:strResSpec].length > 0)
                                                        bReturnStatus = YES;
                                                    else if([strResSpec rangeOfString:@"|"].length > 0){
                                                            if ([strResSpec rangeOfString:strResult].length > 0)
                                                                bReturnStatus = YES;
                                                    }
                                                }
                                                
                                                else {
                                                    bReturnStatus = YES;
                                                }
                                            }
                                        }
                                        
                                        //针对hide项，如果NG了，那么下一show项判定NG。
                                        if (_bFailedAtLeastOneTest[indexFixture] && !bBreakOut) {
                                            bReturnStatus = NO;
                                        }
                                        
                                        if (!bReturnStatus)
                                            _bFailedAtLeastOneTest[indexFixture] = YES;
                                        
                                        [self executeTestResult:strResult withType:strResultShowType withCol:index withStatus:bReturnStatus withIndexFixture:indexFixture];
                                    }
                                
                                //如果成功后直接跳出
                                if (bReturnStatus) {
                                    break;
                                }
                                
                                [NSThread sleepForTimeInterval:fRetrySleep];
                                iInRetryTimes--;
                            } while (iInRetryTimes >= 0);
                            
                            if (!bReturnStatus) {
                                if (bNeedLoop) {
                                    //Retry次数重置
                                    iInRetryTimes = [[[_infoData objectAtIndex:i] objectForKey:@"RetryTimes"] intValue];
                                }
                                //Retry多次后仍NG，跳出for循环
                                break;
                            }
                        }
                        
                        //如果成功后直接跳出
                        if (bReturnStatus) {
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:fRetrySleep];
                        iOutRetryTimes--;
                    } while ((iOutRetryTimes >= 0) && (iInRetryTimes >= 0));

                    //针对hide项，如果NG了，那么下一show项判定NG。
                    if (_bFailedAtLeastOneTest[indexFixture] && !bBreakOut) {
                        bReturnStatus = NO;
                    }
                    
                    if (!bReturnStatus)
                        _bFailedAtLeastOneTest[indexFixture] = YES;
                    
                    [self executeTestResult:strResult withType:strResultShowType withCol:index withStatus:bReturnStatus withIndexFixture:indexFixture];
                }
            } else {
#if DUT_TEST == 1
                if ([typePort isEqualToString:@"DUT"]) {
                    if ([_arrCommDUT count] > indexFixture) {
                        performTmp = _arrCommDUT[indexFixture];
                    }
                }
#endif
                
#if FIXTURE_TEST == 1
                if ([typePort isEqualToString:@"FIXTURE"]) {
                    if ([_arrCommFIXTURE count] > indexFixture) {
                        performTmp = _arrCommFIXTURE[indexFixture];
                    }
                }
#endif
                
#if (INST_TEST == 1) && (NI_VISA == 1)
                if ([typePort isEqualToString:@"INST"]) {
                    if ([_arrCommInst count] > indexFixture) {
                        performTmp = _arrCommInst[indexFixture];
                    }
                }
#endif
                
#if ((DUT_TEST == 1) || (FIXTURE_TEST == 1)) && ((INST_TEST == 1) && (NI_VISA == 1))
                if ([performTmp isKindOfClass:[ORSSerialPort class]] || [performTmp isKindOfClass:[visaGeneral class]])
#elif ((DUT_TEST == 1) || (FIXTURE_TEST == 1))
                if ([performTmp isKindOfClass:[ORSSerialPort class]])
#elif ((INST_TEST == 1) && (NI_VISA == 1))
                if ([performTmp isKindOfClass:[visaGeneral class]])
#endif
                {
                    if ([performTmp isOpen]) {
                        NSArray *arrCommand = nil;
                        NSArray *arrResSpec = nil;
                        NSArray *arrFromString = nil;
                        NSArray *arrToString = nil;
                        NSArray *arrFromIndex = nil;
                        NSArray *arrToIndex = nil;
                        
                        if ([strCommand length] > 0)
                            arrCommand = [strCommand componentsSeparatedByString:@";"];
                        
                        if ([strResSpec length] > 0)
                            arrResSpec = [strResSpec componentsSeparatedByString:@";"];
                        
                        if ([strFromString length] > 0)
                            arrFromString = [strFromString componentsSeparatedByString:@";"];
                        
                        if ([strToString length] > 0)
                            arrToString = [strToString componentsSeparatedByString:@";"];
                        
                        if ([strFromIndex length] > 0)
                            arrFromIndex = [strFromIndex componentsSeparatedByString:@";"];
                        
                        if ([strToIndex length] > 0)
                            arrToIndex = [strToIndex componentsSeparatedByString:@";"];
                        
                        NSString *strResult = nil;
                        
                        NSMutableString *strResBufferTmp = _arrTotalResBuffer[indexFixture];
                        [strResBufferTmp setString:@""];
                        
                        do {
                            int iCommand = 0;
                            for (NSString *strTmpCmd in arrCommand) {
                                NSString *strTmpResSpec = [arrResSpec objectAtIndex:iCommand];
                                NSString *strTmpFromString = [arrFromString objectAtIndex:iCommand];
                                NSString *strTmpToString = [arrToString objectAtIndex:iCommand];
                                NSString *strTmpFromIndex = [arrFromIndex objectAtIndex:iCommand];
                                NSString *strTmpToIndex = [arrToIndex objectAtIndex:iCommand];
                                
                                do {
                                    if ([strTmpCmd length] > 0) {
                                        NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Write command:\n%@", [self getCurrentTime], strTmpCmd];
                                        [self outputMessageTextView:strNewLine withIndex:indexFixture];
                                    }
                                    
                                    //自定义指令处理：Wait等
                                    if ([strTmpCmd rangeOfString:@"wait:"].length > 0) {
                                        float waitTime = [[self getData:strCommand startSet:@":" endSet:@"s"] floatValue];
                                        [NSThread sleepForTimeInterval:waitTime];
                                        bReturnStatus = YES;
                                        break;
                                    }
                                    
                                    if ([strParam isEqualToString:@"Write"]) {
                                        //                        [performTmp write:strCommand];
                                        bReturnStatus = [self write:strTmpCmd SerialPort:performTmp];
//                                        //david add 5.24
//                                        if ([typePort isEqualToString:@"FIXTURE"]) {
//                                            [NSThread sleepForTimeInterval:0.5f];
//                                        }
                                    } else if ([strParam isEqualToString:@"Read"]) {
                                        //保留
                                        NSLog(@"_strTotalResBuffer1 = %@", _arrTotalResBuffer[indexFixture]);
                                        //char's
                                        bReturnStatus = [self getResultFromDevice:performTmp withResult:&strResult withStartString:strFromIndex withEndString:strToIndex withSpecString:strResSpec withIndexFixture:indexFixture withTimeOut:fTimeOut];
                                    } else if ([strParam isEqualToString:@"WriteAndRead"]) {
                                        [self write:strTmpCmd SerialPort:performTmp];
                                        NSLog(@"写入的指令为:%@",strTmpCmd);
                                        
                                        if ([strResType rangeOfString:@"value"].length > 0) {
                                            if ([self getResultFromDevice:performTmp withResult:&strResult withLower:strLower withUpper:strUpper withUnit:strUnit withStartString:strTmpFromString withEndString:strTmpToString withIndexFixture:indexFixture withTimeOut:fTimeOut]) {
                                                //判断是按字符串截取，还是索引截取,如果是索引截取需加处理
                                                if ([strInterceptMethod isEqualToString:@"index"]) {
                                                    int iLengthTmp = [strTmpToIndex intValue] - [strTmpFromIndex intValue];
                                                    strResult = [self getData:strResult startIndex:[strTmpFromIndex intValue] iLength:iLengthTmp];
                                                }
                                                bReturnStatus = YES;
                                            } else {
                                                bReturnStatus = NO;
                                            }
                                        } else if ([strResType rangeOfString:@"string"].length > 0) {
                                            if ([self getResultFromDevice:performTmp withResult:&strResult withStartString:strTmpFromString withEndString:strTmpToString withSpecString:strTmpResSpec withIndexFixture:indexFixture withTimeOut:fTimeOut]) {
                                                //判断是按字符串截取，还是索引截取,如果是索引截取需加处理
                                                if ([strInterceptMethod isEqualToString:@"index"]) {
                                                    int iLengthTmp = [strTmpToIndex intValue] - [strTmpFromIndex intValue];
                                                    strResult = [self getData:strResult startIndex:[strTmpFromIndex intValue] iLength:iLengthTmp];
                                                }
                                                bReturnStatus = YES;
                                            } else {
                                                bReturnStatus = NO;
                                            }
                                        }
                                    }
                                    //如果成功后直接跳出
                                    if (bReturnStatus) {
                                        break;
                                    }
                                    
                                    [NSThread sleepForTimeInterval:fRetrySleep];
                                    iInRetryTimes--;
                                } while (iInRetryTimes >= 0);
                                
                                iCommand++;
                                
                                if (!bReturnStatus) {
                                    if (bNeedLoop) {
                                        //Retry次数重置
                                        iInRetryTimes = [[[_infoData objectAtIndex:i] objectForKey:@"RetryTimes"] intValue];
                                    }
                                    //Retry多次后仍NG，跳出for循环
                                    break;
                                }
                            }
                            
                            //如果成功后直接跳出
                            if (bReturnStatus) {
                                break;
                            }
                            
                            [NSThread sleepForTimeInterval:fRetrySleep];
                            iOutRetryTimes--;
                        } while ((iOutRetryTimes >= 0) && (iInRetryTimes >= 0));
                        
                        //针对hide项，如果NG了，那么下一show项判定NG。
                        if (_bFailedAtLeastOneTest[indexFixture] && !bBreakOut) {
                            bReturnStatus = NO;
                        }
                        
                        if (!bReturnStatus)
                            _bFailedAtLeastOneTest[indexFixture] = YES;
                        
                        [self executeTestResult:strResult withType:strResultShowType withCol:index withStatus:bReturnStatus withIndexFixture:indexFixture];
                        
                    } else {
                        _bFailedAtLeastOneTest[indexFixture] = YES;
                        
                        [self executeCommandDataWithIndex:index WithResult:@"NG" WithStatus:NO withIndexFixture:indexFixture];
                        
                        [NSThread sleepForTimeInterval:0.1f];
                    }
                }
            }
            
//#if INSTANT_PUDDING == 1
//            //PDCA
//            if (strPDCAType.length > 0) {
//                //Edison 2019-3-15
//                SEL selector = NSSelectorFromString(strPDCAType);
//                NSMethodSignature* sig = [self  methodSignatureForSelector:selector];
//                NSInvocation* invoc = [self createInvocationOnTarget:self methodSignature:&sig selector:selector withArguments:@[[_arrCommandData[indexFixture] objectAtIndex:index],[NSNumber numberWithInt:indexFixture]]];
//                [invoc invoke];
//            }
//#endif
            
            if ([strHideOrShow isEqualToString:@"show"]) {
                [self NeedToReflashTableViewSelect:index withIndex:indexFixture];
                index++;
            }
            
            if (bBreakOut) {
                //跳出循环
                if (!bReturnStatus)
                    break;
            }
        }
    }
}

//判断是否为整形：
- (BOOL)isPureInt:(NSString*)string
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

- (void)executeTestResult:(NSString *)strResult withType:(NSString *)strResType withCol:(int)index withStatus:(BOOL)bStatus withIndexFixture:(int)indexFixture
{
    if (bStatus) {
        if ([strResType rangeOfString:@"string"].length > 0) {
            //如果返回值是string类型，需要show到TestResult里
            if ([strResult length] > 0) {
                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:YES withIndexFixture:indexFixture];
            } else {
                [self executeCommandDataWithIndex:index WithResult:@"OK" WithStatus:YES withIndexFixture:indexFixture];
            }
        } else if ([strResType rangeOfString:@"value"].length > 0) {
            //如果返回值是value类型，需要show到TestResult里
            if ([strResult length] > 0) {
                if ([self isPureInt:strResult]) {
                    strResult = [NSString stringWithFormat:@"%d", [strResult intValue]];
                } else {
                    strResult = [NSString stringWithFormat:@"%.2f", [strResult floatValue]];
                }
                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:YES withIndexFixture:indexFixture];
            } else {
                //保留，待处理
                //                                [self executeCommandDataWithIndex:index WithResult:@"OK" WithStatus:YES withIndexFixture:indexFixture];
            }
        } else {
            //默认返回值是bool类型，将OK值show到TestResult里
//            if ([strResult length] > 0) {
//                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:YES withIndexFixture:indexFixture];
//            } else
            {
                [self executeCommandDataWithIndex:index WithResult:@"OK" WithStatus:YES withIndexFixture:indexFixture];
            }
        }
    } else {
        if ([strResType rangeOfString:@"string"].length > 0) {
            //如果返回值是string类型，需要show到TestResult里
            if ([strResult length] > 0) {
                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:NO withIndexFixture:indexFixture];
            } else {
                [self executeCommandDataWithIndex:index WithResult:@"NG" WithStatus:NO withIndexFixture:indexFixture];
            }
        } else if ([strResType rangeOfString:@"value"].length > 0) {
            //如果返回值是value类型，需要show到TestResult里
            if ([strResult length] > 0) {
                if ([self isPureInt:strResult]) {
                    strResult = [NSString stringWithFormat:@"%d", [strResult intValue]];
                } else {
                    strResult = [NSString stringWithFormat:@"%.2f", [strResult floatValue]];
                }
                
                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:NO withIndexFixture:indexFixture];
            } else {
                //默认暂做－9999处理
                [self executeCommandDataWithIndex:index WithResult:@"-9999" WithStatus:NO withIndexFixture:indexFixture];
            }
        } else {
            //默认返回值是bool类型，将NG值show到TestResult里
//            if ([strResult length] > 0) {
//                [self executeCommandDataWithIndex:index WithResult:strResult WithStatus:NO withIndexFixture:indexFixture];
//            } else
            {
                [self executeCommandDataWithIndex:index WithResult:@"NG" WithStatus:NO withIndexFixture:indexFixture];
            }
        }
    }
    
}

- (BOOL)getResultFromDevice:(id)commTmp withResult:(NSString **)resBuf
                  withLower:(NSString *)strLower withUpper:(NSString *)strUpper
                   withUnit:(NSString *)strUnit
            withStartString:(NSString *)strStart withEndString:(NSString *)strEnd
           withIndexFixture:(int)indexFixture withTimeOut:(float)fTimeOut
{
    if (![commTmp isOpen]) {
        return NO;
    }
    
    NSString *result = nil;
    NSMutableString *strResBufferTmp = nil;
    
    strResBufferTmp = _arrTotalResBuffer[indexFixture];
    //[strResBufferTmp setString:@""];
    
    if ([strEnd isEqualToString:@"newline"]) {
        strEnd = @"\n";
    }
    
    BOOL bRead = NO;
    
#if ((DUT_TEST == 1) || (FIXTURE_TEST == 1)) && ((INST_TEST == 1) && (NI_VISA == 1))
    if ([commTmp isKindOfClass:[ORSSerialPort class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut SerialPort:commTmp];
    } else if ([commTmp isKindOfClass:[visaGeneral class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut VisaPort:commTmp];
    }
#elif ((DUT_TEST == 1) || (FIXTURE_TEST == 1))
    if ([commTmp isKindOfClass:[ORSSerialPort class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut SerialPort:commTmp];
    }
#elif ((INST_TEST == 1) && (NI_VISA == 1))
    if ([commTmp isKindOfClass:[visaGeneral class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut VisaPort:commTmp];
    }
#endif
    //    if ([commTmp read:&result From:strStart To:strEnd Timeout:fTimeOut])
    if (bRead) {
        [strResBufferTmp appendString:result];
    }
    
    if ([result length] > 0) {
        NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Received:\n%@", [self getCurrentTime], result];
        [self outputMessageTextView:strNewLine withIndex:indexFixture];
    }
    
    NSString *strRes = nil;
    
    if ([strResBufferTmp length] > 0) {
        //        [self outputMessageTextView:_strTotalResBuffer];
        //特殊处理
        if ([strStart isEqualToString:@"-"]) {
            strRes = [self getSpecialData:strResBufferTmp startSet:strStart endSet:strEnd];
        } else {
            strRes = [self getData:strResBufferTmp startSet:strStart endSet:strEnd];
        }
        strRes = [strRes stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        strRes = [strRes stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        strRes = [strRes stringByReplacingOccurrencesOfString:@"," withString:@""];
        strRes = [strRes stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet]invertedSet]];
        
        if ([strRes floatValue] < 0) {
            strRes = @"-9999";
        }
        
//        if ([strUnit rangeOfString:@"m"].length > 0) {
//            strRes = [NSString stringWithFormat:@"%f", 1000*[strRes floatValue]];
//        } else if ([strUnit rangeOfString:@"u"].length > 0) {
//            strRes = [NSString stringWithFormat:@"%f", 1000000*[strRes floatValue]];
//        } else if ([strUnit rangeOfString:@"n"].length > 0) {
//            strRes = [NSString stringWithFormat:@"%f", 1000000000*[strRes floatValue]];
//        } else {
            strRes = [NSString stringWithFormat:@"%d", [strRes intValue]];
//        }
        
        if ([self compareValue:strRes withMax:strUpper andMin:strLower]) {
            *resBuf = strRes;
            return YES;
        }
    } else {
        strRes = @"No Read";
    }
    
    *resBuf = strRes;
    return NO;
}

- (BOOL)getResultFromDevice:(id)commTmp withResult:(NSString **)resBuf
            withStartString:(NSString *)strStart withEndString:(NSString *)strEnd withSpecString:(NSString *)strSpec withIndexFixture:(int)indexFixture withTimeOut:(float)fTimeOut
{
    if (![commTmp isOpen]) {
        *resBuf = @"No Read";
        return NO;
    }
    
    NSString *result = nil;
    NSMutableString *strResBufferTmp = nil;
    
    strResBufferTmp = _arrTotalResBuffer[indexFixture];
//    [strResBufferTmp setString:@""];
    
    if ([strEnd isEqualToString:@"newline"]) {
        strEnd = @"\n";
    }
    
    BOOL bRead = NO;
    
#if ((DUT_TEST == 1) || (FIXTURE_TEST == 1)) && ((INST_TEST == 1) && (NI_VISA == 1))
    if ([commTmp isKindOfClass:[ORSSerialPort class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut SerialPort:commTmp];
    } else if ([commTmp isKindOfClass:[visaGeneral class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut VisaPort:commTmp];
    }
#elif ((DUT_TEST == 1) || (FIXTURE_TEST == 1))
    if ([commTmp isKindOfClass:[ORSSerialPort class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut SerialPort:commTmp];
    }
#elif ((INST_TEST == 1) && (NI_VISA == 1))
    if ([commTmp isKindOfClass:[visaGeneral class]]) {
        bRead = [self read:&result From:strStart To:strEnd Timeout:fTimeOut VisaPort:commTmp];
    }
#endif
//    if ([commTmp read:&result From:strStart To:strEnd Timeout:fTimeOut])
    if (bRead) {
        [strResBufferTmp appendString:result];
    } else {
        if ([strSpec isEqualToString:@"NoResponse"]) {
            NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Received:\nNo Response", [self getCurrentTime]];
            [self outputMessageTextView:strNewLine withIndex:indexFixture];
            return YES;
        }
    }
    
    if ([result length] > 0) {
        NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Received:\n%@", [self getCurrentTime], result];
        [self outputMessageTextView:strNewLine withIndex:indexFixture];
    }
    
    NSString *strRes = nil;
    
//    [strResBufferTmp setString:[strResBufferTmp stringByReplacingOccurrencesOfString:@"\r" withString:@""]];
//    [strResBufferTmp setString:[strResBufferTmp stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    [strResBufferTmp setString:[strResBufferTmp stringByReplacingOccurrencesOfString:@"," withString:@" "]];
    
    if ([strResBufferTmp length] > 0) {
        //        [self outputMessageTextView:_strTotalResBuffer];
        strRes = [self getData:strResBufferTmp startSet:strStart endSet:strEnd];
        strRes = [strRes stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        //[strResBufferTmp setString:strRes];
        [strResBufferTmp appendString:strRes];
    } else {
        strRes = @"No Read";
    }
    
    *resBuf = strRes;
    
    if ([strRes isEqualToString:@"No Read"]) {
        return NO;
    }
    
    if ([strSpec length] > 0) {
        //针对“!”，"&&","||"需做特殊处理
        if ([strSpec rangeOfString:@"!"].length > 0) {
            NSString *strTmpRet = [strSpec stringByReplacingOccurrencesOfString:@"!" withString:@""];
            
            if ([strTmpRet rangeOfString:@"("].length > 0) {
                strTmpRet = [strTmpRet stringByReplacingOccurrencesOfString:@"(" withString:@""];
                strTmpRet = [strTmpRet stringByReplacingOccurrencesOfString:@")" withString:@""];
                
                NSArray *arraySpec = [strTmpRet componentsSeparatedByString:@"||"];
                
                for (NSString *strTmp in arraySpec) {
                    if ([strResBufferTmp rangeOfString:strTmp].length == 0) {
                        return YES;
                    }
                }
            } else {
                if ([strResBufferTmp rangeOfString:strTmpRet].length == 0) {
                    //如果不包含则返回YES
                    return YES;
                }
            }
        } else if ([strSpec rangeOfString:@"&&"].length > 0) {
            NSArray *arraySpec = [strSpec componentsSeparatedByString:@"&&"];
            
            for (NSString *strTmp in arraySpec) {
                if ([strResBufferTmp rangeOfString:strTmp].length == 0) {
                    return NO;
                }
            }
            
            return YES;
        } else if ([strSpec rangeOfString:@"||"].length > 0) {
            NSArray *arraySpec = [strSpec componentsSeparatedByString:@"||"];
            
            for (NSString *strTmp in arraySpec) {
                if ([strResBufferTmp rangeOfString:strTmp].length > 0) {
                    return YES;
                }
            }
        } else {
            if ([strResBufferTmp rangeOfString:strSpec].length > 0) {
                return YES;
            }
        }
    } else {
        if ([strResBufferTmp length] > 0) {
            return YES;
        } else {
            return NO;
        }
    }
    
    return NO;
}

//通过指定起始index及length，来截取字串
- (NSString *)getData:(NSString *)fileContent startIndex:(int)iStart iLength:(int)iLength
{
    NSString *strRet = nil;
    
    strRet = [fileContent substringWithRange:NSMakeRange(iStart, iLength)];
    
    return strRet;
}

//通过指定起始字符串及length，来截取字串
- (NSString *)getData:(NSString *)fileContent startSet:(NSString *)strStart iLength:(int)iLength
{
    NSString *strRet = nil;
    
    NSRange rangeStr;
    NSUInteger iPosStr;
    
    if ([strStart length] == 0) {
        iPosStr = 0;
    } else {
        if ([fileContent rangeOfString:strStart].length > 0) {
            rangeStr = [fileContent rangeOfString:strStart];
            iPosStr = (rangeStr.location + rangeStr.length);
            //            fileContent = [fileContent substringFromIndex:iPosStr];
        }
    }
    
    strRet = [fileContent substringWithRange:NSMakeRange(iPosStr, iLength)];
    
    return strRet;
}

//通过指定起始字符串及结束字符串，来截取字串
- (NSString *)getData:(NSString *)fileContent startSet:(NSString *)strStart endSet:(NSString *)strEnd
{
    NSRange rangeStr;
    NSUInteger iPosStr;
    
    if ([strStart length] == 0) {
        iPosStr = 0;
    } else {
        if ([fileContent rangeOfString:strStart].length > 0) {
            rangeStr = [fileContent rangeOfString:strStart];
            iPosStr = (rangeStr.location + rangeStr.length);
            fileContent = [fileContent substringFromIndex:iPosStr];
        }
    }
    
    NSRange rangeStrEnd;
    NSUInteger iLengthStr;
    
    //因为无法识别\n，所以需做个转换
    if ([strEnd isEqualToString:@"newline"]) {
        strEnd = @"\n";
    }
    
    if ([strEnd length] == 0) {
        iLengthStr = [fileContent length];
    } else {
        if ([fileContent rangeOfString:strEnd].length > 0) {
            rangeStrEnd = [fileContent rangeOfString:strEnd];
            iLengthStr = rangeStrEnd.location;
        } else {
            iLengthStr = 0;
        }
    }
    
    NSString *strRet = [fileContent substringWithRange:NSMakeRange(0, iLengthStr)];
    
    if ([strRet length] == 0) {
        strRet = @"No Read";
    }
    
    return strRet;
}

- (NSString *)getSpecialData:(NSString *)fileContent startSet:(NSString *)strStart endSet:(NSString *)strEnd
{
    NSRange rangeStr;
    NSUInteger iPosStr;
    
    if ([strStart length] == 0) {
        iPosStr = 0;
    } else {
        do {
            rangeStr = [fileContent rangeOfString:strStart];
            iPosStr = (rangeStr.location + rangeStr.length);
            fileContent = [fileContent substringFromIndex:iPosStr];
        } while ([fileContent rangeOfString:strStart].length > 0);
    }
    
    NSRange rangeStrEnd;
    NSUInteger iLengthStr;
    
    if ([strEnd length] == 0) {
        iLengthStr = [fileContent length];
    } else {
        if ([fileContent rangeOfString:strEnd].length > 0) {
            rangeStrEnd = [fileContent rangeOfString:strEnd];
            iLengthStr = rangeStrEnd.location;
        } else {
            iLengthStr = 0;
        }
    }
    
    NSString *strRet = [fileContent substringWithRange:NSMakeRange(0, iLengthStr)];
    
    if ([strRet length] == 0) {
        strRet = @"No Read";
    }
    
    return strRet;
}

#pragma mark --

- (void)outputMessageTextView:(NSString *)strMessage withIndex:(int)index
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([strMessage length] > 0) {
            NSTextView *textEditTmp = nil;
            
            textEditTmp = _tabViewController.arrMessageView[index].textEdit;
            
            [[[textEditTmp textStorage] mutableString] appendString:[NSString stringWithFormat:@"%@\n", strMessage]];
            
            NSRange rect = NSMakeRange(textEditTmp.string.length, 0);
            [textEditTmp scrollRangeToVisible:rect];
            //        [_tabViewController.messageTextView setNeedsDisplay:YES];
        }
    });
}

- (BOOL)compareValue:(NSString*)value withMax:(NSString *)max andMin:(NSString *)min
{
    BOOL bRet = NO;
    
    if (([min isEqualToString:@"NA"] || [min isEqualToString:@""])
        && !([max isEqualToString:@"NA"] || [max isEqualToString:@""])) {
        if ([value floatValue] <= [max floatValue]) {
            bRet = YES;
        }
    }
    else if (!([min isEqualToString:@"NA"] || [min isEqualToString:@""])
             && ([max isEqualToString:@"NA"] || [max isEqualToString:@""])){
        if ([value floatValue] >= [min floatValue]) {
            bRet = YES;
        }
    }
    else if (([min isEqualToString:@"NA"] || [min isEqualToString:@""])
             && ([max isEqualToString:@"NA"] || [max isEqualToString:@""])){
        bRet = YES;
    }
    else{
        if ([value floatValue] >= [min floatValue] && [value floatValue] <= [max floatValue]) {
            bRet = YES;
        }
    }
    return bRet;
}

- (void)executeCommandDataWithIndex:(int)index WithResult:(NSString *)strResult WithStatus:(BOOL)bStatus
               withIndexFixture:(int)indexFixture
{
    NSMutableArray *arrayData = nil;
    
    arrayData = _arrCommandData[indexFixture];
    
    NSDictionary *item = [arrayData objectAtIndex:index];
    NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
    
    [newItem setObject:[NSNumber numberWithBool:bStatus] forKey:@"Status"];
    [newItem setObject:strResult forKey:@"TestResult"];
//    [newItem setObject:strResult forKey:@"TestValue"];
    
    [arrayData setObject:newItem atIndexedSubscript:index];
    
    NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Test result:\n%@", [self getCurrentTime], strResult];
    [self outputMessageTextView:strNewLine withIndex:indexFixture];
    //[self outputMessageTextView:strResult withIndex:indexFixture];
//    [self NeedToReflashTableViewSelect:index withIndex:indexFixture]; //remove 20170419
}

- (void)executeCommandDataWithIndex:(int)index WithValue:(NSString *)strValue WithResult:(NSString *)strResult WithStatus:(BOOL)bStatus
                   withIndexFixture:(int)indexFixture
{
    NSMutableArray *arrayData = nil;
    
    arrayData = _arrCommandData[indexFixture];
    
    NSDictionary *item = [arrayData objectAtIndex:index];
    NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
    
    
    [newItem setObject:[NSNumber numberWithBool:bStatus] forKey:@"Status"];
    [newItem setObject:strResult forKey:@"TestResult"];
//    [newItem setObject:strValue forKey:@"TestValue"];
    
    [arrayData setObject:newItem atIndexedSubscript:index];
    
    NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Test result:\n%@", [self getCurrentTime], strResult];
    [self outputMessageTextView:strNewLine withIndex:indexFixture];
    //[self outputMessageTextView:strResult withIndex:indexFixture];
    //    [self NeedToReflashTableViewSelect:index withIndex:indexFixture]; //remove 20170419
}

- (void)NeedToReflashTableViewSelect:(NSInteger)iSelected withIndex:(int)index
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTableView *listViewTmp = nil;
        
        listViewTmp = _tabViewController.arrTableView[index].listView;
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:iSelected];
        [listViewTmp selectRowIndexes:indexSet byExtendingSelection:NO];
        
        //        //        NSInteger iSelected = [listViewTmp selectedRow];
        //        NSRect rowRect = [listViewTmp rectOfRow:iSelected];
        //        NSRect viewRect = [[listViewTmp superview] frame];
        //        NSPoint scrollOrigin = rowRect.origin;
        //        scrollOrigin.y = scrollOrigin.y + (rowRect.size.height - viewRect.size.height)/2;
        //
        //        if (scrollOrigin.y < 0)
        //            scrollOrigin.y = 0;
        //
        //        [[[listViewTmp superview] animator] setBoundsOrigin:scrollOrigin];
        
        [listViewTmp scrollRowToVisible:iSelected];
        [listViewTmp scrollColumnToVisible:5];
    });
}

#pragma mark -
- (NSString *)getCurrentTime
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    
    //    [dateFormatter release];
    return currentTime;
}

- (NSString *)getCurrentDate
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    
    //    [dateFormatter release];
    return currentTime;
}

#pragma mark -
- (void)createCSVFileWithIndex:(int)index
{
    //  =================================
    NSMutableArray *muteArrName = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrRet = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrLower = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrUpper = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrUnit = [[NSMutableArray alloc] init];
    
    NSString *strTestResult = nil;
    NSString *strFailList = nil;
    NSMutableArray *muteArrFailList = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrayTmp = nil;
    NSString *strStartTimeTmp = nil;
    NSString *strStopTimeTmp = nil;
    NSString *strSNTmp = nil;
    
    arrayTmp = _arrCommandData[index];
    strStartTimeTmp = _arrStartTime[index];
    strStopTimeTmp = _arrStopTime[index];
    strSNTmp = _arrSN[index];
    
    for (int i = 0; i < [arrayTmp count]; i++)
    {
        NSString *itemName = [[arrayTmp objectAtIndex:i] objectForKey:@"TestItem"];
        NSString *itemValue = [[arrayTmp objectAtIndex:i] objectForKey:@"TestResult"];
//        NSString *itemValue = [[arrayTmp objectAtIndex:i] objectForKey:@"TestValue"];
        NSString *itemLower = [[arrayTmp objectAtIndex:i] objectForKey:@"Lower"];
        NSString *itemUpper = [[arrayTmp objectAtIndex:i] objectForKey:@"Upper"];
        NSString *itemUnit = [[arrayTmp objectAtIndex:i] objectForKey:@"Unit"];
        
        if (itemName != nil)
            [muteArrName addObject:itemName];
        if (itemValue != nil)
        {
            //过滤"\n"
            itemValue = [itemValue stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [muteArrRet addObject:itemValue];
        }
        if (itemUpper != nil)
            [muteArrUpper addObject:itemUpper];
        if (itemLower != nil)
            [muteArrLower addObject:itemLower];
        if (itemUnit != nil)
            [muteArrUnit addObject:itemUnit];
        
        if (![[[arrayTmp objectAtIndex:i] objectForKey:@"Status"] boolValue]) {
            [muteArrFailList addObject:itemName];
        }
    }
    
    if (_bFailedAtLeastOneTest[index]) {
        //        _arrTestResult[index] = @0;
        _bTestResult[index] = NO;
        
        strFailList = [muteArrFailList componentsJoinedByString:@";"];
        strTestResult = @"FAIL";
    } else {
        //        _arrTestResult[index] = @1;
        _bTestResult[index] = YES;
        
        strFailList = @"NA";
        strTestResult = @"PASS";
    }
    
    strStopTimeTmp = [self getCurrentTime];
    
    NSString *measureData = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@\r\n",
                             [NSString stringWithFormat:@"%@:%@", _strProduct, _swName], strSNTmp, _strStationID, strTestResult, strFailList, strStartTimeTmp, strStopTimeTmp, [muteArrRet componentsJoinedByString:@","]];
    
    CSVFile *csv = [[CSVFile alloc] init];
    
    NSString *filePath = [NSString stringWithFormat:@"/vault/%@/%@/CSV%d", _swName, [self getCurrentDate], (index+1)];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", _swName, [self getCurrentTime]];
    
    [csv createFileWithPath:filePath WithName:fileName WithType:@"csv"];
    
    //    NSString *preFileName = nil;
    //    [self readFileName:&preFileName];
    
    //    if (![fileName isEqualToString:preFileName])
    {
        //        [self saveFileName:fileName];
        
        NSString *line0 = [NSString stringWithFormat:@"%@,Version:%@\r\n", _strFactory, _swVersion];
        NSString *line1 = [NSString stringWithFormat:@"Product,SerialNumber,Station ID,Test Pass/Fail Status,List of Failing Tests,StartTime,EndTime,%@\r\n", [muteArrName componentsJoinedByString:@","]];
        NSString *line2 = [NSString stringWithFormat:@"Upper Limit----->,,,,,,,%@\r\n", [muteArrUpper componentsJoinedByString:@","]];
        NSString *line3 = [NSString stringWithFormat:@"Lower Limit----->,,,,,,,%@\r\n", [muteArrLower componentsJoinedByString:@","]];
        NSString *line4 = [NSString stringWithFormat:@"Measurement Unit----->,,,,,,,%@\r\n", [muteArrUnit componentsJoinedByString:@","]];
        NSString *data = [NSString stringWithFormat:@"%@%@%@%@%@\r\n",line0, line1, line2, line3, line4];
        
        [csv appendDataToFileWithString:data];
    }
    
    [csv appendDataToFileWithString:measureData];
    
    [muteArrName removeAllObjects];
    [muteArrRet removeAllObjects];
    [muteArrUpper removeAllObjects];
    [muteArrLower removeAllObjects];
    [muteArrUnit removeAllObjects];
}

- (void)createCSVFileInOneWithIndex:(int)index
{
    //  =================================
    NSMutableArray *muteArrName = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrRet = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrLower = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrUpper = [[NSMutableArray alloc] init];
    NSMutableArray *muteArrUnit = [[NSMutableArray alloc] init];
    
    NSString *strTestResult = nil;
    NSString *strFailList = nil;
    NSMutableArray *muteArrFailList = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrayTmp = nil;
    NSString *strStartTimeTmp = nil;
    NSString *strStopTimeTmp = nil;
    NSString *strSNTmp = nil;
    
    arrayTmp = _arrCommandData[index];
    strStartTimeTmp = _arrStartTime[index];
    strStopTimeTmp = _arrStopTime[index];
    strSNTmp = _arrSN[index];
    
    for (int i = 0; i < [arrayTmp count]; i++)
    {
        NSString *itemName = [[arrayTmp objectAtIndex:i] objectForKey:@"TestItem"];
        NSString *itemValue = [[arrayTmp objectAtIndex:i] objectForKey:@"TestResult"];
//        NSString *itemValue = [[arrayTmp objectAtIndex:i] objectForKey:@"TestValue"];
        NSString *itemLower = [[arrayTmp objectAtIndex:i] objectForKey:@"Lower"];
        NSString *itemUpper = [[arrayTmp objectAtIndex:i] objectForKey:@"Upper"];
        NSString *itemUnit = [[arrayTmp objectAtIndex:i] objectForKey:@"Unit"];
        
        if (itemName != nil)
            [muteArrName addObject:itemName];
        if (itemValue != nil)
        {
            //过滤"\n"
            itemValue = [itemValue stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [muteArrRet addObject:itemValue];
        }
        if (itemUpper != nil)
            [muteArrUpper addObject:itemUpper];
        if (itemLower != nil)
            [muteArrLower addObject:itemLower];
        if (itemUnit != nil)
            [muteArrUnit addObject:itemUnit];
        
        if (![[[arrayTmp objectAtIndex:i] objectForKey:@"Status"] boolValue]) {
            [muteArrFailList addObject:itemName];
        }
    }
    
    if (_bFailedAtLeastOneTest[index]) {
        //        _arrTestResult[index] = @0;
        _bTestResult[index] = NO;
        
        strFailList = [muteArrFailList componentsJoinedByString:@";"];
        strTestResult = @"FAIL";
    } else {
        //        _arrTestResult[index] = @1;
        _bTestResult[index] = YES;
        
        strFailList = @"NA";
        strTestResult = @"PASS";
    }
    
    strStopTimeTmp = [self getCurrentTime];
    
    NSString *measureData = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@\r\n",
                             [NSString stringWithFormat:@"%@:%@", _strProduct, _swName], strSNTmp, _strStationID, strTestResult, strFailList, strStartTimeTmp, strStopTimeTmp, [muteArrRet componentsJoinedByString:@","]];
    
    CSVFile *csv = [[CSVFile alloc] init];
    
    NSString *filePath = [NSString stringWithFormat:@"/vault/%@/%@", _swName, [self getCurrentDate]];
    NSString *fileName = [NSString stringWithFormat:@"%@_CSV%d_%@", _swName, (index+1), [self getCurrentDate]];
    
    [csv createFileWithPath:filePath WithName:fileName WithType:@"csv"];
    
    NSString *csvFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.csv", fileName]];
    NSURL *fileURL = [NSURL fileURLWithPath:csvFilePath];
    
    NSError *err = nil;
    NSString *fileContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&err];
    //    NSLog(@"Error = %@", err);
    
    if (!([fileContent rangeOfString:[NSString stringWithFormat:@"%@", _strFactory]].length > 0)) {
        NSString *line0 = [NSString stringWithFormat:@"%@,SW_Version:%@\r\n", _strFactory, _swVersion];
        NSString *line1 = [NSString stringWithFormat:@"Product,SerialNumber,Station ID,Test Pass/Fail Status,List of Failing Tests,StartTime,EndTime,%@\r\n", [muteArrName componentsJoinedByString:@","]];
        NSString *line2 = [NSString stringWithFormat:@"Upper Limit----->,,,,,,,%@\r\n", [muteArrUpper componentsJoinedByString:@","]];
        NSString *line3 = [NSString stringWithFormat:@"Lower Limit----->,,,,,,,%@\r\n", [muteArrLower componentsJoinedByString:@","]];
        NSString *line4 = [NSString stringWithFormat:@"Measurement Unit----->,,,,,,,%@\r\n", [muteArrUnit componentsJoinedByString:@","]];
        NSString *data = [NSString stringWithFormat:@"%@%@%@%@%@\r\n",line0, line1, line2, line3, line4];
        
        [csv appendDataToFileWithString:data];
    }
    
    [csv appendDataToFileWithString:measureData];
    
    [muteArrName removeAllObjects];
    [muteArrRet removeAllObjects];
    [muteArrUpper removeAllObjects];
    [muteArrLower removeAllObjects];
    [muteArrUnit removeAllObjects];
}

- (void)createLogFileWithIndex:(int)index
{
    NSTextView *textEditTmp = nil;
    
    textEditTmp = _tabViewController.arrMessageView[index].textEdit;
    
    CSVFile *csv = [[CSVFile alloc] init];
    
    NSString *filePath = [NSString stringWithFormat:@"/vault/%@Log/%@", _swName, [self getCurrentDate]];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", _arrSN[index], [self getCurrentTime]];
    
    [csv createFileWithPath:filePath WithName:fileName WithType:@"txt"];
    
    [csv appendDataToFileWithString:[[textEditTmp textStorage] mutableString]];
    
    _arrBlobPath[index] = [NSString stringWithFormat:@"%@/%@.%@", filePath, fileName, @"txt"];
}

- (void)createDumpFileWithIndex:(int)index withMode:(int)iMode
{
    NSString *strSN = nil;
    NSString *strContent = nil;
    NSString *strBlobDumpPathTmp = nil;
    
    CSVFile *csv = [[CSVFile alloc] init];
    
    NSString *filePath = [NSString stringWithFormat:@"/vault/%@Dump/%@", _swName, [self getCurrentDate]];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", strSN, [self getCurrentTime]];
    
    [csv createFileWithPath:filePath WithName:fileName WithType:@"txt"];
    
    [csv appendDataToFileWithString:strContent];
    
    strBlobDumpPathTmp = [NSString stringWithFormat:@"%@/%@.%@", filePath, fileName, @"txt"];
}

#if INSTANT_PUDDING == 1
//Edison 2019-3-15 创建Target调用
- (NSInvocation*)createInvocationOnTarget:(id)target
                         methodSignature:(NSMethodSignature**)sig
                                selector:(SEL)selector
                           withArguments:(id)arg1
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:*sig];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    int ct = 2;
//    int ct = (int)arg1.count;
    if (arg1) {
        for (id value in arg1) {
            [invocation setArgument:(void *)&value atIndex:ct];
            ct++;
        }
    }
    return invocation;
}

- (void)string:(NSDictionary*)dic index:(NSNumber*)index
{
    NSString *pdcaName = [dic objectForKey:@"PDCA"];
    NSString *attributeName = [dic objectForKey:@"AttributeName"];
    [_arrPDCA[index.intValue] AddTestItem:pdcaName
            LowerSpec:@"1"
            UpperSpec:@"1"
                 Unit:@"NA"
            TestValue:[dic[@"Status"] boolValue] ? @"1" : @"0"
           TestResult:[dic[@"Status"] boolValue] ? PASS : FAIL
            ErrorInfo:@"NA"
                        Priority:_bAuditMode ? @"-2":@"0"];
    
    if ([dic[@"TestResult"] length] > 0)
        [_arrPDCA[index.intValue] AddAttribute:attributeName AttributeValue:dic[@"TestResult"]];
}

- (void)value:(NSDictionary*)dic index:(NSNumber*)index
{
    NSString *pdcaName = [dic objectForKey:@"PDCA"];
    NSString * unit = [dic objectForKey:@"Unit"];
    NSString * lower = dic[@"Lower"];
    NSString* upper = dic[@"Upper"];
    lower.length == 0 ? (lower = @"NA") : lower;
    upper.length == 0 ? (upper = @"NA") : upper;
    unit.length == 0 ? (unit = @"NA") : unit;

    if ([dic[@"TestResult"] length] > 0) {
        [_arrPDCA[index.intValue] AddTestItem:pdcaName
                                    LowerSpec:dic[@"Lower"]
                                    UpperSpec:dic[@"Upper"]
                                         Unit:unit
                                    TestValue:dic[@"TestResult"]
                                   TestResult:[dic[@"Status"] boolValue] ? PASS : FAIL
                                    ErrorInfo:@"NA"
                                     Priority:_bAuditMode ? @"-2":@"0"];
    } else {
        [_arrPDCA[index.intValue] AddTestItem:pdcaName
                                    LowerSpec:dic[@"Lower"]
                                    UpperSpec:dic[@"Upper"]
                                         Unit:unit
                                    TestValue:@"-9999"
                                   TestResult:FAIL
                                    ErrorInfo:@"NA"
                                     Priority:_bAuditMode ? @"-2":@"0"];
    }

}

- (void)boolType:(NSDictionary*)dic index:(NSNumber*)index
{
    NSString *pdcaName = [dic objectForKey:@"PDCA"];
    
    [_arrPDCA[index.intValue] AddTestItem:pdcaName
                                LowerSpec:@"1"
                                UpperSpec:@"1"
                                     Unit:@"NA"
                                TestValue:[dic[@"Status"] boolValue] ? @"1" : @"0"
                               TestResult:[dic[@"Status"] boolValue] ? PASS : FAIL
                                ErrorInfo:dic[@"TestResult"]
                                 Priority:_bAuditMode ? @"-2":@"0"];
}

- (void)uploadToPDCAWithIndex:(int)index
{
    NSMutableArray *arrayTmp = nil;
    NSString *strSNTmp = nil;
    
    arrayTmp = _arrCommandData[index];
    strSNTmp = _arrSN[index];
    
    if ([arrayTmp count] > 0)
    {
        //if (_bInitPudding[index])
        {
            [_arrPDCA[index] UUTStartTest];
            [_arrPDCA[index] AddAttribute:@IP_ATTRIBUTE_STATIONSOFTWARENAME AttributeValue:_swName];
            [_arrPDCA[index] AddAttribute:@IP_ATTRIBUTE_STATIONSOFTWAREVERSION AttributeValue:_swVersion];
            [_arrPDCA[index] AddAttribute:@IP_ATTRIBUTE_SERIALNUMBER AttributeValue:strSNTmp];
            
            for (int i = 0; i < [arrayTmp count]; i++) {
                NSDictionary *dic = [arrayTmp objectAtIndex:i];
                NSString *pdcaType = [dic objectForKey:@"PDCA_TYPE"];
                if (pdcaType.length > 0) {
                    //Edison 2019-3-15
                    SEL selector = NSSelectorFromString(pdcaType);
                    NSMethodSignature* sig = [self  methodSignatureForSelector:selector];
                    NSInvocation* invoc = [self createInvocationOnTarget:self methodSignature:&sig selector:selector withArguments:@[dic,[NSNumber numberWithInt:index]]];
                    [invoc invoke];
                }
            }
            [_arrPDCA[index] UUTRelease];
        }
    }
}
#endif

#pragma mark --
- (void)showAlertViewWarning:(NSString *)strWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    @try {
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:strWarning];
        //[alert setInformativeText:@"Fialed!Please ."];
        [alert setAlertStyle:NSWarningAlertStyle];
    } @catch (NSException *exception) {
        NSString *strError = [NSString stringWithFormat:@"%@", exception];
        [alert setMessageText:strError];
    } @finally {
       [alert runModal];
    }
}

- (void)runningHIDControl
{
    [NSThread detachNewThreadSelector:@selector(fireTimer) toTarget:self withObject:nil];
}

- (void)fireTimer
{
    [NSTimer scheduledTimerWithTimeInterval: 0.7
                                     target: self
                                   selector: @selector(handleTimer:)
                                   userInfo: nil
                                    repeats: YES];
    [[NSRunLoop currentRunLoop] run];
}

- (void)handleTimer: (NSTimer *)timer
{
    [self callHIDControlAppTool];
}

#pragma mark --
//将十进制转化为十六进制
- (NSString *)ToHex:(uint16_t)tmpid
{
    NSString *nLetterValue;
    NSString *str = @"";
    uint16_t ttmpig;
    
    for (int i = 0; i < 9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        
        switch (ttmpig) {
            case 10:
                nLetterValue =@"a";
                break;
            case 11:
                nLetterValue =@"b";
                break;
            case 12:
                nLetterValue =@"c";
                break;
            case 13:
                nLetterValue =@"d";
                break;
            case 14:
                nLetterValue =@"e";
                break;
            case 15:
                nLetterValue =@"f";
                break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                break;
        }
        str = [nLetterValue stringByAppendingString:str];
        
        if (tmpid == 0) {
            break;
        }
    }
    return [NSString stringWithFormat:@"0x%@", str];
}

- (BOOL)closeDutPort:(int)index
{
    BOOL bRet = NO;
    
    if (_arrCommDUT[index] != nil) {
        if ([_arrCommDUT[index] isOpen]) {
            [_arrCommDUT[index] close];
//                     _arrCommDUT[index] = nil;
            [NSThread sleepForTimeInterval:2.0f];
        }
        
        if (![_arrCommDUT[index] isOpen]) {
            bRet = YES;
        }
    }
    
    return bRet;
}

- (void)getAutoAlertViewResult:(NSDictionary *)notification
{
    NSDictionary *dic = (NSDictionary *)notification;
    NSString *strCmd = [dic objectForKey:@"Command"];
    NSString *strSpec = [dic objectForKey:@"Spec"];
    float fTime = [[dic objectForKey:@"TimeOut"] floatValue];
    int indexFixture = [[dic objectForKey:@"Index"] intValue];
    
    NSTimeInterval startTime = 0.0f;
    NSTimeInterval endTime = 0.0f;
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
    
    while ((endTime - startTime) < fTime) {
        if ([self getCommandResult:strCmd Spec:strSpec Index:indexFixture]) {
            break;
        }
        usleep(30000); //delay 300 ms
        endTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    //    [_alertWindow windowShouldClose:nil];
    _tabViewController.arrTableView[indexFixture].alertView.bAlert = NO;
    _tabViewController.arrTableView[indexFixture].alertView.hidden = YES;
}

- (BOOL)getCommandResult:(NSString *)strCmd Spec:(NSString *)strSpec Index:(int)indexFixture
{
    BOOL bRet = NO;
    
    NSString *result = nil;
    
    if ([_arrCommDUT[indexFixture] isOpen]) {
        [self write:strCmd SerialPort:_arrCommDUT[indexFixture]];
        if ([self read:&result From:@"<" To:@">" Timeout:3.0f SerialPort:_arrCommDUT[indexFixture]])
        {
            if ([result rangeOfString:strSpec].length > 0) {
                bRet = YES;
            }
        }
        [NSThread sleepForTimeInterval:0.5f];
        //        [_arrCommDUT[indexFixture] query:strCmd ret:&result];
    } else {
        [self initDUTDevice:indexFixture];
    }
    
    return bRet;
}

#pragma mark -
- (time_t)convertTimeStamp:(NSString *)strTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateTime = [dateFormatter dateFromString:strTime];
    
    time_t timeStamp = (time_t)[dateTime timeIntervalSince1970];
    
    return timeStamp;
}

#pragma mark --
//同步请求
- (NSString *)sendRequestSync:(NSString *)urlStr withParam:(NSString *)strParam TimeOut:(float)fTime
{
    // 初始化请求, 这里是变长的, 方便扩展
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    // 设置
    [request setURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    
    //http://172.17.32.16/bobcat/sfc_response.aspxRequest.Form:c=QUERY_RECORD&sn=ZB747000021&StationID=ITKS_A02-2FAP-01_3_CON-OQC&p=SHIPPING_SETTINGS
    NSData *postData = [strParam dataUsingEncoding:NSUTF8StringEncoding];
    [request setTimeoutInterval:fTime]; //响应时间2s
    [request setHTTPBody:postData];
    
    // 发送同步请求, data就是返回的数据
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    if (data == nil) {
        NSLog(@"send request failed: %@", error);
        return [NSString stringWithFormat:@"send request failed: %@", error];
    }
    
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"response: %@", response);
    return response;
}

#pragma mark --
- (NSString *)getSFCURL
{
    NSString *strUrl = nil;
    
    NSString* fileContent = [NSString stringWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json" encoding:NSUTF8StringEncoding error:nil];
    
    NSString *strRet = [self getData:fileContent startSet:@"\"SFC_URL\" : \"" endSet:@"\""];
    
    if ([strRet length] > 0) {
        strUrl = strRet;
    }
    
    return strUrl;
}

- (BOOL)getControlBitsON
{
    if (_bAuditMode) {
        return NO;
    }
    
    BOOL bRet = NO;
    
    NSString* fileContent = [NSString stringWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json" encoding:NSUTF8StringEncoding error:nil];
    
    NSString *strRet = [self getData:fileContent startSet:@"CONTROL_BITS_TO_CHECK_ON_OFF" endSet:@","];
    
    if ([strRet length] > 0) {
        if ([strRet rangeOfString:@"ON"].length > 0) {
            bRet = YES;
        }
    }
    
    return bRet;
}

- (BOOL)getQuerySFCON
{
    return 0;
    if (_bAuditMode) {
        return NO;
    }
    
    BOOL bRet = NO;
    
    NSString* fileContent = [NSString stringWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json" encoding:NSUTF8StringEncoding error:nil];
    
    NSString *strRet = [self getData:fileContent startSet:@"SFC_QUERY_UNIT_ON_OFF" endSet:@","];
    
    if ([strRet length] > 0) {
        if ([strRet rangeOfString:@"ON"].length > 0) {
            bRet = YES;
        }
    }
    
    return bRet;
}

- (NSArray *)getControlBitsArray
{
    NSArray *array = [[NSArray alloc] init];
    
    NSString* fileContent = [NSString stringWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json" encoding:NSUTF8StringEncoding error:nil];
    
    NSString *strRet = [self getData:fileContent startSet:@"\"CONTROL_BITS_TO_CHECK\" : [" endSet:@"]"];
    
    if (([strRet length] > 0) && (![strRet isEqualToString:@"No Read"])) {
        strRet = [strRet stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        //        strRet = [strRet stringByReplacingOccurrencesOfString:@"\”" withString:@""];
        array = [strRet componentsSeparatedByString:@","];
        NSLog(@"array = %@", array);
    }
    
    return array;
}

- (NSArray *)getControlBitsNameArray
{
    NSArray *array = [[NSArray alloc] init];
    
    NSString* fileContent = [NSString stringWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json" encoding:NSUTF8StringEncoding error:nil];
    
    NSString *strRet = [self getData:fileContent startSet:@"\"CONTROL_BITS_STATION_NAMES\" : [" endSet:@"]"];
    
    if (([strRet length] > 0) && (![strRet isEqualToString:@"No Read"])) {
        strRet = [strRet stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        //        strRet = [strRet stringByReplacingOccurrencesOfString:@"\”" withString:@""];
        array = [strRet componentsSeparatedByString:@","];
        NSLog(@"array = %@", array);
    }
    
    return array;
}

#pragma mark --
- (NSString *)startRunShellScript:(NSString *)strFile Content:(NSString *)strContent Param:(NSString *)strParam withIndex:(int)index
{
    NSString *strRes = nil;
    
    //生成可调用的动态Shell脚本
    [self creatDynamicalShellScript:strFile Content:strContent Param:strParam];
    
    //通过Shell去调用python
    strRes = [self runPythonFile:strFile withIndex:index];
    
    //赋值
    [_arrTotalResBuffer[index] setString:@""];
    [_arrTotalResBuffer[index] setString:strRes];
    
    return strRes;
}

- (void)creatDynamicalShellScript:(NSString *)strFile Content:(NSString *)strContent Param:(NSString *)strParam
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:strFile ofType:@""];
    //    NSString *strInfo = [NSString stringWithFormat:@"#!/bin/bash\n# Copyright Statement:\n\ncd /Applications/BR1_DFU2/DFU-mozart\npython ./mozart.py %@", strParam];
    NSString *strInfo = [NSString stringWithFormat:@"#!/bin/bash\n# Copyright Statement:\n\n%@ %@", strContent, strParam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [fileHandle truncateFileAtOffset:0];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[strInfo dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

- (NSString *)runPythonFile:(NSString *)path withIndex:(int)index
{
    //    NSProgressIndicator *indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(480, 220, 30, 30)];
    //    [indicator setStyle:NSProgressIndicatorSpinningStyle];
    //    [self addSubview:indicator];
    //    [indicator startAnimation:self];
    
    NSString *readingTool = [[NSBundle mainBundle] pathForResource:path ofType:@""];
    NSData *data;
    NSPipe *inPipe, *outPipe;
    NSTask *task;
    NSString *aString;
    task = [[NSTask alloc] init];
    inPipe = [[NSPipe alloc] init];
    outPipe = [[NSPipe alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setStandardInput: inPipe];
    [task setStandardOutput: outPipe];
    [task setStandardError: outPipe];
    NSArray *args = [NSArray arrayWithObjects:readingTool, path, nil];
    [task setArguments: args];
    [task launch];
    [task waitUntilExit];
    data = [[outPipe fileHandleForReading] readDataToEndOfFile];
    aString = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding|NSUTF8StringEncoding];
    
    NSString *strNewLine = [NSString stringWithFormat:@"\n%@  Test result:\n%@", [self getCurrentTime], aString];
    [self outputMessageTextView:strNewLine withIndex:index];;
    
    //    [indicator stopAnimation:self];
    //    [indicator setDisplayedWhenStopped:NO];
    
    return aString;
}

#pragma mark - Callback function calls this method

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        [self.window setBackgroundColor:[NSColor controlColor]];
    }
    else {
//        [self.window setBackgroundColor:[NSColor redColor]];
        [self showAlertViewWarning:@"Network is disconnected!Please check network!\n网络已断开!请检查网络!"];
    }
}

- (void)removeResponseObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:self];
}

#pragma mark -- ORS Delegate

- (BOOL)write:(NSString *)strCommand SerialPort:(ORSSerialPort *)commTmp
{
    NSString *strNewCommand = [NSString stringWithFormat:@"%@\r\n", strCommand];
    
    return [commTmp sendData:[strNewCommand dataUsingEncoding:NSASCIIStringEncoding]];
}

- (BOOL)read:(NSString **)Result From:(NSString *)strStart To:(NSString *)strEnd Timeout:(int)fTimeOut SerialPort:(ORSSerialPort *)commTmp
{
    BOOL bRet = NO;
    
    NSTimeInterval startTime = 0.0f;
    NSTimeInterval endTime = 0.0f;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    
    while ((endTime - startTime) < fTimeOut)
    {
        //NSLog(@"commTmp.readString:%@",commTmp.readString);
        //NSLog(@"111111111111111");
        if (([strStart length] > 0) && ([strEnd length] > 0))
        {
            //NSLog(@"---panduan:-----%@",commTmp.readString);
            if ([commTmp.readString rangeOfString:strStart].length > 0)
            {
                NSRange rangeStr;
                NSUInteger iPosStr;
                NSString *fileContent = commTmp.readString;
                
                if ([strStart length] == 0) {
                    iPosStr = 0;
                } else {
                    if ([fileContent rangeOfString:strStart].length > 0) {
                        rangeStr = [fileContent rangeOfString:strStart];
                        iPosStr = (rangeStr.location + rangeStr.length);
                        fileContent = [fileContent substringFromIndex:iPosStr];
                    }
                }
                
                if ([fileContent rangeOfString:strEnd].length > 0)
                {
                    bRet = YES;
                    break;
                }
            }
        }
        else if (([strStart length] == 0) && ([strEnd length] > 0)) {
            if ([commTmp.readString rangeOfString:strEnd].length > 0)
            {
                bRet = YES;
                break;
            }
        }
        //usleep(3000);
        //NSLog(@"---yanshi:-----%@",commTmp.readString);
        endTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    if (commTmp.readString.length){
        NSLog(@"---final-----%@",commTmp.readString);
        *Result = commTmp.readString;
    }
    else
        *Result = @"No Read";
    
    return bRet;
}

#if ((INST_TEST == 1) && (NI_VISA == 1))
- (BOOL)read:(NSString **)Result From:(NSString *)strStart To:(NSString *)strEnd Timeout:(int)fTimeOut VisaPort:(visaGeneral *)commTmp
{
    BOOL bRet = NO;
    NSString *result = nil;
    
    bRet = [commTmp read:&result From:strStart To:strEnd Timeout:fTimeOut];
    
    if ([result length] > 0)
        *Result = result;
    else
        *Result = @"No Read";

    return bRet;
}
#endif

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort
{
    
}

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    NSLog(@"serialPortWasOpened!");
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    NSLog(@"serialPortWasClosed!");
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    NSString *strTmp = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding | NSUTF8StringEncoding];
    if(strTmp.length)
    {
        NSLog(@"%@-Read String:%@",serialPort.name ,strTmp);
        serialPort.readString = [serialPort.readString stringByAppendingString:strTmp];
       // NSLog(@"------serialPort.readString :%@",serialPort.readString);
    }
}
//5.14 add
- (void)setSpamFixturePorts
{
    //    NSDictionary *item = [_arrMatchFixtureAndModem objectAtIndex:index];
    //    NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
    
    const char *cString = [@"system_profiler SPUSBDataType" UTF8String];
    char buf[20480] = {0};
    
    memset(buf, 0, 20480);
    
    FILE *fp = popen(cString, "r");
    fread(buf, sizeof(char), sizeof(buf), fp);
    pclose(fp);
    
    NSData *readData = [NSData dataWithBytes:buf length:20480];
    NSString *strBuf = [[NSString alloc] initWithData:readData encoding:NSASCIIStringEncoding|NSUTF8StringEncoding];
    //    NSString *strBuf = [NSString stringWithFormat:@"%s", buf];
    strBuf = [strBuf stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSArray *arrHub = [strBuf componentsSeparatedByString:@"USB2.0Hub"];
    
    for (NSString *strHub in arrHub) {
        NSMutableDictionary *comdict = [[NSMutableDictionary alloc] initWithCapacity:3];
        NSArray *arrTmp = [strHub componentsSeparatedByString:@"\n"];
        
        BOOL bToGetLID = NO;
        for (NSString *strLine in arrTmp) {
            if (!bToGetLID) {
                if([strLine rangeOfString:@"ProductID:"].length) {
                    if ([strLine rangeOfString:_strSpamPID].length) {
                        bToGetLID = YES;
                    }
                }
            } else {
                if([strLine rangeOfString:@"LocationID:"].length > 0) {
                    //                [_arrLocationIDPreFix addObject:[self getData:strLine startSet:@"LocationID:" iLength:6]];
                    NSString *strTmp = [self getData:strLine startSet:@"LocationID:0x"  endSet:nil];
                    NSString *strZero = [self getData:strTmp startIndex:5 iLength:3];
                    NSString *strLocationIDPreFix = nil;
                    
                    if ([strZero isEqualToString:@"000"]) {
                        strLocationIDPreFix = [self getData:strTmp startIndex:0 iLength:4];
                    } else {
                        strLocationIDPreFix = [self getData:strTmp startIndex:0 iLength:5];
                    }
                    //                    NSString *strLocationIDPreFix = [self getData:strLine startSet:@"LocationID:0x" iLength:5];
                    [comdict setObject:strLocationIDPreFix  forKey:@"PreFix"];
                    
                    [_arrMatchFixtureAndModem addObject:comdict];
                    break;
                } else if ([strLine rangeOfString:@"SerialNumber:"].length > 0) {
                    NSString *strPortName = [NSString stringWithFormat:@"/dev/tty.usbserial-%@", [self getData:strLine startSet:@"SerialNumber:" endSet:@""]];
                    [comdict setObject:strPortName  forKey:@"FixturePort"];
                }
            }
        }
    }
    
    if ([_arrMatchFixtureAndModem count] > 0) {
        NSSortDescriptor *descriporDown = [NSSortDescriptor sortDescriptorWithKey:@"FixturePort" ascending:YES]; //æåº
        _arrMatchFixtureAndModem = [NSMutableArray arrayWithArray:[_arrMatchFixtureAndModem sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriporDown, nil]]];
    }
}

- (NSString *)getModemPortName:(NSString *)strPreFix
{
    NSString *strPortName = nil;
    //    BOOL bRet = NO;
    kern_return_t			kernResult;
    CFMutableDictionaryRef	classToMatch;
    io_iterator_t	serialPortIterator;
    io_object_t		modemService;
    
    classToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    
    if(classToMatch == NULL){
        NSLog(@"IOServiceMatching return null dictionary.");
    } else {
        CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDModemType));
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &serialPortIterator);
    
    if(KERN_SUCCESS != kernResult){
        //NSLog(@"IOServiceGetMatchingServices returned %d \n", kernResult);
    }
    // get device path
    while ((modemService = IOIteratorNext(serialPortIterator))) {
        CFTypeRef	bsdPathAsCFString;
        
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIODialinDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (bsdPathAsCFString) {
            NSString *str = [NSString stringWithFormat:@"%@", bsdPathAsCFString];
            
            if ([str rangeOfString:[NSString stringWithFormat:@"usbmodem%@", strPreFix]].length > 0) {
                //                bRet = YES;
                strPortName = str;
            }
            CFRelease(bsdPathAsCFString);
        }
    }
    
    IOObjectRelease(modemService);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
    return strPortName;
}

- (NSString *)getChargingCableLocationID
{
    const char *cString = [@"system_profiler SPUSBDataType" UTF8String];
    char buf[20480] = {0};
    
    memset(buf, 0, 20480);
    
    FILE *fp = popen(cString, "r");
    sleep(1000);
    fread(buf, sizeof(char), sizeof(buf), fp);
    pclose(fp);
    
    NSData *readData = [NSData dataWithBytes:buf length:20480];
    NSString *strBuf = [[NSString alloc] initWithData:readData encoding:NSASCIIStringEncoding|NSUTF8StringEncoding];
    
    //    NSString *strBuf = [NSString stringWithFormat:@"%s", buf];
    strBuf = [strBuf stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSArray *arrTmp = [strBuf componentsSeparatedByString:@"\n"];
    
    BOOL bToGetLID = NO;
    for (NSString *strLine in arrTmp) {
        if (!bToGetLID) {
            if([strLine rangeOfString:@"ProductID:"].length) {
                if ([strLine rangeOfString:_strChargingCablePID].length) {
                    bToGetLID = YES;
                    //                    break;
                }
            }
        } else {
            if([strLine rangeOfString:@"LocationID:"].length > 0) {
                //                NSString *strLocationIDPreFix = [self getData:strLine startSet:@"LocationID:0x" iLength:4];
                NSString *strLocationIDPreFix = [self getData:strLine startSet:@"LocationID:0x" endSet:@"/"];
                bToGetLID = NO;
                return strLocationIDPreFix;
            }
        }
    }
    
    return nil;
}

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSLog(@"Ports were connected");
    //[_editTxSN setStringValue:_strSN];
    //    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    //    NSLog(@"Ports were connected: %@", connectedPorts);
    //    [self postUserNotificationForConnectedPorts:connectedPorts];
    BOOL bTesting = NO;
    int index = -1;
    
    NSString *strLID = [notification userInfo][ORSConnectedSerialPortsLocationIDKey];
    //david add
    NSString *strSerialNumber = [notification userInfo][ORSConnectedSerialPortsSerialNumberKey];
    NSString *strZero = [self getData:strLID startIndex:5 iLength:3];
    NSString *strLIDPreFix = nil;
    
    if ([strZero isEqualToString:@"000"]) {
        strLIDPreFix = [self getData:strLID startIndex:0 iLength:4];
    } else {
        strLIDPreFix = [self getData:strLID startIndex:0 iLength:5];
    }
    
    for (int i = 0; i < [_arrMatchFixtureAndModem count]; i++) {
        NSString *strFixtureLocationIDPreFix = [[_arrMatchFixtureAndModem objectAtIndex:i] objectForKey:@"PreFix"];
        if ([strFixtureLocationIDPreFix rangeOfString:strLIDPreFix].length > 0) {
            index = i;
            //david add
            //NSString *strSerialNumber = [notification userInfo][ORSConnectedSerialPortsKey];
            //[self getChargeValue:(int)index];
            [_arrSNView[i].editFSN setStringValue:strSerialNumber];
            if ([[_arrSNView[i].editStatus stringValue] isEqualToString:@"Testing"]) {
                bTesting = YES;
                break;
            }
            
            //            for (int j = 0; j < 4; j++) {
            //                [self callHIDControlAppTool];
            //            }
            
            [NSThread sleepForTimeInterval:1.8f];
            
            NSMutableArray *arrayData = _arrMatchFixtureAndModem;
            NSDictionary *item = [_arrMatchFixtureAndModem objectAtIndex:i];
            NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
            NSString *strDUTName = [self getModemPortName:strLIDPreFix];
            [newItem setObject:strDUTName forKey:@"DUTPort"];
            [arrayData setObject:newItem atIndexedSubscript:index];
            
            break;
        }
    }
    
    if (!bTesting && (index >= 0) /*&& _bApproveTest[index]*/)
    {
        if ([self getQuerySFCON]) {
            NSString *strSN = [notification userInfo][ORSConnectedSerialPortsSerialNumberKey];
            NSString *strParam = [NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&tsid=%@&p=UNIT_PROCESS_CHECK", strSN, _strStationID];
            NSString *strReturn = [self sendRequestSync:_strSFCUrl withParam:strParam TimeOut:10.0f];
            
            if ([strReturn length] > 0) {
                NSString *strTmp = [self getData:strReturn startSet:@"unit_process_check=" endSet:nil];
                if([strTmp rangeOfString:@"OK"].length > 0) {
                    [self startTestWithIndex:index];
                } else {
                    [_tabViewController.arrTableView[index] showAlertView:strTmp];
                    //                    [self showAlertViewWarning:strTmp];
                    //                    [snViewTmp.editInputFSN setStringValue:@""];
                }
            }
        }
        else
        {
            [self startTestWithIndex:index];
        }
    }
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    //    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

#pragma mark --
- (BOOL)callHIDControlAppTool
{
    NSTask *task;
    task = [[NSTask alloc] init];
    
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"HID_ControlApp" ofType:@""];
    [task setLaunchPath:path];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString* aStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    [NSThread sleepForTimeInterval:0.2f];
    
    if ([aStr isEqualToString:@"ERROR: No Widget found!\n"])
    {
        //[self showAlertViewWarning:@"ERROR: No Widget found!"];
        return false;
    }
    else
    {
        return true;
    }
}

- (BOOL)isExistModemPort:(NSString *)strModemPort
{
    BOOL bRet = NO;
    kern_return_t			kernResult;
    CFMutableDictionaryRef	classToMatch;//可变字典
    io_iterator_t	serialPortIterator;
    io_object_t		modemService;
    //IOServiceMatching是设置字典中键的值
    classToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    
    if(classToMatch == NULL){
        NSLog(@"IOServiceMatching return null dictionary.");
    } else {
        //CFDictionarySetValue该方法是替换字典中的键值，classToMatch代表要替换键值的字典
        CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDModemType));
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &serialPortIterator);
    
    if(KERN_SUCCESS != kernResult){
        //NSLog(@"IOServiceGetMatchingServices returned %d \n", kernResult);
    }
    // get device path
    while ((modemService = IOIteratorNext(serialPortIterator))) {
        CFTypeRef	bsdPathAsCFString;
        
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIODialinDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (bsdPathAsCFString) {
            NSString *str = [NSString stringWithFormat:@"%@", bsdPathAsCFString];
            
            if ([str rangeOfString:strModemPort].length > 0) {
                bRet = YES;
            }
            CFRelease(bsdPathAsCFString);
        }
    }
    
    IOObjectRelease(modemService);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
    return bRet;
}

- (BOOL)OpenModemPort:(int)index
{
    if (_arrCommDUT[index] != nil) {
        int times = 0;
        
        while (times < 30) {
            //[self callHIDControlAppTool];
            
            if ([self isExistModemPort:[_arrMatchFixtureAndModem[index] objectForKey:@"DUTPort"]/*_arrayDUTs[index]*/])
            {
                if ([self initDUTDevice:index]) {
                    return YES;
                }
            }
            times++;
            
            [NSThread sleepForTimeInterval:0.2f];
        }
    }
    
    return NO;
}
@end
