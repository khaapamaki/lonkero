//
//  MetadataBrowserParameterTable.h
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MetadataBrowserParameter : NSObject

@property NSString *parameter;
@property NSString *stringValue;
@property NSString *dateValue;
@property BOOL isEditable;
@property NSInteger belongsToParameter;

-(id)initWithParameter:(NSString*)parameter andValue:(NSString*)stringValue;
+(void)addToArray:(NSArrayController*)arrayController parameter:(NSString*)parameter value:(NSString*)stringValue;

@end
