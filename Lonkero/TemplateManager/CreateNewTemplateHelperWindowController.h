//
//  CreateNewTemplateHelperWindowController.h
//  Lonkero
//
//  Created by Kati Haapamäki on 12.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "Template.h"
#import "TemplateParameter.h"
#import "Preferences.h"

@class FileSystemItem;

@interface CreateNewTemplateHelperWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
    NSWindowController *_createNewTemplateWindowController;
    Preferences *_preferences;
}

-(void) openPanelWithPreferences:(Preferences*)ApplicationPreferences;

@property (strong) IBOutlet NSPanel *createNewTemplatePanel;

@property (unsafe_unretained) IBOutlet NSPopUpButton *selectLocationPopUp;

@property (unsafe_unretained) IBOutlet NSButton *chooseFromExistingFoldersButton;
@property (unsafe_unretained) IBOutlet NSButton *createNewEmptyFolderButton;

- (IBAction)templateLocationChanged:(id)sender;
- (IBAction)chooseFromExistingFolders:(id)sender;
- (IBAction)createNewEmptyTemplateFolder:(id)sender;
@property (unsafe_unretained) IBOutlet NSTextField *folderNameTextField;

// Existing Folders Table View
@property (unsafe_unretained) IBOutlet NSTableView *existingFoldersTableView;
@property NSMutableArray *existingFolders; // storage for arraycontroller
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;


-(void) updateExistingFolderListTableView;


@end
