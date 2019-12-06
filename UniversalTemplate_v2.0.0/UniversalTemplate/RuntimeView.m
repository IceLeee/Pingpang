//
//  RuntimeView.m
//  NationalTest
//
//  Created by Jason liang on 15-4-2.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "RuntimeView.h"

@implementation RuntimeView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _iTimes = 0;
        [self initRuntimeField];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void)initRuntimeField
{
    //设置Label的Frame
    NSRect labelFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    //创建一个运行时间标签
    _timeField = [[NSTextField alloc]initWithFrame:labelFrame];
    [_timeField setBackgroundColor:[NSColor clearColor]];
    [_timeField setStringValue:@"0 s"];
    [_timeField setFont:[NSFont systemFontOfSize:18.0]];
    [_timeField setBordered:NO];
    [_timeField setEditable:NO];
    [self addSubview:_timeField];
    //    [label release];
}

- (void)createRuntime
{
    [NSThread detachNewThreadSelector:@selector(fireTimer) toTarget:self withObject:nil];
}

- (void)destroyRuntime
{
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
        _iTimes = 0;
    }
}

- (void)startRuntime
{
    if ([_timer isValid]) {
        _iTimes = 0;
        _bRunning = YES;
    }
}

- (void)fireTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                              target: self
                                            selector: @selector(handleTimer:)
                                            userInfo: nil
                                             repeats: YES];
    [[NSRunLoop currentRunLoop] run];
}

- (void)stopRuntime
{
    _bRunning = NO;
}

- (void)handleTimer: (NSTimer *)timer
{
    if (_bRunning) {
        _iTimes += timer.timeInterval;
        
        [self performSelectorOnMainThread:@selector(handleRelashSeconds) withObject:nil waitUntilDone:YES];
    }
}

- (void)handleRelashSeconds
{
    [_timeField setStringValue:[NSString stringWithFormat:@"%0.1f s", _iTimes]];
}

@end
