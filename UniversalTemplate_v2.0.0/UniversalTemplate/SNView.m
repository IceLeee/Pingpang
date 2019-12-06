//
//  SNView.m
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#import "SNView.h"
#import "RuntimeView.h"
#import "GlobalDef.h"

NSString* const MESSAGE_INPUTSN = @"MESSAGE_INPUTSN";
#define kChargeLabelViewTag     108

@implementation SNView

- (id)initWithFrame:(NSRect)frame index:(int)index
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initFrameBox];
        [self initIndexLabel:index];
        //[self initInputFSNView];
        [self initFSNLabel];
        [self initFSNView];
        [self initStatusEditFixture];
        [self initRuntimeView];
        [self initChargeLabel];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)initChargeLabel
{
    //设置Label的Frame
    //NSRect labelFrame = NSMakeRect(40, 470, 290, 25);
    NSRect labelFrame = NSMakeRect(15, 10, SNVIEW_WIDTH - MULTIPLE_NUMBERS*10 - 20, 25);
    //创建一个运行时间标签
    _label = [[NSTextField alloc]initWithFrame:labelFrame];
    [_label setBackgroundColor:[NSColor clearColor]];
    [_label setStringValue:@"Charge-percentage:"];
    [_label setTag:kChargeLabelViewTag];
    [_label setFont:[NSFont systemFontOfSize:12.0]];
    [_label setBordered:NO];
    [_label setEditable:NO];
    [self addSubview:_label];
    //    [label release];
}

- (void)initFrameBox
{
    NSRect boxFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    NSBox *box = [[NSBox alloc]initWithFrame:boxFrame];
    //    [box setTitle:@""];
    //    [box setTitleFont:[NSFont systemFontOfSize:14.0]];
    [box setBoxType:NSBoxCustom];
    [self addSubview:box];
    //    [box release];
}

- (void)initInputFSNView
{
    NSRect textFrame = NSMakeRect(15, 10, SNVIEW_WIDTH - MULTIPLE_NUMBERS*10 - 20, 25);
    _editInputFSN = [[NSTextField alloc] initWithFrame:textFrame];
    [_editInputFSN setAlignment:NSCenterTextAlignment];
    [_editInputFSN setFont:[NSFont systemFontOfSize:16.0]];
    //    [_editInputFSN setStringValue:@"FWYT3HWTH8TT"]; //for test
    [_editInputFSN setDelegate:self];
    [_editInputFSN setEditable:YES];
    [self addSubview:_editInputFSN];
}

- (void)initFSNLabel
{
    //设置Label的Frame
    NSRect labelFrame = NSMakeRect(15, 40, 40, 25);
    
    //创建一个运行时间标签
    NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setStringValue:@"SN:"];
    [label setFont:[NSFont systemFontOfSize:14.0]];
    [label setBordered:NO];
    [label setEditable:NO];
    [self addSubview:label];
    //    [label release];
}

- (void)initFSNView
{
    NSRect textFrame = NSMakeRect(57, 40, SNVIEW_WIDTH - MULTIPLE_NUMBERS*10 - 20, 25);
    _editFSN = [[NSTextField alloc] initWithFrame:textFrame];
    [_editFSN setBackgroundColor:[NSColor clearColor]];
    [_editFSN setFont:[NSFont systemFontOfSize:14.0]];
    [_editFSN setAlignment:NSLeftTextAlignment];
    [_editFSN setBordered:NO];
    [_editFSN setEditable:NO];
    
    [self addSubview:_editFSN];
}

- (void)initIndexLabel:(int)index
{
    //设置Label的Frame
    NSRect labelFrame = NSMakeRect(SNVIEW_WIDTH - 40, 60, 40, 40);
    
    //创建一个运行时间标签
    NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setTextColor:[NSColor purpleColor]];
    [label setStringValue:[NSString stringWithFormat:@"%d", index+1]];
    [label setFont:[NSFont systemFontOfSize:40.0]];
    [label setBordered:NO];
    [label setEditable:NO];
    [self addSubview:label];
    //    [label release];
}

- (void)initStatusEditFixture
{
    //设置Edit的Frame
    NSRect editFrame = NSMakeRect(15, 65, 200 - MULTIPLE_NUMBERS*20, 38);
    
    _editStatus = [[NSTextField alloc]initWithFrame:editFrame];
    [_editStatus setStringValue:@"Wait"];
    [_editStatus setBackgroundColor:[NSColor lightGrayColor]];
    [_editStatus setAlignment:NSCenterTextAlignment];
    _editStatus.textColor = [NSColor whiteColor];
    [_editStatus setFont:[NSFont boldSystemFontOfSize:30.0]];
    [_editStatus setBordered:YES];
    [_editStatus setEditable:NO];
    [self addSubview:_editStatus];
    //[edit release];
}

- (void)initRuntimeView
{
    NSRect timeFrame = NSMakeRect(240 - MULTIPLE_NUMBERS*25, 70, 80, 36);
    _timeView = [[RuntimeView alloc] initWithFrame:timeFrame];
    [self addSubview:_timeView];
    [_timeView createRuntime]; //添加创建
}

#pragma mark -
#pragma mark NSTextField Delegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        NSTextField *edit = (NSTextField*)control;
        //sn位数
        if ([[edit stringValue] length] == SN_LENGTH) {
            //            NSString *strSN = [edit stringValue];
            //            [_editFSN setStringValue:strSN];
            //            [edit setStringValue:@""];
            [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_INPUTSN
                                                                object:self
                                                              userInfo:nil];
            result = YES;
        } else {
            [edit setStringValue:@""];
            result = YES;
        }
    }
    
    return result;
}

- (void)setTestState:(int)iState
{
    switch (iState) {
        case 0:
            [_editStatus setStringValue:@"Wait"];
            [_editStatus setBackgroundColor:[NSColor lightGrayColor]];
            break;
        case 1:
            [_editStatus setStringValue:@"Testing"];
            [_editStatus setBackgroundColor:[NSColor yellowColor]];
            break;
        case 2:
            [_editStatus setStringValue:@"Pass"];
            [_editStatus setBackgroundColor:[NSColor greenColor]];
            break;
        case 3:
            [_editStatus setStringValue:@"Fail"];
            [_editStatus setBackgroundColor:[NSColor redColor]];
            break;
            
        default:
            break;
    }
}

- (void)setRuntime:(BOOL)bState
{
    if (bState) {
        [_timeView startRuntime];
    } else {
        [_timeView stopRuntime];
    }
}

@end
