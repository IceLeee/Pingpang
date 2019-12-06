//
//  AlertWindowController.m
//  GrapeCoexApp
//
//  Created by jason on 14-11-26.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "AlertWindowController.h"

#define kConfirmButtonTag   500

@interface AlertWindowController ()

@end

@implementation AlertWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
//    [self initConfirmButton];
}

- (void)initConfirmButton
{
    //设置button的Frame
    NSRect btnFrame = NSMakeRect(360, 20, 90, 36);
    
    //创建一个设置按钮
    NSButton *btn = [[NSButton alloc]initWithFrame:btnFrame];
    [btn setBezelStyle:NSRoundedBezelStyle];
    [btn setTitle:@"OK"];
    [btn setFont:[NSFont systemFontOfSize:14.0]];
    [btn setTag:kConfirmButtonTag];
    [btn setTarget:self];
    [btn setAction:@selector(buttonAction:)];
    [[self.window contentView] addSubview:btn];
    //    [btn release];
}

- (void)confirmButtonAction
{
    NSButton *btn = (NSButton *)[[self.window contentView] viewWithTag:kConfirmButtonTag];
    [btn performClick:btn];
}

- (void)buttonAction:(id)sender
{
    int tag = 0;
    NSButton *button = (NSButton *)sender;
	tag = (int)button.tag;
    
    if (tag == kConfirmButtonTag) {
        [NSApp stopModalWithCode:1];
        [[self window] close];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    [NSThread sleepForTimeInterval:1.0f];
    [NSApp stopModalWithCode:1];
    [[self window] close];
    [[self window] orderOut:nil];
    return TRUE;
    
}
@end
