//
//  TemplateDeployer.h
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "Template.h"
#import "TemplateMetadata.h"
#import "NSString+Extras.h"
#import "FileSystemItem.h"
#import "NSMutableDictionary-Merge.h"

@interface TemplateDeployer : NSObject {
    Template *_theTemplate;
    FileSystemItem *_theTargetFolder;
}

@property Template* theTemplate;
@property FileSystemItem *theTargetFolder;

-(NSInteger)deployToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr;

#pragma mark -
#pragma mark FILESYSTEM OP

// this is used for creation of parent folders that doesn't already exist
-(NSInteger)createFoldersIfNeeded:(NSArray *)folders defaultPermissions:(NSDictionary *)defaultPermissions;
-(NSInteger)copyFilesToFolder:(FileSystemItem*)folder defaultPermissions:(NSDictionary *)defaultPermissions errString:(NSString**) errStr;


#pragma mark -
#pragma mark PARAMETER PARSING


+(NSString *) parseParametersForString:(NSString*)aString withTemplate:(Template*)aTemplate;
+(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents withTemplate:(Template*)aTemplate error:(NSNumber**)err;
+(NSArray *) parentFoldersForTemplate:(Template *)aTemplate withTargetFolder:(FileSystemItem *)targetFolder error:(NSNumber **)err;

/* +(FileSystemItem *)masterFolderForTemplate:(Template*)aTemplate andTargetFolder:(FileSystemItem*)aTargetFolder;
-(NSString *) masterFolderNameByParsingTags;
-(FileSystemItem*) generateMasterFolderUsingParentArray:(NSArray*)array;
+(FileSystemItem *)generateMasterFolderUsingParentArray:(NSArray *)array withTemplate:(Template*)aTemplate withTargetFolder:(FileSystemItem*)targetFolder;
*/

+(NSString*) parseParametersForPath:(NSString *)path withTemplate:(Template *)aTemplate;

#pragma mark -
#pragma mark METADATA

// these methods generate dictionaries of tags(=parameters) used for name generation of any parent folder level
// they are saved as metadata and used for autocompletion of fields when selecting folders created with earlier template deployments

-(void)writeMetadataToFolders:(NSArray *)folders involvedParametersArray:(NSArray *)parametersArray deploymentId:(NSString*)deploymentId;

+(NSArray *)parentFolderParametersInvolved:(Template *)aTemplate;
+(NSDictionary *)dictionaryWithInvolvedParametersForParentFolder:(NSString *)aString withTemplate:(Template *)aTemplate;

#pragma mark -
#pragma mark INIT

-(id)initWithTemplate:(Template*)aTemplate;


@end
