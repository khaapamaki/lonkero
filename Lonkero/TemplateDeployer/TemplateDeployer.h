//
//  TemplateDeployer.h
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

/** @class TemplateDeployer
 
 Deployes a template, parses parameters and saves metadata.
 
 Deploying includes folder creation and copying the files in the template
 
 */

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "Template.h"
#import "TemplateMetadata.h"
#import "NSString+Extras.h"
#import "FileSystemItem.h"
#import "NSMutableDictionary-Merge.h"
#import "NSDate+Extras.h"

@interface TemplateDeployer : NSObject {
    Template *_theTemplate;
    FileSystemItem *_theTargetFolder;
    NSDate *_deploymentStartDate;
}

@property Template* theTemplate;
@property FileSystemItem *theTargetFolder;

-(NSInteger)deployToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr;
-(NSInteger)rewriteMetadataToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr;
-(NSArray*)processWithTargetFolder:(FileSystemItem*)targetFolder options:(NSInteger)options deploymentId:(NSString*)deploymentId err:(NSNumber**)errNumCode errString:(NSString**)errStr;

#pragma mark -
#pragma mark FILESYSTEM OP

// this is used for creation of parent folders that doesn't already exist
-(NSInteger)createFoldersIfNeeded:(NSArray *)folders defaultPermissions:(NSDictionary *)defaultPermissions;
-(NSInteger)copyTemplateContentsToFolder:(FileSystemItem*)folder defaultPermissions:(NSDictionary *)defaultPermissions errString:(NSString**) errStr;

-(NSArray *) generateParentFolderArrayWithError:(NSNumber **)err;


#pragma mark -
#pragma mark PARAMETER PARSING



-(NSString*) parseParametersForString:(NSString*)aString;
-(NSString*) parseSystemParametersForString:(NSString *)aString;
-(NSString*) parseParametersForPathComponent:(NSString*)filename error:(NSNumber **)err;
-(NSArray*) parseParametersForPathComponents:(NSArray*)pathComponents error:(NSNumber**)err;
-(NSString*) parseParametersForPath:(NSString *)path;



/* +(FileSystemItem *)masterFolderForTemplate:(Template*)aTemplate andTargetFolder:(FileSystemItem*)aTargetFolder;
-(NSString *) masterFolderNameByParsingTags;
-(FileSystemItem*) generateMasterFolderUsingParentArray:(NSArray*)array;
+(FileSystemItem *)generateMasterFolderUsingParentArray:(NSArray *)array withTemplate:(Template*)aTemplate withTargetFolder:(FileSystemItem*)targetFolder;
*/



#pragma mark -
#pragma mark METADATA

-(void)writeMetadataTo:(NSArray *)folders withMetadataItems:(NSArray*)metadataItemArray deploymentId:(NSString*)deploymentId options:(NSInteger)options;
-(NSArray*)generateMetadataItemArrayForFolders:(NSArray *)folders involvedParametersArray:(NSArray *)parametersArray deploymentId:(NSString*)deploymentId;

// these methods generate dictionaries of tags(=parameters) until any parameter that creates a parent folder
// the array will have parameter dictionaries to all parent folders to be created
// they are saved as metadata and used for autocompletion of fields when selecting folders created with earlier template deployments


+(NSArray *)parentFolderParametersInvolved:(Template *)aTemplate;
+(NSDictionary *)dictionaryWithInvolvedParametersTillLevel:(NSInteger)level withTemplate:(Template *)aTemplate;


+(short)combinePosixForTargetFolder:(short)targetPosix andSourceFile:(short)sourcePosix;
+(short)combinePosixForTargetFolder:(short)targetPosix andSourceFolder:(short)sourcePosix;

#pragma mark -
#pragma mark INIT

-(id)initWithTemplate:(Template*)aTemplate;


@end
