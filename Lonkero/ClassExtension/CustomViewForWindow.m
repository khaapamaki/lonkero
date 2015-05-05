//
//  CustomViewForWindow.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "CustomViewForWindow.h"
#import "Definitions.h"

@implementation CustomViewForWindow


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    // Drawing code here.
    
    
    [[Definitions windowBackgroundColor] setFill];
    
    
    NSRectFill(dirtyRect);

}

@end
