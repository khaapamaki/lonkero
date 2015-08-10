//
//  MetadataBrowserDeploymentTable.h
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TemplateMetadataItem.h"

@interface MetadataBrowserDeployment : NSObject

@property NSString *templateName;
@property NSString *deploymentDate;
@property NSString *masterFolderName;
@property NSString *deploymentId;
@property NSString *version;
@property TemplateMetadataItem *metadataItem;
-(id)initWithMetadataItem:(TemplateMetadataItem*) metaItem;

@end
