//
//  Template.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Template.h"
#import "NSString+Extras.h"


@implementation Template

-(void)convertFromVersion:(NSString*)version {
    if ([version isEqualToString:@"0.2"] && [TEMPLATE_VERSION isEqualToString:@"0.3"]) {
        for (TemplateParameter *currentParameter in self.templateParameterSet) {
            if ([NSString isNotEmptyString:currentParameter.parentFolderNamingRule]) {
                NSMutableString *parentName = [NSMutableString stringWithString:currentParameter.parentFolderNamingRule];
                [parentName replaceOccurrencesOfString:@"[" withString:TAGCHAR_BEGIN options:0 range:NSMakeRange(0, [parentName length])];
                [parentName replaceOccurrencesOfString:@"]" withString:TAGCHAR_END options:0 range:NSMakeRange(0, [parentName length])];
                currentParameter.parentFolderNamingRule = [parentName copy];
            }
        }
        _version = TEMPLATE_VERSION;
    }
}

/// Saves the tempalate settings to the template's root

-(void)saveTemplate {
    NSString *templatePath = [NSString stringWithString:[_location.path stringByExpandingTildeInPath]];
    NSString *templateSettingsFilePath = [NSString stringWithFormat:@"%@/%@", templatePath, TEMPLATE_SETTINGS_FILENAME];
    [NSKeyedArchiver archiveRootObject:self toFile:templateSettingsFilePath];
}


/// Generates unique id for templates and groups. The latter is not implemented.


-(void) encodeWithCoder: (NSCoder *) coder {
    if ([_version isEqualToString:@"0.2"]) {
        _version = @"0.3";
    }
    [coder encodeObject:_version forKey:@"version"];
    [coder encodeObject:_name forKey:@"templateName"];
    [coder encodeObject:_location.path forKey:@"templatePath"];
    [coder encodeObject:self.templateParameterSet forKey:@"parameterSet"];
    [coder encodeObject:self.targetFolderPresets forKey:@"targetFolders"];
    [coder encodeObject:self.dateFormatString forKey:@"dateFormatting"];
    if (_groupId == nil || [_groupId isEqualToString:@""]) {
        _groupId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
        _groupId = DEFAULT_GROUP_ID;
    }
    [coder encodeObject:self.groupId forKey:@"groupID"];
    if (_templateId == nil || [_templateId isEqualToString:@""]) {
        _templateId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
    }
    [coder encodeObject:_templateId forKey:@"templateID"];
}

-(id) initWithCoder:(NSCoder *) coder {
    _version = [coder decodeObjectForKey:@"version"];
    _name = [coder decodeObjectForKey:@"templateName"];
    NSString *path = [[coder decodeObjectForKey:@"templatePath"] stringByExpandingTildeInPath];
    _location = [[FileSystemItem alloc] initWithPath:path andNickName:@""];
    _templateParameterSet = [coder decodeObjectForKey:@"parameterSet"];
    _targetFolderPresets = [coder decodeObjectForKey:@"targetFolders"];
    _dateFormatString = [coder decodeObjectForKey:@"dateFormatting"];
    _groupId = [coder decodeObjectForKey:@"groupID"];
    if ([NSString isEmptyString:_groupId]) {
        _groupId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
        _groupId = DEFAULT_GROUP_ID;
    }
    _templateId = [coder decodeObjectForKey:@"templateID"];
    if ([NSString isEmptyString:_templateId]) {
        _templateId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
    }

    return self;
}


/// Initialized a Template object by reading template settings file

-(id)initWithURL:(NSURL *) URL {

    NSString *templatePath = [URL path];
    NSString *templateSettingsFilePath = [NSString stringWithFormat:@"%@/%@", templatePath, TEMPLATE_SETTINGS_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    // read prefrences if they exists
    if ([fm fileExistsAtPath:templateSettingsFilePath]) {
        self = [NSKeyedUnarchiver unarchiveObjectWithFile:templateSettingsFilePath];
        if (self) {
            _location = [[FileSystemItem alloc] initWithURL:URL];
            _name = [_location itemName];
            _version = TEMPLATE_VERSION;
            _isTemplateSaved = YES;
        }
    } else {
        self = [super init];
        if (self) {
            _templateParameterSet = [[NSMutableArray alloc] init]; //< Template parameters as an array
            _targetFolderPresets = [[NSMutableArray alloc] init];
            _dateFormatString = @"";
            _isTemplateSaved = NO;
            _name = @"";
            _location = [[FileSystemItem alloc] initWithURL:URL];
            _name = [_location itemName];
            _version = TEMPLATE_VERSION;
        }
    }
    return self;
}


-(id)init {
    self = [super init];
    if (self) {
        _templateParameterSet = [[NSMutableArray alloc] init];
        _targetFolderPresets = [[NSMutableArray alloc] init];
        _dateFormatString = @"";
        _name = @"";
        _isTemplateSaved = NO;
        _location = [[FileSystemItem alloc] init];
        _version = TEMPLATE_VERSION;
    }
    return self;
}


@end
