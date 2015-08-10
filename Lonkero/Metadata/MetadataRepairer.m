//
//  MetadataRepairer.m
//  Lonkero
//
//  Created by Kati Haapamäki on 15.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "MetadataRepairer.h"

@implementation MetadataRepairer

-(TemplateMetadataItem *)convertMetadataItem:(TemplateMetadataItem *)metadataItem FromVersion:(NSString *)fromVersion toVersion:(NSString *)toVersion {
    
    if ([fromVersion isEqualToString:@"0.4"] && [toVersion isEqualToString:@"0.5"] && _usedTemplate != nil) {
    
        TemplateDeployer *templateDeployer = [[TemplateDeployer alloc] initWithTemplate:_usedTemplate];  // used template .location tyhjä -> crash
        FileSystemItem *targetFolder = [metadataItem creationRootFolder];
        
        NSInteger depth = [metadataItem.depth integerValue];
        NSArray *regeneratedMetadataItemsForAllParents = [templateDeployer processWithTargetFolder:targetFolder options:0 deploymentId:nil err:nil errString:nil];
        
        TemplateMetadataItem *regeneratedMetadataItem = regeneratedMetadataItemsForAllParents[depth];
        
        
        metadataItem.parentFolders = [regeneratedMetadataItem.parentFolders copy];
        metadataItem.metadataVersion = @"0.4.1";
        return metadataItem;
    } else {
        return metadataItem;
    }
}


@end
