//
//  TemplateMetadataItem.h
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileSystemItem.h"
#import "Definitions.h"
#import "Template.h"

@interface TemplateMetadataItem : NSObject

@property Template *usedTemplate;
@property NSDate *creationDate;
@property NSString *creator;
@property NSString *creatorFullName;
@property FileSystemItem *creationRootFolder;
@property FileSystemItem *creationMasterFolder;
@property NSNumber *isMasterFolder;
@property NSNumber *isParentFolder;
@property NSNumber *isTargetFolder;
@property NSNumber *depth;
@property NSArray *templateContents;
@property NSArray *deployedContents;
@property NSDictionary *parametersForParentLevel;
@property NSDictionary *parametersUsed;
@property NSString *templateID;
@property NSString *groupID;
@property NSString *metadataVersion;
@property NSArray *parentFolders;
@property NSNumber *isArchived;
@property NSNumber *markedToBeArchived;
@property NSNumber *isRemoved;
@property NSNumber *isPartialDeployment;
@property NSNumber *isAdditionalDeployment;
@property NSString *deploymentID;
@property FileSystemItem *archiveLocation;
@property NSString *archiveDescription;


-(id)initWithTemplate:(Template *)usedTemplate targetFolder:(FileSystemItem *)targetFolder;
-(void)setAsMasterFolderAsDepthOf:(NSInteger) depth;
-(void)setAsParenFolderAsDepthOf:(NSInteger) depth;
-(void)setAsTargetFolder;
-(void)readTemplateDirectoryContents;
-(void)readDeployedDirectoryContents;

@end
