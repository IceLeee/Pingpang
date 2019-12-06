//
//  AlertView.m
//  ApplicationTest
//
//  Created by macEnics on 2017/12/12.
//  Copyright © 2017年 Char.Wang. All rights reserved.
//

#import "AlertView.h"

@implementation AlertView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor controlColor] CGColor];
        [self initText];
        [self initButton];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawBorder:dirtyRect];
    // Drawing code here.
}

-(void)drawBorder:(NSRect)rect
{
    // NSRect rect = [self bounds];
    NSRect frameRect = [self bounds];
    if(rect.size.height < frameRect.size.height)
        return;
    NSRect newRect = NSMakeRect(rect.origin.x+2, rect.origin.y+2, rect.size.width-3, rect.size.height-3);
    NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:10 yRadius:10];
    [textViewSurround setLineWidth:1];
    [[NSColor blackColor] set];
    [textViewSurround stroke];
}

- (void)initText
{
    _tfText = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 40, self.frame.size.width - 40, 55)];
    _tfText.bordered = NO;
    _tfText.selectable = NO;
    _tfText.backgroundColor = [NSColor controlColor];
    _tfText.stringValue = @"asdfghjksdfhjdfhjk";
    _tfText.font = [NSFont boldSystemFontOfSize:12];
    
    [self addSubview:_tfText];
}

- (void)initButton
{
    NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(self.frame.size.width - 100, 10, 80, 30)];
    btn.bezelStyle = NSRegularSquareBezelStyle;
    btn.title = @"OK";
    btn.target = self;
    btn.action = @selector(buttonAction:);
    
    [self addSubview:btn];
}

- (void)buttonAction:(NSButton *)sender
{
    self.hidden = YES;
    _bAlert = NO;
}

- (void)showAlertWarning:(NSString *)strMsg
{
    _tfText.stringValue = strMsg;
}
@end
