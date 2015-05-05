//
//  PreferencesController.m
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "PreferencesController.h"
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
        _defaultTemplateLocation = nil;
    }
    return self;
}

-(void)windowDidLoad {
    
}
-(void)awakeFromNib {
 
}
-(void)editPreferences:(Preferences *)prefs andUserPreferences:(UserPreferences*)userPrefs {
    _preferencesToBeEdited = prefs;
    _userPreferencesToBeEdited = userPrefs;
    _unsavedPreferences = [prefs copy]; // to be used temporarily while editing values
    _unsavedUserPreferences = [userPrefs copy];


    [_templateFolderArray removeAllObjects];
    [_templateFolderArray addObjectsFromArray:prefs.templateSetLocations];
    

    [super initWithWindow:_preferencesWindow];
    [self showWindow:self];
    if (prefs.defaultDateFormat != nil) [_dateFormat setStringValue:prefs.defaultDateFormat];
    [self populateDefaultTemplatePopupButtonWithSelectedFolder:_userPreferencesToBeEdited.locationOfDefaultTemplate];
    NSApplication *me = [NSApplication sharedApplication];
    _closeMainWindowCheckBox.state = (([userPrefs.postDeploymentAction integerValue] & closeWindow) != 0);
    _openMasterFolderCheckBox.state = (([userPrefs.postDeploymentAction integerValue] & openMasterFolder) != 0);
    [_preferencesWindow setPreventsApplicationTerminationWhenModal:NO];
    [me runModalForWindow:_preferencesWindow];

}

/**
 *  Populates default template Selector AND Preselects the template that matches given folder
 *
 *  If the location is not available add prefix 'missing' to the popup item title
 *
 *  @TODO Also set it to missing if .templatesettings.plist is missing
 *
 *  @param aFolder All ready chosen default template as FilesSystemItem
 */

- (void)populateDefaultTemplatePopupButtonWithSelectedFolder:(FileSystemItem *)aFolder {
    [_defaultTemplatePopupButton removeAllItems];
    _defaultTemplateSelectionArray = [TemplateManager getAvailableTemplatesAsFoldersWithPreferences:_unsavedPreferences];
    
    for (FileSystemItem *currentFolder in _defaultTemplateSelectionArray) {
        [_defaultTemplatePopupButton addItemWithTitle:currentFolder.nickName];
    }
    
    if (aFolder != nil) {
        if ([self selectDefaultTemplateByFolder:aFolder]) {

        } else {
            NSString *missingTemplateTitle = [NSString stringWithFormat:@"[missing] %@", aFolder.nickName];
            [_defaultTemplatePopupButton removeAllItems];
            [_defaultTemplatePopupButton addItemWithTitle:missingTemplateTitle];
            for (FileSystemItem *currentFolder in _defaultTemplateSelectionArray) {
                [_defaultTemplatePopupButton addItemWithTitle:currentFolder.nickName];
            }
            [_defaultTemplateSelectionArray insertObject:aFolder atIndex:0];
        }
    } else {
        [self selectDefaultTemplateByIndex:0];
    }
    
    NSInteger selectedDefaultTemplateIndex = [_defaultTemplatePopupButton indexOfSelectedItem];
    
    if (selectedDefaultTemplateIndex>=0) {
        _defaultTemplateLocation = _defaultTemplateSelectionArray[[_defaultTemplatePopupButton indexOfSelectedItem]];
    }
    
}

-(BOOL)selectDefaultTemplateByFolder:(FileSystemItem*)aFolder {
    BOOL templateFound = NO;
    for (NSInteger index=0; index < [_defaultTemplateSelectionArray count]; index++) {
        FileSystemItem *popupItem = _defaultTemplateSelectionArray[index];
        if ([aFolder.URLStylePath isEqualToString:popupItem.URLStylePath]) {
            templateFound = [self selectDefaultTemplateByIndex:index];
            break;
        }
    }
    return templateFound;
}

-(BOOL)selectDefaultTemplateByIndex:(NSInteger)index {
    if (index<[_defaultTemplatePopupButton numberOfItems]) {
        [_defaultTemplatePopupButton selectItemAtIndex:index];
        return YES;
    }
    return NO;
}
- (IBAction)defaultTemplatePopupAction:(id)sender {
    NSInteger index = [_defaultTemplatePopupButton indexOfSelectedItem];
    _unsavedUserPreferences.locationOfDefaultTemplate = [[_defaultTemplateSelectionArray objectAtIndex:index] copy];
    _defaultTemplateLocation = _unsavedUserPreferences.locationOfDefaultTemplate;

}
- (IBAction)addFolder:(id)sender {
    FileSystemItem *newFolder = [[FileSystemItem alloc] initWithOpenDialogForFolderSelection];
    if (newFolder) {
        [_templateFoldersArrayController addObject:newFolder];
    }
    [self setUserValuesToUnsavedPrefs];
    FileSystemItem *useThisFolder = [_defaultTemplateLocation copy];
    [self populateDefaultTemplatePopupButtonWithSelectedFolder:useThisFolder];
}

- (IBAction)removeFolder:(id)sender {
    //[_templateFoldersArrayController removeSelectedObjects:[_templateFoldersArrayController selectedObjects]];
    long selectedRow = [self.templateFoldersTableView selectedRow];
    if (selectedRow > -1) {
        [self.templateFoldersArrayController removeObjectAtArrangedObjectIndex:selectedRow];
    }
    [self setUserValuesToUnsavedPrefs];
    FileSystemItem *useThisFolder = [_defaultTemplateLocation copy];
    [self populateDefaultTemplatePopupButtonWithSelectedFolder:useThisFolder];
}

- (IBAction)moveUpFolder:(id)sender {
    [self moveUpItemInMutableArray:_templateFolderArray atTableView:_templateFoldersTableView];
    [self setUserValuesToUnsavedPrefs];
    FileSystemItem *useThisFolder = [_defaultTemplateLocation copy];
    [self populateDefaultTemplatePopupButtonWithSelectedFolder:useThisFolder];
}

- (IBAction)moveDownFolder:(id)sender {
    [self moveDownItemInMutableArray:_templateFolderArray atTableView:_templateFoldersTableView];
    [self setUserValuesToUnsavedPrefs];
    FileSystemItem *useThisFolder = [_defaultTemplateLocation copy];
    [self populateDefaultTemplatePopupButtonWithSelectedFolder:useThisFolder];
}

- (IBAction)savePreferences:(id)sender {

    [self setUserValuesToRealPrefs];
    [_preferencesToBeEdited savePreferences];
    [_userPreferencesToBeEdited saveUserPreferences];
    [_preferencesWindow close];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"preferencesDidChange" object:self];
}

-(void)setUserValuesToUnsavedPrefs {
    if (_unsavedPreferences) {
        [_unsavedPreferences.templateSetLocations removeAllObjects];
        [_unsavedPreferences.templateSetLocations addObjectsFromArray:_templateFolderArray];
    }
    for (FileSystemItem *currentFolder in _unsavedPreferences.templateSetLocations) {
        currentFolder.isExpandable = YES; // overriding user's actions, and dont save that expanded state
        currentFolder.isExpanded = YES;
    }
    [_unsavedPreferences setDefaultDateFormat:[_dateFormat stringValue]];
    NSInteger index = [_defaultTemplatePopupButton indexOfSelectedItem];
    if (index>=0) _unsavedUserPreferences.locationOfDefaultTemplate = [[_defaultTemplateSelectionArray objectAtIndex:index] copy];
    _defaultTemplateLocation = _unsavedUserPreferences.locationOfDefaultTemplate;
}


/**
 *  Run this before saving preferences
 */
-(void)setUserValuesToRealPrefs {
    if (_preferencesToBeEdited) {
        [_preferencesToBeEdited.templateSetLocations removeAllObjects];
        [_preferencesToBeEdited.templateSetLocations addObjectsFromArray:_templateFolderArray];
    }
    for (FileSystemItem *currentFolder in _preferencesToBeEdited.templateSetLocations) {
        currentFolder.isExpandable = YES; // overriding user's actions, and dont save that expanded state
        currentFolder.isExpanded = YES;
    }
    [_preferencesToBeEdited setDefaultDateFormat:[_dateFormat stringValue]];
    NSInteger index = [_defaultTemplatePopupButton indexOfSelectedItem];
    
    if (index>=0) {
        _userPreferencesToBeEdited.locationOfDefaultTemplate = [[_defaultTemplateSelectionArray objectAtIndex:index] copy];
    } else {
        _userPreferencesToBeEdited.locationOfDefaultTemplate = nil;
    }
    
    NSInteger postDepAct = (int)(_closeMainWindowCheckBox.state) * closeWindow + (int)(_openMasterFolderCheckBox.state) * openMasterFolder;
    
    _userPreferencesToBeEdited.postDeploymentAction = @((int)(_closeMainWindowCheckBox.state) * closeWindow + (int)(_openMasterFolderCheckBox.state) * openMasterFolder);

}

- (IBAction)cancel:(id)sender {

    [_preferencesWindow close];
}

- (void)moveUpItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView {
    long row =[aTableView selectedRow];
    if (row >= 1) {
        id itemToBeMoved = anArray[row];
        [anArray removeObjectAtIndex:row];
        [anArray insertObject:itemToBeMoved atIndex:row-1];
        [aTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row-1] byExtendingSelection:NO];
        [aTableView reloadData];
    }
}

- (void)moveDownItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView {
    long row =[aTableView selectedRow];
    if (row < [anArray count] -1) {
        id itemToBeMoved = anArray[row];
        [anArray removeObjectAtIndex:row];
        [anArray insertObject:itemToBeMoved atIndex:row+1];
        [aTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row+1] byExtendingSelection:NO];
        [aTableView reloadData];
    }
}


@end
