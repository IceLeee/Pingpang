//
//  SNView.h
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class RuntimeView;

@interface SNView : NSView
{
    NSTextField *_editInputFSN;
    NSTextField *_editFSN;
    NSTextField *_editStatus;
    RuntimeView *_timeView;
    NSTextField *_label;
    
    int _iTestState; //0:Waiting 1:StartTesting 2:Pass 3:Fail
}

@property(nonatomic, retain) NSTextField* editInputFSN;
@property(nonatomic, retain) NSTextField* editFSN;
@property(nonatomic, retain) NSTextField* editStatus;
@property(nonatomic, retain) NSTextField* label;

- (id)initWithFrame:(NSRect)frame index:(int)index;
- (void)setTestState:(int)iState;
- (void)setRuntime:(BOOL)bState;

@end
