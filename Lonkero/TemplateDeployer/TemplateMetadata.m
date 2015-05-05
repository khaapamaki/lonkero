//
//  TemplateMetadata.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateMetadata.h"

@implementation TemplateMetadata


/**
 *  Returns number of items in the metadata array
 *
 *  @return NSInteger
 */

-(NSInteger)count {
    return [_metadataArray count];
}

/**
 *  Adds a new metadata item to the metadata array
 *
 *  @param item A metadata item to be added
 */

-(void)addItem:(TemplateMetadataItem *)item {
    [_metadataArray addObject:item];
}

/**
 *  Writes metadata to given folder
 *
 *  Uses METADATA_FILENAME as file name.
 *
 *  @param folder A folder to write metadata to
 */

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


+(BOOL)metadataExisistAtFolder:(FileSystemItem*)aFolder {
        NSString *path = [NSString stringWithFormat:@"%@/%@", aFolder.pathByExpandingTildeInPath, METADATA_FILENAME];
        NSFileManager *fm = [[NSFileManager alloc] init];
        
        return [fm fileExistsAtPath:path];
}
/**
 *  Initializes the template object with the data read form a folder
 *
 *  Metadata is stored to @a _metadataArray mutable array. Array is empty if no metadata file is found from a folder.
 *
 *  @param folder A folder to search for a metadata
 *
 *  @return self
 */
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

/**
 *  Removes a metadata item from metadata array by its deployment id
 *
 *  @param deploymentId A deployment id
 */
-(void)removeMetadataItemWithId:(NSString *)deploymentId {
    NSMutableArray *newArray = [NSMutableArray array];
    for (TemplateMetadataItem *currentItem in _metadataArray) {
        if (![currentItem.deploymentID isEqualToString:deploymentId]) {
            [newArray addObject:currentItem];
        }
    }
    _metadataArray = newArray;
}

/**
 *  Returns a metadata item by its deployment id
 *
 *  @param deploymentId A deployment id
 *
 *  @return A metadata item (of the metadata array)
 */
-(TemplateMetadataItem *)metadataItemWithId:(NSString *)deploymentId {
    for (TemplateMetadataItem *currentItem in _metadataArray) {
        if ([currentItem.deploymentID isEqualToString:deploymentId]) {
            return currentItem;
        }
    }
    return nil;
}

/**
 *  Returns YES is any metadata item of the metadata array is set as master
 *
 */

-(BOOL)hasAnyMaster {
    BOOL result = NO;
    for (TemplateMetadataItem *metaItem in _metadataArray) {
        if  ([metaItem.isMasterFolder boolValue]) result = YES;
    }
    return result;
}

/**
 *  Returns YES is any metadata item of the metadata array is set as parent
 *
 */

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
