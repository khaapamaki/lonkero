//
//  QuickPathSelectorHelper.h
//  Lonkero
//
//  Created by Kati Haapamäki on 16.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//


// NOT IN USE!!


#import <Foundation/Foundation.h>

@interface PathControlHelper : NSObject <NSPathControlDelegate> {
    
}
@property (unsafe_unretained) IBOutlet NSPathControl *pathControl;
- (IBAction)userSelectedPath:(id)sender;

@end
