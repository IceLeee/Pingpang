//
//  AppDelegate.m
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import "AppDelegate.h"
#import "GlobalDef.h"
#import "MainView.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //create the main window
    NSRect rect = NSMakeRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    NSUInteger uiStyle = NSTitledWindowMask | NSClosableWindowMask;
    NSBackingStoreType backingStoreStyle = NSBackingStoreBuffered;
    
    _window = [[NSWindow alloc] initWithContentRect:rect styleMask:uiStyle backing:backingStoreStyle defer:NO];
    //    [_window setTitle:@"SerialCommTool V2.1.6"];
    
    //create the main view
    _mainView = [[MainView alloc] initWithFrame:rect];
    [[_window contentView] addSubview:_mainView];
    
//    [_window setLevel:1];
    [_window makeKeyAndOrderFront:self];
    [_window makeMainWindow];
    [_window center];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    if (_mainView) {
        [_mainView close];
    }
    
    return YES;
}

@end
