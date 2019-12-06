//
//  CSVFile.h
//  CSVSample
//
//  Created by Jason on 14-3-26.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVFile : NSObject
{
    NSString *_logFilePath;
    NSMutableString *_sumStr;
    //NSString *_logFileName;
}

//@property(nonatomic, retain)NSString *logFileName;

- (id)init;
- (BOOL)createFileWithPath:(NSString *)path WithName:(NSString *)name WithType:(NSString *)type;
- (BOOL)appendDataToFile:(NSArray *)arrData;
- (BOOL)appendDataToFileWithArrar:(NSArray *)arrData orString:(NSString *)str withFlag:(BOOL)flag;
- (BOOL)appendDataToFileWithString:(NSString *)string;
@end
