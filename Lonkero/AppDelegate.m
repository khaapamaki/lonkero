//
//  AppDelegate.m
//  Lonkero
//
//  Created by Kati Haapamäki on 26.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark -
#pragma mark IB ACTIONS

- (IBAction)showMainWindow:(id)sender {
    [_mainWind makeKeyAndOrderFront:self];
}

-(IBAction)openTemplateManager:(id)sender {
    if ([_preferences.templateSetLocations count] > 0) {
        if (!templateManager) {
            templateManager = [[TemplateManager alloc] initWithPreferences:_preferences];
        }
        [_viewMenuItem setHidden:NO];
        [_viewMenuItem setEnabled:YES];
        [templateManager turnOnIdEditorMenuItem:_showIdEditorMenuItem];
        [templateManager openWindow];
        [_toolBar setSelectedItemIdentifier:nil];
        
    } else {
        NSRunAlertPanel(@"Cannot edit templates. No template source folder set in the preferences.", @"", nil, nil, nil);
    }
}

- (IBAction)testButtonPressed:(id)sender {
    [_targetFolderOutlineView reloadData];
}

// -----------
// DEPLOY
// -----------

- (IBAction)deployMenuItem:(id)sender {
    [self deployFolderStructure:sender];

}

- (IBAction)rewriteMetadataMenuItem:(id)sender {
    if (!_selectedTemplate) return;
    
    if ([self hasMissingParameters]) {
        [self errorPanelForErrCode:ErrRequiredParametersMissing andParameter:nil] ;
        return;
    }
    
    NSInteger err = [self updateTargetFolder];
    
    if (err!=0) {
        [self errorPanelForErrCode:err andParameter:nil];
        return;
    }
    
    NSString *errString = @"";
    NSInteger errCode = 0;
    
    // DO
    FileSystemItem *targetFolder = [self parsedTargetFolder];
    
    errCode = [_templateDeployer rewriteMetadataToTargetFolder:targetFolder errString:&errString];
    if (errCode != 0) {
        if (errCode <= 128) {
            [self updateTargetFolderViews];
            [self errorPanelForErrCode:errCode andParameter:errString];
        }
    }
}



- (IBAction)deployFolderStructure:(id)sender {
    
    if (!_selectedTemplate) return;
    
    [self cleanUpParametersForTemplate:_selectedTemplate];
    
    if ([self hasMissingParameters]) {
        [self errorPanelForErrCode:ErrRequiredParametersMissing andParameter:nil] ;
        return;
    }

    NSInteger err = [self updateTargetFolder];
    
    if (err!=0) {
        [self errorPanelForErrCode:err andParameter:nil];
        return;
    }
    
    NSString *errString = @"";
    NSInteger errCode = 0;
    
    // DEPLOY
    errCode = [_templateDeployer deployToTargetFolder:[self parsedTargetFolder] errString:&errString];
    
    // Deploy results
    if (errCode != 0) {
        if (errCode <= 128) {
            [self updateTargetFolderViews];
            [self errorPanelForErrCode:errCode andParameter:errString];
        }
    } else {
        // Show in Finder
        FileSystemItem *masterfolder = [[_templateDeployer getParentFoldersWithError:nil] lastObject];
        BOOL couldOpen = [[NSWorkspace sharedWorkspace] openURL:[masterfolder fileURL]];
        
        NSAssert(couldOpen, @"Could not open finder window");
        [self reloadParameterQueryTable];
        [self updateTargetFolder];
        [self updateTargetFolderViews];
       // [_mainWind close];
        
    }
}

- (IBAction)showPreferencePanel:(id)sender {
    if (!preferencesController) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController editPreferences:_preferences];
    [_toolBar setSelectedItemIdentifier:nil];
}


#pragma mark -
#pragma mark TEMPLATE SELECTION

- (void)populateTemplatePopUpButton {
    [_templatePopUpButton removeAllItems];
    _templateArray = [TemplateManager getAvailableTemplatesAsFoldersWithPreferences:_preferences];
    for (FileSystemItem *currentFolder in _templateArray) {
        [_templatePopUpButton addItemWithTitle:currentFolder.nickName];
    }
}

- (IBAction)templatePopUpAction:(id)sender {
    [self setSelectedTemplateByPopUp];
    [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self updateTargetFolderViews];
}

#pragma mark -
#pragma mark PARAMETER QUERY TABLE

-(BOOL)hasMissingParameters {
    BOOL result = NO;
    long tableIndex = 0;
    long arrayIndex = 0;
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {

        if (!currentParameter.isHidden) {
            NSInteger column = [_parameterQueryTableView columnWithIdentifier:@"value"];
            id cellView = [_parameterQueryTableView viewAtColumn:column row:tableIndex makeIfNecessary:NO];
            
            if (currentParameter.isRequired) {
                switch (currentParameter.parameterType) {
                    case boolean:
                         // cannot be missing
                        break;
                    case list:
                        if  ([[cellView objectValueOfSelectedItem] isEqualToString:@""] || [cellView objectValueOfSelectedItem]==nil) {
                            result = YES;
                        }
                        break;
                    case date:
                         // cannot be missing
                        break;
                    default:
                        if (([[[cellView textField] stringValue] isEqualToString:@""] || [[cellView textField] stringValue] == nil)) {
                            result = YES;
                        }
                        break;
                }
            }
            tableIndex++;
        }
        arrayIndex++;
    }
    return result;
}

- (void)setSelectedTemplateByPopUp {
    if ([_templateArray count] > 0) {
        FileSystemItem *templateFolder = _templateArray[[_templatePopUpButton indexOfSelectedItem]];
        _selectedTemplate = [[Template alloc] initWithURL:[templateFolder fileURL]];
    } else {
        _selectedTemplate = nil;
    }
    [_templateBrowserHelper updateWithFolder:_selectedTemplate.location andTemplate:_selectedTemplate];
    [_templateBrowserHelper refresh];
    [_templateFileBrowserOutlineView reloadData];
    _templateDeployer = [[TemplateDeployer alloc] initWithTemplate:_selectedTemplate];
    
}

-(void)loadParameterQueryTableWithTemplate:(Template*)aTemplate {
    
    // load template default values to query table and displays it
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.parameterType != list) {
            currentParameter.stringValue = [currentParameter.defaultValue copy];
        }
        
        if (currentParameter.parameterType == loginName && ([currentParameter.stringValue isEqualToString:@""] || currentParameter.stringValue == nil) ) {
            currentParameter.stringValue = NSUserName();
        }
        
        if (currentParameter.parameterType == userName && ([currentParameter.stringValue isEqualToString:@""] || currentParameter.stringValue == nil) ) {
            currentParameter.stringValue = NSFullUserName();
        }
        if (currentParameter.parameterType == boolean) {

            if ([currentParameter.stringValue isEqualToString:@""] || currentParameter.defaultValue==nil) {
                currentParameter.booleanValue = NO;
            } else {
                currentParameter.booleanValue = YES;
            }
            currentParameter.stringValue = @"";
        }
        if (currentParameter.stringValue == nil) currentParameter.stringValue = @"";
        if (currentParameter.dateValue == nil) currentParameter.dateValue = [NSDate date];
    }
    
    // load hidden defaults also
    
    [self setHiddenParametersToTemplate:aTemplate];
    
    
    //NSInteger rows = [self numberOfRowsInTableView:_parameterQueryTableView];
   // [_parameterQueryTableContents removeAllObjects];
    _parameterQueryTableContents = nil;
    _parameterQueryTableContents = [NSMutableArray array];
    
    // Prepare array for parameter NSView objects
    long rowIndex=0;
    for (NSInteger arrayIndex =0; arrayIndex<[_selectedTemplate.templateParameterSet count ]; arrayIndex++) {
        if (![(_selectedTemplate.templateParameterSet)[arrayIndex] isHidden]) {
            [_parameterQueryTableContents addObject:[self getNSViewForParameterQueryValueColumnForRow:rowIndex]];
            rowIndex++;
        }
    }
    [_parameterQueryTableView reloadData];
    
    [self populateTargetFolderPopUpButton];
    [_templateFileBrowserPathControl setURL:[_selectedTemplate.location fileURL]];

}

-(void)clearParameters:(id)sender {
    [self reloadParameterQueryTable];
}

-(void)reloadParameterQueryTable {
    
    // loads template default values to query table and displays it
    
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        if (currentParameter.parameterType != list) {
            currentParameter.stringValue = [currentParameter.defaultValue copy];
        }
        
        if (currentParameter.parameterType == loginName && ([currentParameter.stringValue isEqualToString:@""] || currentParameter.stringValue == nil) ) {
            currentParameter.stringValue = NSUserName();
        }
        
        if (currentParameter.parameterType == userName && ([currentParameter.stringValue isEqualToString:@""] || currentParameter.stringValue == nil) ) {
            currentParameter.stringValue = NSFullUserName();
        }
        if (currentParameter.parameterType == boolean) {
            
            if ([currentParameter.stringValue isEqualToString:@""] || currentParameter.defaultValue==nil) {
                currentParameter.booleanValue = NO;
            } else {
                currentParameter.booleanValue = YES;
            }
            currentParameter.stringValue = @"";
        }
        if (currentParameter.stringValue == nil) currentParameter.stringValue = @"";
        if (currentParameter.dateValue == nil) currentParameter.dateValue = [NSDate date];
    }
    
    _parameterQueryTableContents = nil;
    _parameterQueryTableContents = [NSMutableArray array];
    
    // Prepare array for parameter NSView objects
    long rowIndex=0;
    for (NSInteger arrayIndex =0; arrayIndex<[_selectedTemplate.templateParameterSet count ]; arrayIndex++) {
        if (![(_selectedTemplate.templateParameterSet)[arrayIndex] isHidden]) {
            [_parameterQueryTableContents addObject:[self getNSViewForParameterQueryValueColumnForRow:rowIndex]];
            rowIndex++;
        }
    }
    [_parameterQueryTableView reloadData];
    
}



-(void)setHiddenParametersToTemplate:(Template *)aTemplate {
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.isHidden) {
            switch (currentParameter.parameterType) {
                case date:
                    currentParameter.dateValue = [NSDate date];
                    currentParameter.stringValue = [self parseDate:currentParameter.dateValue withFormat:aTemplate.dateFormatString];
                    break;
                case loginName:
                    currentParameter.stringValue = NSUserName();
                    break;
                case userName:
                    currentParameter.stringValue = NSFullUserName();
                    break;
                case incremental:
                    currentParameter.stringValue = @"not_avail"; // IMPLEMENTOI
                    break;
                case boolean:
                    if ([currentParameter.stringValue isEqualToString:@""] || currentParameter.defaultValue==nil) {
                        currentParameter.booleanValue = NO;
                    } else {
                        currentParameter.booleanValue = YES;
                    }
                    currentParameter.stringValue = @"";
                    break;
                default:
                    currentParameter.stringValue = currentParameter.defaultValue;
                    break;
            }
        }
    }
}

-(void)readParameterQueryTableToTemplate:(Template *)aTemplate {

    // reads user given parameters and set them and hidden parameters to template
    long tableIndex = 0;
    long arrayIndex = 0;
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.isHidden) {
            //automated parameters
            switch (currentParameter.parameterType) {
                case date:
                    currentParameter.dateValue = [NSDate date];
                    currentParameter.stringValue = [self parseDate:currentParameter.dateValue withFormat:aTemplate.dateFormatString];
                    break;
                case loginName:
                    currentParameter.stringValue = NSUserName();
                    break;
                case userName:
                    currentParameter.stringValue = NSFullUserName();
                    break;
                case incremental:
                    currentParameter.stringValue = @"not_avail"; // IMPLEMENTOI
                    break;
                case boolean:
                    if ([currentParameter.stringValue isEqualToString:@""] || currentParameter.defaultValue==nil) {
                        currentParameter.booleanValue = NO;
                    } else {
                        currentParameter.booleanValue = YES;
                    }
                    currentParameter.stringValue = @"";
                    break;
                default:
                    currentParameter.stringValue = [currentParameter.defaultValue copy];
                    break;
            }
            
        } else {
            
            NSInteger column = [_parameterQueryTableView columnWithIdentifier:@"value"];
            id cellView = [_parameterQueryTableView viewAtColumn:column row:tableIndex makeIfNecessary:NO];
            
            if([cellView isKindOfClass:[NSDatePicker class]]) {
                currentParameter.dateValue = [cellView dateValue];
                currentParameter.stringValue = [self parseDate:currentParameter.dateValue withFormat:aTemplate.dateFormatString];
            } else {
                currentParameter.dateValue = nil;
            }
            if ([cellView isKindOfClass:[NSComboBox class]]) { // checkbox
                currentParameter.stringValue = [cellView stringValue];
                
            }
            if ([cellView isKindOfClass:[NSTableCellView class]]) { // textfield/number
                if ([[cellView textField] stringValue] == nil) {
                    currentParameter.stringValue = @"";
                } else {
                    currentParameter.stringValue = [[cellView textField] stringValue] ;
                }
            }
            if ([cellView isKindOfClass:[NSButton class]]) { // checkbox
                currentParameter.stringValue = @"";
                currentParameter.booleanValue = [cellView state];
            }
            tableIndex++;
        }
        arrayIndex++;
        if (currentParameter.stringValue == nil) currentParameter.stringValue = @"";
         //   currentParameter.stringValue = [currentParameter.stringValue stringByPerformingFullCleanUp];
    }
}

-(void)cleanUpParametersForTemplate:(Template *) aTemplate {
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (!currentParameter.isHidden) {
            currentParameter.stringValue = [currentParameter.stringValue stringByPerformingFullCleanUp];
        }
    }
}

-(long)calculateArrayRowFromTableRow:(long)row {
    long arrayIndex = 0;
    long rowIndex = 0;
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        if (rowIndex <= row) {
            arrayIndex++;
            if (!currentParameter.isHidden) {
                rowIndex++;
            }
        }
    }
    return arrayIndex-1;
}


#pragma mark -
#pragma mark PARAMETER QUERY TABLE DATASOURCE / DELEGATE PROTOCOL


-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [_mainWind makeFirstResponder:_parameterQueryTableView];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_parameterQueryTableContents count];

}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result;
    
    if (row >= [_parameterQueryTableContents count]) {
        return nil;
    }
    // LABEL COLUMN
    if ([tableColumn.identifier isEqualToString:@"title"]) {
        return [self getNSViewForParameterQueryTitleColumnForRow:row];
    }
    
    // VALUE COLUMN
    if ([tableColumn.identifier isEqualToString:@"value"]) {
        
        // Set nextKeyViews
        if (row>0) {
            NSView *currentView = _parameterQueryTableContents[row];
            NSView *previousView = _parameterQueryTableContents[row-1];
            if ([[currentView subviews] count]>0) currentView = [[currentView subviews] lastObject];
            if ([[previousView subviews] count]>0) previousView = [[previousView subviews] lastObject];
            [previousView setNextKeyView:currentView];
        }
        
        return _parameterQueryTableContents[row];
    }
    return result;
}

#pragma mark Generate Views

-(NSView*)getNSViewForParameterQueryTitleColumnForRow:(NSInteger)row {

    NSTableCellView *result;
    long newRow = [self calculateArrayRowFromTableRow:row];
    
    TemplateParameter *theParameter =(_selectedTemplate.templateParameterSet)[newRow];
    
    result = [_parameterQueryTableView makeViewWithIdentifier:@"imageAndLabel" owner:self];
    
    [result.textField setStringValue:[NSString stringWithFormat:@"%@:", [theParameter name]]];
    if ([NSString isNotEmptyString:theParameter.parentFolderNamingRule] && theParameter.isRequired) {
        [result imageView].image = [NSImage imageNamed:@"parameter_folder_required"];
    }
    if ([NSString isNotEmptyString:theParameter.parentFolderNamingRule] && !theParameter.isRequired) {
        [result imageView].image = [NSImage imageNamed:@"parameter_folder"];
    }
    if ([NSString isEmptyString:theParameter.parentFolderNamingRule] && theParameter.isRequired) {
        [result imageView].image = [NSImage imageNamed:@"parameter_required"];
    }
    if ([NSString isEmptyString:theParameter.parentFolderNamingRule] && !theParameter.isRequired) {
        [result imageView].image = nil;
    }
    return result;
}

-(NSView*)getNSViewForParameterQueryValueColumnForRow:(NSInteger)row {
    
    NSTableCellView *result;
    NSDatePicker *resultDatePicker = [[NSDatePicker alloc] init];
    NSComboBox *resultCombo;
    NSButton *resultCheckBox;
    long newRow = [self calculateArrayRowFromTableRow:row];
    
    TemplateParameter *theParameter =(_selectedTemplate.templateParameterSet)[newRow];

        NSDate *today = [NSDate date];
        BOOL isEditable = [theParameter isEditable];
        switch ([theParameter parameterType]) {
            case text:
                result = [_parameterQueryTableView makeViewWithIdentifier:@"textfield" owner:self];
                [result.textField setEditable:isEditable];
                [result.textField setEnabled:isEditable];
                [result.textField setStringValue:theParameter.stringValue];
                break;
            case number:
                result = [_parameterQueryTableView makeViewWithIdentifier:@"textfield" owner:self];
                [result.textField setEditable:isEditable];
                [result.textField setEnabled:isEditable];
                [result.textField setStringValue:theParameter.stringValue];
                break;
            case list:
                resultCombo = [_parameterQueryTableView makeViewWithIdentifier:@"combo" owner:self];
                [self updateParameterQueryComboBox:resultCombo withString:[theParameter defaultValue]];
                [resultCombo setEditable:isEditable];
                return resultCombo; // breaking out of method, must be changed if something is added at the end
                break;
            case date:
                resultDatePicker = [_parameterQueryTableView makeViewWithIdentifier:@"date" owner:self];
                [resultDatePicker setDateValue:today];
                [resultDatePicker setEnabled:isEditable];
                return resultDatePicker; // breaking out of method, must be changed if something is added at the end
                break;
            case loginName:
                result = [_parameterQueryTableView makeViewWithIdentifier:@"textfield" owner:self];
                [result.textField setEditable:isEditable];
                [result.textField setEnabled:isEditable];
                [result.textField setStringValue:theParameter.stringValue];
                break;
            case userName:
                result = [_parameterQueryTableView makeViewWithIdentifier:@"textfield" owner:self];
                [result.textField setEditable:isEditable];
                [result.textField setEnabled:isEditable];
                [result.textField setStringValue:theParameter.stringValue];
                break;
            case boolean:
                resultCheckBox = [_parameterQueryTableView makeViewWithIdentifier:@"checkbox" owner:self];
                [resultCheckBox setEnabled:isEditable];
                [resultCheckBox setState:theParameter.booleanValue];
                return resultCheckBox; // breaking out of method, must be changed if something is added at the end
                break;
            default:
                result = [_parameterQueryTableView makeViewWithIdentifier:@"textfield" owner:self];
                [result.textField setEditable:isEditable];
                [result.textField setEnabled:isEditable];
                [result.textField setStringValue:theParameter.stringValue];
                break;
        }
        
    
    return result;
}

#pragma mark -
#pragma mark TARGET FOLDER

#pragma mark Path Control

-(void)setTargetFolderPopUpToFolder:(FileSystemItem*)folder {
    NSInteger index=0;
    for (FileSystemItem *targetPreset in _selectedTemplate.targetFolderPresets) {
        if ([targetPreset.pathByExpandingTildeInPath isEqualToString:folder.pathByExpandingTildeInPath]) {
            [_targetFolderPopUpButton selectItemAtIndex:index];
            lastSelectedTargetFolderIndex = index;
            return;
        }
        index++;
    }
}


-(void)browseForNewTargetFolder:(id)sender {
    NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
    [openDlg setCanChooseFiles:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:NO];
    [openDlg setDirectoryURL:_selectedTargetFolder.fileURL];
    [openDlg setAnimationBehavior:NSWindowAnimationBehaviorNone];
    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray* selectedURLS = [openDlg URLs];
        _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:selectedURLS[0]];
        lastSelectedTargetFolderIndex = -1;
        [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
        [self updateTargetFolderViews];
        [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];

    }
}

-(void)doubleClick:(id)nid {
    NSOutlineView *theView = nid;
    NSInteger theRow = [theView selectedRow];
    FileSystemItem *item = [theView itemAtRow:theRow];
    if (item.isDirectory==NO) return;
    // TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:folder];
    
    _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:item.fileURL];
    lastSelectedTargetFolderIndex = -1;
    [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
    [self updateTargetFolderViews];
    [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"targetPathChanged" object:self];
}




- (IBAction)userSelectedPath:(id)sender {
    NSPathComponentCell *clickedPathCell = [sender clickedPathComponentCell];
	NSURL *clickedPathURL = [clickedPathCell URL];
    
    if (clickedPathURL != NULL) {
        BOOL isLastPathComponent = [[clickedPathURL path] isEqualToString:[[_pathControl URL] path]];
        
		if (!isLastPathComponent) {
			[sender setURL:clickedPathURL];
            _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:clickedPathURL];
            lastSelectedTargetFolderIndex = -1;
            [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
            [self updateTargetFolderViews];
            [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:@"targetPathChanged" object:self];
        }
	}
}

- (IBAction)selectParentFolder:(id)sender {
    if ([[_selectedTargetFolder.pathByExpandingTildeInPath pathComponents] count] > 1) {
        NSURL *newTargetURL = [[_pathControl URL] URLByDeletingLastPathComponent];
        
        _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:newTargetURL];
        lastSelectedTargetFolderIndex = -1;
        [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
        [self updateTargetFolderViews];
        [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
        
    }
}

#pragma mark Common

-(void)updateTargetFolderViews {
    
    FileSystemItem *parsedTargetFolder = [[FileSystemItem alloc] initWithPath:[_templateDeployer parseParametersForPath:_selectedTargetFolder.pathByExpandingTildeInPath] andNickName:_selectedTargetFolder.nickName];
    
    [_pathControl setURL:[parsedTargetFolder fileURL]];

    [_targetBrowserHelper updateWithFolder:parsedTargetFolder andTemplate:_selectedTemplate];
    
    [_targetBrowserHelper refresh];
    [_targetFolderOutlineView reloadData];
    [_targetFolderOutlineView deselectAll:_targetFolderOutlineView];
}

-(NSInteger)updateTargetFolder {
    NSInteger err = 0;

    FileSystemItem *previousParsedTargetFolder = [self parsedTargetFolder];
    [self readParameterQueryTableToTemplate:_selectedTemplate];
    
    // Parse tags for path
    FileSystemItem *parsedTargetFolder = [self parsedTargetFolder];
    
    BOOL targetFolderHasChanged = NO;
    targetFolderHasChanged = ![parsedTargetFolder.pathByExpandingTildeInPath isEqualToString:previousParsedTargetFolder.pathByExpandingTildeInPath];
    
    if ([_filterOnOffButton state] == 1) {
        [self readParameterQueryTableToTemplate:_selectedTemplate];
        [_targetBrowserHelper setFilteringTemplate:_selectedTemplate];
    }
    
    if (targetFolderHasChanged) {

        [self populateTargetFolderPopUpButton];
        [self updateTargetFolderViews];

    }
    return err;
}

-(FileSystemItem *) parsedTargetFolder {
    FileSystemItem *parsedTargetFolder;

    if (lastSelectedTargetFolderIndex >= 0) { // parse only if target is a preset
        parsedTargetFolder = [[FileSystemItem alloc] initWithPath:[_templateDeployer parseParametersForPath:_selectedTargetFolder.pathByExpandingTildeInPath] andNickName:_selectedTargetFolder.nickName];
    } else {
        parsedTargetFolder = _selectedTargetFolder;
    }
    return parsedTargetFolder;
}


#pragma mark PopUpButton

-(void)populateTargetFolderPopUpButton {
    [_targetFolderPopUpButton removeAllItems];
    for (FileSystemItem *currentFolder in _selectedTemplate.targetFolderPresets) {
        if ([currentFolder.nickName isEqualToString:@""]) {
            [_targetFolderPopUpButton addItemWithTitle:[NSString stringWithString:currentFolder.path]];
        } else {
            [_targetFolderPopUpButton addItemWithTitle:[NSString stringWithString:currentFolder.nickName]];
        }
    }
    [_targetFolderPopUpButton addItemWithTitle:@"Custom"];
    if ([_selectedTemplate.targetFolderPresets count] > 0) {
        _selectedTargetFolder = (_selectedTemplate.targetFolderPresets)[0];
        [self readParameterQueryTableToTemplate:_selectedTemplate];
        
    } else {
        _selectedTargetFolder = [FileSystemItem systemRootFolder];
    }
    [_pathControl setURL:[_selectedTargetFolder fileURL]];
    lastSelectedTargetFolderIndex = 0;
}

- (IBAction)targetFolderPopUpAction:(id)sender {                                        // REFACTOR
    long selectedIndex = [_targetFolderPopUpButton indexOfSelectedItem];
    long lastIndex = [[_targetFolderPopUpButton itemArray] count] -1;
    if (selectedIndex == lastIndex) { // means always custom selection
        
        // CUSTOM FOLDER
        
        NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
        [openDlg setCanChooseFiles:NO];
        [openDlg setAllowsMultipleSelection:NO];
        [openDlg setCanChooseDirectories:YES];
        [openDlg setCanCreateDirectories:NO];
        [openDlg setDirectoryURL:[_selectedTargetFolder fileURL]];
        [openDlg setAnimationBehavior:NSWindowAnimationBehaviorNone];
        
        if ( [openDlg runModal] == NSOKButton ) {
            NSArray* selectedURLS = [openDlg URLs];
            NSURL *selectedURL =selectedURLS[0];
            _selectedTargetFolder = [[FileSystemItem alloc] initWithPath:[selectedURL path] andNickName:@"Custom"];
            [self updateTargetFolderViews];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:@"targetPathChanged" object:self];
            lastSelectedTargetFolderIndex = -1;
            [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
            [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        } else {
            if (lastSelectedTargetFolderIndex >=0) [_targetFolderPopUpButton selectItemAtIndex:lastSelectedTargetFolderIndex]; // cancel reverts to previous selection
        }
    } else {
        
        // FOLDER PRESET
        
        _selectedTargetFolder = (_selectedTemplate.targetFolderPresets)[selectedIndex];
        lastSelectedTargetFolderIndex = selectedIndex;
        [self updateTargetFolderViews];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
    }
}

#pragma mark -
#pragma mark TARGET BROWSER VIEW

- (IBAction)targetOutlineViewAction:(id)sender {
    if (metadataBrowser) {
        NSInteger rowIndex =  [_targetFolderOutlineView clickedRow];
        id item = [_targetFolderOutlineView itemAtRow:rowIndex];
        FileSystemItem *clickedItem;
        if (item == nil) {
            clickedItem = _selectedTargetFolder;
        } else {
            clickedItem = item;
        }
        TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:clickedItem];
        [metadataBrowser setMetadata:metadata];
    }
  
}




- (IBAction)contextMenuCopyParameters:(id)sender {
    NSInteger rowIndex =  [_targetFolderOutlineView clickedRow];
    id item = [_targetFolderOutlineView itemAtRow:rowIndex];
    if (![item isKindOfClass:[FileSystemItem class]]) return;
    FileSystemItem *fileSystemItem = item;
    if (fileSystemItem.isDirectory) {
        TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:fileSystemItem];
        if (metadata==nil || [metadata.metadataArray count]==0) {
            return;
        }
        if (_selectedTemplate!=nil) {
            [self readParametersFromMetadata:metadata];
        }
        
    }
}

- (IBAction)contextMenuShowInFinder:(id)sender {
    NSInteger rowIndex =  [_targetFolderOutlineView clickedRow];
    id item = [_targetFolderOutlineView itemAtRow:rowIndex];
    FileSystemItem *clickedItem;
    if (item==nil) {
        clickedItem = _selectedTargetFolder;
    } else {
        clickedItem = item;
    }
    [clickedItem updateExistingStatus];
    if (clickedItem.isDirectory) {
        BOOL couldOpen = [[NSWorkspace sharedWorkspace] openURL:[clickedItem fileURL]];
    }

}

- (IBAction)showMetadataContextMenuAction:(id)sender {
    NSInteger rowIndex =  [_targetFolderOutlineView clickedRow];
    id item = [_targetFolderOutlineView itemAtRow:rowIndex];
    FileSystemItem *fileSystemItem;
    if (item==nil) {
        fileSystemItem = _selectedTargetFolder;
    } else {
        fileSystemItem = item;
    }
    [fileSystemItem updateExistingStatus];

    
    if (!metadataBrowser) {
        metadataBrowser = [[MetadataBrowser alloc] init];
    }
    TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:fileSystemItem];
    if ([metadata.metadataArray count] > 0) {
        [metadataBrowser openWindow];
        [metadataBrowser setMetadata:metadata];
    }
}


#pragma mark -
#pragma mark METADATA BROWSER

-(void)openMetadataBrowser:(id)sender {
    if (!metadataBrowser) {
        metadataBrowser = [[MetadataBrowser alloc] init];
    }
    [metadataBrowser setMetadata:nil];
    [metadataBrowser openWindow];
}

#pragma mark -
#pragma mark NOTIFICATIONS AND EVENTS

-(void)preferencesDidChange:(NSNotification*)aNotification {
    [_templateManagerToolbarItem setAutovalidates:NO];
    [_templateManagerMenuItem setEnabled:[_preferences.templateSetLocations count]>0];
    [_templateManagerToolbarItem setEnabled:[_preferences.templateSetLocations count]>0];

    if (templateManager) {
        [templateManager updatePreferences:_preferences];
    }
    [self populateTemplatePopUpButton];
    [self setSelectedTemplateByPopUp];
    [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self updateTargetFolderViews];
}

-(void)templatesDidChange:(NSNotification*)aNotification {
    [_viewMenuItem setHidden:YES];
    [self populateTemplatePopUpButton];
    [self setSelectedTemplateByPopUp];
    [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self updateTargetFolder];
    [self updateTargetFolderViews];
}

-(void)targetDidChange:(NSNotification*)aNotification {
//    TemplateMetadata *targetMetadata = [[TemplateMetadata alloc] initByReadingFromFolder:_selectedTargetFolder];
    
}
- (IBAction)comboBoxAction:(id)sender {
    [self updateTargetFolder];
}

- (IBAction)checkBoxAction:(id)sender {
    [self updateTargetFolder];
}

- (IBAction)datePickerAction:(id)sender {
    [self updateTargetFolder];
}

- (IBAction)textFieldAction:(id)sender {
    [self updateTargetFolder];
}


#pragma mark -
#pragma mark SUPPORTING METHODS

-(void)readParametersFromMetadata:(TemplateMetadata*)metadata {
    NSInteger tableIndex=0;
    NSInteger arrayIndex=0;
    
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        
        if (!currentParameter.isHidden && currentParameter.isEditable) {
            NSString *foundStringValue = nil;
            NSString *previouslyFoundStringValue = nil;
            NSNumber *foundCheckBoxValue = nil;
            NSNumber *previouslyFoundCheckBoxValue = nil;
            
            for (TemplateMetadataItem *metadataItem in metadata.metadataArray) {
                
                if (currentParameter.parameterType == boolean) {
                    
                    foundCheckBoxValue = (metadataItem.parametersForParentLevel)[[currentParameter.tag lowercaseString]] ;
                    if (foundCheckBoxValue!=nil) {
                        if (previouslyFoundCheckBoxValue==nil) previouslyFoundStringValue = [foundCheckBoxValue copy];
                        if ([foundCheckBoxValue boolValue] != [previouslyFoundCheckBoxValue boolValue] ) {
                            foundCheckBoxValue = nil; // multiple values found, skip this
                            break;
                        }
                    }
                } else {
                    foundStringValue = (metadataItem.parametersForParentLevel)[[currentParameter.tag lowercaseString]];
                    if (![foundStringValue isEqualToString:@""] && foundStringValue!=nil) {
                        if (previouslyFoundStringValue==nil) previouslyFoundStringValue = [foundStringValue copy];
                        if (![previouslyFoundStringValue isCaseInsensitiveLike:foundStringValue]) {
                            foundStringValue = nil; // multiple values found, skip this
                            break;
                        }
                    }
                }
            }
            
            if (foundStringValue!=nil || foundCheckBoxValue!=nil) {
                NSInteger column = [_parameterQueryTableView columnWithIdentifier:@"value"];
                id cellView = [_parameterQueryTableView viewAtColumn:column row:tableIndex makeIfNecessary:NO];

                if ([cellView isKindOfClass:[NSComboBox class]]) { // checkbox
                    [cellView setStringValue:foundStringValue];
                }
                if ([cellView isKindOfClass:[NSTableCellView class]]) { // textfield/number
                    [[cellView textField] setStringValue:foundStringValue] ;

                }
                if ([cellView isKindOfClass:[NSButton class]]) { // checkbox
                    [cellView setState:[foundCheckBoxValue boolValue]];
                }

            }
            tableIndex++;
        }
        arrayIndex++;
    }

    
}


-(void)updateParameterQueryComboBox:(NSComboBox *)comboBox withString:(NSString *)semicolonSeparatedString {
    // Parses xx;yy;zz list
    [comboBox removeAllItems];
        long defaultIndex = 0;
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[semicolonSeparatedString componentsSeparatedByString:@";"]];
    for (long index = 0; index < [items count]; index++) {
        NSString *string = items[index];
        items[index] = [string stringByRemovingDoubleSpacesAndPunctuation];
    }
    if ([items count] >0) {
        if ([items[0] isEqualToString:@""]) {
            defaultIndex = -1;
        }
    } else {
        defaultIndex = -1;
    }
    [self removeEmptyStringsFromMutableArray:items];

    if ([items count] > 1 && defaultIndex >= 0) {
        for (long index = 1; index < [items count]; index++) {
            if ([items[0] isEqualToString:items[index]]) {
                defaultIndex = index-1;
                [items removeObjectAtIndex:0];
                break ;
            }
        }
    }
    [comboBox removeAllItems];
    [comboBox addItemsWithObjectValues:items];
    if (defaultIndex >= 0) {
        [comboBox selectItemAtIndex:defaultIndex];

    } else {
        [comboBox deselectItemAtIndex:[comboBox indexOfSelectedItem]];
    }
}

// used only(?) for list type parameter default list parser
-(void)removeEmptyStringsFromMutableArray:(NSMutableArray *)mutableArray {
    if ([mutableArray count] > 0) {
        for (long index = [mutableArray count] - 1; index >= 0; index--) {
            if ([mutableArray[index] isEqualToString:@""]) {
                [mutableArray removeObjectAtIndex:index];
            }
        }
    }
}

-(NSString *)parseDate:(NSDate *)date withFormat:(NSString *)formatString {
    NSMutableString *fixedFormatString = [NSMutableString stringWithString:[formatString stringByPerformingFullCleanUp]];
    [fixedFormatString replaceOccurrencesOfString:@"Y" withString:@"y" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    [fixedFormatString replaceOccurrencesOfString:@"D" withString:@"d" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    [fixedFormatString replaceOccurrencesOfString:@"m" withString:@"M" options:0 range:NSMakeRange(0, [fixedFormatString length])];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fixedFormatString];
    return [dateFormatter stringFromDate:date];
}


#pragma mark Errors

-(void)errorPanelForErrCode:(NSInteger)errCode andParameter:(NSString*)paramStr {
    NSString *errMsg;
    BOOL isError = NO;
    // BOOL isWargning = NO;
    if (errCode>0) {
        
        switch (errCode) {
            case ErrMasterFolderExists:
                errMsg = @"Project folder already exists";
                isError = YES;
                break;
            case ErrCouldntCreateFolder:
                errMsg = @"Cannot create folder";
                isError = YES;
                break;
            case ErrFolderOccupiedByFile:
                errMsg = @"Cannot create folder. Folder's name is in use";
                isError = YES;
                break;
            case ErrInvalidParentFolderName:
                errMsg = @"Invalid parent folder name";
                isError = YES;
                break;
            case ErrTargetFolderDoesntExist:
                errMsg = @"Target folder does not exist";
                isError = YES;
                break;
            case ErrFileExistsAtTarget:
                errMsg = @"File already exists";
                isError = YES;
                break;
            case ErrFileCopyError:
                errMsg = @"Cannot write file";
                isError = YES;
                break;
            case ErrParameterTagsYieldedEmptyString:
                errMsg = @"Empty parent folder name";
                isError = YES;
                break;
            case ErrRequiredParametersMissing:
                errMsg = @"Required parameter missing";
                isError = YES;
                break;
            case ErrInvalidMasterFolderName:
                errMsg = @"Invalid master folder name";
                isError = YES;
                break;
            case ErrInvalidFileOrFolderName:
                errMsg = @"Invalid file or folder name";
                isError = YES;
                break;
            case ErrSettingPosix:
                errMsg = @"Could not set permissions";
                isError = YES;
                break;
            case WarnSkippedExistingFiles:
                errMsg = @"Skipped existing file(s)";
                isError = NO;
                break;
                
            default:
                errMsg = [NSString stringWithFormat:@"General error with code: %li", errCode];
                isError = YES;
                break;
        }
        if (isError) {
            errMsg = [NSString stringWithFormat:@"Error:\n%@", errMsg];
        } else {
            errMsg = [NSString stringWithFormat:@"Warning:\n%@", errMsg];
        }
        if (!paramStr) {
            paramStr = @"";
        }
        NSRunAlertPanel(errMsg, paramStr, nil, nil, nil);
        
    }
}

#pragma mark -
#pragma mark INITIALIZATION


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // TEST
    
    // seeding random generator;
    srandom((unsigned int) time(NULL));
    
    _preferences = [[Preferences alloc] initWithLoadingPreferences];
    [_templateManagerToolbarItem setAutovalidates:NO];
    [_templateManagerMenuItem setEnabled:[_preferences.templateSetLocations count]>0];
    [_templateManagerToolbarItem setEnabled:[_preferences.templateSetLocations count]>0];
    _parameterQueryTableContents = [[NSMutableArray alloc] init];
    
    _targetBrowserHelper = [[FileBrowserHelper alloc] initWithOutlineView:_targetFolderOutlineView folder:nil showFiles:YES];
    _templateBrowserHelper = [[FileBrowserHelper alloc] initWithOutlineView:_templateFileBrowserOutlineView folder:nil showFiles:YES];
    
    [self populateTemplatePopUpButton];
    [self setSelectedTemplateByPopUp];
    [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self updateTargetFolder];
    [self updateTargetFolderViews];
    [_targetFolderOutlineView setTarget:self];
    [_targetFolderOutlineView setDoubleAction:@selector(doubleClick:)];
    [_targetFolderOutlineView setDataSource:_targetBrowserHelper];
    [_targetFolderOutlineView setDelegate:_targetBrowserHelper];
    [_templateFileBrowserOutlineView setDelegate:_templateBrowserHelper];
    [_templateFileBrowserOutlineView setDataSource:_templateBrowserHelper];
    [_templateFileBrowserPathControl setBackgroundColor:[Definitions controlPathBackgroundColor ]];
    [_pathControl setBackgroundColor:[Definitions controlPathBackgroundColor]];
    
#if DEBUG
    [_testButton setHidden:NO];
    [_debugLabel setHidden:NO];
    
#endif

}

-(id)init {
    self = [super init];
    if (self) {
        _preferences = [[Preferences alloc] init];
        _selectedTargetFolder = [FileSystemItem systemRootFolder];
        lastSelectedTargetFolderIndex = 0;
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(preferencesDidChange:) name:@"preferencesDidChange" object:nil];
        [nc addObserver:self selector:@selector(templatesDidChange:) name:@"templatesDidChange" object:nil];
        [nc addObserver:self selector:@selector(targetDidChange:) name:@"targetPathChanged" object:nil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)filterAction:(id)sender {
    if ([_filterOnOffButton state] == 1) {
        _filterOnOffButton.title = @"Filter On";
        [self readParameterQueryTableToTemplate:_selectedTemplate];
        [_targetBrowserHelper setFilteringTemplate:_selectedTemplate];
    } else {
        _filterOnOffButton.title = @"Filter Off";
        [_targetBrowserHelper stopFiltering];
    }
}


@end

