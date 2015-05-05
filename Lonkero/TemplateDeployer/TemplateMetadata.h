//
//  TemplateMetadata.h
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TemplateMetadataItem.h"
#import "Definitions.h"

@interface TemplateMetadata : NSObject

@property NSMutableArray *metadataArray;
-(void)addItem:(TemplateMetadataItem*)item;
-(void)writeToFolder:(FileSystemItem*)folder;

-(id) initByReadingFromFolder:(FileSystemItem*)folder;
-(BOOL) hasAnyMaster;
-(BOOL) hasAnyParent;

@end
