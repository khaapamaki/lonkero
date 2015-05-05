//
//  NSString+Extras.h
//  Lonkero
//
//  Created by Kati Haapamäki on 18.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"

@interface NSString (Extras)

-(NSString *)stringByRemovingDoubleSpaces;
-(NSString *)stringByRemovingDoubleSpacesAndPunctuation;
-(NSString *)stringByTrimmingSpaces;
-(NSString *)stringByReplacingIllegalCharactersWith:(NSString *)replacementString ;
-(NSString *)stringByPerformingFullCleanUp;
-(BOOL)isValidFileName;
+(Case)analyzeCaseConversionBetweenString:(NSString*)str1 andString:(NSString*)str2;
-(Case)getCase;
-(NSString*)capitalizeFirstCharacter;
-(NSString*)convertToCase:(Case)newCase;
+(NSString *)generateRandomStringOfLength:(short)len;

@end
