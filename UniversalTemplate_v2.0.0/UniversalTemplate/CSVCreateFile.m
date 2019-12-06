    //
//  CSVFile.m
//  CSVSample
//
//  Created by Jason on 14-3-26.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "CSVCreateFile.h"

@implementation CSVFile

-(id)init
{
    self = [super init];
    
    if (self) {
        _sumStr = [[NSMutableString alloc] initWithCapacity:10];
        [_sumStr setString:@""];
        
    }
    
    return self;
}

-(void)dealloc
{
//    if (_logFilePath) {
//        [_logFilePath release];
//        _logFilePath = nil;
//    }
//    
//    if (_logFileName) {
//        [_logFileName release];
//        _logFileName = nil;
//    }
//    
//    if (_sumStr) {
//        [_sumStr release];
//        _sumStr = nil;
//    }
//    
//    [super dealloc];
}

//Create folder & CSV file if directory & file not exist
-(BOOL)createFileWithPath:(NSString *)path WithName:(NSString *)name WithType:(NSString *)type
{
    _logFilePath = [NSString stringWithFormat:@"%@/%@.%@", path, name, type];
    
    BOOL bResult = NO;
    BOOL isDir = NO;
    
    //1. Get execution tool's folder path
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //2. If bDirExist&isDir are true, the directory exit
    BOOL bDirExist = [fm fileExistsAtPath:path isDirectory:&isDir];
    NSError *errMsg;
    
    if (!(bDirExist == YES && isDir == YES))
    {
        bResult = [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&errMsg];
        if (!bResult)
            return bResult;
    }
    
    //4. Check file exist or not
    BOOL bExist = [fm fileExistsAtPath:_logFilePath isDirectory:&isDir];
    
    //5. If file not exist, creat data to file
    if (!bExist)
    {
        bResult = [fm createFileAtPath:_logFilePath contents:nil attributes:nil];
        
        if (!bResult)
            return bResult;
        
        NSString *strSum = [[NSString alloc] init];
        bResult = [strSum writeToFile:_logFilePath atomically:YES encoding:NSUTF8StringEncoding error:&errMsg];
//        [strSum release];
        
        if (!bResult)
            return bResult;
    }
    
    
    return bResult;
}

// Private: transfor array to sting format
//          {"11","22","33"} -> "11,22,33"
- (BOOL)appendDataToFile:(NSArray *)arrData
{
    BOOL bFirstTime = YES;
    
    NSMutableString *sumStr = [[NSMutableString alloc] initWithCapacity:10];
    
    for (NSString *str in arrData)
    {
        if (bFirstTime)
        {
            [sumStr appendString:str];
            bFirstTime = NO;
        }
        else
        {
            [sumStr appendString:@","];
            [sumStr appendString:str];
        }
    }
    
    [sumStr appendString:@"\r\n"];
    
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[sumStr dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
    
//    [sumStr release];
    
    return YES;
}

- (BOOL)appendDataToFileWithArrar:(NSArray *)arrData orString:(NSString *)str withFlag:(BOOL)flag
{
    if (arrData != nil) {
        BOOL bFirstTime = YES;
        
        for (NSString *str in arrData)
        {
            if (bFirstTime)
            {
                [_sumStr appendString:str];
                bFirstTime = NO;
            }
            else
            {
                [_sumStr appendString:@","];
                [_sumStr appendString:str];
            }
        }
        
        [_sumStr appendString:@"\r\n"];
    }
    else if (str != nil)
    {
        [_sumStr appendString:str];
        [_sumStr appendString:@"\r\n"];
    }
    
    if (flag) {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[_sumStr dataUsingEncoding:NSUTF8StringEncoding]];
        [myHandle closeFile];
    }
    
    return YES;
}

- (BOOL)appendDataToFileWithString:(NSString *)string
{
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
    
    return YES;
}

@end
