//
//  TemplateParameter.h
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"


@interface TemplateParameter : NSObject {
    NSArray *_availableTypes;
}

@property NSString *name;
@property NSString *tag;
@property NSString *defaultValue;
@property BOOL isEditable;
@property BOOL isRequired;
@property BOOL isHidden;
@property BOOL createParentFolder;
@property NSArray *parentFolderOption;
@property NSString *parentFolderNamingRule;
@property NSArray *typeSelection;
@property NSInteger parameterType;
@property NSString *dateFormatString;
@property NSString *stringValue;
@property NSDate *dateValue;
@property BOOL booleanValue;
@property BOOL optionalWithAbove;

@end
