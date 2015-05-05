//
//  CreateNewTemplateHelperWindowController.m
//  Lonkero
//
//  Created by Kati Haapamäki on 12.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "CreateNewTemplateHelperWindowController.h"
#import "TemplateManager.h"

@interface CreateNewTemplateHelperWindowController ()

@end

@implementation CreateNewTemplateHelperWindowController


#pragma mark
#pragma mark WINDOW MANAGEMENT

-(void) openPanelWithPreferences:(Preferences*)ApplicationPreferences {
    
    // Initialize Panel
    [_folderNameTextField setStringValue:@""];
    _preferences = ApplicationPreferences;
    
    [_createNewEmptyFolderButton setEnabled:YES];
    [_selectLocationPopUp removeAllItems];
    for (FileSystemItem *currentFolder in _preferences.templateSetLocations) {
        if (currentFolder.nickName != nil && ![currentFolder.nickName isEqualToString:@""]) {
            [_selectLocationPopUp addItemWithTitle:currentFolder.nickName];
        } else {
            [_selectLocationPopUp addItemWithTitle:currentFolder.path];
        }
      
    }
    [_selectLocationPopUp selectItemAtIndex:0];
    [_chooseFromExistingFoldersButton setEnabled:NO];

    [self updateExistingFolderListTableView];
    NSWindowController *newController = [[NSWindowController alloc] initWithWindow:_createNewTemplatePanel];
    [newController showWindow:_createNewTemplatePanel];
    [_createNewTemplatePanel setPreventsApplicationTerminationWhenModal:NO];
    [self showWindow:self];
    [_createNewTemplatePanel orderFront:self];
    NSApplication *me = [NSApplication sharedApplication];
    [me runModalForWindow:_createNewTemplatePanel];
}

-(void)updateExistingFolderListTableView {

    FileSystemItem *templateSetFolder = (_preferences.templateSetLocations)[[_selectLocationPopUp indexOfSelectedItem]];
    [_existingFolders removeAllObjects];
    [_existingFolders addObjectsFromArray:[TemplateManager getFoldersAtFolder:templateSetFolder select:nonTemplatesOnly]];
    [_existingFoldersTableView reloadData];
    [_existingFoldersTableView displayIfNeeded];
}

#pragma mark
#pragma mark IB ACTIONS


- (IBAction)templateLocationChanged:(id)sender {
    //[_existingFolders removeAllObjects];
    [self updateExistingFolderListTableView];
}

// Table View Deletgate Methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if (aNotification.object == _existingFoldersTableView) {
        [ _chooseFromExistingFoldersButton setEnabled:([_existingFoldersTableView selectedRow] >= 0)];
    }
}

- (IBAction)chooseFromExistingFolders:(id)sender {
    FileSystemItem *selectedFolder = _existingFolders[[_existingFoldersTableView selectedRow]];

    Template *newTemplate = [[Template alloc] init];
  //  Folder *currentTemplateSetFolder = [_preferences.templateSetLocations objectAtIndex:[_selectLocationPopUp indexOfSelectedItem]];
    newTemplate.location = selectedFolder;
    [newTemplate saveTemplate];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc postNotificationName:@"newTemplateCreated" object:self];
    [_createNewTemplatePanel close];
}

- (IBAction)createNewEmptyTemplateFolder:(id)sender {
    NSFileManager *fm = [[NSFileManager defaultManager] init ];
    FileSystemItem *selectedFolder = (_preferences.templateSetLocations)[[_selectLocationPopUp indexOfSelectedItem]];
    NSString *folderName = [_folderNameTextField stringValue];
    if (!folderName || [folderName isEqualToString:@""]) {
        // no name, do nothing
        return;
    }
    NSString *path = [NSString stringWithFormat:@"%@/%@", [selectedFolder.path stringByExpandingTildeInPath], folderName];
    FileSystemItem *templateFolder = [[FileSystemItem alloc] initWithPath:path andNickName:folderName];
    BOOL isDir = NO;
    
    if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:0 error:nil];
        
        // write empty plist
        Template *newTemplate = [[Template alloc] init];
        newTemplate.location = templateFolder;
        [newTemplate saveTemplate];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"newTemplateCreated" object:self];
        [_createNewTemplatePanel close];
        
    } else {
        NSString *errMsg = [NSString stringWithFormat:@"Error:\nFile/folder already exists: %@", folderName];
        // FILE / FOLDER EXIST WITH THAT NAME
        NSRunAlertPanel(errMsg, @"", nil, nil, nil);

    }
    
}
#pragma mark
#pragma mark TABLE VIEW DELEGATE

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_existingFolders count];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row  {
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"imageandtext" owner:self];
    
    if (result != nil) {
        [result textField].stringValue = [[_existingFolders[row] path] lastPathComponent];
    }
    
    return result;
}

#pragma mark
#pragma mark WINDOW DELEGATE

-(void)windowWillClose:(NSNotification *)notification {
    NSApplication *me = [NSApplication sharedApplication];
    [me abortModal];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"createNewTemplatePanelClose" object:self];
    
}

#pragma mark
#pragma mark INITIALIZATION

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.

    }
    return self;
}


- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
        _createNewTemplateWindowController = [[NSWindowController alloc] init];
        _existingFolders = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
