//
//  TemplateMetadata.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateMetadata.h"

@implementation TemplateMetadata

-(NSInteger)count {
    return [_metadataArray count];
    
}
-(void)addItem:(TemplateMetadataItem *)item {
    [_metadataArray addObject:item];
}
-(void)writeToFolder:(FileSystemItem*)folder {
    NSString *path = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, METADATA_FILENAME];
    [NSKeyedArchiver archiveRootObject:self toFile:path];
    FileSystemItem *metadataFile = [[FileSystemItem alloc] initWithPath:path andNickName:@""];
    
    // get permissions from enclosing folder
    short posix = [folder.posix shortValue] & 0666;
    [FileSystemItem setPosix:@(posix) toItem:metadataFile];
}

-(void) encodeWithCoder: (NSCoder *) coder {
    NSString *version = METADATA_VERSION;
    [coder encodeObject:version forKey:@"metadataVersion"];
    [coder encodeObject:_metadataArray forKey:@"metadataArrayForTemplates"];
}

-(id) initWithCoder:(NSCoder *) coder {
    _metadataArray = [coder decodeObjectForKey:@"metadataArrayForTemplates"];
    return self;
}

-(id) initByReadingFromFolder:(FileSystemItem*)folder {
    NSString *path = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, METADATA_FILENAME];
    NSFileManager *fm = [[NSFileManager alloc] init];

        if (self = [super init]) {
            if ([fm fileExistsAtPath:path]) {

                    TemplateMetadata *newMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
                    self = newMetadata;


            } else {
                _metadataArray = [[NSMutableArray alloc] init];
            }
        }
        return self;
}

-(void)removeMetadataItemWithId:(NSString *)deploymentId {
    NSMutableArray *newArray = [NSMutableArray array];
    for (TemplateMetadataItem *currentItem in _metadataArray) {
        if (![currentItem.deploymentID isEqualToString:deploymentId]) {
            [newArray addObject:currentItem];
        }
    }
    _metadataArray = newArray;
}

-(TemplateMetadataItem *)metadataItemWithId:(NSString *)deploymentId {
    for (TemplateMetadataItem *currentItem in _metadataArray) {
        if ([currentItem.deploymentID isEqualToString:deploymentId]) {
            return currentItem;
        }
    }
    return nil;
}

-(BOOL)hasAnyMaster {
    BOOL result = NO;
    for (TemplateMetadataItem *metaItem in _metadataArray) {
        if  ([metaItem.isMasterFolder boolValue]) result = YES;
    }
    return result;
}

-(BOOL)hasAnyParent {
    BOOL result = NO;
    for (TemplateMetadataItem *metaItem in _metadataArray) {
        if  ([metaItem.isParentFolder boolValue]) result = YES;
    }
    return result;
}

-(id) init {
    if (self = [super init]) {
        _metadataArray = [[NSMutableArray alloc] init];
    }
    return self;
}
@end
