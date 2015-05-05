//
//  TemplateManager.h
//  Lonkero
//
//  Created by Kati Haapamäki on 31.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "TemplateManager.h"
#import "Template.h"
#import "TemplateParameter.h"
#import "Preferences.h"
#import "CreateNewTemplateHelperWindowController.h"

@class FileSystemItem;

@interface TemplateManager : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate> {

    Preferences *_preferences;
}


@property (unsafe_unretained) IBOutlet NSTableView *parameterTableView;

// Self Management
@property (strong) IBOutlet NSWindow *templateManagerWindow;
- (void)windowWillClose:(NSNotification *)notification;

-(void)openWindow;
-(id)initWithPreferences:(Preferences *) preferences;
- (IBAction)saveTemplateButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

// Template Selection
@property NSMutableArray *templateList;
@property (unsafe_unretained) IBOutlet NSOutlineView *templateListOutlineView;
@property Template *selectedTemplate;
- (IBAction)userSelectedRowOnTemplateList:(id)sender;
-(void) loadTemplateAtFolder:(FileSystemItem *)selectedTemplate;
@property (unsafe_unretained) IBOutlet NSTextField *currentTemplateNameTextField;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;

// Templete Creation and Removal
- (IBAction)addTemplate:(id)sender;
- (IBAction)removeTemplate:(id)sender;
- (IBAction)showInFinder:(id)sender;
@property (unsafe_unretained) IBOutlet NSButton *addTemplateButton;
@property (unsafe_unretained) IBOutlet NSButtonCell *addTemplateButtonCell;

// Template Naming
//@property (unsafe_unretained) IBOutlet NSTextField *masterFolderNamingRule;

// Template Parameter Handling
@property (strong) IBOutlet NSArrayController *parametersArrayController;
@property NSMutableArray *parametersArray; // storage for arraycontroller
- (IBAction)addParameter:(id)sender;
- (IBAction)removeParameter:(id)sender;
- (IBAction)parameterTableViewAction:(id)sender;
- (IBAction)moveUpParameter:(id)sender;
- (IBAction)moveDownParameter:(id)sender;

// Date Formatting
@property (unsafe_unretained) IBOutlet NSTextField *dateFormatTextField;

// Target Location Management
@property (strong) IBOutlet NSArrayController *targetFoldersArrayController;
@property NSMutableArray *targetFoldersArray; // storage for arraycontroller
- (IBAction)addTargetFolder:(id)sender;
- (IBAction)removeTargerFolder:(id)sender;
- (IBAction)moveUptTargetFolder:(id)sender;
- (IBAction)moveDownTargetFolder:(id)sender;
@property (unsafe_unretained) IBOutlet NSTableView *targetFoldersTableView;

// Template and Group ID
@property (unsafe_unretained) IBOutlet NSTextField *groupIdTextField;
@property (unsafe_unretained) IBOutlet NSTextField *templateIdtTextField;

// CREATE NEW TEMPLATE PANEL
// Outlets and Actions For Create New Template Panel
@property (strong) IBOutlet NSPanel *createNewTemplatePanel;
@property (strong) IBOutlet CreateNewTemplateHelperWindowController *createNewTemplateHelper;


#pragma mark -
#pragma mark SUPPORTING METHODS

// Supporting Methods
-(NSMutableArray*) generateContentArrayForTemplateListOutlineView;
+(NSMutableArray *) getAvailableTemplatesAsFoldersWithPreferences:(Preferences *)prefs;
+(NSArray *) getFoldersAtFolder:(FileSystemItem *)folder select:(FolderSelectionType) selection;
+(NSArray *)getFoldersAtURL:(NSURL *) URL filter:(FolderSelectionType) selection;

- (void)moveUpItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;
- (void)moveDownItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;

+(BOOL) isURLDirectory:(NSURL *) URL;

-(void) updateTemplateListOutlineView;

-(void)updatePreferences:(Preferences *) appPreferences;



@end
