//
//  CustomView.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "CustomView.h"
#import "Definitions.h"

@implementation CustomView

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
    
    
    [[Definitions parameterTableBackgroundColor] setFill];


    NSRectFill(dirtyRect);

}

@end
