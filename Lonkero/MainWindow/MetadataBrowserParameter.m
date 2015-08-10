//
//  MetadataBrowserParameterTable.m
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "MetadataBrowserParameter.h"

@implementation MetadataBrowserParameter

+(void)addToArray:(NSMutableArray *)arrayController parameter:(NSString *)parameter value:(NSString *)stringValue {
    MetadataBrowserParameter *newParameter = [[MetadataBrowserParameter alloc] initWithParameter:parameter andValue:stringValue];
    [arrayController addObject:newParameter];
}

-(id)initWithParameter:(NSString *)parameter andValue:(NSString *)stringValue {
    if (self = [super init]) {
        _parameter = parameter;
        _stringValue = stringValue;
        _isEditable = NO;
        _dateValue = nil;
        _belongsToParameter = -1;
    }
    return self;
}

-(id)init {
    if (self = [super init]) {
        _parameter = @"";
        _stringValue = @"";
        _isEditable = NO;
        _dateValue = nil;
        _belongsToParameter = -1;
    }
    return self;
}


@end
