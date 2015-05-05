//
//  Definitions.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Definitions.h"

@implementation Definitions

+(NSColor *)windowBackgroundColor {
     return [NSColor colorWithSRGBRed:0.88f green:0.88f blue:0.88f alpha:1.0f];
}

+(NSColor *)parameterTableBackgroundColor {
     return[ NSColor colorWithSRGBRed:0.950f green:0.953f blue:0.965f alpha:1.0f];
}

+(NSColor *)controlPathBackgroundColor {
    return [NSColor colorWithSRGBRed:0.88f green:0.886f blue:0.912f alpha:1.0f];
}

+(NSArray *)reservedTags {
    NSArray* tags = @[@"today", @"creator", @"creator-fullname"];
    return tags;
}

@end
