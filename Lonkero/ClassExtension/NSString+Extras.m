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

-(NSString*)capitalizeFirstCharacter {
    if ([self length]==0) {
        return [self copy];
    }
    if ([self length]==1) {
        return [self uppercaseString];
    }
    NSString *firstCharacter = [self substringToIndex:1];
    NSString *body = [self substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", [firstCharacter uppercaseString], [body lowercaseString]];
}

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


-(NSString *)stringByTrimmingSpaces {
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    return [NSString stringWithString:[mutableString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

-(NSString *)stringByTrimmingSpacesAndPunctuation {
    NSMutableCharacterSet *mySet = [NSCharacterSet whitespaceCharacterSet];
    [mySet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    return [self stringByTrimmingCharactersInSet:mySet];
}

-(NSString *)stringByReplacingIllegalCharactersWith:(NSString *)replacementString {

    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    NSArray *illegalCharacters = [NSArray arrayWithObjects:@"/", @"\"", @":", @"*", @"?" , nil];
    for (NSString *illegalCharacater in illegalCharacters)  {
        [mutableString replaceOccurrencesOfString:illegalCharacater
                                       withString:replacementString
                                          options:0
                                            range:NSMakeRange(0, [mutableString length])];
    }
    return [NSString stringWithString:mutableString];
}

-(NSString *)stringByPerformingFullCleanUp {
    NSString *useThis = [self copy];
    return [[[useThis stringByReplacingIllegalCharactersWith:@""] stringByTrimmingSpaces] stringByRemovingDoubleSpaces];
}


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

+(NSString *)generateRandomStringOfLength:(short)len {
    NSMutableString *result = [NSMutableString stringWithString:@""];
    
    NSString *validCharacters = @"aeiouyaeiouyaeiouyabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzABCEDEFGHIJKLMNOPQRSTUVVXYZ012345678901234567890123456789";
    
    for (int index = 0; index < len; index++) {
        NSInteger rnd = random() % [validCharacters length];
        [result appendString:[validCharacters substringWithRange:NSMakeRange(rnd, 1)]];
    }
    return result;
}

@end
