//
//  AlertWindowController.h
//  GrapeCoexApp
//
//  Created by jason on 14-11-26.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AlertWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *alertMessage;

- (BOOL)windowShouldClose:(id)sender;

@end
