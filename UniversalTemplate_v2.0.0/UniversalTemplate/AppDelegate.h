//
//  AppDelegate.h
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MainView;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    MainView *_mainView;
    NSWindow *_window;
}

@property (readonly) NSWindow *window;

@end

