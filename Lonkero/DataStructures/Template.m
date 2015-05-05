//
//  Template.m
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Template.h"

@implementation Template

-(void)saveTemplate {
    NSString *templatePath = [NSString stringWithString:[_location.path stringByExpandingTildeInPath]];
    NSString *templateSettingsFilePath = [NSString stringWithFormat:@"%@/Template Settings.plist", templatePath];
    [NSKeyedArchiver archiveRootObject:self toFile:templateSettingsFilePath];
}

+(NSString *)generateRandomIDString {
    return [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
}

-(void) encodeWithCoder: (NSCoder *) coder {
    NSString *version = TEMPLATE_VERSION;
    [coder encodeObject:version forKey:@"version"];
    [coder encodeObject:self.name forKey:@"templateName"];
    [coder encodeObject:self.location.path forKey:@"templatePath"];
    [coder encodeObject:self.templateParameterSet forKey:@"parameterSet"];
    [coder encodeObject:self.targetFolderPresets forKey:@"targetFolders"];
    [coder encodeObject:self.dateFormatString forKey:@"dateFormatting"];
    if (_groupId == nil || [_groupId isEqualToString:@""]) {
        _groupId = [Template generateRandomIDString];
        _groupId = DEFAULT_GROUP_ID;
    }
    [coder encodeObject:self.groupId forKey:@"groupID"];
    if (_templateId == nil || [_templateId isEqualToString:@""]) {
        _templateId = [Template generateRandomIDString];
    }
    [coder encodeObject:_templateId forKey:@"templateID"];
}

-(id) initWithCoder:(NSCoder *) coder {
    NSString *version;
    version = [coder decodeObjectForKey:@"version"];
    
    self.templateParameterSet = [coder decodeObjectForKey:@"parameterSet"];
    self.targetFolderPresets = [coder decodeObjectForKey:@"targetFolders"];
    self.dateFormatString = [coder decodeObjectForKey:@"dateFormatting"];
    _groupId = [coder decodeObjectForKey:@"groupID"];
    if (_groupId == nil || [_groupId isEqualToString:@""]) {
        _groupId = [Template generateRandomIDString];
        _groupId = DEFAULT_GROUP_ID;
    }
    _templateId = [coder decodeObjectForKey:@"templateID"];
    if (_templateId == nil || [_templateId isEqualToString:@""]) {
        _templateId = [Template generateRandomIDString];
    }
    return self;
}

-(id)initWithURL:(NSURL *) URL {
    self = [super init];
    if (self) {
        NSString *templatePath = [URL path];
        NSString *templateSettingsFilePath = [NSString stringWithFormat:@"%@/Template Settings.plist", templatePath];
        NSFileManager *fm = [[NSFileManager alloc] init];
        // read prefrences if they exists
        if ([fm fileExistsAtPath:templateSettingsFilePath]) {
            self = [NSKeyedUnarchiver unarchiveObjectWithFile:templateSettingsFilePath];
            _isTemplateSaved = YES;
          
        } else {
//           _masterFolderNamingRule = @"";
            _templateParameterSet = [[NSMutableArray alloc] init];
            _targetFolderPresets = [[NSMutableArray alloc] init];
            _dateFormatString = @"";
            _isTemplateSaved = NO;
            _name = @"";
        }
        _location = [[FileSystemItem alloc] initWithURL:URL];
        _name = [_location itemName];
    }
    return self;
}

-(id)init {
    self = [super init];
    if (self) {
//        _masterFolderNamingRule = @"";
        _templateParameterSet = [[NSMutableArray alloc] init];
        _targetFolderPresets = [[NSMutableArray alloc] init];
        _dateFormatString = @"";
        _name = @"";
        _isTemplateSaved = NO;
        _location = [[FileSystemItem alloc] init];
    }
    return self;
}


@end
