//
//  TargetFolderOutlineViewHelper.m
//  Lonkero
//
//  Created by Kati Haapamäki on 17.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "FileBrowserHelper.h"
#import "TemplateMetadata.h"

@implementation FileBrowserHelper

-(NSMutableArray *)getFoldersAtFolder:(FileSystemItem *)folder readMetadata:(BOOL)readMetadata {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    int dirEnumOptions = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles );
    
    
    if (folder==nil) {
        return [NSMutableArray array];
    }
    NSDirectoryEnumerator *dirEnum = [fileMgr enumeratorAtURL:[folder fileURL]
                                   includingPropertiesForKeys:[NSArray arrayWithObjects:
                                                               NSURLNameKey,
                                                               NSURLIsDirectoryKey,
                                                               NSURLIsAliasFileKey,
                                                               NSURLIsPackageKey,
                                                               nil]
                                                      options:dirEnumOptions
                                                 errorHandler:nil];
    
    for (NSURL *currentURL in dirEnum) {
        
        if ([FileBrowserHelper isURLDirectory:currentURL]) {
            FileSystemItem *entryFolder = [[FileSystemItem alloc] initWithURL:currentURL];
            if (readMetadata) {
                TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:entryFolder];
                if ([metadata.metadataArray count]>0) {
                    entryFolder.isMaster = [metadata hasAnyMaster];
                    entryFolder.isParent = [metadata hasAnyParent];
                }
            }
            entryFolder.isExpandable = YES;
            [result addObject:entryFolder];
        } else {
            if (_showFiles) {
                FileSystemItem *entryFolder = [[FileSystemItem alloc] initWithURL:currentURL];
                entryFolder.isExpandable = NO;
                [result addObject:entryFolder];
            }
        }
    }

    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [result sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    return result;
}

+(BOOL)isURLDirectory:(NSURL *)URL {
    NSNumber *isDirectory = [NSNumber numberWithInt:0];
    NSNumber *isPackage = [NSNumber numberWithInt:0];
    [URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    [URL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
    return  ([isDirectory boolValue] && ![isPackage boolValue]);
}

#pragma mark -
#pragma mark DATA SOURCE PROTOCOL

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSMutableArray *contents;
    FileSystemItem *parentFolder;
    if (! ([item isKindOfClass:[FileSystemItem class]] || item==nil) ) return 0;
    
    if (item==nil) {
        parentFolder = _rootFolder;
    }
    else {
        parentFolder = item;
    }
    
    if (parentFolder==nil) {
        return 0;
    }
    contents = [_directoryContentStorage objectForKey:[parentFolder URLStylePath]];
    if (!contents) {
        contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"]];
        [_directoryContentStorage setObject:contents forKey:[parentFolder URLStylePath]];
    }
    FileSystemItem *resultItem =  [contents objectAtIndex:index];
    return resultItem;
}
    
-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[NSString class]]) return NO; // not a folder
    FileSystemItem *theItem = item;
    return theItem.isExpandable;
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSMutableArray *contents;
    FileSystemItem *parentFolder;

    if (! ([item isKindOfClass:[FileSystemItem class]] || item==nil)) return 0;
    
    if (item==nil) {
        parentFolder = _rootFolder;
    }
    else {
        parentFolder = item;
    }
    if (parentFolder==nil) {
        return 0;
    }
    contents = [_directoryContentStorage objectForKey:[parentFolder URLStylePath]];
    if (!contents) {
        contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"]];
        [_directoryContentStorage setObject:contents forKey:[parentFolder URLStylePath]];
    }
    return [contents count];
    
}

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *result;
    if ([item isKindOfClass:[FileSystemItem class]]) {
        FileSystemItem *fileSystemItem = item;
        
        result = [outlineView makeViewWithIdentifier:@"imageAndText" owner:self];
        
//        if ([outlineView.identifier isEqualToString:@"targetBrowser"]) {
//            [result setMenu:_contextMenu];
//            LOG(@"Menu: %@", _contextMenu);
//        }

        [result.textField setStringValue:[item itemName]];
        if
            (fileSystemItem.isDirectory) {
            if (fileSystemItem.isMaster) {
                [result.imageView setImage:[NSImage imageNamed:@"folder16x16_master"]];
            } else if (fileSystemItem.isParent) {
                [result.imageView setImage:[NSImage imageNamed:@"folder16x16_parent"]];
            } else {
                [result.imageView setImage:[NSImage imageNamed:@"folder16x16"]];
            }
        } else {
            [result.imageView setImage:fileSystemItem.icon];
        }
        return result;
        
        
    }
    
    if ([item isKindOfClass:[NSString class]]) {
        result = [outlineView makeViewWithIdentifier:@"imageAndText" owner:self];
        [result.textField setStringValue:item];
        [result.imageView setImage:[NSImage imageNamed:@"NSFolder"]];
        return result;
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return nil; // not in use, this is cell based stuff
}


- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    FileSystemItem *changedItem = [notification.userInfo objectForKey:@"NSObject"];
    NSNumber *expandedValue = nil;
    NSNumber *isExpanded = [NSNumber numberWithBool:YES];
    expandedValue = [_expandedStatus objectForKey:[changedItem URLStylePath]];
    NSString *key = [NSString stringWithString:[changedItem URLStylePath]];
    [_expandedStatus setObject:changedItem forKey:key];
    [changedItem setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    FileSystemItem *changedItem = [notification.userInfo objectForKey:@"NSObject"];
    NSNumber *expandedValue = nil;
    NSNumber *isExpanded = [NSNumber numberWithBool:NO];
    expandedValue = [_expandedStatus objectForKey:[changedItem URLStylePath]];
    [_expandedStatus removeObjectForKey:[changedItem URLStylePath]];
    [changedItem setIsExpanded:NO];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    return YES;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    return YES;
}


#pragma mark -
#pragma mark INITIALIZATION

-(void)updateWithFolder:(FileSystemItem *)rootFolder andTemplate:(Template *) currentTemplate  {
    _rootFolder = rootFolder;
    _currentTemplate = currentTemplate;
   // _directoryContentStorage = [[NSMutableDictionary alloc] init];
  //  _masterFolder = [masterFolder copy];
    [self expandOrCollapseBySavedStatus];
}

-(void)expandOrCollapseBySavedStatus {
    for (NSString *key in _expandedStatus) {
    //NSAssert([[_targetBrowserOutlineView itemAtRow:index] isKindOfClass:[FileSystemItem class]], @"wrong class" );
      //  FileSystemItem *item = [_targetBrowserOutlineView itemAtRow:index];

//        FileSystemItem *item = [_expandedStatus objectForKey:key];
//        [_targetBrowserOutlineView expandItem:item];

    }
}

-(void)refresh {
    _directoryContentStorage = nil;
    _directoryContentStorage = [[NSMutableDictionary alloc] init];
    [_targetBrowserOutlineView reloadData];
}

-(void)awakeFromNib {
 
    
}

-(id)initWithOutlineView:(NSOutlineView*)outlineView folder:(FileSystemItem*)rootFolder showFiles:(BOOL)showFiles {
    if (self = [super init]) {
        _targetBrowserOutlineView = outlineView;
        _rootFolder = rootFolder;
        _showFiles = showFiles;
        fileManager = [NSFileManager defaultManager];
        _directoryContentStorage = [[NSMutableDictionary alloc] init];
        _expandedStatus = [[NSMutableDictionary alloc] init];
     //   _masterFolder = nil;
        [_targetBrowserOutlineView setDelegate:self];

    }
    return self;
}


-(id)initWithFolder:(FileSystemItem *)rootFolder andTemplate:(Template *)currentTemplate {
    if (self = [super init]) {
        _rootFolder = rootFolder;
        _currentTemplate = currentTemplate;
        fileManager = [NSFileManager defaultManager];
        _directoryContentStorage = [[NSMutableDictionary alloc] init];
        _expandedStatus = [[NSMutableDictionary alloc] init];
        _masterFolder = nil;
       // [_targetBrowserOutlineView setAutosaveExpandedItems:YES];
    }
    return self;
}

-(id)init {
    if (self = [super init]) {
        fileManager = [NSFileManager defaultManager];
        _directoryContentStorage = [[NSMutableDictionary alloc] init];
        _expandedStatus = [[NSMutableDictionary alloc] init];
       // [_targetBrowserOutlineView setAutosaveExpandedItems:YES];
    }
    return self;
}
@end
