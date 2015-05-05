//
//  PreferencesController.h
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"
#import "TemplateManager.h"
#import "UserPreferences.h"
#import "Definitions.h"

@class Preferences;


@interface PreferencesController : NSWindowController <NSWindowDelegate> {
    Preferences *_preferencesToBeEdited;
    UserPreferences *_userPreferencesToBeEdited;
    Preferences *_unsavedPreferences;
    UserPreferences *_unsavedUserPreferences;
    NSModalSession _prefsModalSession;
    NSMutableArray *_defaultTemplateSelectionArray;
    FileSystemItem *_defaultTemplateLocation;
    
}

@property NSMutableArray *templateFolderArray;
@property (unsafe_unretained) IBOutlet NSTableView *templateFoldersTableView;
@property (strong) IBOutlet NSArrayController *templateFoldersArrayController;
@property (weak) IBOutlet NSComboBox *dateFormat;

@property (weak) IBOutlet NSPopUpButton *defaultTemplatePopupButton;

@property (strong) IBOutlet NSPanel *preferencesWindow;
@property (weak) IBOutlet NSPopUpButton *defaultPostDeploymentAction;

- (IBAction)savePreferences:(id)sender;
- (IBAction)cancel:(id)sender;

-(void)editPreferences:(Preferences *)prefs andUserPreferences:(UserPreferences*)userPrefs;


-(void)populateDefaultTemplatePopupButtonWithSelectedFolder:(FileSystemItem*)aFolder;
- (IBAction)defaultTemplatePopupAction:(id)sender;


- (IBAction)addFolder:(id)sender;
- (IBAction)removeFolder:(id)sender;
- (IBAction)moveUpFolder:(id)sender;
- (IBAction)moveDownFolder:(id)sender;

- (void)moveUpItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;
- (void)moveDownItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;

#pragma mark -
#pragma mark Post Deployment Actions

@property (weak) IBOutlet NSButton *openMasterFolderCheckBox;
@property (weak) IBOutlet NSButton *closeMainWindowCheckBox;


@end
