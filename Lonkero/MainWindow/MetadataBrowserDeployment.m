//
//  MetadataBrowserDeploymentTable.m
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "MetadataBrowserDeployment.h"

@implementation MetadataBrowserDeployment


-(id)initWithMetadataItem:(TemplateMetadataItem *) metaItem {
    if (self = [super init]) {
        _templateName = metaItem.usedTemplate.name;
        _deploymentDate = [metaItem.creationDate description];
        _deploymentId = [metaItem.deploymentID stringByInsertingHyphensEvery:4];
        _version = metaItem.metadataVersion;
        _metadataItem = metaItem;
        NSMutableString *name = [NSMutableString stringWithString:@""];
        
        for (FileSystemItem *parentFolder in metaItem.parentFolders) {
            if (parentFolder.isMaster  || parentFolder.isParent) {
                    [name appendString:parentFolder.itemName];
                if (parentFolder != [metaItem.parentFolders lastObject]) {
                    [name appendString:@"/"];
                }
            }


        }
        _masterFolderName = [NSString stringWithString:name];
    }
    return self;
}

-(id)init {
    if (self = [super init]) {
        _templateName = @"";
        _deploymentDate =  @"";
        _deploymentId = @"";
        _masterFolderName = @"";
    }
    return self;
}


@end
