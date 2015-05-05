//
//  FileSystemItem.m
//  Lonkero
//
//  Created by Kati Haapamäki on 31.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "FileSystemItem.h"

@implementation FileSystemItem

-(NSURL *) URL {
    return [NSURL URLWithString:[self.path stringByExpandingTildeInPath]];
}

-(NSURL *) fileURL {
    return [NSURL fileURLWithPath:[self.path stringByExpandingTildeInPath]];
}

-(NSString *)itemName {
    return [[_path stringByExpandingTildeInPath] lastPathComponent];
}
-(NSString *)parentItemName {
    return [[[_path stringByExpandingTildeInPath] stringByDeletingLastPathComponent]  lastPathComponent];
}

-(NSString *)pathByExpandingTildeInPath {
    return [_path stringByExpandingTildeInPath];
}

-(void)setPathByAbbreviatingTildeInPath:(NSString *)path {
    [self setPath:[path stringByAbbreviatingWithTildeInPath]];
}

-(NSString *)URLStylePath {
    return [[self fileURL] description];
}

+(FileSystemItem *)systemRootFolder {
    FileSystemItem *newFolder = [[FileSystemItem alloc] initWithPath:@"/" andNickName:@""];
    return newFolder;
}

//
+(NSArray *)getDirectoryContentForFolder:(FileSystemItem *)folder includeFiles:(BOOL)includeFiles includeFolders:(BOOL)includeFolders includeSubDirectories:(BOOL)includeSubDirectories {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    int dirEnumOptions = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles );
    
    if (!includeSubDirectories) dirEnumOptions |= NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSInteger depthOfRootFolder = [[[folder fileURL] pathComponents] count];
    
    NSDirectoryEnumerator *dirEnum = [fileMgr enumeratorAtURL:[folder fileURL]
                                   includingPropertiesForKeys:@[NSURLNameKey,
                                                               NSURLIsDirectoryKey,
                                                               NSURLIsAliasFileKey,
                                                               NSURLIsPackageKey,
                                                               NSURLFileSizeKey,
                                                               NSURLCreationDateKey,
                                                               NSURLLabelNumberKey,
                                                               NSURLLocalizedLabelKey,
                                                               NSURLLocalizedNameKey,
                                                               NSURLContentModificationDateKey]
                                                      options:dirEnumOptions
                                                 errorHandler:nil];
    
    for (NSURL *currentURL in dirEnum) {
        BOOL isDir = [FileSystemItem isURLDirectory:currentURL];
        BOOL includeBasedOnFileOrFolder = (includeFiles && !isDir) || (includeFolders && isDir);
        
        if (includeBasedOnFileOrFolder) {
            FileSystemItem *entryItem = [[FileSystemItem alloc] initWithURL:currentURL];
            NSMutableArray *relativePathComponents = [NSMutableArray arrayWithArray:[currentURL pathComponents]];
            [relativePathComponents removeObjectsInRange:NSMakeRange(0, depthOfRootFolder)];
            entryItem.relativePath = [NSString pathWithComponents:relativePathComponents];
            [result addObject:entryItem];
        }
    }
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [result sortUsingDescriptors:@[sortDesc]];
    return [NSArray arrayWithArray:result];
}


+(BOOL)isURLDirectory:(NSURL *)URL {
    NSNumber *isDirectory = @0;
    NSNumber *isPackage = @0;
    [URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    [URL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
    return  ([isDirectory boolValue] && ![isPackage boolValue]);
}


+(NSInteger)createDirectoryWithIntermediatesInheritingPermissions:(FileSystemItem *)aFolder errString:(NSString**)errStr {
    NSArray *pathComponets = [NSArray arrayWithArray:[aFolder.pathByExpandingTildeInPath pathComponents]];
    NSNumber *lastSeenPosix;
    NSInteger errcode = 0;
    for (NSInteger index = 0; index < [pathComponets count]; index++) {
        NSString *currentPath = [NSString pathWithComponents:[pathComponets subarrayWithRange:NSMakeRange(0, index+1)]];
        FileSystemItem *currentDirectoryLevel = [[FileSystemItem alloc] initWithPath:currentPath andNickName:@""];
        if (currentDirectoryLevel.itemExists) {
            lastSeenPosix = currentDirectoryLevel.posix;
        } else {
            errcode = [self createDirectory:currentDirectoryLevel];
            if (errcode!=0) {
                if (*errStr != nil) *errStr = [NSString stringWithString:currentDirectoryLevel.path];
                return errcode;
            }
            [self setPosix:lastSeenPosix toItem:currentDirectoryLevel];
                if (*errStr != nil) *errStr = [NSString stringWithString:currentDirectoryLevel.path];
            if (errcode!=0) return errcode;
        }
    }
    return 0;
}

+(NSInteger)createDirectory:(FileSystemItem*)aFolder {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fmError;
    BOOL folderCreated = [fm createDirectoryAtPath:aFolder.pathByExpandingTildeInPath withIntermediateDirectories:NO attributes:0 error:&fmError];
    if (fmError || !folderCreated ) return ErrCouldntCreateFolder;
    return 0;
}

+(NSInteger)setPosix:(NSNumber*)posix toItem:(FileSystemItem*)anItem {
    NSDictionary *attributes = @{NSFilePosixPermissions: posix};
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
    [fm setAttributes:attributes ofItemAtPath:anItem.pathByExpandingTildeInPath error:&err];
    if (err) return ErrSettingPosix;
    return 0;
}

-(void)readPropertiesFromFileSystem {
    [self setPropertiesByURL:[self fileURL]];
}


-(void)setPropertiesByURL:(NSURL *) URL {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL URLExists = [fm fileExistsAtPath:[URL path] isDirectory:&isDir];
    
    _path = [NSString stringWithString:[[URL path] stringByAbbreviatingWithTildeInPath]];
    _isRootObject = NO;
    _itemExists = URLExists;
    _fileSize = 0;
    
    if (URLExists) {
        
        _isDirectory = isDir;
        _isExpandable = isDir;
        
        NSDate *modificationDate;
        NSDate *creationDate;
        NSNumber *isPackage = @0;
        NSNumber *hasHiddenExtendsion = @0;
        NSNumber *fileSizeNSNumber = @0LL;
        NSNumber *isAlias = @0;
        NSNumber *labelNSNumber;
        NSString *labelText;
        NSImage *icon;
        
        [URL getResourceValue:&isAlias               forKey:NSURLIsAliasFileKey                      error:nil];
        [URL getResourceValue:&modificationDate      forKey:NSURLContentModificationDateKey          error:nil];
        [URL getResourceValue:&creationDate          forKey:NSURLCreationDateKey                     error:nil];
        [URL getResourceValue:&fileSizeNSNumber      forKey:NSURLFileSizeKey                         error:nil];
        [URL getResourceValue:&isPackage             forKey:NSURLIsPackageKey                        error:nil];
        [URL getResourceValue:&labelNSNumber         forKey:NSURLLabelNumberKey                      error:nil];
        [URL getResourceValue:&labelText             forKey:NSURLLocalizedLabelKey                   error:nil];
        [URL getResourceValue:&hasHiddenExtendsion   forKey:NSURLHasHiddenExtensionKey               error:nil];
        
        [URL getResourceValue:&icon   forKey:NSURLEffectiveIconKey               error:nil];
        
        _isAlias = [isAlias boolValue];
        _isPackage = [isPackage boolValue];
        _modificationDate = modificationDate;
        _creationDate = creationDate;
        _labelNumber = [labelNSNumber integerValue];
        _hasHiddenExtension = [hasHiddenExtendsion boolValue];
        _icon = nil;
        if(!isDir) {
           _icon = icon;
        }
        
        NSDictionary *attributes = [fm attributesOfItemAtPath:[URL path] error:nil];
        _posix = attributes[NSFilePosixPermissions];
        _groupId = attributes[NSFileOwnerAccountID];
        _ownerId = attributes[NSFileGroupOwnerAccountID];
        _groupName = attributes[NSFileOwnerAccountName];
        _ownerName = attributes[NSFileGroupOwnerAccountName];
        
        if (!_isDirectory && !_isPackage) {
            NSNumber *fileSize = @0LL;
            [URL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
            _fileSize = [fileSizeNSNumber longLongValue];
        }
    } else {
        
    }
    if ([[URL pathComponents] count] <=1) {
        _isRootObject = YES;
    }
    
}


#pragma mark -
#pragma mark INIT AND CODING

-(void) encodeWithCoder:(NSCoder *) coder {
    [coder encodeObject:self.nickName forKey:@"name"];
    [coder encodeObject:self.path forKey:@"path"];
    [coder encodeObject:@(_isRootObject) forKey:@"isRoot"];
    [coder encodeObject:@(_isExpandable) forKey:@"isExpandable"];
    [coder encodeObject:@(_isDirectory) forKey:@"isDirectory"];
    [coder encodeObject:@(_fileSize) forKey:@"fileSize"];
    [coder encodeObject:_createdBy forKey:@"createdBy"];
    [coder encodeObject:_lockedBy forKey:@"lockedBy"];
    [coder encodeObject:@(_isLocked) forKey:@"isLocked"];
    [coder encodeObject:@(_isAlias) forKey:@"isAlias"];
    [coder encodeObject:@(_isPackage) forKey:@"isPackage"];
    [coder encodeObject:_modificationDate forKey:@"modificationDate"];
    [coder encodeObject:_creationDate forKey:@"creationDate"];
    [coder encodeObject:_relativePath forKey:@"relativePath"];
    [coder encodeObject:@(_labelNumber) forKey:@"label"];
    [coder encodeObject:@(_hasHiddenExtension) forKey:@"hiddenExtension"];
    [coder encodeObject:_posix forKey:@"posix"];
    [coder encodeObject:_ownerId forKey:@"ownerID"];
    [coder encodeObject:_ownerName forKey:@"ownerName"];
    [coder encodeObject:_groupId forKey:@"groupID"];
    [coder encodeObject:_groupName forKey:@"groupName"];
}

-(id) initWithCoder:(NSCoder *) coder {
    _nickName = [coder decodeObjectForKey:@"name"];
    _path = [coder decodeObjectForKey:@"path"];
    _isRootObject = [[coder decodeObjectForKey:@"isRoot"] boolValue];
    _isExpandable = [[coder decodeObjectForKey:@"isExpandable"] boolValue];
    _isExpanded = NO;
    _isDirectory = [[coder decodeObjectForKey:@"isDirectory"] boolValue];
    _fileSize = [[coder decodeObjectForKey:@"fileSize"] longLongValue];
    _isCopied = NO;
    _creationDate = [coder decodeObjectForKey:@"creationDate"];
    _modificationDate = [coder decodeObjectForKey:@"modificationDate"];
    _createdBy = [coder decodeObjectForKey:@"createdBy"];
    _lockedBy = [coder decodeObjectForKey:@"lockedBy"];
    _isLocked = [[coder decodeObjectForKey:@"isLocked"] boolValue];
    _relativePath = [coder decodeObjectForKey:@"relativePath"];
    _labelNumber = [[coder decodeObjectForKey:@"label"] integerValue];
    _hasHiddenExtension = [[coder decodeObjectForKey:@"hiddenExtension"] boolValue];
    _posix = [coder decodeObjectForKey:@"posix"];
    _ownerId = [coder decodeObjectForKey:@"ownerID"];
    _ownerName = [coder decodeObjectForKey:@"ownerName"];
    _groupId = [coder decodeObjectForKey:@"groupID"];
    _groupName = [coder decodeObjectForKey:@"groupName"];
    return self;
}


-(id)initWithOpenDialogForFolderSelection {
    NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
    [openDlg setCanChooseFiles:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setAnimationBehavior:NSWindowAnimationBehaviorNone];
    if ([openDlg runModal] == NSOKButton) {
        self = [super init];
        if (self) {
            [self setPropertiesByURL:[openDlg URL]];
            _path = [[[openDlg URL] path] stringByAbbreviatingWithTildeInPath];
            _nickName = @"";
        }
        return self;
    }
    return nil;
}

-(id) init {
    self = [super init];
    if (self) {
        _nickName = @"";
        _path = @"";
        _isRootObject = NO;
        _isExpanded = NO;
        _isExpandable = NO;
        _isRootObject = NO;
        _pathToCopyExists = NO;
        _pathToCopy = nil;
        _itemExists = NO;
        _isDirectory = NO;
        _fileSize = 0;
        _relativePath = nil;
        _isMaster = NO;
        _isParent = NO;
        _isTarget = NO;
    }
    return self;
}

-(void)updateExistingStatus {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL URLExists = [fm fileExistsAtPath:[self pathByExpandingTildeInPath] isDirectory:&isDir];
    _itemExists = URLExists;
    _isDirectory = isDir;
}



-(id) initWithPath:(NSString *)path andNickName:(NSString *)name {
    self = [super init];
    if (self) {
        if ([NSString isNotEmptyString:path]) {
            [self setPropertiesByURL:[NSURL fileURLWithPath:path]];
        }
        _nickName = name;
    }
    return self;
}
-(id) initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        [self setPropertiesByURL:URL];
        _nickName = @"";
        _isExpanded = NO;
        _isExpanded = NO;
        _isLocked = NO;
        _createdBy = @"";
        _lockedBy = @"";
        _isCopied = NO;
        _pathToCopy = nil;
        _isPathToCopyValid = NO;
        _relativePath = nil;
        _pathToCopyIsDirectory = NO;
        _isMaster = NO;
        _isParent = NO;
        _isTarget = NO;
    }
    return self;
}

-(NSString *) description {
    return [NSString stringWithFormat:@"%@", self.path];
}

-(id) copyWithZone:(NSZone *)zone {
    
    
    FileSystemItem *newFolder = [[FileSystemItem allocWithZone:zone] init];
    //newFolder = [self copy];
   
    newFolder.path = [_path copy];
    newFolder.nickName = [_nickName copy];
    newFolder.isRootObject = _isRootObject;
    newFolder.isExpandable = _isExpandable;
    newFolder.isExpanded = _isExpanded;
    newFolder.itemExists = _itemExists;
    newFolder.isDirectory = _isDirectory;
    newFolder.fileSize = _fileSize;
    newFolder.pathToCopy = [_pathToCopy copy];
    newFolder.pathToCopyExists = _pathToCopyExists;
    newFolder.createdBy = [_createdBy copy];
    newFolder.creationDate = [_creationDate copy];
    newFolder.modificationDate = _modificationDate;
    newFolder.isCopied = _isCopied;
    newFolder.isLocked = _isLocked;
    newFolder.lockedBy = [_lockedBy copy];
    newFolder.isAlias = _isAlias;
    newFolder.isPackage = _isPackage;
    newFolder.isPathToCopyValid = _isPathToCopyValid;
    newFolder.relativePath = [_relativePath copy];
    newFolder.pathToCopyIsDirectory = _pathToCopyIsDirectory;
    newFolder.labelNumber = _labelNumber;
    newFolder.hasHiddenExtension = _hasHiddenExtension;
    newFolder.isParent = _isParent;
    newFolder.isMaster = _isMaster;
    newFolder.isTarget = _isTarget;
    return newFolder;
}

@end
