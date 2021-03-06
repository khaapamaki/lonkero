//
//  Template.h
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//


/** @class Template

 @brief Template is a class to store template
 
 */



#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "TemplateParameter.h"
#import "FileSystemItem.h"
#import "NSString+Extras.h"


@interface Template : NSObject {
    
}

@property NSString *version;
@property NSString *name;
@property FileSystemItem *location;

@property NSMutableArray *templateParameterSet;
@property NSMutableArray *targetFolderPresets;
@property NSString *dateFormatString;
@property BOOL isTemplateSaved;
@property NSString *groupId;
@property NSString *templateId;

-(id) initWithURL:(NSURL *)URL;
-(void) saveTemplate;




@end

