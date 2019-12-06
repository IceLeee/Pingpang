//
//  visaGeneral.m
//  visaGeneralTest
//
//  Created by jason on 14-4-11.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "visaGeneral.h"

#define BUFFER_SIZE 512

@implementation visaGeneral

- (id)init
{
    self = [super init];
    
    if (self) {
        _delay = 0.1f;

    }
    return self;
}

//- (void)dealloc
//{
//    [super dealloc];
//}

- (BOOL)open:(NSString *)strName
{
    BOOL bRet = NO;
    
    /* Now we will open a session to the instrument we just found. */
    if ([strName length] > 0) {
        /* First we will need to open the default resource manager. */
        ViStatus status;
        status = viOpenDefaultRM (&defaultRM);
        
        if (status != VI_SUCCESS)
        {
            printf ("Could not open a session to the VISA Resource Manager!\n");
            _fOpen = NO;
            viClose (defaultRM);
            return NO;
        }
        
        //status = viOpen (defaultRM, "USB0::0x0699::0x0406::C023705::INSTR", VI_NULL, VI_NULL, &instr);
        status = viOpen (defaultRM, [strName cStringUsingEncoding:NSASCIIStringEncoding], VI_NULL, VI_NULL, &instr);
        
        if (status != VI_SUCCESS) {
            _fOpen = NO;
            viClose (defaultRM);
            return NO;
        }
        
        /*
         * Set timeout value to 5000 milliseconds (5 seconds).
         */
        status = viSetAttribute (instr, VI_ATTR_TMO_VALUE, 5000);
        
        if (status != VI_SUCCESS) {
            printf ("An error occurred set attribute\n");
            _fOpen = NO;
            viClose (defaultRM);
            return NO;
        }
        
        _fOpen = YES;
        bRet = YES;
    }
    
    return bRet;
}

- (void)close
{
    _fOpen = NO;
    
    if (instr) {
        viClose (instr);
    }
    
    if (defaultRM) {
        viClose (defaultRM);
    }
}

- (BOOL)isOpen
{
	return _fOpen;
}

- (BOOL)write:(NSString*)strCommand
{
    char stringinput[BUFFER_SIZE];
    ViUInt32 writeCount;
    ViStatus status;
    
    NSString *strTemp = [NSString stringWithFormat:@"%@\n", strCommand];
    strcpy(stringinput, [strTemp cStringUsingEncoding:NSASCIIStringEncoding]);
    status = viWrite (instr, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    
    if (status != VI_SUCCESS) {
        NSLog(@"Write command fail!!! command: %@",strTemp);
        return NO;
    }

    return YES;
}

- (BOOL)read:(NSString **)data
{
    unsigned char buffer[BUFFER_SIZE];
    ViUInt32 retCount;
    ViStatus status;
    
    memset(buffer, 0, BUFFER_SIZE);
    [NSThread sleepForTimeInterval:_delay];
    status = viRead (instr, buffer, BUFFER_SIZE, &retCount);
    //status = viWrite (instr, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    if (status != VI_SUCCESS) {
        NSLog(@"read command fail!!!");
        return NO;
    }
    
    NSLog(@"Query Data: %s", buffer);
//    float value = [[NSString stringWithFormat:@"%s", buffer] floatValue];
//    *data = [NSString stringWithFormat:@"%f", value];
    *data = [NSString stringWithFormat:@"%s", buffer];
    return YES;
}

- (BOOL)read:(NSString **)data From:(NSString *)strStart To:(NSString *)strEnd Timeout:(float)fTime
{
    unsigned char buffer[BUFFER_SIZE];
    ViUInt32 retCount;
    ViStatus status;
    
    memset(buffer, 0, BUFFER_SIZE);
    //[NSThread sleepForTimeInterval:fTime];
    [NSThread sleepForTimeInterval:_delay];
    status = viRead (instr, buffer, BUFFER_SIZE, &retCount);
    //status = viWrite (instr, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    if (status != VI_SUCCESS) {
        NSLog(@"read command fail!!!");
        return NO;
    }
    
    NSLog(@"Query Data: %s", buffer);
    //    float value = [[NSString stringWithFormat:@"%s", buffer] floatValue];
    //    *data = [NSString stringWithFormat:@"%f", value];
    *data = [NSString stringWithFormat:@"%s", buffer];
    return YES;
}

- (BOOL)query:(NSString *)strCommand ret:(NSString **)data
{
    unsigned char buffer[BUFFER_SIZE];
    char stringinput[BUFFER_SIZE];
    ViUInt32 writeCount;
    ViUInt32 retCount;
    ViStatus status;
    
    NSString *strTemp = [NSString stringWithFormat:@"%@\n", strCommand];
    strcpy(stringinput,[strTemp cStringUsingEncoding:NSASCIIStringEncoding]);
    status = viWrite (instr, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    
    if (status != VI_SUCCESS)
    {
        NSLog(@"Write command fail!!! command: %@",strTemp);
        return NO;
    }
    
    [NSThread sleepForTimeInterval:_delay];
    memset(buffer, 0, BUFFER_SIZE);
    status = viRead(instr, buffer, BUFFER_SIZE, &retCount);
    
    if (status != VI_SUCCESS)
    {
        NSLog(@"Read command fail!!! command: %@", strTemp);
        return NO;
    }
    NSLog(@"Query Data: %s", buffer);
//    float value = [[NSString stringWithFormat:@"%s", buffer] floatValue];
//    *data = [NSString stringWithFormat:@"%f", value];
    *data = [NSString stringWithFormat:@"%s", buffer];
    return YES;
}


@end
