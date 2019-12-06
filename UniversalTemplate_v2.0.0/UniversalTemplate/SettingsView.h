//
//  SettingsView.h
//  PCM0
//
//  Created by Jason liang on 17/3/23.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsView : NSView
{
#if DUT_TEST == 1
    NSMutableArray *_arrayDUTSerials;
    NSMutableArray <NSComboBox *> *_arrComboBoxDUT;
#endif
    
#if FIXTURE_TEST == 1
    NSMutableArray *_arrayFIXTURESerials;
    NSMutableArray <NSComboBox *> *_arrComboBoxFIXTURE;
#endif
    
#if INST_TEST == 1
    NSMutableArray *_arrayInstDevices;
    NSMutableArray <NSComboBox *> *_arrComboBoxINST;
#endif
    
    //    NSComboBox *_comboBoxDUT;
#if INSTANT_PUDDING == 1
    NSButton *_scPudding;
    NSButton *_scAuditMode;
#endif
    
    NSButton *_rdModeR;
    NSButton *_rdModeL;
    
    BOOL _bPudding;
    BOOL _bAuditMode;
    NSString *_strMode;
    
    NSButton *_btnSave;
}

@end
