//
//  TemplateParameter.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#define PARAMETER_TYPES @"text", @"number", @"date", @"list", @"login name", @"user's name", @"incremental", @"boolean"

#import "TemplateParameter.h"

@implementation TemplateParameter

-(TemplateParameterType)type {
    return (TemplateParameterType) _parameterType;
}
-(void)setType:(TemplateParameterType)type {
    _parameterType = (NSInteger) type;
}

-(void) encodeWithCoder: (NSCoder *) coder {
    [coder encodeObject:self.name forKey:@"parameterName"];
    [coder encodeObject:self.tag forKey:@"parameterTag"];
    [coder encodeObject:[NSNumber numberWithLong:self.parameterType] forKey:@"parameterType"];
    [coder encodeObject:self.defaultValue forKey:@"parameterDefaultValue"];
    [coder encodeObject:[NSNumber numberWithBool:self.isEditable] forKey:@"parameterIsEditable"];
    [coder encodeObject:[NSNumber numberWithBool:self.isRequired] forKey:@"parameterIsRequired"];
    [coder encodeObject:[NSNumber numberWithBool:self.isHidden] forKey:@"parameterIsHidden"];
    [coder encodeObject:self.typeSelection forKey:@"parameterAvailableTypes"];
    [coder encodeObject:[NSNumber numberWithBool:self.createParentFolder] forKey:@"parameterCreateParent"];
    [coder encodeObject:self.parentFolderNamingRule forKey:@"parameterParentName"];
    [coder encodeObject:[NSNumber numberWithBool:self.optionalWithAbove] forKey:@"parameterIsOptionalWithAbove"];
    [coder encodeObject:self.value forKey:@"stringValue"];
    [coder encodeObject:self.dateValue forKey:@"dateValue"];
}

-(id) initWithCoder:(NSCoder *) coder {
    self.name = [coder decodeObjectForKey:@"parameterName"];
    self.tag = [coder decodeObjectForKey:@"parameterTag"];
    self.parameterType = [[coder decodeObjectForKey:@"parameterType"] longValue];
    self.defaultValue = [coder decodeObjectForKey:@"parameterDefaultValue"];
    self.isEditable = [[coder decodeObjectForKey:@"parameterIsEditable"] boolValue];
    self.isRequired = [[coder decodeObjectForKey:@"parameterIsRequired"] boolValue];
    self.isHidden = [[coder decodeObjectForKey:@"parameterIsHidden"] boolValue];
    self.createParentFolder = [[coder decodeObjectForKey:@"parameterCreateParent"] boolValue];
    self.parentFolderNamingRule = [coder decodeObjectForKey:@"parameterParentName"];
    self.optionalWithAbove = [[coder decodeObjectForKey:@"parameterIsOptionalWithAbove"] boolValue];
    self.value = [coder decodeObjectForKey:@"stringValue"];
    self.dateValue = [coder decodeObjectForKey:@"dateValue"];
    // _typeSelection = [coder decodeObjectForKey:@"parameterAvailableTypes"];

    if (_typeSelection == nil) {
       _typeSelection = [[NSArray alloc] initWithObjects:PARAMETER_TYPES, nil];
    }
    _dateValue = [NSDate date];
    _value = @"";
    
    return self;
}
-(id) init {
    self = [super init];
    if (self) {
        _name = @"";
        _tag = @"";
        _parameterType = text;
        _isEditable = YES;
        _isRequired = YES;
        _isHidden = NO;
        _parentFolderNamingRule = @"";
        _defaultValue = @"";
        _value = @"";
        _createParentFolder = NO;
        _dateValue = [NSDate date];
        _typeSelection = [[NSArray alloc] initWithObjects:PARAMETER_TYPES, nil];
        _optionalWithAbove = NO;

    }
    return self;
}
@end
