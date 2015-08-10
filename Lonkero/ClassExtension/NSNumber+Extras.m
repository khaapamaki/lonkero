//
//  NSNumber+Extras.m
//  Lonkero
//
//  Created by Kati Haapamäki on 12.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "NSNumber+Extras.h"

@implementation NSNumber (Extras)

/**
 *  Converts boolean NSNumber's to a string.
 *
 *  @return A string containing Yes or No
 */

-(NSString *)boolString {
    if ([self boolValue]) {
        return [NSString stringWithFormat:@"%@", @"Yes"];
    } else {
        return [NSString stringWithFormat:@"%@", @"No"];
    }
}

/**
 *  Returns a string value of NSNumber
 *
 *  @return A string
 */

-(NSString *) string {
    return [self description];
}
@end
