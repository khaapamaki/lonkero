//
//  UserPreferences.m
//  Lonkero
//
//  Created by Kati Haapamäki on 20.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "UserPreferences.h"

@implementation UserPreferences

-(void)saveUserPreferences {
    NSString *userPreferenceFolderPath = [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), APPNAME];
    NSString *userPreferenceFilePath = [NSString stringWithFormat:@"%@/%@", userPreferenceFolderPath, USERPREFERENCES_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    BOOL isdir;
    
    // create prefs folder if it doesn't exist
    if (![fm fileExistsAtPath:userPreferenceFolderPath isDirectory:&isdir]) {
        if (![fm createDirectoryAtPath:userPreferenceFolderPath withIntermediateDirectories:YES attributes:0 error:nil]) {
            NSRunAlertPanel(@"Cannot create folder for preferences", @"", @"Ok", nil, nil);
        
        }
    }
    if(![NSKeyedArchiver archiveRootObject:self toFile:userPreferenceFilePath]) {
        NSRunAlertPanel(@"Cannot write user preferences", @"", @"Ok", nil, nil);
    }
}

-(void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:USERPREFERENCES_VERSION forKey:@"version"];
    [coder encodeObject:_locationOfDefaultTemplate forKey:@"locationOfDefaultTemplate"];
    [coder encodeObject:_postDeploymentAction forKey:@"postDeploymentAction"];
}

-(id)initWithCoder:(NSCoder*)coder {
    NSString *version;
    version = [coder decodeObjectForKey:@"version"];
    if ([version isEqualToString:USERPREFERENCES_VERSION]) {
        _locationOfDefaultTemplate = [coder decodeObjectForKey:@"locationOfDefaultTemplate"];
        _postDeploymentAction = [coder decodeObjectForKey:@"postDeploymentAction"];
        return self;
    }
    return nil;
}

-(id)copyWithZone:(NSZone*)zone {
    UserPreferences *newUserPrefs = [[UserPreferences allocWithZone:zone] init];
    newUserPrefs.locationOfDefaultTemplate = [_locationOfDefaultTemplate copy];
    newUserPrefs.postDeploymentAction = [_postDeploymentAction copy];
    return newUserPrefs;
}

-(id)initWithLoadingUserPreferences {
    
    NSString *userPreferenceFolderPath = [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), APPNAME];
    NSString *userPreferenceFilePath = [NSString stringWithFormat:@"%@/%@", userPreferenceFolderPath, USERPREFERENCES_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];
    // read prefrences if they exists
    if ([fm fileExistsAtPath:userPreferenceFilePath]) {
        UserPreferences *loadedUserPreferences = [NSKeyedUnarchiver unarchiveObjectWithFile:userPreferenceFilePath];
        if (loadedUserPreferences != nil) {
            self = loadedUserPreferences;
        } else {
            self = [super init];
            if (self) {
                _postDeploymentAction = [NSNumber numberWithInt:ask];
                _locationOfDefaultTemplate = nil;
            }
        }
    }
    return self;
}

-(id)init {
    self = [super init];
    if (self) {
        _postDeploymentAction = [NSNumber numberWithInt:ask];
        _locationOfDefaultTemplate = nil;
    }
    return self;
}
@end
