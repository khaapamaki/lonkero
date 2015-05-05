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
@property NSNumber *isMasterFolder; ///< Master folder flag, metadata item is for deployment master, the root of template structure
@property NSNumber *isParentFolder; ///< Parent folder flag, metadata item is for deployment parent
@property NSNumber *isTargetFolder; ///< Targe folder flag, metadata item is for deployment root, above all parents
@property NSNumber *depth; ///< The depth for the metadata item in deployment folder hierarchy. Level 0 is the target folder
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

/**
 *  Metadata item stores the information of the deployment process in high detail
 *
 *  Metadata is saved to every level starting from the target folder level, every parent folder CREATED based on template parameters during the deployment process, and finally for the master folder level.
 *
 *  Master folder level is the root level for the template folder structure, and folders below that are part of the template structure. Metadata is NOT saved to folders that belongs to template itself.
 */

@end

