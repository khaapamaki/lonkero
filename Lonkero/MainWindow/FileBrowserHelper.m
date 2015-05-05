//
//  FileBrowserHelper.m
//  Lonkero
//
//  Created by Kati Haapamäki on 17.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "FileBrowserHelper.h"


@implementation FileBrowserHelper

-(NSMutableArray *)getFoldersAtFolder:(FileSystemItem *)folder readMetadata:(BOOL)readMetadata {
    return [self getFoldersAtFolder:folder readMetadata:readMetadata filteringTemplate:nil];
}

-(NSMutableArray *)getFoldersAtFolder:(FileSystemItem *)folder readMetadata:(BOOL)readMetadata filteringTemplate:(Template*) filterTemplate {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    int dirEnumOptions = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles );
    
    
    if (folder==nil) {
        return [NSMutableArray array];
    }
    NSDirectoryEnumerator *dirEnum = [fileMgr enumeratorAtURL:[folder fileURL]
                                   includingPropertiesForKeys:@[NSURLNameKey,
                                                               NSURLIsDirectoryKey,
                                                               NSURLIsAliasFileKey,
                                                               NSURLIsPackageKey]
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
                    
                    if (_isFilteringOn && _filteringTemplate!=nil) {
                        
                        // FILTERING
                        
                        if ([self filterMetadata:metadata withTemplate:filterTemplate]) {
                            
                        } else {
                            entryFolder = nil;
                        }
                        
                    }
                } else {
                   //  if (selfLevelMetadata && !selfLevelMetadataPassed && _isFilteringOn && _filteringTemplate!=nil) entryFolder = nil;
                }
            }
            
            if (entryFolder) {
                entryFolder.isExpandable = YES;
                [result addObject:entryFolder];
            }

        } else {
            // is file, not folder
            if (_showFiles) {
                FileSystemItem *entryFolder = [[FileSystemItem alloc] initWithURL:currentURL];
                entryFolder.isExpandable = NO;
                [result addObject:entryFolder];
            }
        }
    }

    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [result sortUsingDescriptors:@[sortDesc]];
    return result;
}

-(BOOL)filterMetadata:(TemplateMetadata *)metadata withTemplate:(Template *)filter {
    BOOL result = YES;
    unsigned int searchOptions = (NSCaseInsensitiveSearch | NSRegularExpressionSearch);
    
    for (TemplateParameter *currentParameter in filter.templateParameterSet) {
        if (!currentParameter.isHidden) {
            
            NSString *testParameterTag = [currentParameter.tag lowercaseString];
            NSString *testParameterName = [currentParameter.name lowercaseString];
            NSString *testParameterValue = [currentParameter.stringValue lowercaseString];
            
            for (TemplateMetadataItem* currentMetadataItem in metadata.metadataArray) {
                for (TemplateParameter *currentMetadataParameter in currentMetadataItem.usedTemplate.templateParameterSet) {
                    
                    NSString *metadataParameterTag = [currentMetadataParameter.tag lowercaseString];
                    NSString *metadataParameterName = [currentMetadataParameter.name lowercaseString];
                    NSString *metadataParameterValue = [currentMetadataParameter.stringValue lowercaseString];
                    
                    if ([NSString isNotEmptyString:testParameterValue] ) {
                        
                        if ( ([metadataParameterTag isEqualToString:testParameterTag] || [metadataParameterName isEqualToString:testParameterName]) && [NSString isNotEmptyString:testParameterValue] ) {
                            if ([NSString isNotEmptyString:metadataParameterValue]) {
                                
                                NSString *regularExpressionTestString = [NSString convertWildCardToRegExp:testParameterValue];
                                NSRange range = [metadataParameterValue rangeOfString:regularExpressionTestString options:searchOptions];

                                result = result && (range.location != NSNotFound);

                                //result = result && [testParameterValue isEqualToString:metadataParameterValue];
                            } else {
                                result = result && NO;
                            }
                            
                        }
                    }
                }
            }
        }
    }
    return result;
}



+(BOOL)isURLDirectory:(NSURL *)URL {
    NSNumber *isDirectory = @0;
    NSNumber *isPackage = @0;
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
    contents = _directoryContentStorage[[parentFolder URLStylePath]];
    if (!contents) {
        if (_isFilteringOn) {
            contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"] filteringTemplate:_filteringTemplate];
        } else {
            contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"]];
        }
        _directoryContentStorage[[parentFolder URLStylePath]] = contents;
    }
    FileSystemItem *resultItem =  contents[index];
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
    contents = _directoryContentStorage[[parentFolder URLStylePath]];
    if (!contents) {
        if (_isFilteringOn) {
            contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"] filteringTemplate:_filteringTemplate];
        } else {
            contents = [self getFoldersAtFolder:parentFolder readMetadata:[outlineView.identifier isEqualToString:@"targetBrowser"]];
        }
    }
    return [contents count];
    
}

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *result;
    if ([item isKindOfClass:[FileSystemItem class]]) {
        FileSystemItem *fileSystemItem = item;
        
        result = [outlineView makeViewWithIdentifier:@"imageAndText" owner:self];

        [result.textField setStringValue:[item itemName]];
        if (fileSystemItem.isDirectory) {
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

-(void)setFilteringTemplate:(Template*)filteringTemplate {
    _filteringTemplate = filteringTemplate;
    _isFilteringOn = YES;
    [self refresh];
}

-(void)stopFiltering {
    _isFilteringOn = NO;
    _filteringTemplate = nil;
    [self refresh];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    FileSystemItem *changedItem = (notification.userInfo)[@"NSObject"];
    NSNumber *expandedValue = nil;
    NSNumber *isExpanded = @YES;
    expandedValue = _expandedStatus[[changedItem URLStylePath]];
    NSString *key = [NSString stringWithString:[changedItem URLStylePath]];
    _expandedStatus[key] = changedItem;
    [changedItem setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    FileSystemItem *changedItem = (notification.userInfo)[@"NSObject"];
    NSNumber *expandedValue = nil;
    NSNumber *isExpanded = @NO;
    expandedValue = _expandedStatus[[changedItem URLStylePath]];
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

}

-(void)refresh {
    _directoryContentStorage = nil;
    _directoryContentStorage = [[NSMutableDictionary alloc] init];
    [_myOutlineView reloadData];
}

-(void)awakeFromNib {
 
    
}

-(id)initWithOutlineView:(NSOutlineView*)outlineView folder:(FileSystemItem*)rootFolder showFiles:(BOOL)showFiles {
    if (self = [super init]) {
        _myOutlineView = outlineView;
        _rootFolder = rootFolder;
        _showFiles = showFiles;
        fileManager = [NSFileManager defaultManager];
        _directoryContentStorage = [[NSMutableDictionary alloc] init];
        _expandedStatus = [[NSMutableDictionary alloc] init];
     //   _masterFolder = nil;
        [_myOutlineView setDelegate:self];

    }
    return self;
}

//deprecated...
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
