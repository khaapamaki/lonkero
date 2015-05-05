//
//  FileSystemItem.m
//  Lonkero
//
//  Created by Kati Haapamäki on 31.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "FileSystemItem.h"

@implementation FileSystemItem


#pragma mark GETTING AND SETTING PROPERTIES

/** Returns URL of the FileSystemItem

 @Note This cannot be used for many methods. Use fileURL intead.
 
 @See fileURL
 
 */

-(NSURL *) URL {
    return [NSURL URLWithString:[self.path stringByExpandingTildeInPath]];
}


/// Returns fileURL of the FileSystemItem

-(NSURL *) fileURL {
    if ([NSString isEmptyString:self.path]) {
        return nil;
    }
    return [NSURL fileURLWithPath:[self.path stringByExpandingTildeInPath]];
}


/// Returns last pathComponent (filename or foldername)

-(NSString *)itemName {
    return [[_path stringByExpandingTildeInPath] lastPathComponent];
}


/// Returns the second last pathComponent (parent)

-(NSString *)parentItemName {
    return [[[_path stringByExpandingTildeInPath] stringByDeletingLastPathComponent]  lastPathComponent];
}


/** Returns the path by expanding tilde
 
 @Note In this app, tilde format is often used for storing paths to be interchangable with other users.
        Thus expanding tilde is neccessary before file operations.
 
 @see setPathByAbbreviatingTildeInPath:(NSString *)path
 
 */

-(NSString *)pathByExpandingTildeInPath {
    return [_path stringByExpandingTildeInPath];
}


/** Sets path property of the object by first converting it to 'tilded' format.
 *
 * @param path A path to be converted and stored to the object
 *
 * @Note In this app, tilde format is often used for storing paths to be interchangable with other users.
 * Converting back to 'full' format is neccessary before file operations.
 *
 * @see pathByExpandingTildeInPath
 *
 */

-(void)setPathByAbbreviatingTildeInPath:(NSString *)path {
    [self setPath:[path stringByAbbreviatingWithTildeInPath]];
}


/// Returns a string with URL style format of the path.

-(NSString *)URLStylePath {
    return [[self fileURL] description];
}


/** Returns FileSystemItem object intialized with root folder '/'
 
 */

+(FileSystemItem *)systemRootFolder {
    FileSystemItem *newFolder = [[FileSystemItem alloc] initWithPath:@"/" andNickName:@""];
    return newFolder;
}


/// Returns path property.

-(NSString *) description {
    return [NSString stringWithFormat:@"%@", self.path];
}


#pragma mark -
#pragma mark FILE SYSTEM OPERATIONS


/** Returns YES, if the given URL is a directory or a package.
 
 @param URL An URL to be checked.
 
 */

+(BOOL)isURLDirectory:(NSURL *)URL {
    NSNumber *isDirectory = @0;
    NSNumber *isPackage = @0;
    [URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    [URL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
    return  ([isDirectory boolValue] && ![isPackage boolValue]);
}


/** Returns contents of a folder as an array of FileSystemItems.

 Resulting array will be ordered alphabetically.
 
 @param folder Folder as a FileSystemItem
 @param includeFiles Include files (BOOL)
 @param includeFolders Include folders (BOOL)
 @param includeSubDirectories Recursively add the contents of all subdirectories (BOOL)
 
 */

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



/** Creates folders with all intermediate folders that doesn't allready exist.
 
 Inherits permissions from the folder that is closest existing one.

 @param aFolder A folder as a FileSystemItem
 @param *errStr Pointer to the string for error description
 
 @return errcode as NSInteger
 
 */

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

/** Creates a folder
 
 @param aFolder A folder to be created as a FileSystemItem
 
 @return errcode as NSInteger, 0 if no error.
 
 */

+(NSInteger)createDirectory:(FileSystemItem*)aFolder {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fmError;
    BOOL folderCreated = [fm createDirectoryAtPath:aFolder.pathByExpandingTildeInPath withIntermediateDirectories:NO attributes:0 error:&fmError];
    if (fmError || !folderCreated ) return ErrCouldntCreateFolder;
    return 0;
}

/** Sets posix for a FileSystemItem
 
 @param posix Posix mask as NSNumber
 @param anItem An FileSystemItem to have posix set
 
 @return errcode as NSInteger, 0 if no error.
 
 */

+(NSInteger)setPosix:(NSNumber*)posix toItem:(FileSystemItem*)anItem {
    NSDictionary *attributes = @{NSFilePosixPermissions: posix};
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
    [fm setAttributes:attributes ofItemAtPath:anItem.pathByExpandingTildeInPath error:&err];
    if (err) return ErrSettingPosix;
    return 0;
}

/** Reads file/folder's properties to already existing and initialized FileSystemItem

 @note Assumes that @a path property is set already and file system item exists.
 
 @see setPropertiesByURL
 
 */

-(void)readPropertiesFromFileSystem {
    [self setPropertiesByURL:[self fileURL]];
}


/** Set file/folder properties with given URL
 
 Is used to initialize a FileSystemItem for the first time.
 
 @param URL An URL for the FileSystemItem
 
 @result If URL doens't exist the properties are not read, but @a itemExists property is set to NO.
 
 */


-(void)setPropertiesByURL:(NSURL *) URL {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL URLExists = [fm fileExistsAtPath:[URL path] isDirectory:&isDir];
    URL = [URL URLByStandardizingPath];
    
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

/// Updates itemExists property by current state of file or folder

-(void)updateExistingStatus {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    NSString *path = [self pathByExpandingTildeInPath];
    BOOL URLExists = [fm fileExistsAtPath:[self pathByExpandingTildeInPath] isDirectory:&isDir];
    _itemExists = URLExists;
    if (URLExists) _isDirectory = isDir;
}


/** Initializes a FileSystemItem object by letting user to select a folder in open dialog.
 
 @param URL First folder to open in the dialog.
 @return self if successful.
 @return nil if user cancels the operation.
 
 */

-(id)initWithOpenDialogForFolderSelection:(NSURL*) URL {
    NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
    [openDlg setCanChooseFiles:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setDirectoryURL:URL];
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

/** Initializes a FileSystemItem object by letting user to select a folder in open dialog.
 
 @return self if successful.
 @return nil if user cancels the operation.
 
 
 */

-(id)initWithOpenDialogForFolderSelection {
    NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
    [openDlg setCanChooseFiles:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setDirectoryURL:[[FileSystemItem systemRootFolder] fileURL]];
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
    [coder encodeObject:@(_isMaster) forKey:@"isMaster"];
    [coder encodeObject:@(_isParent) forKey:@"isParent"];
    [coder encodeObject:@(_isTarget) forKey:@"isTarget"];
    
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
    _isMaster = [[coder decodeObjectForKey:@"isMaster"] boolValue];
    _isParent = [[coder decodeObjectForKey:@"isParent"] boolValue];
    _isTarget = [[coder decodeObjectForKey:@"isTarget"] boolValue];
    _shouldCopy = NO;
    _filteredOut = NO;
    
    return self;
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
        _shouldCopy = NO;
        _filteredOut = NO;

    }
    return self;
}

/** Initializes a FileSystemItem with given path and nick name

Initialises the object and also reads file/folder parameters from the file system.
 
 @param path    A path to a file system item
 @param name    A nick name for the location. Is used for default locations.

 @return self

 */

-(id) initWithPath:(NSString *)path andNickName:(NSString *)name {
    self = [super init];
    if (self) {
        if ([NSString isNotEmptyString:[path stringByExpandingTildeInPath]]) {
            NSString *testPath = [path stringByExpandingTildeInPath];
            [self setPropertiesByURL:[NSURL fileURLWithPath:[path stringByExpandingTildeInPath]]];
        }
        _nickName = name;
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
        _shouldCopy = NO;
        _filteredOut = NO;
    }
    return self;
}

-(id) initWithPathByAbbreviatingTildeInPath:(NSString *)path andNickName:(NSString *)name {
    self = [super init];
    if (self) {
        if ([NSString isNotEmptyString:[path stringByExpandingTildeInPath]]) {
            [self setPropertiesByURL:[NSURL fileURLWithPath:[path stringByExpandingTildeInPath]]];
        }
        _nickName = name;
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
        _shouldCopy = NO;
        _filteredOut = NO;
        [self setPathByAbbreviatingTildeInPath:_path];
    }
    return self;
}

/** Initializes a FileSystemItem with given URL

 Initialises the object and also reads file/folder parameters from the file system.
 
 @param URL   An URL to a file system item

 @return self

 */

-(id) initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        [self setPropertiesByURL:URL];
        _nickName = @"";
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
        _shouldCopy = NO;
        _filteredOut = NO;
    }
    return self;
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
    newFolder.shouldCopy = _shouldCopy;
    newFolder.filteredOut = _filteredOut;
    return newFolder;
}

@end
