//
//  TemplateMetadataItem.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateMetadataItem.h"


@implementation TemplateMetadataItem

/**
 *  Reads directory contents form the original template location and stores it
 *
 *  Is used for master level metadata items to store extra data about deployed templete
 *
 *  @see readDeployedDirectoryContents
 */
-(void)readTemplateDirectoryContents {
    _templateContents = [FileSystemItem getDirectoryContentForFolder:_usedTemplate.location includeFiles:YES includeFolders:YES includeSubDirectories:YES];
}

/**
 *  Reads directory contents form the used deployment target folder and stores it
 *
 *  Is used for master level metadata items to store extra data about deployed content
 *
 *  @see readTemplateDirectoryContents
 */

-(void)readDeployedDirectoryContents {
    _deployedContents = [FileSystemItem getDirectoryContentForFolder:_creationMasterFolder includeFiles:YES includeFolders:YES includeSubDirectories:YES];
}

/**
 *  Sets master folder flag to YES and parent folder flag to NO, and sets depth to a given value.
 *
 *  @param depth A depth
 */

-(void)setAsMasterFolderAsDepthOf:(NSInteger) depth {
    _isMasterFolder = @YES;
    _isParentFolder = @NO;
    _depth = @(depth);
}
/**
 *  Sets parent folder flag to YES and master folder flag to NO, and sets depth to a given value.
 *
 *  @param depth A depth
 */
-(void)setAsParenFolderAsDepthOf:(NSInteger)depth {
    _isMasterFolder = @NO;
    _isParentFolder = @YES;
    _isTargetFolder = @NO;
    _depth = @(depth);
}

/**
 *  Sets target folder flag to YES and parent folder flag to NO, and sets depth to 0.
 *
 *  @note Target folder can also be a master folder at the same time, but not a parent.
 *
 *  Target folder simply means the root folder of the whole deployment process. Folder above parent folders.
 *  Master folder is the root for the template structure, below parent folders
 */

-(void)setAsTargetFolder {
    // don't get confused here, target can be master but not a parent.
    _isTargetFolder = @YES;
    _isParentFolder = @NO;
    _depth = @0;
}

-(void) encodeWithCoder: (NSCoder *) coder {
    NSString *version = METADATA_VERSION;
    if (![_metadataVersion isEqualToString:@""] && _metadataVersion!=nil) {
        version = _metadataVersion;
    }
    [coder encodeObject:version forKey:@"metadataVersion"];
    [coder encodeObject:_usedTemplate forKey:@"template"];
    [coder encodeObject:_deploymentID forKey:@"deploymentID"];
    [coder encodeObject:_usedTemplate.templateId forKey:@"templateID"];
    [coder encodeObject:_usedTemplate.groupId forKey:@"groupID"];
    [coder encodeObject:_creationDate forKey:@"creationDate"];
    [coder encodeObject:_creator forKey:@"creator"];
    [coder encodeObject:_creatorFullName forKey:@"creatorFullName"];
    [coder encodeObject:_isMasterFolder forKey:@"isMasterFolder"];
    [coder encodeObject:_isParentFolder forKey:@"isParentFolder"];
    [coder encodeObject:_isTargetFolder forKey:@"isTargetFolder"];
    [coder encodeObject:_depth forKey:@"depthInFolderHierarchy"];
    [coder encodeObject:_creationRootFolder forKey:@"rootFolder"];
    [coder encodeObject:_creationMasterFolder forKey:@"masterFolder"];
    [coder encodeObject:_templateContents forKey:@"templateDirectoryContents"];
    [coder encodeObject:_deployedContents forKey:@"deployedDirectoryContents"];
    [coder encodeObject:_parametersForParentLevel forKey:@"usedParametersTillParentLevel"];
    [coder encodeObject:_isArchived forKey:@"isArchived"];
    [coder encodeObject:_markedToBeArchived forKey:@"isMarkedToBeArchived"];
    [coder encodeObject:_isRemoved forKey:@"isRemoved"];
    [coder encodeObject:_isPartialDeployment forKey:@"isPartialDeployment"];
    [coder encodeObject:_isAdditionalDeployment forKey:@"isAdditionalDeployment"];
    [coder encodeObject:_archiveLocation forKey:@"archiveLocation"];
    [coder encodeObject:_archiveDescription forKey:@"archiveDescription"];
    [coder encodeObject:_parentFolders forKey:@"parentFolders"];

}

-(id) initWithCoder:(NSCoder *) coder {
    _metadataVersion = [coder decodeObjectForKey:@"metadataVersion"];
    _usedTemplate = [coder decodeObjectForKey:@"template"];
    _deploymentID = [coder decodeObjectForKey:@"deploymentID"];
    _templateID = [coder decodeObjectForKey:@"templateID"];
    _groupID = [coder decodeObjectForKey:@"groupID"];
    _creationDate = [coder decodeObjectForKey:@"creationDate"];
    _creator = [coder decodeObjectForKey:@"creator"];
    _creatorFullName = [coder decodeObjectForKey:@"creatorFullName"];
    _isMasterFolder = [coder decodeObjectForKey:@"isMasterFolder"];
    _isParentFolder = [coder decodeObjectForKey:@"isParentFolder"];
    _isTargetFolder = [coder decodeObjectForKey:@"isTargetFolder"];
    _depth = [coder decodeObjectForKey:@"depthInFolderHierarchy"];
    _creationRootFolder = [coder decodeObjectForKey:@"rootFolder"];
    _creationMasterFolder = [coder decodeObjectForKey:@"masterFolder"];
    _templateContents = [coder decodeObjectForKey:@"templateDirectoryContents"];
    _deployedContents = [coder decodeObjectForKey:@"deployedDirectoryContents"];
    _parametersForParentLevel = [coder decodeObjectForKey:@"usedParametersTillParentLevel"];
    _isArchived = [coder decodeObjectForKey:@"isArchived"];
    _markedToBeArchived = [coder decodeObjectForKey:@"isMarkedToBeArchived"];
    _isRemoved = [coder decodeObjectForKey:@"isRemoved"];
    _isPartialDeployment = [coder decodeObjectForKey:@"isPartialDeployment"];
    _isAdditionalDeployment = [coder decodeObjectForKey:@"isAdditionalDeployment"];
    _archiveLocation = [coder decodeObjectForKey:@"archiveLocation"];
    _archiveDescription = [coder decodeObjectForKey:@"archiveDescription"];
    _parentFolders = [coder decodeObjectForKey:@"parentFolders"];

    return self;
}

-(id)initWithTemplate:(Template *)usedTemplate targetFolder:(FileSystemItem *)targetFolder {
    if (self = [super init]) {
        _metadataVersion = METADATA_VERSION;
        _usedTemplate = usedTemplate;
        _groupID = @"";
        _templateID = @"";
        _deploymentID = @"";
        _creationRootFolder = targetFolder;
        _templateContents = @[];
        _deployedContents = @[];
        _isArchived = @NO;
        _markedToBeArchived = @NO;
        _isRemoved = @NO;
        _isAdditionalDeployment = @NO;
        _archiveLocation = [[FileSystemItem alloc] init];
        _archiveDescription = @"";
        _depth = @0L;
        _creationDate = [NSDate date];
        _creator = NSUserName();
        _creatorFullName = NSFullUserName();
        _parametersForParentLevel = [[NSDictionary alloc] init];
        _parentFolders = [NSArray array];
        _isMasterFolder = @NO;
        _isParentFolder = @NO;
        _isTargetFolder = @NO;
    }
    return self;
}

@end
