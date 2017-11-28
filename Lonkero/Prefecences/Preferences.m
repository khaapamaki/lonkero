//
//  Preferences.m
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Preferences.h"
#import "Definitions.h"


@implementation Preferences

-(void)savePreferences {

    NSString *preferenceFolderPath = [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), APPNAME];
    NSString *preferenceFilePath = [NSString stringWithFormat:@"%@/%@", preferenceFolderPath, PREFERENCES_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    BOOL isdir;
    
    // create prefs folder if it doesn't exist
    if (![fm fileExistsAtPath:preferenceFolderPath isDirectory:&isdir]) {
        if (![fm createDirectoryAtPath:preferenceFolderPath withIntermediateDirectories:YES attributes:0 error:nil]) {
            NSRunAlertPanel(@"Cannot create folder for preferences", @"", @"Ok", nil, nil);
        }
    }
    
    if (![NSKeyedArchiver archiveRootObject:self toFile:preferenceFilePath]) {
        NSRunAlertPanel(@"Cannot write preferences", @"", @"Ok", nil, nil);
    }
}

-(void) encodeWithCoder: (NSCoder *) coder {
    [coder encodeObject:PREFEFENCES_VERSION forKey:@"version"];
    [coder encodeObject:_templateSetLocations forKey:@"templateFolders"];
    [coder encodeObject:_defaultDateFormat forKey:@"defaultDateFormat"];
}

-(id) initWithCoder:(NSCoder *) coder {
    NSString *version;
    version = [coder decodeObjectForKey:@"version"];
    if ([version isEqualToString:PREFEFENCES_VERSION]) {
        _templateSetLocations = [coder decodeObjectForKey:@"templateFolders"];
        _defaultDateFormat = [coder decodeObjectForKey:@"defaultDateFormat"];
        for (FileSystemItem *currentFolder in _templateSetLocations) {
            currentFolder.isRootObject = YES; // just make sure that templates list shows up correctly, deprecated
            currentFolder.isExpanded = YES;   // we dont want to save this as prefs hence using always expanded wiew at start
            currentFolder.isExpandable = YES; // we dont want to save this as prefs hence using always expanded wiew at start
        }
        return self;
    }
    return nil;
}

-(id)initWithLoadingPreferences {

    NSString *preferenceFolderPath = [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), APPNAME];
//    NSString *globalPreferenceFolderPath = [NSString stringWithFormat:@"/Library/Preferences/%@", APPNAME];
    NSString *preferenceFilePath = [NSString stringWithFormat:@"%@/%@", preferenceFolderPath, PREFERENCES_FILENAME];
//    NSString *globalPreferenceFilePath = [NSString stringWithFormat:@"%@/%@", globalPreferenceFolderPath, PREFERENCES_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    // read prefrences if they exists
    if ([fm fileExistsAtPath:preferenceFilePath]) {
        Preferences *loadedPreferences = [NSKeyedUnarchiver unarchiveObjectWithFile:preferenceFilePath];
        
        if (loadedPreferences != nil) {
            self = loadedPreferences;
        } else {
            self = [super init];
            if (self) {
                _templateSetLocations = [[NSMutableArray alloc] init];
                _defaultDateFormat = @"yyyy-dd-mm";
            }
        }
    }
    return self;
}

-(NSMutableArray *)templateSetLocationsByParsingSystemParameters {
    NSMutableArray *parsedTemplateLocations = [NSMutableArray array];
    for (FileSystemItem *currentLocation in _templateSetLocations) {
        TemplateDeployer *td = [[TemplateDeployer alloc] init];
        NSString *testPath = [td parseSystemParametersForString:currentLocation.path];
        FileSystemItem *anItem = [[FileSystemItem alloc] initWithPath:[td parseSystemParametersForString:currentLocation.path] andNickName:currentLocation.nickName];
        [parsedTemplateLocations addObject:anItem];
    }
    
    return parsedTemplateLocations;
}

-(id)copyWithZone:(NSZone*)zone {
    Preferences *newPrefs = [[Preferences allocWithZone:zone] init];
    newPrefs.templateSetLocations = [_templateSetLocations mutableCopy];
    newPrefs.defaultDateFormat = [_defaultDateFormat copy];
    return newPrefs;
}

-(id)init {
    self = [super init];
    if (self) {
        _templateSetLocations = [[NSMutableArray alloc] init];
        _defaultDateFormat = @"yyyy-dd-mm";
        
    }
    return self;
}

@end
