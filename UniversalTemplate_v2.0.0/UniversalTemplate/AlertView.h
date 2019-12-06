//
//  AlertView.h
//  ApplicationTest
//
//  Created by macEnics on 2017/12/12.
//  Copyright © 2017年 Char.Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AlertView : NSView
{
    NSTextField *_tfText;
}

@property BOOL bAlert;
- (void)showAlertWarning:(NSString *)strMsg;
@end
