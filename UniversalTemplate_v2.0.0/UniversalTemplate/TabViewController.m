//
//  TabViewController.m
//  NationalTest
//
//  Created by Jason liang on 15-4-2.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "TabViewController.h"

@implementation TabViewController

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initTabViewController];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)initTabViewController
{
    NSRect tabFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    //设置TableViews
    _tableViews = [[TableViews alloc] initWithFrame:tabFrame];
    
    //设置MessageViews
    _messageViews = [[MessageViews alloc] initWithFrame:tabFrame];
    
    //设置SettingsViews
    _settingsViews = [[NSView alloc] initWithFrame:tabFrame];
    _settingsView1 = [[SettingsView alloc] initWithFrame:tabFrame];
    [_settingsViews addSubview:_settingsView1];
    
    _arrTableView = [[NSMutableArray alloc] initWithCapacity:4];
    _arrMessageView = [[NSMutableArray alloc] initWithCapacity:4];
    //    _arrSettingView = [[NSMutableArray alloc] initWithCapacity:4];
    
    for (int i = 0; i < MULTIPLE_NUMBERS; i++)
    {
        [self initTableViewsAndMessageViews:i];
    }
    
    
    [self addSubview:_tableViews];
    [self addSubview:_messageViews];
    [self addSubview:_settingsViews];
    
    [_tableViews setHidden:NO];
    [_messageViews setHidden:YES];
    [_settingsViews setHidden:YES];
}

- (void)initTableViewsAndMessageViews:(int)index
{
    NSRect tabFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    TableViewController *tableView = [[TableViewController alloc] initWithFrame:tabFrame index:index];
    
    //    NSRect rect = NSMakeRect(0, index*self.frame.size.height/4, self.frame.size.width, self.frame.size.height/4 - 10);
    NSRect rect = NSMakeRect(5+index*self.frame.size.width/MULTIPLE_NUMBERS, 0, self.frame.size.width/MULTIPLE_NUMBERS-10, self.frame.size.height);
    
    [tableView setFrame:rect withIndex:index];
    //    TableViewController *tableView = [[TableViewController alloc] initWithFrame:rect withIndex:index];
    MessageTextView *messageTextView = [[MessageTextView alloc] initWithFrame:rect];
    
    [_tableViews addSubview:tableView];
    [_messageViews addSubview:messageTextView];
    
    [_arrTableView setObject:tableView atIndexedSubscript:index];
    [_arrMessageView setObject:messageTextView atIndexedSubscript:index];
    
}

@end
