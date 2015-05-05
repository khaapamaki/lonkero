//
//  TemplateManager.m
//  Lonkero
//
//  Created by Kati Haapamäki on 31.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateManager.h"
#import "FileSystemItem.h"

@implementation TemplateManager

#pragma mark WINDOW MANAGEMENT

//-------------------------------------
// WINDOW MANAGEMENT
//-------------------------------------

-(void)windowWillClose:(NSNotification *)notification {
    if (_idEditorMenuItem) {
        [_idEditorMenuItem setEnabled:NO];
        [_idEditorMenuItem setHidden:YES];
    }
    
    NSApplication *me = [NSApplication sharedApplication];
    [me stopModal];
    [_selectedTemplate saveTemplate];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"templatesDidChange" object:self];
}

-(void)openWindow {
    // [_templateManagerWindow setPreventsApplicationTerminationWhenModal:NO];
    [super initWithWindow:_templateManagerWindow];

    [self showWindow:self];

    for (NSDictionary *objekti in _templateList) {
        if ([objekti[@"templateSet"] isExpanded]) {
            [_templateListOutlineView expandItem:objekti];
        } else {
            [_templateListOutlineView collapseItem:objekti];
        }
    }
    if (_selectedTemplate.location == nil) {
        [self loadTemplateAtFolder:nil];
    }
    [self hideIdEditor];
    [_templateListOutlineView reloadData];
    
    if (!_selectedTemplate) {
        NSArray *availableTemplates = [TemplateManager getAvailableTemplatesAsFoldersWithPreferences:_preferences];
        if ([availableTemplates count] > 0)
        {
            [self loadTemplateAtFolder:availableTemplates[0]];
        }
    }

    [_templateManagerWindow makeKeyAndOrderFront:self];
    NSApplication *me = [NSApplication sharedApplication];
    [_templateManagerWindow setPreventsApplicationTerminationWhenModal:NO];
    [me runModalForWindow:_templateManagerWindow];
}

-(void)closeWindow {

    [_templateManagerWindow close];
}

-(void)loadTemplateAtFolder:(FileSystemItem *)templateFolder  {
    if (templateFolder) {
        NSURL *templateSettingURL = [NSURL fileURLWithPath:[templateFolder pathByExpandingTildeInPath]];
        _selectedTemplate = [[Template alloc] initWithURL:templateSettingURL];
        _selectedTemplate.location = templateFolder;
        [_dateFormatTextField setStringValue:_selectedTemplate.dateFormatString];
        [_currentTemplateNameTextField setStringValue:_selectedTemplate.location.nickName];
        [_parametersArrayController removeObjects:_parametersArray];
        [_parametersArrayController addObjects:_selectedTemplate.templateParameterSet];
        [_targetFoldersArrayController removeObjects:_targetFoldersArray];
        [_targetFoldersArrayController addObjects:_selectedTemplate.targetFolderPresets];
        [_groupIdTextField setStringValue:_selectedTemplate.groupId];
        [_templateIdtTextField setStringValue:_selectedTemplate.templateId];
        _templateVersionLabel.stringValue = _selectedTemplate.version;
    } else {
        // Clear Template Manager Panel
        _selectedTemplate = nil;
        [_currentTemplateNameTextField setStringValue:@""];
        [_parametersArrayController removeObjects:_parametersArray];
        [_groupIdTextField setStringValue:@""];
        [_templateIdtTextField setStringValue:@""];
        [_dateFormatTextField setStringValue:@""];
        _templateVersionLabel.stringValue = @"";
    }
}

-(void)saveTemplate {
    // copy IB fields to _selectedTemplate and save that
//    _selectedTemplate.masterFolderNamingRule = [_masterFolderNamingRule stringValue];
    if ([NSString isNotEmptyString:_dateFormatTextField.stringValue]) {
            _selectedTemplate.dateFormatString = [_dateFormatTextField stringValue];
    } else {
        _selectedTemplate.dateFormatString = _preferences.defaultDateFormat;
    }

    _selectedTemplate.templateParameterSet = [_parametersArray copy];
    _selectedTemplate.targetFolderPresets = [_targetFoldersArray copy];
    _selectedTemplate.groupId = [_groupIdTextField stringValue];
    _selectedTemplate.templateId = [_templateIdtTextField stringValue];
    [_selectedTemplate saveTemplate];
    _selectedTemplate.isTemplateSaved = YES;
}

-(void)handleTemplateListChange:(NSNotification *)note {
    [self updateTemplateListOutlineView];
}

-(void)createNewTemplatePanelClose:(NSNotification *)note {
   // [_templateManagerWindow makeKeyAndOrderFront:self];
}

-(void)updateTemplateListOutlineView {
    _templateList = [self generateContentArrayForTemplateListOutlineView] ;
    [_templateListOutlineView reloadData];
    [_templateListOutlineView display];
    
    //expand or collapse
    for (NSDictionary *objekti in _templateList) {
        if ([objekti[@"templateSet"] isExpanded]) {
            [_templateListOutlineView expandItem:objekti];
        } else {
            [_templateListOutlineView collapseItem:objekti];
        }
    }
    [_templateListOutlineView reloadData];
 }

#pragma mark -
#pragma mark TEMPLATE AND GROUP ID

-(void)turnOnIdEditorMenuItem:(NSMenuItem *)idEditorMenuItem {
    _idEditorMenuItem = idEditorMenuItem;
    [_idEditorMenuItem setAction:@selector(showOrHideIdEditor)];
    [_idEditorMenuItem setEnabled:YES];
    [_idEditorMenuItem setHidden:NO];
    
    
}

-(void)showOrHideIdEditor {
    [_idEditorBox setHidden:!_idEditorBox.isHidden];
    [_idEditorMenuItem setState:!_idEditorBox.isHidden];

}
-(void)showIdEditor {[_idEditorMenuItem setState:!_idEditorBox.isHidden];
    [_idEditorBox setHidden:NO];
    [_idEditorMenuItem setState:!_idEditorBox.isHidden];
}

-(void)hideIdEditor {
    [_idEditorBox setHidden:YES];
    [_idEditorMenuItem setState:!_idEditorBox.isHidden];
}


#pragma mark -
#pragma mark IB ACTIONS

//-------------------------------------
// NIB ACTIONS
//-------------------------------------


// Templates


#pragma mark Template Selection

- (IBAction)addTemplate:(id)sender {
    if (!_createNewTemplateHelper) {
        _createNewTemplateHelper = [[CreateNewTemplateHelperWindowController alloc] initWithWindow:_createNewTemplatePanel];
    }
    //NSApplication *me = [NSApplication sharedApplication];
    [_createNewTemplateHelper openPanelWithPreferences:_preferences];
}

- (IBAction)removeTemplate:(id)sender {
    long selectedRow = [_templateListOutlineView selectedRow];
    id selectedItem = [_templateListOutlineView itemAtRow:selectedRow];
    if ([selectedItem isKindOfClass:[FileSystemItem class]]) {
        if (_selectedTemplate.location != nil) {
            BOOL answer = NSRunAlertPanel(@"Warning: Removing a template does not delete files or folders included with the template, but it WILL DELETE all template parameters. \n\nAre you sure you want to do this?", @"", @"Delete", @"Cancel", nil);
            if (answer) {
                NSFileManager *fm = [NSFileManager defaultManager];
                NSString *path = [NSString stringWithFormat:@"%@/Template Settings.plist", _selectedTemplate.location.pathByExpandingTildeInPath];
                NSError *err = nil;
                [fm removeItemAtPath:path error:&err];
                NSAssert(err==nil, @"Cannot delete template settings file.")  ;
                _selectedTemplate = nil;
                [_templateListOutlineView deselectAll:self];
                [self loadTemplateAtFolder:nil];
                [self updateTemplateListOutlineView];
            }
        }

        
    } else {
        // not a template selected, do nothing
    }
}

- (IBAction)showInFinder:(id)sender {
    long selectedRow = [_templateListOutlineView selectedRow];
    id selectedItem = [_templateListOutlineView itemAtRow:selectedRow];
    if ([selectedItem isKindOfClass:[FileSystemItem class]]) {
        if (_selectedTemplate.location != nil) {
            [[NSWorkspace sharedWorkspace] openURL:[selectedItem fileURL]];
        }
    }
}

- (IBAction)userSelectedRowOnTemplateList:(id)sender {

    long int selectedRow = [_templateListOutlineView selectedRow];
    id selectedItem = [_templateListOutlineView itemAtRow:selectedRow];

    if ([selectedItem isKindOfClass:[FileSystemItem class]]) {
        if (_selectedTemplate.location != nil) {
            [self saveTemplate];
        }
        [self loadTemplateAtFolder:selectedItem];
         [_parameterTableView selectRowIndexes:nil byExtendingSelection:NO];
    }
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return [item isKindOfClass:[FileSystemItem class]];
}

#pragma mark Parameter Control

// Parameters

- (IBAction)addParameter:(id)sender {
    TemplateParameter *newParameter = [[TemplateParameter alloc] init];
    [_parametersArrayController addObject:newParameter];
}


- (IBAction)removeParameter:(id)sender {
    long row =[_parameterTableView selectedRow];
    if (row >= 0) {
        [_parametersArrayController removeObjectAtArrangedObjectIndex:row];
    }
}

- (IBAction)parameterTableViewAction:(id)sender {
    // no action
}

- (IBAction)moveUpParameter:(id)sender {
    [self moveUpItemInMutableArray:_parametersArray atTableView:_parameterTableView];
}

- (IBAction)moveDownParameter:(id)sender {
    [self moveDownItemInMutableArray:_parametersArray atTableView:_parameterTableView];
}


#pragma mark Template Editing

- (IBAction)saveTemplateButtonPressed:(id)sender {
    [self saveTemplate];
    [self closeWindow];

}

- (IBAction)cancelButtonPressed:(id)sender {
    [self closeWindow];
}

#pragma mark Target Folder Table

- (IBAction)addTargetFolder:(id)sender {
    FileSystemItem *newFolder = [[FileSystemItem alloc] initWithOpenDialogForFolderSelection];
    if (newFolder) {
        [_targetFoldersArrayController addObject:newFolder];
    }
}

- (IBAction)removeTargerFolder:(id)sender {
    long row =[_targetFoldersTableView selectedRow];
    if (row >= 0) {
        [_targetFoldersArrayController removeObjectAtArrangedObjectIndex:row];
    }
}

- (IBAction)moveUptTargetFolder:(id)sender {
    [self moveUpItemInMutableArray:_targetFoldersArray atTableView:_targetFoldersTableView];
}

- (IBAction)moveDownTargetFolder:(id)sender {
    [self moveDownItemInMutableArray:_targetFoldersArray atTableView:_targetFoldersTableView];
}

#pragma mark -
#pragma mark SUPPORTING METHODS

//-------------------------------------
// SUPPORTING METHODS
//-------------------------------------

-(NSMutableArray *) generateContentArrayForTemplateListOutlineView {
    
    // VAIN OUTLINE VIEWTA VARTEN
    
    // generoi MutableArrayn jossa jokainen item on NSMutableDictionary ja vastaa yhtä template settiä
    // M.Dictionary sisältää:
    // templateSet = Folder *TemplateSetFolder
    // template = NSMutableArray *templates (sis. Folder *)
    //
    

    
    NSMutableArray *newTemplateList = [[NSMutableArray alloc] init];
    TemplateDeployer *td = [[TemplateDeployer alloc] init];
    
    for (FileSystemItem *currentFolder in _preferences.templateSetLocations) {
        
        FileSystemItem *newFolder = [[FileSystemItem alloc] initWithPath:[td parseSystemParametersForString:currentFolder.pathByExpandingTildeInPath] andNickName:currentFolder.nickName];
       // [currentFolder copy]; // cannot use currentFolder directly because it would change preferences
        
        newFolder.isExpandable = YES;
        if ([NSString isEmptyString:newFolder.nickName]) {
                newFolder.nickName = [[newFolder fileURL] lastPathComponent];
        }

        // check if exists
        NSMutableArray *templatesInCurrentTemplateFolder = [[NSMutableArray alloc] initWithArray:
                                                            [TemplateManager getFoldersAtURL:[newFolder fileURL] filter:templatesOnly]];
        
        NSMutableDictionary *templateFolderEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:newFolder, @"templateSet", templatesInCurrentTemplateFolder, @"templates", nil];
        [newTemplateList addObject:templateFolderEntry];
    }
    
    return newTemplateList;
}

/**
 *  Returns an array of alla available templates by preferences.
 *
 *  @param prefs Preferences
 *
 *  @return NSMutableArray
 */

+(NSMutableArray *) getAvailableTemplatesAsFoldersWithPreferences:(Preferences *)prefs  {

    NSMutableArray *newTemplateList = [[NSMutableArray alloc] init];
    NSMutableArray *templateLocations = prefs.templateSetLocationsByParsingSystemParameters;
    for (FileSystemItem *currentFolder in templateLocations) {
        currentFolder.isExpandable = YES;
        NSString *currentFolderName = currentFolder.nickName;
        if (currentFolder.nickName == nil || [currentFolder.nickName isEqualToString:@""]) {
           currentFolderName = [[currentFolder fileURL] lastPathComponent];
        }
        
        // check if exists
        NSArray *templatesInCurrentTemplateFolder = [TemplateManager getFoldersAtURL:[currentFolder fileURL] filter:templatesOnly];
        [newTemplateList addObjectsFromArray:templatesInCurrentTemplateFolder];
        for (FileSystemItem *currentTemplateFolder in templatesInCurrentTemplateFolder) {
         //   currentTemplateFolder.parentNickName = currentFolderName;
            NSString *templateName = [NSString stringWithFormat:@"%@: %@", currentFolderName, currentTemplateFolder.itemName];
            currentTemplateFolder.nickName = templateName;
        }
        
    }
    
    return newTemplateList;
}


+(NSArray *)getFoldersAtFolder:(FileSystemItem *)folder select:(FolderSelectionType)selection {

    return [TemplateManager getFoldersAtURL:[folder fileURL] filter:selection];
}

+(NSArray *)getFoldersAtURL:(NSURL *) URL filter:(FolderSelectionType)selection {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    int dirEnumOptions = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles );
    

    NSDirectoryEnumerator *dirEnum = [fileMgr enumeratorAtURL:URL
                                   includingPropertiesForKeys:@[NSURLNameKey,
                                                               NSURLIsDirectoryKey,
                                                               NSURLIsAliasFileKey,
                                                               NSURLIsPackageKey]
                                                      options:dirEnumOptions
                                                 errorHandler:nil];

    for (NSURL *currentURL in dirEnum) {

        if ([TemplateManager isURLDirectory:currentURL]) {

            NSString *currentName = [[currentURL pathComponents] lastObject];
            FileSystemItem *entryFolder = [[FileSystemItem alloc] initWithPath:currentURL.path andNickName:currentName];
            entryFolder.isExpandable = NO;
            BOOL isTemplate = [fileMgr fileExistsAtPath:[NSString stringWithFormat:@"%@/Template Settings.plist", [entryFolder.path stringByExpandingTildeInPath]]];
            
            if (isTemplate && selection==templatesOnly) {
                [result addObject:entryFolder];
            }
            if (!isTemplate && selection==nonTemplatesOnly) {
                [result addObject:entryFolder];
            }
            if (selection==bothTemplatesAndNonTemplates) {
                [result addObject:entryFolder];
            }
        }
    }
    return [[NSArray alloc] initWithArray:result];
}

+(BOOL)isURLDirectory:(NSURL *)URL {
    NSNumber *isDirectory = @0;
    NSNumber *isPackage = @0;
    [URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    [URL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
    return  ([isDirectory boolValue] && ![isPackage boolValue]);
}

-(NSArray *)getTemplateFolderNames {
    NSMutableArray *mutableResult = [[NSMutableArray alloc] init];
    for (FileSystemItem *currentFolder in _preferences.templateSetLocations) {
        [mutableResult addObject:currentFolder.nickName];
    }
    return [[NSArray alloc] initWithArray:mutableResult];
}

-(NSArray *)getFolderNamesInsideFolder:(FileSystemItem *)folder select:(FolderSelectionType)selection {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *folderArray = [[NSArray alloc] initWithArray:[TemplateManager getFoldersAtFolder:folder select:selection]];
    for (FileSystemItem *currentFolder in folderArray) {
        [result addObject:currentFolder.nickName];
    }
    return [[NSArray alloc] initWithArray:result];
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


#pragma mark -
#pragma mark TEMPLATE LIST OUTLINE VIEW CONTROL


//-------------------------------------
// DATASOURCE PROTOCOL METHODS
//-------------------------------------

// Template List Outline View


// child
-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return _templateList[index];  // returns NSMutableDictionary for template folder contents
    }
    
    if ([item isKindOfClass:[NSMutableDictionary class]]) {
        return item[@"templates"][index]; // returns NSMutableArray of templates
    }
    return nil;
}


// is expandable
-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
//    if ([item isKindOfClass:[NSMutableDictionary class]] || [item isKindOfClass:[NSMutableArray class]]) {
    if (![item isKindOfClass:[FileSystemItem class]]) {
          return YES;
    } else {
        return NO;
    }
 
}

// number of children of item
-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
   
    if (item == nil) {
        return [_templateList count];
    }
    
    if ([item isKindOfClass:[NSMutableDictionary class]]) {
        return [item[@"templates"] count];
    }
    
    return 0;
}

// contents
-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    
    if ([item isKindOfClass:[NSMutableDictionary class]]) {
        return [item[@"templateSet"] nickName];
    } else {


    }
    if ([item isKindOfClass:[FileSystemItem class]]) {
        return [item nickName];
    }
    return nil;
}

// save expanded status after change
- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    NSDictionary *changedObject = (notification.userInfo)[@"NSObject"];
     [changedObject[@"templateSet"] setIsExpanded:YES];

}
// save expanded status after change
- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    NSDictionary *changedObject = (notification.userInfo)[@"NSObject"];
       [changedObject[@"templateSet"] setIsExpanded:NO];
    
}

#pragma mark -
#pragma mark INITIALIZATION

//-------------------------------------
// INITIALIZATION
//-------------------------------------

-(void)updatePreferences:(Preferences *) appPreferences {
    _preferences = appPreferences;
    _parametersArray =  [[NSMutableArray alloc] init];
    _targetFoldersArray = [[NSMutableArray alloc] init];
    _selectedTemplate = [[Template alloc] init];
    _templateList = [self generateContentArrayForTemplateListOutlineView];
    [self updateTemplateListOutlineView];
    
}
-(void)awakeFromNib {
    [self hideIdEditor];
}
-(id)initWithPreferences:(Preferences *) appPreferences {
    self = [super initWithWindowNibName:@"TemplateManagerWindow"];
    if (self) {
        _preferences = appPreferences;
        _parametersArray =  [[NSMutableArray alloc] init];
        _targetFoldersArray = [[NSMutableArray alloc] init];
        _selectedTemplate = nil;
        _templateList = [self generateContentArrayForTemplateListOutlineView];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleTemplateListChange:) name:@"newTemplateCreated" object:nil];
        [nc addObserver:self selector:@selector(createNewTemplatePanelClose:) name:@"createNewTemplatePanelClose" object:nil];

    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
