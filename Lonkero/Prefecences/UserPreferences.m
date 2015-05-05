//
//  UserPreferences.m
//  Lonkero
//
//  Created by Kati Haapamäki on 20.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "UserPreferences.h"

@implementation UserPreferences

-(id)init {
    self = [super init];
    if (self) {
        _closeApplicationAfterDeployment = NO;
        _closeWindowAfterDeployment = YES;
        _openMasterFolderAfterDeployment = YES;
        _openTargetFolderAfterDeployment = NO;
    }
    return self;
}
@end
