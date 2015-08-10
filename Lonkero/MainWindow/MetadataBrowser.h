//
//  MetadataBrowserHelper.h
//  Lonkero
//
//  Created by Kati Haapamäki on 11.12.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "NSNumber+Extras.h"
#import "NSString+Extras.h"
#import "Template.h"
#import "TemplateMetadata.h"
#import "MetadataBrowserDeployment.h"
#import "MetadataBrowserParameter.h"
#import "MetadataRepairer.h"

@interface MetadataBrowser : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    Template *_selectedTemplate;
    TemplateMetadata *_selectedMetadata;
    TemplateMetadataItem *_selectedMetadataItem;
}

@property Template *selectedTemplate;

@property  NSMutableArray *deploymentTableData;
@property  NSMutableArray *deploymentParameterTableData;
@property  NSMutableArray *templateParameterTableData;



@property (strong) IBOutlet NSWindow *metadataBrowserWindow;

@property (weak) IBOutlet NSTableView *deploymentTableView;
@property (weak) IBOutlet NSTableView *deploymentParameterTableView;
@property (weak) IBOutlet NSTableView *templateParameterTableView;
@property (strong) IBOutlet NSArrayController *deploymentTableArrayController;
@property (strong) IBOutlet NSArrayController *templateParameterTableArrayController;
@property (strong) IBOutlet NSArrayController *deploymentParameterTableArrayController;

- (IBAction)deploymentTableAction:(id)sender;
-(void)openWindow;
-(void)update;
-(void)setMetadata: (TemplateMetadata*)setMetadata;

-(void)selectDeploymentWithIndexOf:(NSInteger) deploymentIndex;

-(void)populateParameterTable;
-(void)populateDeploymentTable;
-(void)addDeploymentParameter:(NSString *)parameter value:(NSString *)stringValue;
-(void)addTemplateParameter:(NSString *)parameter value:(NSString *)stringValue;
@end
