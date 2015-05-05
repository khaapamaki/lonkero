//
//  Preferences.h
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Definitions.h"
#import "FileSystemItem.h"
#import "TemplateDeployer.h"

@class PreferencesController;

@interface Preferences : NSObject <NSCopying> {
    PreferencesController *preferencesController;
}

@property NSMutableArray *templateSetLocations; // retain?
@property NSString *defaultDateFormat;

-(void) savePreferences;
-(id) initWithLoadingPreferences;
-(NSMutableArray*)templateSetLocationsByParsingSystemParameters;

@end
