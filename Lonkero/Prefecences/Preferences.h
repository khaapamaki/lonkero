//
//  Preferences.h
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "Definitions.h"
#import "PreferencesController.h"

@interface Preferences : NSObject {
    PreferencesController *preferencesController;
}

@property NSMutableArray *templateSetLocations; // retain?
@property NSString *defaultTemplatePath;
@property NSString *defaultTemplateName;

-(void) savePreferences;
-(id) initWithLoadingPreferences;

@end
