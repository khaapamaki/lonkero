//
//  NSString+Extras.m
//  Lonkero
//
//  Created by Kati Haapamäki on 18.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "NSString+Extras.h"
#import "Definitions.h"

@implementation NSString (Extras)


#pragma mark Case conversion


/** Analyzes if case has changed from first string to second string.
 
 @param str1 First string
 @param str2 Second string
 
 @results The case of the second string if cases are different.
 @result @a customcase if there is no differences.

 */

+(Case)analyzeCaseConversionBetweenString:(NSString*)str1 andString:(NSString*)str2 {
    Case originalCase = [str1 getCase];
    Case newCase = [str2 getCase];
    if ([str1 isCaseInsensitiveLike:str2]) {
        if (originalCase != newCase) {
            return newCase;
        }
    }
    return customcase;
}


/** Returns the string converted to given case.
 
 @param newCase The case the string will be converted to.
 
 @return Converted string.
 
 */

-(NSString*)convertToCase:(Case)newCase {
    
    NSString *result = nil;
    
    switch (newCase) {
        case uppercase:
            result = [self uppercaseString];
            break;
        case lowercase:
            result = [self lowercaseString];
            break;
        case capitalcase:
            result = [self capitalizeFirstCharacter];
            break;
        default:
            result = [self copy];
            break;
    }
    
    return result;
}

/** Returns a string with capitalized first charater. Leaves other characters as they are.
 

 */

-(NSString*)capitalizeFirstCharacter {
    if ([self length]==0) {
        return [self copy];
    }
    if ([self length]==1) {
        return [self uppercaseString];
    }
    NSString *firstCharacter = [self substringToIndex:1];
    NSString *body = [self substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", [firstCharacter uppercaseString], body];
}


/** Returns the case of the string.
 
 @return @a lowercase if the string has all charcters in lowercase.
 @return @a uppercase if the string has all characters in uppercase.
 @return @a capitalcase if the first character is uppercase and others are lowercase.
 @return @a customcase for anything else.
 
 */


-(Case)getCase {
    if ([self length]==0) {
        return customcase;
    }
    
    if ([self isEqualToString:[self lowercaseString]]) {
        return lowercase;
    }
    if ([self isEqualToString:[self uppercaseString]]) {
        return uppercase;
    }
    if ([self isEqualToString:[self capitalizeFirstCharacter]]) {
        return capitalcase;
    }
    
    return customcase;
    
}

#pragma mark String Cleaning

/** Removes multiple successive spaces or punctuation marks from the string.
 
 */

-(NSString *)stringByRemovingDoubleSpacesAndPunctuation {
    NSMutableCharacterSet *mySet = [NSCharacterSet whitespaceCharacterSet];
    [mySet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

    NSMutableString *result = [NSMutableString stringWithString:@""];
    NSString *lastCharacter;
    for (NSInteger index=0; index < [self length]; index++ ) {
        NSString *currentCharacter = [self substringWithRange:NSMakeRange(index, 1)];

        if ([currentCharacter rangeOfCharacterFromSet:mySet].length == 0) {
            [result appendString:currentCharacter];
            lastCharacter = currentCharacter;
        } else {
            if (![currentCharacter isEqualToString:lastCharacter]) {
                [result appendString:currentCharacter];
                lastCharacter = currentCharacter;
            }
        }
    }
    return [NSString stringWithString:result];
}

/** Removes multiple successive spaces from the string.
 
 */

-(NSString *)stringByRemovingDoubleSpaces {
    NSMutableCharacterSet *mySet = [NSCharacterSet whitespaceCharacterSet];
    
    NSMutableString *result = [NSMutableString stringWithString:@""];
    NSString *lastCharacter;
    for (NSInteger index=0; index < [self length]; index++ ) {
        NSString *currentCharacter = [self substringWithRange:NSMakeRange(index, 1)];
        
        if ([currentCharacter rangeOfCharacterFromSet:mySet].length == 0) {
            [result appendString:currentCharacter];
            lastCharacter = currentCharacter;
        } else {
            if (![currentCharacter isEqualToString:lastCharacter]) {
                [result appendString:currentCharacter];
                lastCharacter = currentCharacter;
            }
        }
    }
    return [NSString stringWithString:result];
}

/** Removes spaces from the beginning and the end of the string.
 
 */

-(NSString *)stringByTrimmingSpaces {
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    return [NSString stringWithString:[mutableString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

/** Removes spaces and punctuation from the beginning and the end of the string.
 
 
 */

-(NSString *)stringByTrimmingSpacesAndPunctuation {
    NSMutableCharacterSet *mySet = [NSCharacterSet whitespaceCharacterSet];
    [mySet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    return [self stringByTrimmingCharactersInSet:mySet];
}

/** Replaces characters that are illegal for filenames with given replacement string.
 
 @param replacementString   A string to replace illegal characters
 
 
 */
-(NSString *)stringByReplacingIllegalCharactersWith:(NSString *)replacementString {

    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    NSArray *illegalCharacters = @[@"/", @"\"", @":", @"*", @"?", @"<", @">", @"|"];
    for (NSString *illegalCharacater in illegalCharacters)  {
        [mutableString replaceOccurrencesOfString:illegalCharacater
                                       withString:replacementString
                                          options:0
                                            range:NSMakeRange(0, [mutableString length])];
    }
    return [NSString stringWithString:mutableString];
}

/** Returns cleaned up version from the string.
 
 Removes illegal characters, multiple successive spaces and heading and trailing spaces.
 
 
 */
-(NSString *)stringByPerformingFullCleanUp {
    NSString *useThis = [self copy];
    return [[[useThis stringByReplacingIllegalCharactersWith:@""] stringByTrimmingSpaces] stringByRemovingDoubleSpaces];
}

/** Checks if the string has at least one alphanumeric character.
 
@return BOOL Yes if valid.
 
 @note The name of method is misleading. It does not check illegal characters or anything else that can make a string invalid as a filename.
 
 */
-(BOOL)isValidFileName {
        NSMutableCharacterSet *alphabets= [NSCharacterSet lowercaseLetterCharacterSet];
        [alphabets formUnionWithCharacterSet:[NSCharacterSet uppercaseLetterCharacterSet]];
        [alphabets addCharactersInString:@"0123456789"];

        if (![self isEqualToString:@""]) {
            if ([self rangeOfCharacterFromSet:alphabets options:NSCaseInsensitiveSearch].length >0) {
                return YES;
            }
        }
        return NO;
}

#pragma mark Checks

/** Check if the string is not @"" nor nil.
 
 @see isEmptyString as opposite.
 
 */

+(BOOL)isNotEmptyString:(NSString *)str {
    if (str==nil) {
        return NO;
    }
    if ([str length]==0) {
        return NO;
    }
    return YES;
}

/** Check if the string is @"" or nil.
 
 @see isNotEmptyString as opposite.
 
 */

+(BOOL)isEmptyString:(NSString *)str {
    if (str==nil) {
        return YES;
    }
    if ([str length]==0) {
        return YES;
    }
    return NO;
}

/** Inserts '-' to the string into every @a n th place.
 
 
 */

-(NSString *)stringByInsertingHyphensEvery:(short)number {
    NSMutableString *result = [self mutableCopy];
    short index = [result length] - number;
    while (index>0) {
        [result insertString:@"-" atIndex:index];
        index -= number;
    }
    return [NSString stringWithString:result];
    
}

#pragma mark Generation and Conversion

/** Converts wild card formatted string to regular expression format
 
 
 @note Only simple conversion is made. Not to be used generally.
 
 */

+(NSString *)convertWildCardToRegExp:(NSString *)WildCardString {
    NSMutableString *result = [NSMutableString stringWithString:@"^"];
    [result appendString: [NSString stringWithString:WildCardString]];
    [result replaceOccurrencesOfString:@"." withString:@"\\." options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"*" withString:@".*" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"?" withString:@"." options:0 range:NSMakeRange(0, [result length])];
    [result appendString:@"$"];
    return result;
}

/**  Returns a randomly generated alphanumeric string of given length.
 
 Generated string will only have numbers and capital letters from A to Z.
 
 @param len A legth of string.
 
 */

+(NSString *)generateRandomStringOfLength:(short)len {
    NSMutableString *result = [NSMutableString stringWithString:@""];
    NSString *validCharacters = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //NSString *validCharacters = @"aeiouyaeiouyaeiouyabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzABCEDEFGHIJKLMNOPQRSTUVVXYZ012345678901234567890123456789";
    
    for (int index = 0; index < len; index++) {
        NSInteger rnd = random() % [validCharacters length];
        [result appendString:[validCharacters substringWithRange:NSMakeRange(rnd, 1)]];
    }
    return result;
}

/**
 *  Returns an arrays of semicolon separated items of the string
 *
 *  @return NSArray
 */

-(NSArray*)arrayFromSemicolonSeparatedList {
    // Parses xx;yy;zz list

    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self componentsSeparatedByString:@";"]];
    for (long index = 0; index < [items count]; index++) {
        NSString *string = items[index];
        items[index] = [string stringByRemovingDoubleSpacesAndPunctuation];
    }

    BOOL firstItemIsEmpty = NO;
    
    
    // remove all empty items but the possible one at index 0
    if ([items[0] isEqualToString:@""]) firstItemIsEmpty = YES;
    [items removeEmptyStringItems];
    if (firstItemIsEmpty) [items insertObject:@"" atIndex:0];
    
    return items;
}

@end
