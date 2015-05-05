//
//  Definitions.h
//  Lonkero
//
//  Created by Kati Haapamäki on 7.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//
#define APPNAME @"Lonkero"
#define APPVERSION @"0.6 beta"
#define APPDESC @"Folder Template Manager"

#define PREFEFENCES_VERSION @"0.2"
#define PREFERENCES_FILENAME @""

#define TEMPLATE_VERSION @"0.2"
#define USERPREFERENCES_VERSION @"0.1"
#define USERPREFERENCES_FILENAME @"User Preferences.plist"
#define METADATA_VERSION @"0.4";
#define TEMPLATE_SETTINGS_FILENAME @"Template Settings.plist"
#define METADATA_FILENAME @".Template Metadata.plist"
#define DEFAULT_ID_LENGTH 8
#define DEFAULT_GROUP_ID @"Jlkjes12"


#if DEBUG
#   define LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define LOG(...)
#endif

#import <Foundation/Foundation.h>

enum {
    ErrMasterFolderExists = 1,
    ErrCouldntCreateFolder = 2,
    ErrFolderOccupiedByFile = 3,
    ErrInvalidParentFolderName = 4,
    ErrTargetFolderDoesntExist = 5,
    ErrFileExistsAtTarget = 6,
    ErrFileCopyError = 7,
    ErrParameterTagsYieldedEmptyString = 8,
    ErrRequiredParametersMissing = 9,
    ErrInvalidMasterFolderName = 10,
    ErrSettingPosix = 11,
    ErrInvalidFileOrFolderName = 12,
    WarnSkippedExistingFiles = 65,
    SkippedByUser = 129
} ErrCodes;

typedef enum {
    text = 0,
    number = 1,
    date = 2,
    list=3,
    loginName = 4,
    userName = 5,
    incremental = 6,
    boolean = 7
} TemplateParameterType;


typedef enum {
    lowercase,
    uppercase,
    capitalcase,
    customcase
} Case;

// typedef enum { isNotParentFolder = 0, isParentFolderOptional = 1, isParentFolderRequired = 2 } templateParentFolderSetting;
typedef enum { templatesOnly = 1, nonTemplatesOnly = 0, bothTemplatesAndNonTemplates= -1 } FolderSelectionType;

@interface Definitions : NSObject

+(NSColor*)windowBackgroundColor;
+(NSColor*)parameterTableBackgroundColor;
+(NSColor *)controlPathBackgroundColor;
@end
