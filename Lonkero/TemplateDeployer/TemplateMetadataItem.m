//
//  TemplateMetadataItem.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateMetadataItem.h"


@implementation TemplateMetadataItem

-(void)readTemplateDirectoryContents {
    _templateContents = [FileSystemItem getDirectoryContentForFolder:_usedTemplate.location includeFiles:YES includeFolders:YES includeSubDirectories:YES];
}

-(void)readDeployedDirectoryContents {
    _deployedContents = [FileSystemItem getDirectoryContentForFolder:_creationMasterFolder includeFiles:YES includeFolders:YES includeSubDirectories:YES];
}

-(void)setAsMasterFolderAsDepthOf:(NSInteger) depth {
    _isMasterFolder = [NSNumber numberWithBool:YES];
    _isParentFolder = [NSNumber numberWithBool:NO];
    _depth = [NSNumber numberWithInteger:depth];
}

-(void)setAsParenFolderAsDepthOf:(NSInteger)depth {
    _isMasterFolder = [NSNumber numberWithBool:NO];
    _isParentFolder = [NSNumber numberWithBool:YES];
    _isTargetFolder = [NSNumber numberWithBool:NO];
    _depth = [NSNumber numberWithInteger:depth];
}

-(void)setAsTargetFolder {
    // don't get confused here, target can be master but not a parent.
    _isTargetFolder = [NSNumber numberWithBool:YES];
    _isParentFolder = [NSNumber numberWithBool:NO];
    _depth = [NSNumber numberWithInteger:0];
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
        _templateContents = [NSArray array];
        _deployedContents = [NSArray array];
        _isArchived = [NSNumber numberWithBool:NO];
        _markedToBeArchived = [NSNumber numberWithBool:NO];
        _isRemoved = [NSNumber numberWithBool:NO];
        _isAdditionalDeployment = [NSNumber numberWithBool:NO];
        _archiveLocation = [[FileSystemItem alloc] init];
        _archiveDescription = @"";
        _depth = [NSNumber numberWithLong:0];
        _creationDate = [NSDate date];
        _creator = NSUserName();
        _creatorFullName = NSFullUserName();
        _parametersForParentLevel = [[NSDictionary alloc] init];
        _isMasterFolder = [NSNumber numberWithBool:NO];
        _isParentFolder = [NSNumber numberWithBool:NO];
        _isTargetFolder = [NSNumber numberWithBool:NO];
    }
    return self;
}

@end
