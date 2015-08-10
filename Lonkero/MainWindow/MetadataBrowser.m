//
//  MetadataBrowserHelper.m
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "MetadataBrowser.h"

@implementation MetadataBrowser


-(void)setMetadata:(TemplateMetadata *)metadata {
    
    _selectedMetadata = metadata;
    if ([_selectedMetadata.metadataArray count] == 0) {
        _selectedMetadataItem = nil;
        _selectedTemplate = nil;
    } else {
        _selectedMetadataItem = _selectedMetadata.metadataArray[0];
        _selectedTemplate = _selectedMetadataItem.usedTemplate;
    }
    [self populateDeploymentTable];
    [self populateParameterTable];
    if (_selectedMetadata) {
        NSIndexSet *rows = [[NSIndexSet alloc] initWithIndex:0];
        [_deploymentTableView selectRowIndexes:rows byExtendingSelection:NO];
    }
}

-(void)populateDeploymentTable {

    [_deploymentTableArrayController removeObjects:_deploymentTableData];

    for (TemplateMetadataItem *currentMetadataItem in _selectedMetadata.metadataArray) {
          MetadataBrowserDeployment *deploymentItem = [[MetadataBrowserDeployment alloc] initWithMetadataItem:currentMetadataItem];
//        MetadataRepairer *metadataRepairer = [[MetadataRepairer alloc] init];
//        metadataRepairer.usedTemplate = currentMetadataItem.usedTemplate;
//        MetadataBrowserDeployment *deploymentItem = [[MetadataBrowserDeployment alloc] initWithMetadataItem:[metadataRepairer
//                                            convertMetadataItem:currentMetadataItem FromVersion:currentMetadataItem.metadataVersion toVersion:@"0.5"]];
        [_deploymentTableArrayController addObject:deploymentItem];
    }
    [_deploymentTableView reloadData];
    
}

-(void)populateParameterTable {
    [_templateParameterTableArrayController removeObjects:_templateParameterTableData];
    [_deploymentParameterTableArrayController removeObjects:_deploymentParameterTableData];
    
    for (TemplateParameter *currentParameter in _selectedTemplate.templateParameterSet) {
        MetadataBrowserParameter *parameterItem = [[MetadataBrowserParameter alloc] init];
        parameterItem.parameter = currentParameter.name;
        parameterItem.stringValue = currentParameter.stringValue;
        [_templateParameterTableArrayController addObject:parameterItem];
    }
    
    
    [self addDeploymentParameter:@"Metadata version" value:_selectedMetadataItem.metadataVersion];
    
    [self addDeploymentParameter:@"Template Name" value:_selectedMetadataItem.usedTemplate.name];
    [self addDeploymentParameter:@"Template Path" value:_selectedMetadataItem.usedTemplate.location.path];
    [self addDeploymentParameter:@"Deployment Id"
                           value:[_selectedMetadataItem.deploymentID stringByInsertingHyphensEvery:4]];
    [self addDeploymentParameter:@"Template Id"
                                   value:[_selectedMetadataItem.templateID stringByInsertingHyphensEvery:4]];
    
    [self addDeploymentParameter:@"Group Id"
                                   value:[_selectedMetadataItem.groupID stringByInsertingHyphensEvery:4]];
    
    [self addDeploymentParameter:@"Creation date" value:[_selectedMetadataItem.creationDate description]];
    
    [self addDeploymentParameter:@"Created By" value:[NSString stringWithFormat:@"%@ (%@)", _selectedMetadataItem.creatorFullName, _selectedMetadataItem.creator]];
    
    [self addDeploymentParameter:@"Files/Folders deployed"
                                   value:[NSString stringWithFormat:@"%li",[_selectedMetadataItem.deployedContents count]]];
    
    [self addDeploymentParameter:@"Deployment Target Folder" value:_selectedMetadataItem.creationRootFolder.path];
    
    [self addDeploymentParameter:@"Project Folder" value:_selectedMetadataItem.creationMasterFolder.path];
    
    [self addDeploymentParameter:@"Depth in Folder Hierarchy" value:[_selectedMetadataItem.depth string]];

    [self addDeploymentParameter:@"Is Deployment Root" value:[_selectedMetadataItem.isTargetFolder boolString]];
    
    [self addDeploymentParameter:@"Is Parent Folder" value:[_selectedMetadataItem.isParentFolder boolString]];
    [self addDeploymentParameter:@"Is Project Folder" value:[_selectedMetadataItem.isMasterFolder boolString]];

    
//    [self addDeploymentParameter:@"Marked For Archiving" value:[_selectedMetadataItem.markedToBeArchived boolString]];
//    
//    [self addDeploymentParameter:@"Is Archived" value:[_selectedMetadataItem.isArchived boolString]];
    
    [_deploymentParameterTableView reloadData];
    [_templateParameterTableView reloadData];
}

-(void)selectDeploymentWithIndexOf:(NSInteger)deploymentIndex {
    
}

-(void)addDeploymentParameter:(NSString *)parameter value:(NSString *)stringValue {
    MetadataBrowserParameter *newParameter = [[MetadataBrowserParameter alloc] initWithParameter:parameter andValue:stringValue];
    [_deploymentParameterTableArrayController addObject:newParameter];
}

-(void)addTemplateParameter:(NSString *)parameter value:(NSString *)stringValue {
    MetadataBrowserParameter *newParameter = [[MetadataBrowserParameter alloc] initWithParameter:parameter andValue:stringValue];
    [_templateParameterTableArrayController addObject:newParameter];
}

- (IBAction)deploymentTableAction:(id)sender {
    NSInteger rowIndex = [_deploymentTableView clickedRow];
    
    if (rowIndex>=0) {
        
        _selectedMetadataItem = [[_deploymentTableArrayController arrangedObjects][rowIndex] metadataItem] ; //_selectedMetadata.metadataArray[rowIndex];
        _selectedTemplate = _selectedMetadataItem.usedTemplate;
        
        [self populateParameterTable];
    }
}

-(void)openWindow {
    id window = [super initWithWindow:_metadataBrowserWindow];
    
    [self showWindow:self];
    
    [_metadataBrowserWindow orderFront:self];
    
//    NSApplication *me = [NSApplication sharedApplication];
//    [_templateManagerWindow setPreventsApplicationTerminationWhenModal:NO];
//    [me runModalForWindow:_templateManagerWindow];
}

-(void)update {
    [self populateDeploymentTable];
    [self populateParameterTable];
}

-(id)init{
    self = [super initWithWindowNibName:@"MetadataBrowserWindow"];
    if (self) {
     
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        _templateParameterTableData = [NSMutableArray array];
        _deploymentParameterTableData = [NSMutableArray array];
        _deploymentTableData = [NSMutableArray array];
        _selectedTemplate = nil;
    }
    return self;
}
@end
