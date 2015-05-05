//
//  TargetFolderOutlineViewHelper.h
//  Lonkero
//
//  Created by Kati Haapamäki on 17.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Template.h"
#import "FileSystemItem.h"

@interface FileBrowserHelper : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate> {
@private
    FileSystemItem *_rootFolder;
    Template *_currentTemplate;
    NSFileManager *fileManager;
    NSMutableDictionary *_directoryContentStorage;
    FileSystemItem *_masterFolder;
    NSMutableDictionary *_expandedStatus;
    NSOutlineView *_targetBrowserOutlineView;
}
@property (weak) IBOutlet NSMenu *contextMenu;

//@property (unsafe_unretained) IBOutlet NSOutlineView *targetBrowserOutlineView;
@property BOOL showFiles;

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item ;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

-(NSMutableArray *)getFoldersAtFolder:(FileSystemItem *)folder readMetadata:(BOOL)readMetadata;
-(void)updateWithFolder:(FileSystemItem *)rootFolder andTemplate:(Template *) currentTemplate;

-(void)expandOrCollapseBySavedStatus;

-(void)refresh;

-(id)initWithOutlineView:(NSOutlineView*)outlineView folder:(FileSystemItem*)rootFolder showFiles:(BOOL)showFiles;

-(id)initWithFolder:(FileSystemItem *)rootFolder andTemplate:(Template *) currentTemplate;

+(BOOL)isURLDirectory:(NSURL *)URL;

@end
