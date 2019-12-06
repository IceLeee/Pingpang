//
//  SettingsView.m
//  PCM0
//
//  Created by Jason liang on 17/3/23.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import "SettingsView.h"

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/serial/ioss.h>
#include <IOKit/IOBSD.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#import <VISA/VISA.h>

NSString* const MESSAGE_SAVESETTING = @"MESSAGE_SAVESETTING";

@implementation SettingsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
#if DUT_TEST == 1
        _arrayDUTSerials = [[NSMutableArray alloc] initWithCapacity:3];
        _arrComboBoxDUT = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
#if FIXTURE_TEST == 1
        _arrayFIXTURESerials = [[NSMutableArray alloc] initWithCapacity:3];
        _arrComboBoxFIXTURE = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
#if INST_TEST == 1
        _arrayInstDevices = [[NSMutableArray alloc] initWithCapacity:3];
        _arrComboBoxINST = [[NSMutableArray alloc] initWithCapacity:4];
#endif
        
        [self initPropertyFile];
        [self initAllControllers];
        [self initDefaultStatus];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)initPropertyFile
{
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"TestConfig" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSLog(@"dict = %@", dict);
    
#if DUT_TEST == 1
    _arrayDUTSerials = [dict objectForKey:@"DUTPorts"];
#endif

#if FIXTURE_TEST == 1
    _arrayFIXTURESerials = [dict objectForKey:@"FIXTUREPorts"];
#endif
    
#if INST_TEST == 1
    _arrayInstDevices = [dict objectForKey:@"InstPorts"];
#endif
    
#if INSTANT_PUDDING == 1
    _bPudding = [[dict objectForKey:@"Pudding"] boolValue];
    _bAuditMode = [[dict objectForKey:@"Audit"] boolValue];
#endif
    //    _strMode = [dict objectForKey:@"Mode"];
}

- (void)initAllControllers
{
    [self initFrameBox];
#if DUT_TEST == 1
    [self initDUTPortsLabel];
    [self initDUTsComboBox];
#endif
    
#if FIXTURE_TEST == 1
    [self initFIXTUREPortsLabel];
    [self initFIXTUREsComboBox];
#endif
    
#if INST_TEST == 1
    [self initInstPortsLabel];
    [self initInstsComboBox];
#endif
    
#if INSTANT_PUDDING == 1
    [self initCheckPuddingButton];
    [self initAuditModeButton];
#endif
    
    //    [self initModeRRadioButton];
    //    [self initModeLRadioButton];
    [self initSaveButton];
}

- (void)initDefaultStatus
{
#if INSTANT_PUDDING == 1
    [_scPudding setState:_bPudding];
    [_scAuditMode setState:_bAuditMode];
#endif

//    if ([_strMode isEqualToString:@"R"]) {
//        [_rdModeR setState:1];
//        [_rdModeL setState:0];
//    } else if ([_strMode isEqualToString:@"L"]) {
//        [_rdModeR setState:0];
//        [_rdModeL setState:1];
//    }
}

- (void)initFrameBox
{
    NSRect boxFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    NSBox *box = [[NSBox alloc]initWithFrame:boxFrame];
    //    [box setTitle:@""];
    //    [box setTitleFont:[NSFont systemFontOfSize:14.0]];
    [box setBoxType:NSBoxCustom];
    [self addSubview:box];
    //    [box release];
}

#if DUT_TEST == 1
- (void)initDUTPortsLabel
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置Label的Frame
        NSRect labelFrame = NSMakeRect(20, (20 + i*50), 60, 25);
        
        //创建一个运行时间标签
        NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setStringValue:[NSString stringWithFormat:@"DUT%d:", i+1]];
        [label setFont:[NSFont systemFontOfSize:18.0f]];
        [label setBordered:NO];
        [label setEditable:NO];
        [self addSubview:label];
        //    [label release];
    }
}

- (void)initDUTsComboBox
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置comboBox的Frame
        NSRect comboFrame = NSMakeRect(85, (18 + i*50), 250, 26);
        
        _arrComboBoxDUT[i] = [[NSComboBox alloc] initWithFrame:comboFrame];
        
        if ([_arrayDUTSerials count] > i)
            [_arrComboBoxDUT[i].cell setTitle:_arrayDUTSerials[i]];
        
        [_arrComboBoxDUT[i] setUsesDataSource:YES];
        [_arrComboBoxDUT[i] setDataSource:self];
        [_arrComboBoxDUT[i] setDelegate:self];
        [_arrComboBoxDUT[i] setEditable:YES];
        
        [self addSubview:_arrComboBoxDUT[i]];
        //[comboBox release];
    }
}
#endif

#if FIXTURE_TEST == 1
- (void)initFIXTUREPortsLabel
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置Label的Frame
        NSRect labelFrame = NSMakeRect(380, (20 + i*50), 120, 25);
        
        //创建一个运行时间标签
        NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setStringValue:[NSString stringWithFormat:@"FIXTURE%d:", i+1]];
        [label setFont:[NSFont systemFontOfSize:18.0f]];
        [label setBordered:NO];
        [label setEditable:NO];
        [self addSubview:label];
        //    [label release];
    }
}

- (void)initFIXTUREsComboBox
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置comboBox的Frame
        NSRect comboFrame = NSMakeRect(475, (18 + i*50), 250, 26);
        
        _arrComboBoxFIXTURE[i] = [[NSComboBox alloc] initWithFrame:comboFrame];
        
        if ([_arrayFIXTURESerials count] > i)
            [_arrComboBoxFIXTURE[i].cell setTitle:_arrayFIXTURESerials[i]];
        
        [_arrComboBoxFIXTURE[i] setUsesDataSource:YES];
        [_arrComboBoxFIXTURE[i] setDataSource:self];
        [_arrComboBoxFIXTURE[i] setDelegate:self];
        [_arrComboBoxFIXTURE[i] setEditable:YES];
        
        [self addSubview:_arrComboBoxFIXTURE[i]];
        //[comboBox release];
    }
}
#endif

#if INST_TEST == 1
- (void)initInstPortsLabel
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置Label的Frame
        NSRect labelFrame = NSMakeRect(800, (20 + i*50), 60, 25);
        
        //创建一个运行时间标签
        NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setStringValue:[NSString stringWithFormat:@"Inst%d:", i+1]];
        [label setFont:[NSFont systemFontOfSize:18.0f]];
        [label setBordered:NO];
        [label setEditable:NO];
        [self addSubview:label];
        //    [label release];
    }
}

- (void)initInstsComboBox
{
    for (int i = 0; i < MULTIPLE_NUMBERS; i++) {
        //设置comboBox的Frame
        NSRect comboFrame = NSMakeRect(855, (18 + i*50), 250, 26);
        
        _arrComboBoxINST[i] = [[NSComboBox alloc] initWithFrame:comboFrame];
        
        if ([_arrayInstDevices count] > i)
            [_arrComboBoxINST[i].cell setTitle:_arrayInstDevices[i]];
        
        [_arrComboBoxINST[i] setUsesDataSource:YES];
        [_arrComboBoxINST[i] setDataSource:self];
        [_arrComboBoxINST[i] setDelegate:self];
        [_arrComboBoxINST[i] setEditable:YES];
        
        [self addSubview:_arrComboBoxINST[i]];
        //[comboBox release];
    }
}
#endif

#if INSTANT_PUDDING == 1
- (void)initCheckPuddingButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(20, 220, 120, 26);;
    
    //创建一个设置按钮
    _scPudding = [[NSButton alloc]initWithFrame:btnFrame];
    [_scPudding setButtonType:NSSwitchButton];
    [_scPudding setTitle:@"Pudding"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_scPudding setFont:[NSFont systemFontOfSize:14.0]];
    [_scPudding setTarget:self];
    [self addSubview:_scPudding];
    //    [btn release];
}

- (void)initAuditModeButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(380, 220, 120, 26);
    
    //创建一个设置按钮
    _scAuditMode = [[NSButton alloc]initWithFrame:btnFrame];
    [_scAuditMode setButtonType:NSSwitchButton];
    [_scAuditMode setTitle:@"AuditMode"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_scAuditMode setFont:[NSFont systemFontOfSize:14.0]];
    [_scAuditMode setTarget:self];
    [self addSubview:_scAuditMode];
    //    [btn release];
}
#endif

- (void)initModeRRadioButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(20, 260, 80, 26);
    
    //创建一个设置按钮
    _rdModeR = [[NSButton alloc]initWithFrame:btnFrame];
    [_rdModeR setButtonType:NSRadioButton];
    [_rdModeR setTitle:@"R Mode"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_rdModeR setFont:[NSFont systemFontOfSize:14.0]];
    [_rdModeR setTarget:self];
    [_rdModeR setAction:@selector(buttonAction:)];
    [self addSubview:_rdModeR];
    //    [btn release];
}

- (void)initModeLRadioButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(160, 260, 80, 26);
    
    //创建一个设置按钮
    _rdModeL = [[NSButton alloc]initWithFrame:btnFrame];
    [_rdModeL setButtonType:NSRadioButton];
    [_rdModeL setTitle:@"L Mode"];
    //    [_rdWorkCenter setAlignment:NSRightTextAlignment];
    [_rdModeL setFont:[NSFont systemFontOfSize:14.0]];
    [_rdModeL setTarget:self];
    [_rdModeL setAction:@selector(buttonAction:)];
    [self addSubview:_rdModeL];
    //    [btn release];
}

- (void)initSaveButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(self.frame.size.width - 140, 258, 100, 32);
    
    //创建一个设置按钮
    _btnSave = [[NSButton alloc]initWithFrame:btnFrame];
    [_btnSave setBezelStyle:NSRegularSquareBezelStyle];
    [_btnSave setTitle:@"Save"];
    [_btnSave setFont:[NSFont systemFontOfSize:18.0]];
    [_btnSave setTarget:self];
    [_btnSave setAction:@selector(buttonAction:)];
    [self addSubview:_btnSave];
    //[btn release];
}

#pragma mark -
#pragma mark NSTableViewDataSource Delegate
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
#if DUT_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxDUT) {
        if (tmp == aComboBox) {
            return [_arrayDUTSerials count];
        }
    }
#endif
    
#if FIXTURE_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxFIXTURE) {
        if (tmp == aComboBox) {
            return [_arrayFIXTURESerials count];
        }
    }
#endif
    
#if INST_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxINST) {
        if (tmp == aComboBox) {
            return [_arrayInstDevices count];
        }
    }
#endif
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    NSString *strRet = nil;
    
#if DUT_TEST == 1
    for (int i = 0; i < [_arrComboBoxDUT count]; i++) {
        if (aComboBox == _arrComboBoxDUT[i]) {
            if ([_arrayDUTSerials count] > index) {
                strRet = [_arrayDUTSerials objectAtIndex:index];
                break;
            }
        }
    }
#endif
    
#if FIXTURE_TEST == 1
    for (int i = 0; i < [_arrComboBoxFIXTURE count]; i++) {
        if (aComboBox == _arrComboBoxFIXTURE[i]) {
            if ([_arrayFIXTURESerials count] > index) {
                strRet = [_arrayFIXTURESerials objectAtIndex:index];
                break;
            }
        }
    }
#endif
    
#if INST_TEST == 1
    for (int i = 0; i < [_arrComboBoxINST count]; i++) {
        if (aComboBox == _arrComboBoxINST[i]) {
            if ([_arrayInstDevices count] > index) {
                strRet = [_arrayInstDevices objectAtIndex:index];
                break;
            }
        }
    }
#endif
    
    return strRet;
}

- (void)comboBoxWillPopUp:(NSNotification *)notification
{
    NSComboBox *aComboBox = (NSComboBox *)notification.object;
    
#if DUT_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxDUT) {
        if (tmp == aComboBox) {
            [self searchDUTPorts];
            break;
        }
    }
#endif
    
#if FIXTURE_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxFIXTURE) {
        if (tmp == aComboBox) {
            [self searchFIXTUREPorts];
            break;
        }
    }
#endif
    
#if INST_TEST == 1
    for (NSComboBox *tmp in _arrComboBoxINST) {
        if (tmp == aComboBox) {
            [self searchInstPorts];
            break;
        }
    }
#endif
}

#pragma mark --
- (void)buttonAction:(id)sender
{
    NSButton *button = (NSButton *)sender;
    
    if (button == _btnSave) {
#if DUT_TEST == 1
        NSMutableArray *comboBoxDUTs = [[NSMutableArray alloc] initWithCapacity:4];
        for (int i = 0; i < [_arrComboBoxDUT count]; i++) {
            NSCell *comboBoxDUTsCell = _arrComboBoxDUT[i].cell;
            if ([comboBoxDUTsCell.title length] > 0) {
                [comboBoxDUTs addObject:comboBoxDUTsCell.title];
            }
        }
#endif
        
#if FIXTURE_TEST == 1
        NSMutableArray *comboBoxFIXTUREs = [[NSMutableArray alloc] initWithCapacity:4];
        for (int i = 0; i < [_arrComboBoxFIXTURE count]; i++) {
            NSCell *comboBoxFIXTUREsCell = _arrComboBoxFIXTURE[i].cell;
            if ([comboBoxFIXTUREsCell.title length] > 0) {
                [comboBoxFIXTUREs addObject:comboBoxFIXTUREsCell.title];
            }
        }
#endif
        
#if INST_TEST == 1
        NSMutableArray *comboBoxInsts = [[NSMutableArray alloc] initWithCapacity:4];
        for (int i = 0; i < [_arrComboBoxINST count]; i++) {
            NSCell *comboBoxInstsCell = _arrComboBoxINST[i].cell;
            if ([comboBoxInstsCell.title length] > 0) {
                [comboBoxInsts addObject:comboBoxInstsCell.title];
            }
        }
#endif
        
        NSMutableArray *comboBoxAll = [[NSMutableArray alloc] initWithCapacity:4];
#if DUT_TEST == 1
        [comboBoxAll addObjectsFromArray:comboBoxDUTs];
#endif

#if FIXTURE_TEST == 1
        [comboBoxAll addObjectsFromArray:comboBoxFIXTUREs];
#endif
        
#if INST_TEST == 1
        [comboBoxAll addObjectsFromArray:comboBoxInsts];
#endif
        
        NSSet *set = [NSSet setWithArray:comboBoxAll];
        NSLog(@"set allObjects%@",[set allObjects]);
        
#if ((DUT_TEST == 1) && (FIXTURE_TEST == 1)) && ((INST_TEST == 1) && (NI_VISA == 1))
        if (([comboBoxFIXTUREs count] + [comboBoxDUTs count] + [comboBoxInsts count]) != [[set allObjects] count])
#elif ((DUT_TEST == 1) && (FIXTURE_TEST == 1))
        if (([comboBoxFIXTUREs count] + [comboBoxDUTs count]) != [[set allObjects] count])
#elif (DUT_TEST == 1)
        if (([comboBoxDUTs count]) != [[set allObjects] count])
#elif ((INST_TEST == 1) && (NI_VISA == 1))
        if (([comboBoxInsts count]) != [[set allObjects] count])
#endif
        {
            [self showAlertViewWarning:@"Do not set repeats!\n请勿设置重复项!"];
            return;
        }
        
        [self saveSettings];
    }
    //    else if (button == _rdModeR) {
    //        [_rdModeR setState:1];
    //        [_rdModeL setState:0];
    //    } else if (button == _rdModeL) {
    //        [_rdModeL setState:1];
    //        [_rdModeR setState:0];
    //    }
}

- (void)saveSettings
{
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"TestConfig" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    //    NSMutableArray *comboBoxDUTs = [[NSMutableArray alloc] initWithCapacity:2];
    //    for (int i = 0; i < [_arraySerials count]; i++) {
    //        [comboBoxDUTs addObject:_arraySerials[i]];
    //    }
    //    [dict setValue:comboBoxDUTs forKey:@"DUTPorts"];
    
#if DUT_TEST == 1
    NSMutableArray *comboBoxDUTs = [[NSMutableArray alloc] initWithCapacity:2];
    for (int i = 0; i < [_arrComboBoxDUT count]; i++) {
        NSCell *comboBoxDUTsCell = _arrComboBoxDUT[i].cell;
        if ([comboBoxDUTsCell.title length] > 0) {
            [comboBoxDUTs addObject:comboBoxDUTsCell.title];
            //            break;
        }
    }
    
    [dict setValue:comboBoxDUTs forKey:@"DUTPorts"];
#endif
    
#if FIXTURE_TEST == 1
    NSMutableArray *comboBoxFIXTUREs = [[NSMutableArray alloc] initWithCapacity:2];
    for (int i = 0; i < [_arrComboBoxFIXTURE count]; i++) {
        NSCell *comboBoxFIXTUREsCell = _arrComboBoxFIXTURE[i].cell;
        if ([comboBoxFIXTUREsCell.title length] > 0) {
            [comboBoxFIXTUREs addObject:comboBoxFIXTUREsCell.title];
            //            break;
        }
    }
    
    [dict setValue:comboBoxFIXTUREs forKey:@"FIXTUREPorts"];
#endif
    
#if (INST_TEST == 1) && (NI_VISA == 1)
    NSMutableArray *comboBoxInsts = [[NSMutableArray alloc] initWithCapacity:2];
    for (int i = 0; i < [_arrComboBoxINST count]; i++) {
        NSCell *comboBoxInstsCell = _arrComboBoxINST[i].cell;
        if ([comboBoxInstsCell.title length] > 0) {
            [comboBoxInsts addObject:comboBoxInstsCell.title];
            //            break;
        }
    }
    
    [dict setValue:comboBoxInsts forKey:@"InstPorts"];
#endif
    
#if INSTANT_PUDDING == 1
    if ([_scPudding state] == 1) {
        _bPudding = YES;
    } else {
        _bPudding = NO;
    }

    [dict setValue:[NSNumber numberWithBool:_bPudding] forKey:@"Pudding"];

    if ([_scAuditMode state] == 1) {
        _bAuditMode = YES;
    } else {
        _bAuditMode = NO;
    }

    [dict setValue:[NSNumber numberWithBool:_bAuditMode] forKey:@"Audit"];
#endif
    
    //    if ([_rdModeR state] == 1) {
    //        _strMode = @"R";
    //    } else {
    //        _strMode = @"L";
    //    }
    //
    //    [dict setValue:_strMode forKey:@"Mode"];
    
    
    //写入plist文件
    if ([dict writeToFile:path atomically:YES]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_SAVESETTING
                                                            object:self
                                                          userInfo:nil];
        [self showAlertViewWarning:@"保存成功!"];
    }
}

#pragma mark -
-(int)enumUSBModemPorts:(NSMutableArray *)array
{
    kern_return_t			kernResult;
    CFMutableDictionaryRef	classToMatch;
    io_iterator_t	serialPortIterator;
    io_object_t		modemService;
    
    int devicecount = 0;
    
    classToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    
    if(classToMatch == NULL){
        NSLog(@"IOServiceMatching return null dictionary.");
    } else {
        CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &serialPortIterator);
    //	    if (KERN_SUCCESS != kernResult) {
    //	        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    //			continue;
    //	    }
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
            
            //            if ([str rangeOfString:@"/dev/tty.usbserial"].length > 0)
            if ([str rangeOfString:@"usbmodem"].length > 0)
            {
                [array addObject:str];
                devicecount++;
            }
            CFRelease(bsdPathAsCFString);
        }
    }
    
    IOObjectRelease(modemService);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
    return devicecount;
}

-(int)enumUSBPorts:(NSMutableArray *)array
{
    kern_return_t			kernResult;
    CFMutableDictionaryRef	classToMatch;
    io_iterator_t	serialPortIterator;
    io_object_t		modemService;
    
    int devicecount = 0;
    
    classToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    
    if(classToMatch == NULL){
        NSLog(@"IOServiceMatching return null dictionary.");
    } else {
        CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &serialPortIterator);
    //	    if (KERN_SUCCESS != kernResult) {
    //	        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    //			continue;
    //	    }
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
            
            //            if ([str rangeOfString:@"/dev/tty.usbserial"].length > 0)
            if ([str rangeOfString:@"usb"].length > 0)
            {
                [array addObject:str];
                devicecount++;
            }
            CFRelease(bsdPathAsCFString);
        }
    }
    
    IOObjectRelease(modemService);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
    return devicecount;
}

#if DUT_TEST == 1
- (int)searchDUTPorts
{
    NSMutableArray *comboBoxTmp = [[NSMutableArray alloc] initWithCapacity:2];
    int uartcount = [self enumUSBModemPorts:comboBoxTmp];
    NSLog(@"_comboBoxUART = %@, uartcount = %d", comboBoxTmp, uartcount);
    
    _arrayDUTSerials = comboBoxTmp;
    return uartcount;
}
#endif

#if FIXTURE_TEST == 1
- (int)searchFIXTUREPorts
{
    NSMutableArray *comboBoxTmp = [[NSMutableArray alloc] initWithCapacity:2];
    int uartcount = [self enumUSBPorts:comboBoxTmp];
    NSLog(@"_comboBoxUART = %@, uartcount = %d", comboBoxTmp, uartcount);
    
    _arrayFIXTURESerials = comboBoxTmp;
    return uartcount;
}
#endif

#if INST_TEST == 1
- (int)searchInstPorts
{
    NSMutableArray *comboBoxTmp = [[NSMutableArray alloc] initWithCapacity:2];
    int uartcount = [self enumVisaPorts:comboBoxTmp Type:2];
    NSLog(@"_comboBoxUART = %@, uartcount = %d", comboBoxTmp, uartcount);
    
    _arrayInstDevices = comboBoxTmp;
    return uartcount;
}

- (int)enumVisaPorts:(NSMutableArray *)array Type:(int)iType
{
    int deviceCount = 0;
    
    char instrDescriptor[VI_FIND_BUFLEN];
    ViUInt32 numInstrs;
    ViFindList findList;
    ViSession defaultRM;
    ViStatus status;
    
    status = viOpenDefaultRM (&defaultRM);
    if (status < VI_SUCCESS)
    {
        printf ("Could not open a session to the VISA Resource Manager!\n");
        viClose (defaultRM);
        return status;
    }
    
    if (iType == 0)
        status = viFindRsrc(defaultRM, "USB[0-17]*::?*INSTR", &findList, &numInstrs, instrDescriptor);
    else if (iType == 1)
        status = viFindRsrc(defaultRM, "GPIB[0-17]*::?*INSTR", &findList, &numInstrs, instrDescriptor);
    else
        status = viFindRsrc(defaultRM, "?*INSTR", &findList, &numInstrs, instrDescriptor);
    
    
    if (status < VI_SUCCESS)
    {
        printf ("An error occurred while finding resources.\nHit enter to continue.");
        fflush(stdin);
        viClose (defaultRM);
        return status;
    }
    
    deviceCount = numInstrs;
    
    for (int i = 0; i < numInstrs; i++) {
        printf("%s \n",instrDescriptor);
        //添加设备
        [array addObject:[NSString stringWithFormat:@"%s", instrDescriptor]];
        
        /* stay in this loop until we find all instruments */
        status = viFindNext (findList, instrDescriptor);  /* find next desriptor */
        if (status < VI_SUCCESS)
            break;
    }
    
    status = viClose(findList);
    status = viClose (defaultRM);
    printf ("\nHit enter to continue.");
    fflush(stdin);
    
    return deviceCount;
}
#endif

#pragma mark --
- (void)showAlertViewWarning:(NSString *)strWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:strWarning];
    //[alert setInformativeText:@"Fialed!Please ."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}
@end
