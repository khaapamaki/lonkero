//
//  CustomView.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "CustomViewForParameterTable.h"
#import "Definitions.h"

@implementation CustomViewForParameterTable

-(void)keyUp:(NSEvent*)theEvent {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"parameterValueDidChange" object:nil];
    return;
}


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
