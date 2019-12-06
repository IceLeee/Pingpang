//
//  PDCA.h
//  FT_MFC
//
//  Created by INCUBECN on 8/11/15.
//  Copyright (c) 2015 BEN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstantPudding_API.h"

#define PASS @"PASS"
#define FAIL @"FAIL"



@interface PDCA : NSObject
{
@private
    IP_UUTHandle        UID;
    IP_TestSpecHandle   testSpec;
    IP_TestResultHandle testResult;
    
    NSString            *ErrorInfo;
    NSString            *DoneErrorInfo;
    NSString            *CommitErrorInfo;
    NSString            *UartFileLog;
    NSString            *DCSDFileLog;
    
    BOOL                failedAtLeastOneTest;
}

@property (readwrite, copy) NSString *ErrorInfo;
@property (readwrite, copy) NSString *DoneErrorInfo;
@property (readwrite, copy) NSString *CommitErrorInfo;
@property (readwrite, copy) NSString *UartFileLog;
@property (readwrite, copy) NSString *DCSDFileLog;

/*Open start upload.*/
-(BOOL)UUTStartTest;
/*Release UID object.*/
-(BOOL)UUTRelease;
- (void)UIDCancel;
/*validate serial number.*/
-(BOOL)ValidateSerialNumber:(NSString *)sn;
/*validate AMI with sn.*/
-(BOOL)ValidateAMIOK:(NSString *)sn;

-(BOOL)AddAttribute:(NSString *) attributeName AttributeValue:(NSString *) attributeValue;

-(BOOL)AddBlob:(NSString *) fileName FilePath:(NSString *) filePath;

-(BOOL)SetStartTime:(time_t) startTime;

-(BOOL)SetEndTime:(time_t) endTime;

-(BOOL)AddTestItem:(NSString *)itemName TestValue:(NSString *)testValue
         TestResult:(NSString *)tr ErrorInfo:(NSString *)errorInfo Priority:(NSString *)priority;

-(BOOL)AddTestItemAndSubItems:(NSString *)itemName SubItems:(NSArray *)subItems
                    TestValues:(NSArray *)testValues TestResults:(NSArray *)tesetResults
                   ErrorInfoes:(NSArray *)errorInfoes Priorities:(NSArray *)priorities;

-(BOOL)AddTestItemAndSubItems:(NSString *)itemName SubItems:(NSArray *)subItems
                    LowerSpecs:(NSArray *)lowerSpecs UpperSpecs:(NSArray *)upperSpecs
                         Units:(NSArray *)units TestValues:(NSArray *)testValues
                   TestResults:(NSArray *)tesetResults ErrorInfoes:(NSArray *)errorInfoes
                    Priorities:(NSArray *)priorities;

-(BOOL)AddTestItem:(NSString*)itemName
          LowerSpec:(NSString*)lowerSpec UpperSpec:(NSString*)upperSpec Unit:(NSString*)unit
          TestValue:(NSString*)testValue TestResult:(NSString*)tr
          ErrorInfo:(NSString*)errorInfo Priority:(NSString*)priority;


- (NSString *)GetFailInfomation;

- (NSString *)GetSITEInfo;

- (NSString *)GetStationType;

-(BOOL)checkBobcat:(NSString *)SN;

@end
