//
//  InstantPudding.h
//  SkunkSample
//
//  Created by Jason liang on 14-8-30.
//  Copyright (c) 2014年 Jason liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstantPudding_API.h"

@interface InstantPudding : NSObject
{
    IP_UUTHandle UID;
    BOOL failedAtLeastOneTest;
}

- (BOOL)IPStart;
//- (BOOL)IPCheck:(NSString*)sn;
//- (BOOL)IPCheck:(NSString*)sn Ret:(NSString **)strRet;
- (NSString *)IPCheck:(NSString*)sn;
- (void)GetIPStationType:(NSString **)strRet;
- (BOOL)ValidateSerialNumber:(NSString*)sn;
- (BOOL)AddIPAttribute:(NSString*)name Value:(NSString*)value;
- (BOOL)AddIPTestItem:(NSString*)itemName TestValue:(NSString*)testValue
           LowerLimit:(NSString*)lowerLimit UpperLimit:(NSString*)upperLimit
             Priority:(enum IP_PDCA_PRIORITY)priority Units:(NSString*)units
              Message:(NSString*)strErrorInfo;
- (BOOL)AddIPTestItem:(NSString*)itemName
          SubTestName:(NSString*)subTestName
       SubSubTestName:(NSString *)subSubTestName
             Priority:(enum IP_PDCA_PRIORITY)priority
              Message:(NSString*)strErrorInfo;
- (BOOL)AddIPBlob:(NSString*)fileName FilePath:(NSString*)filePath;
- (BOOL)IPDoneAndCommit:(NSString*)sn;
- (BOOL)SetStartTime:(time_t)startTime;
- (BOOL)SetStopTime:(time_t)stopTime;

@end
