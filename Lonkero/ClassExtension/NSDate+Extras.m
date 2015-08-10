//
//  NSDate+Extras.m
//  Lonkero
//
//  Created by Kati Haapamäki on 15.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "NSDate+Extras.h"

@implementation NSDate (Extras)

/**
 *  Convert date formatting string to style used in NSDateFormatter
 *
 *  NSDateFormatter uses casesensitive placeholders for y, d and M. This method converts user's date formatting string to correct format.
 *
 *  @param formatString Date format string
 *
 *  @return NSDateFormatter style string
 */

-(NSString *)parsedDateWithFormat:(NSString *)formatString {
    NSMutableString *fixedFormatString = [formatString mutableCopy];
    [fixedFormatString replaceOccurrencesOfString:@"Y" withString:@"y" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    [fixedFormatString replaceOccurrencesOfString:@"D" withString:@"d" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    [fixedFormatString replaceOccurrencesOfString:@"m" withString:@"M" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fixedFormatString];
    return [dateFormatter stringFromDate:self];
}

@end
