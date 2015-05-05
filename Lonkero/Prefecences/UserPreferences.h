//
//  UserPreferences.h
//  Lonkero
//
//  Created by Kati Haapamäki on 20.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileSystemItem.h"
#import "Definitions.h"

@interface UserPreferences : NSObject <NSCopying>

/*
@property BOOL closeWindowAfterDeployment;
@property BOOL closeApplicationAfterDeployment;
@property BOOL openTargetFolderAfterDeployment;
@property BOOL openMasterFolderAfterDeployment;
*/
@property FileSystemItem *locationOfDefaultTemplate;
@property NSNumber *postDeploymentAction;

-(id)initWithLoadingUserPreferences;
-(void)saveUserPreferences;

@end
