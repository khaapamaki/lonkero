//
//  LMWindow.h
//  Lonkero
//
//  Created by Kati Haapamäki on 27.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMWindow : NSWindow

- (void)_showFirstResponderWindowIfNeeded:(NSResponder*)aResponder;
- (void)becomeMainWindow;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
@property (unsafe_unretained) IBOutlet NSScrollView *parameterQueryTableView;

@end
