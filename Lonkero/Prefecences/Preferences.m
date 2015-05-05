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
        [fm createDirectoryAtPath:preferenceFolderPath withIntermediateDirectories:YES attributes:0 error:nil];
    }
    [NSKeyedArchiver archiveRootObject:self toFile:preferenceFilePath];
    
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
    NSString *preferenceFilePath = [NSString stringWithFormat:@"%@/%@", preferenceFolderPath, PREFERENCES_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    // read prefrences if they exists
    if ([fm fileExistsAtPath:preferenceFilePath]) {
        Preferences *loadedPreferences;
        loadedPreferences = [NSKeyedUnarchiver unarchiveObjectWithFile:preferenceFilePath];
        
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


-(id)init {
    self = [super init];
    if (self) {
        _templateSetLocations = [[NSMutableArray alloc] init];
        _defaultDateFormat = @"yyyy-dd-mm";
        
    }
    return self;
}

@end
