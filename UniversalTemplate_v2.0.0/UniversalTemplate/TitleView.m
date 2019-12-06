//
//  TitleView.m
//  NationalTest
//
//  Created by jason on 15-3-30.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "TitleView.h"

@implementation TitleView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        [self initPropertyFile];
        [self initTitleBox];
        [self initTitleLabel];
        [self initSubTitleLabel];
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

- (void)initPropertyFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TestConfig" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    _strSWVersion = [dict objectForKey:@"SW_Version"];
}

- (void)initTitleBox
{
    NSRect boxFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    NSBox *box = [[NSBox alloc]initWithFrame:boxFrame];
    //    [box setTitle:@""];
    //    [box setTitleFont:[NSFont systemFontOfSize:14.0]];
    [box setBoxType:NSBoxCustom];
    
    NSImageView *imgView = [[NSImageView alloc] init];
    [imgView setImage:[NSImage imageNamed:@"background.jpg"]];
    [imgView setImageScaling:NSImageScaleAxesIndependently];
    box.contentView = imgView;
    
    [self addSubview:box];
    //    [box release];
}

- (void)initTitleLabel
{
    //设置Label的Frame
    NSRect labelFrame = NSMakeRect(0, 20, self.frame.size.width - 20, 36);
    
    //创建一个运行时间标签
    NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setAlignment:NSCenterTextAlignment];
//    [label setStringValue:@"H16/H17 ShippingSettings Dev Fused Test Station"];
    [label setStringValue:@"PingPong Test Station"];
    [label setFont:[NSFont systemFontOfSize:28.0]];
    [label setTextColor:[NSColor blueColor]];
    [label setBordered:NO];
    [label setEditable:NO];
    [self addSubview:label];
    //    [label release];
}

- (void)initSubTitleLabel
{
    //设置Label的Frame
    NSRect labelFrame = NSMakeRect(0, 60, self.frame.size.width - 20, 30);
    
    //创建一个运行时间标签
    NSTextField *label = [[NSTextField alloc]initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setAlignment:NSRightTextAlignment];
    [label setStringValue:[NSString stringWithFormat:@"---- By Luxshare ICT SW,  Version:%@", _strSWVersion]];
    [label setFont:[NSFont systemFontOfSize:18.0]];
    [label setTextColor:[NSColor blueColor]];
    [label setBordered:NO];
    [label setEditable:NO];
    [self addSubview:label];
    //    [label release];
}
@end
