//
//  AppDelegate.m
//  Lonkero
//
//  Created by Kati Haapamäki on 26.10.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark
#pragma TESTING


-(void)performTestRoutineForDevelopmentPurposes {
#if DEBUG
    
   
    
    
#endif
}



#pragma mark -
#pragma mark IB ACTIONS

/**
 *  IBAction for showing the mainwindow
 *
 *  @param sender The sender
 */

- (IBAction)showMainWindow:(id)sender {
    [_mainWind makeKeyAndOrderFront:self];
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



- (IBAction)deployMenuItem:(id)sender {
    [self deployFolderStructure:sender];

}


/**
 *  Rewrite metadata by preforming deployment process without actually deploying anything.
 *
 *  @param sender A sender
 */

- (IBAction)rewriteMetadataMenuItem:(id)sender {
    if (!_selectedTemplate) return;
    
    if ([self hasMissingParameters]) {
        [self errorPanelForErrCode:ErrRequiredParametersMissing andParameter:nil] ;
        return;
    }
    
    // err code not implemented yet..
    NSInteger err = [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    
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
            [_targetBrowserHelper flushMetadataCache];
            [self updateTargetFolderViews];
            [self errorPanelForErrCode:errCode andParameter:errString];
        }
    }
}

// -----------
// DEPLOY
// -----------

/**
 *  Deploys the selected template with parameters set by user
 *
 *  Is cancelled if required parameters are missing. TemplateDeployer class is used for deployment process.
 *  After deployment the target folder is opened in Finder and/or the main window is closed
 *  depending on user preferences.
 *
 *  @see TemplateDeployer
 *
 *  @param sender A sender
 */
- (IBAction)deployFolderStructure:(id)sender {
    
    if (!_selectedTemplate) return;
    
    [self cleanUpParametersForTemplate:_selectedTemplate];
    
    if ([self hasMissingParameters]) {
        [self errorPanelForErrCode:ErrRequiredParametersMissing andParameter:nil] ;
        return;
    }
    NSString *errStr = nil;
    if ([self hasTooManyParameters:&errStr]) {
        [self errorPanelForErrCode:ErrOverlappingOptionalParameters andParameter:errStr];
        return;
    }
    
    // err code not implemented yet..
    NSInteger err = [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    
    if (err!=0) {
        [self errorPanelForErrCode:err andParameter:nil];
        return;
    }
    
    // check if custom target folder is set and warn user
    if (lastSelectedTargetFolderIndex == -1) {
        NSInteger answer = NSRunAlertPanel(@"Warning! Custom target folder is set. Are you sure you want to deploy to that folder?", _selectedTargetFolder.path, @"Proceed", @"Cancel", nil);
        if (answer == NSCancelButton) return;
    }
    NSString *errString = @"";
    NSInteger errCode = 0;
    
    // DEPLOY
    
    FileSystemItem *targetFolder = [self parsedTargetFolder];
    
    errCode = [_templateDeployer deployToTargetFolder:targetFolder errString:&errString];
    
    FileSystemItem *masterFolder = [[_templateDeployer generateParentFolderArrayWithError:nil] lastObject];
    
    [_targetBrowserHelper flushMetadataCache];
    
    // Deploy results
    if (errCode != 0) {
        if (errCode <= 128) {

            [self updateTargetFolderViews];
            [self errorPanelForErrCode:errCode andParameter:errString];
        }
    } else {
        BOOL couldOpen = NO;
        BOOL openFolder = (([_userPreferences.postDeploymentAction integerValue] & openMasterFolder) || ([_userPreferences.postDeploymentAction integerValue] & openTargetFolder) );
        
        if (openFolder) {

            FileSystemItem *folderToShow = nil;
            if ([_userPreferences.postDeploymentAction integerValue] & openMasterFolder) {
                folderToShow = masterFolder;
            } else {
                folderToShow = targetFolder;
            }
            couldOpen = [[NSWorkspace sharedWorkspace] openURL:[folderToShow fileURL]];
            NSAssert(couldOpen, @"Could not open finder window");
        } else {
            NSRunAlertPanel(@"Folder structure deployed", masterFolder.path, @"Ok", nil, nil);
        }
        
        

        [self reloadParameterQueryTable];
        [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
        [self updateTargetFolderViews];
        
        if ([_userPreferences.postDeploymentAction integerValue] & closeWindow) {
            [_mainWind close];
        }
        
        if ([_userPreferences.postDeploymentAction integerValue] & quitApp) {
            // QUIT APP
        }
    }
}

- (IBAction)showPreferencePanel:(id)sender {
    if (!preferencesController) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController editPreferences:_preferences andUserPreferences:_userPreferences];
    [_toolBar setSelectedItemIdentifier:nil];
}


#pragma mark -
#pragma mark TEMPLATE SELECTION

/**
 *  Sets contents for template selection pop up button
 */

- (void)populateTemplatePopUpButton {
    [_templatePopUpButton removeAllItems];
    _templateArray = [TemplateManager getAvailableTemplatesAsFoldersWithPreferences:_preferences];
    for (FileSystemItem *currentFolder in _templateArray) {
        [_templatePopUpButton addItemWithTitle:currentFolder.nickName];
    }
}

/**
 *  Selects a templete by user's choice
 *
 *  Sets selected template,initializes parameter query table and refresh target folder view.
 *
 */

- (IBAction)templatePopUpAction:(id)sender {
    [self setSelectedTemplateByPopUp];

}

/**
 *  Reads template selection popup button's value and set it to be the current template
 *
 *  Sets @a _selectedTemplate variable and initializes the template browser
 */

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
    [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self populateTargetFolderPopUpButton];
    [self setTargetFolderPopUpButtonToIndex:0];
    [_targetBrowserHelper flushMetadataCache];
    [self updateTargetFolderViews];
}

-(void)setTemplatePopUpButtonByUserPreferencesDefault {
    FileSystemItem *chooseThis = _userPreferences.locationOfDefaultTemplate;
    BOOL templateFound = NO;
    for (NSInteger index=0; index < [_templateArray count]; index++) {
        FileSystemItem *popupItem = _templateArray[index];
        if ([chooseThis.URLStylePath isEqualToString:popupItem.URLStylePath]) {
            templateFound = YES;
            [_templatePopUpButton selectItemAtIndex:index];
            break;
        }
    }
    if (!templateFound) {
        [_templatePopUpButton selectItemAtIndex:0];
    }
    [self setSelectedTemplateByPopUp];
    
}


#pragma mark -
#pragma mark PARAMETER QUERY TABLE

/**
 *  Checks if parameter query table has missing required parameters
 *
 *  This is used before deployment to check if it's possible to proceed.
 *
 *  @return YES if parameters are missing
 */

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
                        if  ([NSString isEmptyString:[cellView objectValueOfSelectedItem]]) {
                            result = YES;
                        }
                        break;
                    case date:
                         // cannot be missing
                        break;
                    default:
                        
                        if ([NSString isEmptyString:[[cellView textField] stringValue]]) {
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


/**
 *  Checks if user has entered too many parameter values in parameter query
 *
 *  This can occur if there are optional parameters that are not allowed together with another.
 *
 *  @return YES if there are too many parameters
 */

-(BOOL)hasTooManyParameters:(NSString**)errStr {
    BOOL result = NO;
    long tableIndex = 0;
    long arrayIndex = 0;
    BOOL previousParameterSet = NO;
    BOOL thisParameterSet = NO;
    TemplateParameter *previousParameter = nil;
    
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        if (!currentParameter.isHidden) {
            thisParameterSet = NO;
            
            NSInteger column = [_parameterQueryTableView columnWithIdentifier:@"value"];
            id cellView = [_parameterQueryTableView viewAtColumn:column row:tableIndex makeIfNecessary:NO];
            switch (currentParameter.parameterType) {
                case boolean:
                    thisParameterSet = YES;
                    break;
                case list:
                    if ([NSString isNotEmptyString:[cellView objectValueOfSelectedItem]]) thisParameterSet = YES;
                    
                    break;
                case date:
                    thisParameterSet = YES;
                    break;
                default:
                    if ([NSString isNotEmptyString:[[cellView textField] stringValue]]) thisParameterSet = YES;
                    break;
            }
            
            if (currentParameter.optionalWithAbove && previousParameter != nil) {
                if (thisParameterSet && previousParameterSet) {
                    if (result == NO && errStr!=NULL) {
                        *errStr = [NSString stringWithFormat:@"\"%@\" and \"%@\"", previousParameter.name, currentParameter.name];
                    }
                    result = YES;
                }
            }
            tableIndex++;
            previousParameter = currentParameter;
            previousParameterSet = thisParameterSet;
        }
        arrayIndex++;
        
    }
    
    return result;
}



/**
 *  Initializes parameter query table for a given template
 *  
 *  Sets parameters values to the defaults as set in the template settings.
 *  If parameter type is text or number, @a defaultValue is just copied to @a stringValue.
 *  If parameter type is date, current date is used for @a dateValue.
 *  If parameter type is userName or loginName, current user's name is used for @a stringValue.
 *
 *  Initializes @a _parameterQueryTableContents array with NSView objects (Refactor: could be own methdod)
 *
 *  Initializes target folder selection popup button and path control view object
 *
 *  @param aTemplate A template
 */

-(void)loadParameterQueryTableWithTemplate:(Template*)aTemplate {
    
    // loads template default values to query table and displays it
    
    
    [self setParameterValuesToDefaults:aTemplate];
    
    /*
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (!currentParameter.isHidden) {
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
    }
    
    // load hidden defaults also
    
    [self setHiddenParametersToTemplate:aTemplate];
    */
    
    //NSInteger rows = [self numberOfRowsInTableView:_parameterQueryTableView];
   // [_parameterQueryTableContents removeAllObjects];
    
    _parameterQueryTableContents = nil; 
    _parameterQueryTableContents = [NSMutableArray array];
    
    // Prepare array for parameter NSView objects
    long rowIndex=0;
    for (NSInteger arrayIndex =0; arrayIndex<[aTemplate.templateParameterSet count ]; arrayIndex++) {
        if (![(aTemplate.templateParameterSet)[arrayIndex] isHidden]) {
            [_parameterQueryTableContents addObject:[self getNSViewForParameterQueryValueColumnForRow:rowIndex]];
            rowIndex++;
        }
    }
    [_parameterQueryTableView reloadData];
    
    [self populateTargetFolderPopUpButton];
    [self setTargetFolderPopUpButtonToIndex:0];
    [_templateFileBrowserPathControl setURL:[aTemplate.location fileURL]];

}

-(IBAction)clearParameters:(id)sender {
    [self reloadParameterQueryTable];
}

/**
 *  Resets parameter query table to its default values
 *
 *  Very similar to loadParameterQueryTableWithTemplate. This doesn't set target folder popup button or path control.
 *
 *  @see loadParameterQueryTableWithTemplate:(Template*)aTemplate
 */

-(void)reloadParameterQueryTable {
    
    // loads template default values to query table and displays it
    
    
    [self setParameterValuesToDefaults:_selectedTemplate];
    
    /*
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        if (!currentParameter.isHidden) {
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
    }
    */
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

/**
 *  Sets parameter values for a given template to its default values
 *
 *  @param aTemplate A template
 */

-(void)setParameterValuesToDefaults:(Template *)aTemplate {
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        
        switch (currentParameter.parameterType) {
            case date:
                currentParameter.dateValue = [NSDate date];
                currentParameter.stringValue = [currentParameter.dateValue parsedDateWithFormat:aTemplate.dateFormatString];
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
            case list:
                currentParameter.stringValue = [currentParameter.defaultValue arrayFromSemicolonSeparatedList][0];
                break;
            default:
                currentParameter.stringValue = currentParameter.defaultValue;
                break;
        }
        if (currentParameter.stringValue == nil) currentParameter.stringValue = @"";
    }
}

/**
 *  Sets parameter values for hidden parameters of a given template to defaults
 *
 *  Deprecated. No need to set default values separately for hidden parameters.
 *
 *  @param aTemplate A template
 */


-(void)setHiddenParametersToTemplate:(Template *)aTemplate {
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.isHidden) {
            switch (currentParameter.parameterType) {
                case date:
                    currentParameter.dateValue = [NSDate date];
                    currentParameter.stringValue =  [currentParameter.dateValue parsedDateWithFormat:aTemplate.dateFormatString];
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

/**
 *  Reads user input from paramter query table and stores it to a given template.
 *
 *  @param aTemplate A template
 */

-(void)readParameterQueryTableToTemplate:(Template *)aTemplate {

    // reads user given parameters and set them and hidden parameters to template
    long tableIndex = 0;
    long arrayIndex = 0;
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.isHidden) {
            
            /*
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
            */
        } else {
            
            NSInteger column = [_parameterQueryTableView columnWithIdentifier:@"value"];
            id cellView = [_parameterQueryTableView viewAtColumn:column row:tableIndex makeIfNecessary:NO];
            
            if([cellView isKindOfClass:[NSDatePicker class]]) {
                currentParameter.dateValue = [cellView dateValue];
                currentParameter.stringValue = [currentParameter.dateValue parsedDateWithFormat:aTemplate.dateFormatString];
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
                currentParameter.stringValue = [cellView state] == 0 ? @"off" : @"on";
                currentParameter.booleanValue = [cellView state];
            }
            tableIndex++;
        }
        arrayIndex++;
        if (currentParameter.stringValue == nil) currentParameter.stringValue = @"";
         //   currentParameter.stringValue = [currentParameter.stringValue stringByPerformingFullCleanUp];
    }
}

/**
 *  Cleans up parameter value string formatting in given template
 *
 *  This is used before deployment to remove illegal characters and bad formatting
 *  from string values of template's parameters.
 *
 *  Method used is stringByPerformingFullCleanUp.
 *
 *  @see stringByPerformingFullCleanUp
 *  @param aTemplate A template
 */

-(void)cleanUpParametersForTemplate:(Template *) aTemplate {
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (!currentParameter.isHidden) {
            currentParameter.stringValue = [currentParameter.stringValue stringByPerformingFullCleanUp];
        }
    }
}

/**
 *  Converts index of template parameter array to table view row index
 *
 *  Conversion is calulcated by skipping hidden parameters in a template parameter set.
 *
 *  @param row Index value of an parameter in a template parameter set
 *
 *  @return Row index of a parameter query table
 */

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

/**
 *  TableView protocol method. Also sets nextKeyViews for correct tabbing. This may be unusual place to do
 *  that, but it seems to work.
 *
 */

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

/**
 *  Generates NSView object for any cell in parameter name column of parameter query table
 *
 *  NSView can include icons among text.
 *
 *  @param row Row index
 *
 *  @return NSView object for parameter key cell
 */

-(NSView*)getNSViewForParameterQueryTitleColumnForRow:(NSInteger)row {

    NSTableCellView *result;
    long newRow = [self calculateArrayRowFromTableRow:row];
    
    TemplateParameter *theParameter =(_selectedTemplate.templateParameterSet)[newRow];
    
    result = [_parameterQueryTableView makeViewWithIdentifier:@"imageAndLabel" owner:self];
    
    if (theParameter.optionalWithAbove) {
        [result.textField setStringValue:[NSString stringWithFormat:@"+ %@:", [theParameter name]]];
    } else {
        [result.textField setStringValue:[NSString stringWithFormat:@"%@:", [theParameter name]]];
    }
    
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

/**
 *  Generates NSView object for any cell in parameter value column of parameter query table
 *
 *  Selects from predefined NSViews stored in the view object declare in the nib file by the parameter type
 *
 *  @param row Row index
 *
 *  @return NSView object for parameter key cell
 */

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

/**
 *  Changes target folder popup button's value by given folder
 *
 *  If the given folder is among the presets, then correnponding preset value is selected.
 *  If it's not among the presets, the last object that is always @b custom, is selected.
 *
 *  @note Comparison for paths is made case-insensitively, thus this in not working with casesensitive file ops.
 *
 *  @param folder FileSystemItem pointing to currently selected target folder, thus usually @a _selectedTargetFolder
 */

-(void)setTargetFolderPopUpToFolder:(FileSystemItem*)folder {
    NSInteger index=0;
    for (FileSystemItem *targetPreset in _selectedTemplate.targetFolderPresets) {
        NSString *parsedPresetFolder = [[_templateDeployer parseParametersForPath:targetPreset.pathByExpandingTildeInPath] lowercaseString];
        NSString *parsedSelectedFolder = [[_templateDeployer parseParametersForPath:folder.pathByExpandingTildeInPath] lowercaseString];
        if ([parsedPresetFolder isEqualToString:parsedSelectedFolder]) {
            [_targetFolderPopUpButton selectItemAtIndex:index];
            lastSelectedTargetFolderIndex = index;
            return;
        }
        index++;
    }
    // not found -> set button to 'custom' (last object)
    [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
    lastSelectedTargetFolderIndex = -1;
}

/**
 *  Shows open dialog and let user to select a new target folder.
 *
 *  @param sender A sender
 */

-(IBAction)browseForNewTargetFolder:(id)sender {
    
    FileSystemItem *newTargetFolder = [[FileSystemItem alloc] initWithOpenDialogForFolderSelection:_selectedTargetFolder.fileURL];
    
    if (newTargetFolder != nil) {
        _selectedTargetFolder = newTargetFolder;
        [_targetBrowserHelper flushMetadataCache];
        [self updateTargetFolderViews];
        [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
    }
    return;
    
    /*
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
     */
}

/**
 *  Performs action when user has double clicked folder in target browser
 *
 *  This selects clicked folder to a new target folder.
 */

-(void)doubleClick:(id)nid {
    NSOutlineView *theView = nid;
    NSInteger theRow = [theView selectedRow];
    FileSystemItem *item = [theView itemAtRow:theRow];
    if (item.isDirectory==NO) return;
    // TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:folder];
    
    _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:item.fileURL];
//    lastSelectedTargetFolderIndex = -1;
//    [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
    [_targetBrowserHelper flushMetadataCache];
    [self updateTargetFolderViews];
    [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"targetPathChanged" object:self];
}


/**
 *  Performs action when user has clicked path control
 *
 *  Clicking last component (current folder) does not do anything. Clicking others will change target folder correspondingly.
 */

- (IBAction)userSelectedPath:(id)sender {
    NSPathComponentCell *clickedPathCell = [sender clickedPathComponentCell];
	NSURL *clickedPathURL = [clickedPathCell URL];
    
    if (clickedPathURL != NULL) {
        BOOL isLastPathComponent = [[clickedPathURL path] isEqualToString:[[_pathControl URL] path]];
        
		if (!isLastPathComponent) {
			[sender setURL:clickedPathURL];
            _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:clickedPathURL];
//            lastSelectedTargetFolderIndex = -1;
//            [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
            [_targetBrowserHelper flushMetadataCache];
            [self updateTargetFolderViews];
            [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:@"targetPathChanged" object:self];
        }
	}
}

/**
 *  Performs action when user has clicked 'go up' button
 *
 */

- (IBAction)selectParentFolder:(id)sender {
    if ([[_selectedTargetFolder.pathByExpandingTildeInPath pathComponents] count] > 1) {
        NSURL *newTargetURL = [[_pathControl URL] URLByDeletingLastPathComponent];
        
        _selectedTargetFolder = [[FileSystemItem alloc] initWithURL:newTargetURL];
//        lastSelectedTargetFolderIndex = -1;
//        [_targetFolderPopUpButton selectItemAtIndex:[[_targetFolderPopUpButton itemArray] count] -1];
        [_targetBrowserHelper flushMetadataCache];
        [self updateTargetFolderViews];
        [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
        
    }
}

#pragma mark Common

/**
 *  Updates view objects that are related to the target folder, except target folder selection popup button
 *
 *  Objects updated: path control, target browser
 */

-(void)updateTargetFolderViews {
    
    FileSystemItem *parsedTargetFolder = [[FileSystemItem alloc] initWithPath:[_templateDeployer parseParametersForPath:_selectedTargetFolder.pathByExpandingTildeInPath] andNickName:_selectedTargetFolder.nickName];
    
    [_pathControl setURL:[parsedTargetFolder fileURL]];
    // [self populateTargetFolderPopUpButton]; // added later to combine stuff.. test that it works! DOESNT
    
    [_targetBrowserHelper updateWithFolder:parsedTargetFolder andTemplate:_selectedTemplate];
    
    [_targetBrowserHelper refresh];
    [_targetFolderOutlineView reloadData];
    [_targetFolderOutlineView deselectAll:_targetFolderOutlineView];
}

/**
 *  Updates target folder view and repopulates target folder popup button if needed
 *
 *  Parses target folder for any parameters that may exist in a target path.
 *  If target folder has changed, repopulates target folder selection popup button and
 *  updates target folder views.
 *
 *
 *  @return 0 always. Should be removed if there's no need for errcode feedback.
 */

-(NSInteger)checkIfTargetFolderHasChangedDueParsingAndUpdate {
    NSInteger err = 0;

    FileSystemItem *previousParsedTargetFolder = [self parsedTargetFolder];
    [self readParameterQueryTableToTemplate:_selectedTemplate];
    
    // Parse tags for path
    FileSystemItem *parsedTargetFolder = [self parsedTargetFolder];
    
    BOOL targetFolderHasChanged = NO;
    targetFolderHasChanged = ![parsedTargetFolder.pathByExpandingTildeInPath isEqualToString:previousParsedTargetFolder.pathByExpandingTildeInPath];
    
    if (targetFolderHasChanged) {
     //   NSInteger lastIndex = lastSelectedTargetFolderIndex;
        [self populateTargetFolderPopUpButton];
     //   [_targetFolderPopUpButton selectItemAtIndex:lastIndex];
        [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        [_targetBrowserHelper flushMetadataCache];
        [self updateTargetFolderViews];
        NSRunAlertPanel(@"Note: Target folder has changed due to parameter change.", _selectedTargetFolder.path, @"Ok", nil, nil);
    }
    return err;
}

/**
 *  Reads user input from parameter table, if filtering mode is on
 */
-(void)prepareForFilteringIfNeeded {
    if ([_filterOnOffButton state] == 1) {
        [self readParameterQueryTableToTemplate:_selectedTemplate];
        [_targetBrowserHelper setFilteringTemplate:_selectedTemplate];
    }
}

/**
 *  Returns parameter-parsed value of currently selected target folder
 *
 *  @return FileSystemItem of parsed target folder.
 */
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

/**
 *  Populates target folder selection popup button with preset target folder's
 *
 *  In addition to preset values, @b custom item is added as last object to indicate when
 *  non-preset target folder is in use.
 *
 *  Nick name of preset is in used when available. If not available the path will be shown instead.
 *  The path is parsed with parameters in case they are used in path.
 */

-(void)populateTargetFolderPopUpButton {
    [_targetFolderPopUpButton removeAllItems];
    for (FileSystemItem *currentFolder in _selectedTemplate.targetFolderPresets) {
        if ([NSString isEmptyString:currentFolder.nickName]) {
            NSString *parsedPath = [_templateDeployer parseParametersForPath:currentFolder.pathByExpandingTildeInPath];
            
            [_targetFolderPopUpButton addItemWithTitle:[parsedPath stringByAbbreviatingWithTildeInPath]];
        } else {
            [_targetFolderPopUpButton addItemWithTitle:[NSString stringWithString:currentFolder.nickName]];
        }
    }
    [_targetFolderPopUpButton addItemWithTitle:@"Custom"];
    }

/**
 *  Selects target folder preset by given index of target folder popup button
 *
 *  @param index A index value of the popup button
 */
-(void)setTargetFolderPopUpButtonToIndex:(NSInteger)index {
    if ([_selectedTemplate.targetFolderPresets count] > 0) {
        _selectedTargetFolder = (_selectedTemplate.targetFolderPresets)[index];
        [self readParameterQueryTableToTemplate:_selectedTemplate];  // miksi?
        
    } else {
        _selectedTargetFolder = [FileSystemItem systemRootFolder];
    }
    //[_pathControl setURL:[_selectedTargetFolder fileURL]];
    lastSelectedTargetFolderIndex = 0;

}

/**
 *  Responder of target folder popup button change
 *
 *  Selects target folder by preset corresponding the popup button value.
 *  If last item is selected, that means @b custom folder and open dialog is shown
 *  to let user select a new target folder.
 *
 *  @param sender A sender
 */

- (IBAction)targetFolderPopUpAction:(id)sender {                                        // REFACTOR
    long selectedIndex = [_targetFolderPopUpButton indexOfSelectedItem];
    long lastIndex = [[_targetFolderPopUpButton itemArray] count] -1;
    if (selectedIndex == lastIndex) { // means always custom selection
        
        // CUSTOM FOLDER

        FileSystemItem *newTargetFolder = [[FileSystemItem alloc] initWithOpenDialogForFolderSelection:_selectedTargetFolder.fileURL];
        
        if (newTargetFolder != nil) {
            _selectedTargetFolder = newTargetFolder;
            [_targetBrowserHelper flushMetadataCache];
            [self updateTargetFolderViews];
            [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:@"targetPathChanged" object:self];
        }

       // [self setTargetFolderPopUpToFolder:_selectedTargetFolder];
        /*
        
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
        
        */
    } else {
        
        // FOLDER PRESET
        
        _selectedTargetFolder = (_selectedTemplate.targetFolderPresets)[selectedIndex];
        lastSelectedTargetFolderIndex = selectedIndex;
        [_targetBrowserHelper flushMetadataCache];
        [self updateTargetFolderViews];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
    }
}

#pragma mark -
#pragma mark TARGET BROWSER VIEW IB ACTIONS

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
            [_parameterQueryTableView reloadData];
            [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
            if ([_filterOnOffButton state] == 1) {
                [_targetBrowserHelper refresh];
            }
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
/**
 *  Opens metadata browser window
 *
 *  Creates an instance of metadata browser window controller if not already exists.
 *
 *  @param sender A sender
 */

-(IBAction)openMetadataBrowser:(id)sender {
    if (!metadataBrowser) {
        metadataBrowser = [[MetadataBrowser alloc] init];
    }
    [metadataBrowser setMetadata:nil];
    [metadataBrowser openWindow];
}

#pragma mark -
#pragma mark NOTIFICATIONS AND EVENTS

/**
 *  Notification responder for preferences change
 *
 *  Reloads template selection, selects first template and resets about everything
 *
 *  @param aNotification A notification
 */
-(void)preferencesDidChange:(NSNotification*)aNotification {
    [_templateManagerToolbarItem setAutovalidates:NO];
    [_templateManagerMenuItem setEnabled:[_preferences.templateSetLocations count]>0];
    [_templateManagerToolbarItem setEnabled:[_preferences.templateSetLocations count]>0];

    if (templateManager) {
        [templateManager updatePreferences:_preferences];
    }
    [self populateTemplatePopUpButton];
    [self setTemplatePopUpButtonByUserPreferencesDefault];
    [self setSelectedTemplateByPopUp];
   // [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    //[_targetBrowserHelper flushMetadataCache];
    //[self updateTargetFolderViews];
}

/**
 *  Notification responder for template selection change
 *
 *  Resets parameter query table and target folder view items
 *
 *  @param aNotification A notification
 */

-(void)templatesDidChange:(NSNotification*)aNotification {
    [_viewMenuItem setHidden:YES];
    [self populateTemplatePopUpButton];
    [self setSelectedTemplateByPopUp];
 //   [self loadParameterQueryTableWithTemplate:_selectedTemplate];
   // [self checkIfTargetFolderHasChangedDueParsingAndUpdate];  // check!
   // [self updateTargetFolderViews];
}

-(void)targetPathDidChange:(NSNotification*)aNotification {
//    TemplateMetadata *targetMetadata = [[TemplateMetadata alloc] initByReadingFromFolder:_selectedTargetFolder];

    
}
- (IBAction)comboBoxAction:(id)sender {
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    if ([_filterOnOffButton state] == 1) {
    //    [_targetBrowserHelper flushMetadataCache];
        [_targetBrowserHelper refresh];
    }
   // [self prepareForFilteringIfNeeded];
}

- (IBAction)checkBoxAction:(id)sender {
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    if ([_filterOnOffButton state] == 1) {
      //  [_targetBrowserHelper flushMetadataCache];
        [_targetBrowserHelper refresh];
    }
 //   [self prepareForFilteringIfNeeded];
}

- (IBAction)datePickerAction:(id)sender {
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    if ([_filterOnOffButton state] == 1) {
     //   [_targetBrowserHelper flushMetadataCache];
        [_targetBrowserHelper refresh];
    }
    //[self prepareForFilteringIfNeeded];
}

- (IBAction)textFieldAction:(id)sender {
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    if ([_filterOnOffButton state] == 1) {
      //  [_targetBrowserHelper flushMetadataCache];
        [_targetBrowserHelper refresh];
    }
    //[self prepareForFilteringIfNeeded];
}

-(void)parameterValueDidChange:(NSNotification*)aNotification {
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
    if ([_filterOnOffButton state] == 1) {
        [_targetBrowserHelper refresh];
    }
    //[self prepareForFilteringIfNeeded];
    return;
}

#pragma mark -
#pragma mark SUPPORTING METHODS
/**
 *  Reads parameters from TemplateMetadata object and sets them to the parameter query table
 *
 *  When there are multiple metadata items, only parameters that has the same value in
 *  all of them are copied to parameter table.
 *
 *  @param metadata TemplateMetadata
 */
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
            if (foundStringValue==nil) {
                foundStringValue = @"";
            }
            if (YES) { // jos vaikka jotain ei pitäiskään kopioida... 
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

/**
 *  Updates parameter query combobox items by templates default semicolon separated list
 *
 *  @param comboBox                 NSComboBox object
 *  @param semicolonSeparatedString A string with semicolon separated items
 */
-(void)updateParameterQueryComboBox:(NSComboBox *)comboBox withString:(NSString *)semicolonSeparatedString {
    // Parses xx;yy;zz list
    
    long defaultIndex = 0;
    
    /*
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
     */
    
    
    // checks if there the first item (default value) is occurred later second time
    // action is then to remove the first item an just set combobox's value pointing to index of second occurrence
    NSMutableArray *items = [NSMutableArray arrayWithArray:[semicolonSeparatedString arrayFromSemicolonSeparatedList]];
    
    if ([items[0] isEqualToString:@""]) {
        defaultIndex = -1;
        [items removeObjectAtIndex:0];
    }
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


#pragma mark Errors

/**
 *  Show alert panel for error code.
 *
 *  @Note Error code masking bit will determine if it's error or warning. To be implemeted...
 *
 *  @param errCode  Error code as NSInteger
 *  @param paramStr Description string
 */

-(void)errorPanelForErrCode:(NSInteger)errCode andParameter:(NSString*)paramStr {
    NSString *errMsg;
    BOOL isError = NO;
    BOOL isWarning = NO;
    
    if (errCode>0 && errCode<128) {
        if (errCode<64) isError = YES;
        if (errCode>=64) isWarning = YES;
        switch (errCode) {
            case ErrMasterFolderExists:
                errMsg = @"Project folder already exists";
                break;
            case ErrCouldntCreateFolder:
                errMsg = @"Cannot create folder";
                break;
            case ErrFolderOccupiedByFile:
                errMsg = @"Cannot create folder. Folder's name is in use";
                break;
            case ErrInvalidParentFolderName:
                errMsg = @"Invalid parent folder name";
                break;
            case ErrTargetFolderDoesntExist:
                errMsg = @"Target folder does not exist";
                break;
            case ErrFileExistsAtTarget:
                errMsg = @"File already exists";
                break;
            case ErrFileCopyError:
                errMsg = @"Cannot write file";
                break;
            case ErrParameterTagsYieldedEmptyString:
                errMsg = @"Empty parent folder name";
                break;
            case ErrRequiredParametersMissing:
                errMsg = @"Required parameter missing";
                break;
            case ErrInvalidMasterFolderName:
                errMsg = @"Invalid master folder name";
                break;
            case ErrInvalidFileOrFolderName:
                errMsg = @"Invalid file or folder name";
                break;
            case ErrNoExistingMetadata:
                errMsg = @"Metadata is missing";
                break;
            case ErrSettingPosix:
                errMsg = @"Could not set permissions";
                break;
            case ErrMasterFolderDoesNotExistWhileUpdatingMetadata:
                errMsg = @"Master folder doesn't exist. You have probably set wrong target folder.";
                break;
            case ErrMasterFolderDoesNotExist:
                errMsg = @"Master folder doesn't exist";
                break;
            case WarnSkippedExistingFiles:
                errMsg = @"Skipped existing file(s)";
                break;
            case ErrOverlappingOptionalParameters:
                errMsg = @"Two optional parameters are used at the same time. Remove at least one.";
            default:
                errMsg = [NSString stringWithFormat:@"Error with code: %li", errCode];
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

    // seeding random generator;
    srandom((unsigned int) time(NULL));
    
    _preferences = [[Preferences alloc] initWithLoadingPreferences];
    _userPreferences = [[UserPreferences alloc] initWithLoadingUserPreferences];
    [_templateManagerToolbarItem setAutovalidates:NO];
    [_templateManagerMenuItem setEnabled:[_preferences.templateSetLocations count]>0];
    [_templateManagerToolbarItem setEnabled:[_preferences.templateSetLocations count]>0];
    _parameterQueryTableContents = [[NSMutableArray alloc] init];
    
    _targetBrowserHelper = [[FileBrowserHelper alloc] initWithOutlineView:_targetFolderOutlineView folder:nil showFiles:YES];
    _templateBrowserHelper = [[FileBrowserHelper alloc] initWithOutlineView:_templateFileBrowserOutlineView folder:nil showFiles:YES];
    
    [self populateTemplatePopUpButton];
    [self setTemplatePopUpButtonByUserPreferencesDefault];
  //  [self setSelectedTemplateByPopUp];
  //  [self loadParameterQueryTableWithTemplate:_selectedTemplate];
    [self checkIfTargetFolderHasChangedDueParsingAndUpdate];
  //  [self updateTargetFolderViews];
    [_targetFolderOutlineView setTarget:self];
    [_targetFolderOutlineView setDoubleAction:@selector(doubleClick:)];
    [_targetFolderOutlineView setDataSource:_targetBrowserHelper];
    [_targetFolderOutlineView setDelegate:_targetBrowserHelper];
    [_templateFileBrowserOutlineView setDelegate:_templateBrowserHelper];
    [_templateFileBrowserOutlineView setDataSource:_templateBrowserHelper];
    [_templateFileBrowserPathControl setBackgroundColor:[Definitions controlPathBackgroundColor ]];
    [_pathControl setBackgroundColor:[Definitions controlPathBackgroundColor]];

    
    // RUN TESTS FOR DEVELOPMENT
#if DEBUG
    [_testButton setHidden:NO];
    [_debugLabel setHidden:NO];
    [self performTestRoutineForDevelopmentPurposes];
    
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
        [nc addObserver:self selector:@selector(targetPathDidChange:) name:@"targetPathChanged" object:nil];
        [nc addObserver:self selector:@selector(parameterValueDidChange:) name:@"parameterValueDidChange" object:nil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

