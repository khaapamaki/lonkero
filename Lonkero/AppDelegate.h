//
//  AppDelegate.h
//  Lonkero
//
//  Created by Kati Haapamäki on 26.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "Preferences.h"
#import "UserPreferences.h"
#import "FileSystemItem.h"
#import "TemplateManager.h"
#import "PreferencesController.h"
#import "NSString+Extras.h"
#import "NSDate+Extras.h"
#import "FileBrowserHelper.h"
#import "TemplateMetadata.h"
#import "TemplateDeployer.h"
#import "MetadataBrowser.h"

/**
 *  @brief Handler for the main window
 *
 *  AppDelegate is also NSTableView data source and delegate for parameter query table
 *
 *  @copyright Kati Haapamäki
 *  @date 2013-2015
 */


@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
@private
    NSString *preferenceFilePath;
    NSString *preferenceFolderPath;
    PreferencesController *preferencesController;
    TemplateManager *templateManager;
    Template *_selectedTemplate;
    FileSystemItem *_selectedTargetFolder;
    long lastSelectedTargetFolderIndex;
    FileBrowserHelper *_targetBrowserHelper;
    NSMutableArray *_parameterQueryTableContents; ///< Holds the data for the table view
    FileBrowserHelper *_templateBrowserHelper;
    MetadataBrowser *metadataBrowser;
    TemplateDeployer *_templateDeployer;
}


@property (unsafe_unretained) IBOutlet NSWindow *mainWind;
- (IBAction)showMainWindow:(id)sender;

@property (weak) IBOutlet NSView *parameterAreaCustomView;
@property (weak) IBOutlet NSSplitView *splitView;


#pragma mark -
#pragma mark TEMPLATE MANAGER

-(IBAction)openTemplateManager:(id)sender;

#pragma mark -
#pragma mark DEPLOYMENT


- (IBAction)deployFolderStructure:(id)sender;

#pragma mark -
#pragma mark PREFERENCES

@property Preferences *preferences;
@property UserPreferences *userPreferences;

-(IBAction)showPreferencePanel:(id)sender;

#pragma mark -
#pragma mark TEMPLATE SELECTION

@property NSMutableArray *templateArray;

@property Template *selectedTemplate;
@property (unsafe_unretained) IBOutlet NSPopUpButton *templatePopUpButton;
- (IBAction)templatePopUpAction:(id)sender;
- (void)populateTemplatePopUpButton;

#pragma mark -
#pragma mark TEMPLATE FILE BROWSER

@property (weak) IBOutlet NSPathControl *templateFileBrowserPathControl;

@property (weak) IBOutlet NSOutlineView *templateFileBrowserOutlineView;

#pragma mark -
#pragma mark TEMPLATE PARAMETERS

@property (unsafe_unretained) IBOutlet NSTableView *parameterQueryTableView;
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
-(long) calculateArrayRowFromTableRow:(long)row;
-(void) updateParameterQueryComboBox:(NSComboBox *)comboBox withString:(NSString *)semicolonSeparatedString;
-(void)loadParameterQueryTableWithTemplate:(Template*) aTemplate;
-(void)readParameterQueryTableToTemplate:(Template*) aTemplate;
-(void)cleanUpParametersForTemplate:(Template *) aTemplate;
-(BOOL)hasMissingParameters;
-(BOOL)hasTooManyParameters:(NSString**)errCode;
-(void)setHiddenParametersToTemplate:(Template *)aTemplate;
-(NSView*)getNSViewForParameterQueryTitleColumnForRow:(NSInteger)row;
-(NSView*)getNSViewForParameterQueryValueColumnForRow:(NSInteger)row;
-(IBAction)clearParameters:(id)sender;

#pragma mark IB Actions

-(IBAction)comboBoxAction:(id)sender;
-(IBAction)checkBoxAction:(id)sender;
-(IBAction)datePickerAction:(id)sender;
-(IBAction)textFieldAction:(id)sender;
-(IBAction)recreateMissingFolders:(id)sender;
-(void)doubleClick:(id)nid;
-(IBAction)rewriteMetadataMenuItem:(id)sender;

#pragma mark -
#pragma mark TARGET FOLDER SELECTION

@property (unsafe_unretained) IBOutlet NSOutlineView *targetFolderOutlineView;
@property (unsafe_unretained) IBOutlet NSPopUpButton *targetFolderPopUpButton;
@property (unsafe_unretained) IBOutlet NSPathControl *pathControl;
- (IBAction)targetFolderPopUpAction:(id)sender;
- (IBAction)userSelectedPath:(id)sender;
-(NSInteger)checkIfTargetFolderHasChangedDueParsingAndUpdate;
-(void)updateTargetFolderViews;
- (IBAction)selectParentFolder:(id)sender;
- (IBAction)browseForNewTargetFolder:(id)sender;
- (IBAction)targetOutlineViewAction:(id)sender;
- (IBAction)contextMenuCopyParameters:(id)sender;
- (IBAction)contextMenuShowInFinder:(id)sender;
@property (weak) IBOutlet NSMenu *contextMenu;

- (IBAction)filterAction:(id)sender;
-(void)setTargetFolderPopUpButtonToIndex:(NSInteger)index;

@property (weak) IBOutlet NSButton *filterOnOffButton;

#pragma mark -
#pragma mark TOOLBAR AND MENU

@property (unsafe_unretained) IBOutlet NSToolbar *toolBar;
@property (unsafe_unretained) IBOutlet NSToolbarItem *templateManagerToolbarItem;
@property (unsafe_unretained) IBOutlet NSToolbarItem *preferencesToolbarItem;
@property (unsafe_unretained) IBOutlet NSMenuItem *templateManagerMenuItem;
-(IBAction)deployMenuItem:(id)sender;


#pragma mark -
#pragma mark METADATA BROWSER

- (IBAction)openMetadataBrowser:(id)sender;
- (IBAction)showMetadataContextMenuAction:(id)sender;

#pragma mark -
#pragma mark NOTIFICATIONS

- (void) preferencesDidChange:(NSNotification*)aNotification;
- (void) templatesDidChange:(NSNotification*)aNotification;
- (void) targetPathDidChange:(NSNotification*)aNotification;
- (void) parameterValueDidChange:(NSNotification*)aNotification;

#pragma mark -
#pragma mark SUPPORTING METHODS

-(void)errorPanelForErrCode:(NSInteger)errCode andParameter:(NSString*)paramStr;

#pragma mark -
#pragma mark MENU ITEMS

@property (weak) IBOutlet NSMenuItem *showIdEditorMenuItem;
@property (weak) IBOutlet NSMenuItem *viewMenuItem;

#pragma mark -
#pragma mark DEBUG

@property (unsafe_unretained) IBOutlet NSTextField *debugLabel;
- (IBAction)testButtonPressed:(id)sender;
@property (unsafe_unretained) IBOutlet NSButton *testButton;


@end
