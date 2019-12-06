//
//  TableViewController.h
//  NationalTest
//
//  Created by jason on 15-3-30.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AlertView.h"

@interface TableViewController : NSView
{
    NSScrollView *_scrollViewContainer;
    NSTableView *_listView;
    
    NSMutableArray *_listData;
    
    BOOL _fSelected;
    NSMutableArray *_arraySelectedPara;
    
    BOOL _fAmplify;
    
    NSTextField *_lbIndex;
}

@property (retain, nonatomic) NSMutableArray *listData;
@property (retain, nonatomic) NSTableView *listView;
@property (retain, nonatomic) NSScrollView *scrollViewContainer;
@property (assign, nonatomic) BOOL fSelected;
@property (retain, nonatomic) NSMutableArray *arraySelectedPara;
@property AlertView *alertView;

- (id)initWithFrame:(NSRect)frame index:(int)index;
- (void)setFrame:(NSRect)frame withIndex:(int)index;
- (void)showAlertView:(NSString *)msg;

@end
