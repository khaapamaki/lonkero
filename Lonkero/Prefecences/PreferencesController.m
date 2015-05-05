//
//  PreferencesController.m
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "PreferencesController.h"
#import "Preferences.h"
#import "FileSystemItem.h"

@implementation PreferencesController

-(void)windowWillClose:(NSNotification *)notification {
    NSApplication *me = [NSApplication sharedApplication];
    [me stopModal];
}
-(id)init {
    self = [super initWithWindowNibName:@"PreferencesWindow"];
    if (self) {
        _templateFolderArray = [[NSMutableArray alloc] init];
        _prefsModalSession = nil;
    }
    return self;
}

-(void)windowDidLoad {
    NSLog(@"Prefs window loaded");
}
-(void)awakeFromNib {
 
}
-(void)editPreferences:(Preferences *)prefs {
    preferencesToBeEdited = prefs;
    [_templateFolderArray removeAllObjects];
    [_templateFolderArray addObjectsFromArray:prefs.templateSetLocations];
   /*
    if (!preferencesController) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController  removeAllObjects];
    [_templateFolders addObjectsFromArray:self.templateFolders];
    */

    [super initWithWindow:_preferencesWindow];
    [self showWindow:self];
    NSApplication *me = [NSApplication sharedApplication];
    [_preferencesWindow setPreventsApplicationTerminationWhenModal:NO];
    [me runModalForWindow:_preferencesWindow];

}

- (IBAction)addFolder:(id)sender {
    FileSystemItem *newFolder = [[FileSystemItem alloc] initWithOpenDialogForFolderSelection];
    if (newFolder) {
        [_templateFoldersArrayController addObject:newFolder];
    }
}

- (IBAction)removeFolder:(id)sender {
    //[_templateFoldersArrayController removeSelectedObjects:[_templateFoldersArrayController selectedObjects]];
    long selectedRow = [self.templateFoldersTableView selectedRow];
    if (selectedRow > -1) {
        [self.templateFoldersArrayController removeObjectAtArrangedObjectIndex:selectedRow];
    }
}

- (IBAction)moveUpFolder:(id)sender {
    [self moveUpItemInMutableArray:_templateFolderArray atTableView:_templateFoldersTableView];
}

- (IBAction)moveDownFolder:(id)sender {
    [self moveDownItemInMutableArray:_templateFolderArray atTableView:_templateFoldersTableView];
}

- (IBAction)savePreferences:(id)sender {

    if (preferencesToBeEdited) {
        [preferencesToBeEdited.templateSetLocations removeAllObjects];
        [preferencesToBeEdited.templateSetLocations addObjectsFromArray:_templateFolderArray];
    }
    for (FileSystemItem *currentFolder in preferencesToBeEdited.templateSetLocations) {
        currentFolder.isExpandable = YES; // overriding user's actions, and dont save that expanded state
        currentFolder.isExpanded = YES;
    }
    [preferencesToBeEdited savePreferences];
    [_preferencesWindow close];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"preferencesDidChange" object:self];
}

- (IBAction)cancel:(id)sender {

    [_preferencesWindow close];
}

- (void)moveUpItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView {
    long row =[aTableView selectedRow];
    if (row >= 1) {
        id itemToBeMoved = [anArray objectAtIndex:row];
        [anArray removeObjectAtIndex:row];
        [anArray insertObject:itemToBeMoved atIndex:row-1];
        [aTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row-1] byExtendingSelection:NO];
        [aTableView reloadData];
    }
}

- (void)moveDownItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView {
    long row =[aTableView selectedRow];
    if (row < [anArray count] -1) {
        id itemToBeMoved = [anArray objectAtIndex:row];
        [anArray removeObjectAtIndex:row];
        [anArray insertObject:itemToBeMoved atIndex:row+1];
        [aTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row+1] byExtendingSelection:NO];
        [aTableView reloadData];
    }
}


@end
