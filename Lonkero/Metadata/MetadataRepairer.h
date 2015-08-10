//
//  MetadataRepairer.h
//  Lonkero
//
//  Created by Kati Haapamäki on 15.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TemplateMetadata.h"
#import "Template.h"
#import "TemplateDeployer.h"

@interface MetadataRepairer : NSObject {
    
}

@property Template *usedTemplate;

-(TemplateMetadataItem*)convertMetadataItem:(TemplateMetadataItem*)metadataItem FromVersion:(NSString*)fromVersion toVersion:(NSString*)toVersion;


@end
