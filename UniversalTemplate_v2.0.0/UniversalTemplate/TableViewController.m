//
//  TableViewController.m
//  NationalTest
//
//  Created by jason on 15-3-30.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "TableViewController.h"

NSString* const MESSAGE_TO_UPDATE_UI = @"MESSAGE_TO_UPDATE_UI";

@implementation TableViewController

- (id)initWithFrame:(NSRect)frame index:(int)index
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //        _listData = [[NSMutableArray alloc] initWithCapacity:3];
        _arraySelectedPara = [[NSMutableArray alloc] initWithCapacity:3];
        
        _fAmplify = NO;
        
        [self initTableViewController];
        [self initAlertView:index];
    }
    return self;
}

- (void)setListData:(NSMutableArray *)listData
{
    _listData = listData;
    
    if (_fSelected) {
        NSString *strTmp;
        
        for (int i = 0; i < [_listData count]; i++) {
            strTmp = @"1";
            [_arraySelectedPara addObject:strTmp];
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)initTableViewController
{
    //设置tableView的Frame
    NSRect tableViewFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    
    //创建一个scrollView容器
    _scrollViewContainer = [[NSScrollView alloc] initWithFrame:tableViewFrame];
    _scrollViewContainer.hasVerticalScroller = YES;
    _scrollViewContainer.hasHorizontalScroller = YES;
    
    //创建TableView
    NSRect viewRect = [[_scrollViewContainer contentView] bounds];
    _listView = [[NSTableView alloc] initWithFrame:viewRect];
    [_listView setRowHeight:18];
    
    [_listView setBackgroundColor:[NSColor whiteColor]];
    [_listView setGridColor:[NSColor lightGrayColor]];
    [_listView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask | NSTableViewSolidVerticalGridLineMask];
    [_listView setUsesAlternatingRowBackgroundColors:YES];
    [_listView setAutosaveTableColumns:YES];
    [_listView setAllowsEmptySelection:YES];
    [_listView setAllowsColumnSelection:YES];
    //    [_listView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    //    [_listView setDoubleAction:@selector(doubleClick:)];
    
    [self addColumn:@"ID" withTitle:@"ID"];
    [self addColumn:@"TestItem" withTitle:@"TestItem"];
    [self addColumn:@"Lower" withTitle:@"Lower"];
    [self addColumn:@"Upper" withTitle:@"Upper"];
    [self addColumn:@"Unit" withTitle:@"Unit"];
    //    [self addColumn:@"TestValue" withTitle:@"TestValue"];
    [self addColumn:@"TestResult" withTitle:@"TestResult"];
    
    [_listView setDataSource:self];
    [_scrollViewContainer setDocumentView:_listView];
    
    [self addSubview:_scrollViewContainer];
    //    [scrollViewContainer release];
    
    //    _lbIndex = [[NSTextField alloc] initWithFrame:NSMakeRect(self.frame.size.width/2-30, 0, 60, 60)];
    //    [_lbIndex setBackgroundColor:[NSColor clearColor]];
    //    [_lbIndex setAlignment:NSTextAlignmentCenter];
    //    [_lbIndex setFont:[NSFont systemFontOfSize:40]];
    //    _lbIndex.alphaValue = 0.5;
    //    [_lbIndex setBordered:NO];
    //    [_lbIndex setEditable:NO];
    ////    [lbIndex setStringValue:[NSString stringWithFormat:@"%d",index + 1]];
    //
    //    [self addSubview:_lbIndex positioned:NSWindowAbove relativeTo:nil];
}

- (void)initAlertView:(int)index
{
    NSRect frame = NSMakeRect(5+index*self.frame.size.width/4, self.frame.size.height/2 - 100, self.frame.size.width/4 - 10, 100);
    
    _alertView = [[AlertView alloc] initWithFrame:frame];
    _alertView.hidden = YES;
    [self addSubview:_alertView positioned:NSWindowAbove relativeTo:nil];
    [_alertView.window setLevel:1];
}

- (void)setFrame:(NSRect)frame withIndex:(int)index
{
    NSRect rect = NSMakeRect((frame.size.width-60)/2 + frame.origin.x + 15, frame.origin.y + (frame.size.height - 80)/2, 60, 60);
    [_lbIndex setFrame:rect];
    [_lbIndex setStringValue:[NSString stringWithFormat:@"%d",index + 1]];
    
    [self.scrollViewContainer setFrame:frame];
}

#pragma mark -
#pragma mark NSTableViewDataSource Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (_listData != nil) {
        return [_listData count];
    } else {
        return 0;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSParameterAssert(row >= 0 && row < [_listData count]);
    
    id result = [[_listData objectAtIndex:row] objectForKey:[tableColumn identifier]];
    
    [[tableColumn dataCellForRow:row] setFont:[NSFont systemFontOfSize:11.0]];
    //    [[tableColumn dataCellForRow:row] setTextColor:[NSColor brownColor]];
    
    if ([[tableColumn identifier] isEqualToString:@"TestItem"] || [[tableColumn identifier] isEqualToString:@"TestResult"])
    {
        //        [[tableColumn dataCellForRow:row] setDrawsBackground:YES];
        //        [[tableColumn dataCellForRow:row] setBackgroundColor:[NSColor selectedControlColor]];
        [[tableColumn dataCellForRow:row] setAlignment:NSLeftTextAlignment];
    } else {
        [[tableColumn dataCellForRow:row] setAlignment:NSCenterTextAlignment];
    }
    
    if ([[tableColumn identifier] isEqualToString:@"TestResult"] || [[tableColumn identifier] isEqualToString:@"TestValue"]) {
        if (![[[_listData objectAtIndex:row] objectForKey:@"Status"] boolValue]) {
            [[tableColumn dataCellForRow:row] setTextColor:[NSColor redColor]];
        }
        else{
            [[tableColumn dataCellForRow:row] setTextColor:[NSColor blueColor]];
        }
    }
    
    if (_fSelected) {
        if([[tableColumn identifier] isEqualToString:@"ID"]){
            NSButtonCell *cell = [[NSButtonCell alloc] init];
            [cell setButtonType:NSSwitchButton];
            [cell setTitle:[[_listData objectAtIndex:row] objectForKey:[tableColumn identifier]]];
            [cell setState:[[_arraySelectedPara objectAtIndex:row] integerValue]];
            [tableColumn setDataCell:cell];
            
            //        [cell setTag:(row + 300)];
            //        [cell setAction:@selector(cellClick:)];
            //        [cell setTarget:self];
            
            return cell;
        }
    }
    
    return result;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (_fSelected) {
        if([[tableColumn identifier] isEqualToString:@"ID"]){
            NSString *strTmp = (NSString*)[_arraySelectedPara objectAtIndex:row];
            
            if([strTmp isEqualToString:@"1"]) {
                strTmp = @"0";
            } else {
                strTmp = @"1";
            }
            
            [_arraySelectedPara replaceObjectAtIndex:row withObject:strTmp];
        }
    }
}

#pragma mark -
#pragma mark method

- (void)addColumn:(NSString*)newid withTitle:(NSString*)title
{
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:newid];
    
    [[column headerCell] setFont:[NSFont systemFontOfSize:14.0]];
    [[column headerCell] setStringValue:title];
    [[column headerCell] setAlignment:NSCenterTextAlignment];
    
    if ([newid isEqualToString:@"ID"]) {
        [column setWidth:25.0];
        [column setMinWidth:20];
    } else if ([newid isEqualToString:@"TestItem"]) {
        [column setWidth:650 - MULTIPLE_NUMBERS*100];
        [column setMinWidth:100];
    } else if ([newid isEqualToString:@"Lower"]) {
        [column setWidth:80 - MULTIPLE_NUMBERS*10];
        [column setMinWidth:20];
    } else if ([newid isEqualToString:@"Upper"]) {
        [column setWidth:80 - MULTIPLE_NUMBERS*10];
        [column setMinWidth:20];
    } else if ([newid isEqualToString:@"Unit"]) {
        [column setWidth:60 - MULTIPLE_NUMBERS*5];
        [column setMinWidth:20];
//    } else if ([newid isEqualToString:@"TestValue"]) {
//        [column setWidth:100.0];
//        [column setMinWidth:100];
    } else if ([newid isEqualToString:@"TestResult"]) {
        [column setWidth:500 - MULTIPLE_NUMBERS*100];
        [column setMinWidth:20];
    } else {
        [column setWidth:100.0];
        [column setMinWidth:50];
    }
    
    [column setEditable:NO];
    //	[column setResizingMask:NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
    [column setResizingMask:NSTableColumnNoResizing];
    [_listView addTableColumn:column];
    //	[column release];
}

#pragma mark -
#pragma mark target action

- (void)doubleClick:(id)sender
{
    _fAmplify = !_fAmplify;
    
    NSMutableDictionary *newdict = [[NSMutableDictionary alloc] initWithCapacity:2];
    [newdict setObject:[NSNumber numberWithBool:_fAmplify] forKey:@"Amplify"];
    [newdict setObject:self forKey:@"TableView"];
    
    //    id topView = [[[[[self superview] superview] superview] superview] superview];
    id topView = [[[self superview] superview] superview];
    
    //    NSLog(@"self.superview = %@", [[[[[self superview] superview] superview] superview] superview]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_TO_UPDATE_UI
                                                        object:topView
                                                      userInfo:newdict];
}

- (void)showAlertView:(NSString *)msg
{
    _alertView.bAlert = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        _alertView.hidden = NO;
        [_alertView showAlertWarning:msg];
    });
}

@end
