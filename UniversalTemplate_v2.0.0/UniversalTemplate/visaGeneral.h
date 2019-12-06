//
//  visaGeneral.h
//  visaGeneralTest
//
//  Created by jason on 14-4-11.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VISA/VISA.h>

@interface visaGeneral : NSObject {
    ViSession defaultRM;
    ViSession instr;
    
    float _delay;
    BOOL _fOpen;
}

- (BOOL)open:(NSString *)strName;
- (void)close;
- (BOOL)isOpen;
- (BOOL)write:(NSString*)strCommand;
- (BOOL)read:(NSString **)data;
- (BOOL)query:(NSString *)strCommand ret:(NSString **)data;
- (BOOL)read:(NSString **)strData From:(NSString *)strStart To:(NSString *)strEnd Timeout:(float)fTime;

@end
