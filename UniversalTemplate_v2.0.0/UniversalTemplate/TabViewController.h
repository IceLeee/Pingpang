//
//  TabViewController.h
//  NationalTest
//
//  Created by Jason liang on 15-4-2.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableViewController.h"
#import "MessageTextView.h"
#import "SettingsView.h"
#import "TableViews.h"
#import "MessageViews.h"

@interface TabViewController : NSView
{
    NSScrollView *_scrollViewContainer;
    MessageTextView *_messageTextView;
    //    NSSegmentedControl *_segmentedController;
    
    TableViews *_tableViews;
    MessageViews *_messageViews;
    NSView *_settingsViews;
    
    NSMutableArray <TableViewController *> *_arrTableView;
    NSMutableArray <MessageTextView *> *_arrMessageView;
    //    NSMutableArray <SettingsView *> *_arrSettingView;
    
    //    TableViewController *_tableView1;
    //    MessageTextView *_messageTextView1;
    SettingsView *_settingsView1;
}

@property NSMutableArray <TableViewController *> *arrTableView;
@property NSMutableArray <MessageTextView *> *arrMessageView;
//@property NSMutableArray <SettingsView *> *arrSettingView;

//@property (retain, nonatomic) TableViewController *tableView1;
//@property (retain, nonatomic) MessageTextView *messageTextView1;
@property (retain, nonatomic) SettingsView *settingsView1;

@property (retain, nonatomic) TableViews *tableViews;
@property (retain, nonatomic) MessageViews *messageViews;
@property (retain, nonatomic) NSView *settingsViews;

@end
