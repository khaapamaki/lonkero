//
//  UserPreferences.h
//  Lonkero
//
//  Created by Kati Haapamäki on 20.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserPreferences : NSObject

@property BOOL closeWindowAfterDeployment;
@property BOOL closeApplicationAfterDeployment;
@property BOOL openTargetFolderAfterDeployment;
@property BOOL openMasterFolderAfterDeployment;

@end