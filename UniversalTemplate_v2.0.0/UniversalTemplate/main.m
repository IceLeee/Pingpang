//
//  main.m
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        id delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        NSApplicationMain(argc, argv);
        return 0;
    }
}
