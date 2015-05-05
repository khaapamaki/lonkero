//
//  TemplateDeployer.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "TemplateDeployer.h"

@implementation TemplateDeployer



-(NSInteger)deployToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr {
    NSString *deploymentId = [NSString generateRandomStringOfLength:12];
    NSNumber *err = [NSNumber numberWithInteger:0];
    NSString *errString = @"";
    NSDictionary *targetFolderPermissions;
    NSInteger errcode = 0;

    _theTargetFolder = targetFolder; // store for other methods
    
    if (!_theTargetFolder.itemExists) {
        NSInteger answer = NSRunAlertPanel(@"Target folder does not exist. Do you want to create it?", targetFolder.path, @"No", @"Create", nil);
        
        if (answer==YES) {
            return SkippedByUser;
        } else {
            errcode = [FileSystemItem createDirectoryWithIntermediatesInheritingPermissions:_theTargetFolder errString:&errString];
            if (errcode != 0) {
                *errStr = [NSString stringWithString:errString];
                return errcode;
            }
            [targetFolder setPropertiesByURL:targetFolder.fileURL];
        }
    }
    
    targetFolderPermissions = [NSDictionary dictionaryWithObjectsAndKeys:_theTargetFolder.posix, NSFilePosixPermissions, nil];
    
    NSArray *parentFolders = [TemplateDeployer parentFoldersForTemplate:_theTemplate
                                                      withTargetFolder:_theTargetFolder
                                                                 error:&err];
    
    FileSystemItem *masterFolder;
    if ([parentFolders count]==0) {
        masterFolder = _theTargetFolder;
        masterFolder.isMaster = YES;
        masterFolder.isParent = NO;
        masterFolder.isTarget = YES;
    } else {
        [[parentFolders lastObject] setIsParent:NO];
        [[parentFolders lastObject] setIsMaster:YES];
        masterFolder = [parentFolders lastObject];
    }
    

    // Pitää tsekata onko master folder olemassa JA ONKO SAMAN groupin/templaten nimissä
    if (masterFolder.itemExists) return ErrMasterFolderExists;
    
    
    if ([parentFolders count]>1) {  // at least one parent more than the target folder
        if ([err integerValue] !=0 ) {
            *errStr = masterFolder.path;
            return ErrParameterTagsYieldedEmptyString;
        } else {
            // Create Parent Folders
            NSArray *parentsExcludingTarget = [NSArray arrayWithArray:[parentFolders subarrayWithRange:NSMakeRange(1, [parentFolders count] - 1)]];
            err = [NSNumber numberWithInteger:[self createFoldersIfNeeded:parentsExcludingTarget defaultPermissions:targetFolderPermissions]];
            if ([err integerValue]!=0) return [err integerValue];
        }
    }
    
    // COPY FILES AND FOLDERS
    err = [NSNumber numberWithInteger:[self copyFilesToFolder:masterFolder defaultPermissions:targetFolderPermissions errString:&errString]];
    
    if ([err integerValue]!=0) {
        *errStr = errString;
       return [err integerValue];
    }
    
    // WRITE METADATA
    
    NSArray *involvedParametersForParentFolders = [TemplateDeployer parentFolderParametersInvolved:_theTemplate];

//    [self writeMetadataForMasterFolder:masterFolder
//                    involvedParameters:[involvedParametersForParentFolders lastObject]
//                           withDepthOf:[parentFolders count]];
    
    [self writeMetadataToFolders:parentFolders involvedParametersArray:involvedParametersForParentFolders deploymentId:deploymentId];
    
    return [err integerValue];
}

-(NSInteger)createFoldersIfNeeded:(NSArray *)folders defaultPermissions:(NSDictionary *)defaultPermissions {
    NSInteger errCode = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    for (FileSystemItem *aFolder in folders) {
        if (aFolder.itemExists && !aFolder.isDirectory) {
            errCode = ErrFolderOccupiedByFile;
        }
    }
    NSError *err;
    if (errCode!=0) return errCode;
    
    for (FileSystemItem *aFolder in folders) {
        if (!aFolder.itemExists) {
            LOG(@"Creating Folder: %@", aFolder.pathByExpandingTildeInPath);
            [fm createDirectoryAtPath:aFolder.pathByExpandingTildeInPath withIntermediateDirectories:NO attributes:0 error:&err];
            if (err) return ErrCouldntCreateFolder;
            [fm setAttributes:defaultPermissions ofItemAtPath:aFolder.pathByExpandingTildeInPath error:nil];
            [aFolder readPropertiesFromFileSystem];
        } else {
            LOG(@"Folder exists already: %@", aFolder.pathByExpandingTildeInPath);
        }
    }
    return errCode;
}

-(NSInteger)copyFilesToFolder:(FileSystemItem*)folder
           defaultPermissions:(NSDictionary *)defaultPermissions
                    errString:(NSString**) errStr {
    
    NSInteger errCode = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *itemsToBeCopied = [FileSystemItem getDirectoryContentForFolder:_theTemplate.location includeFiles:YES includeFolders:YES includeSubDirectories:YES];
    NSInteger totalFileSize = 0;
    NSString *templateSettingsPathToBeExcluded = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, TEMPLATE_SETTINGS_FILENAME];
    
    // SET COPY PATHS TO "TODO-ARRAY"
    
    for (FileSystemItem *item in itemsToBeCopied) {
        NSNumber *pathComponentErr = nil;
        if (!item.isDirectory) {
            
        }
        
        NSString *relativeParsedPath = [NSString pathWithComponents:[TemplateDeployer parseParametersForPathComponents:[item.relativePath pathComponents] withTemplate:_theTemplate error:&pathComponentErr]];
        if (pathComponentErr==nil) {
            NSString *targetPath = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, relativeParsedPath];
            item.pathToCopy = targetPath;
            BOOL isDir;
            item.pathToCopyExists = [fm fileExistsAtPath:item.pathToCopy isDirectory:&isDir];
            item.pathToCopyIsDirectory = isDir;
            if (isDir == NO && item.pathToCopyExists) errCode = ErrFileExistsAtTarget;
            totalFileSize += item.fileSize;
        } else {
            *errStr = [NSString stringWithString:item.path];
            return ErrInvalidFileOrFolderName;
        }
        
        if (item.pathToCopyExists && !item.pathToCopyIsDirectory) {
            *errStr = [NSString stringWithString:item.pathToCopy];
            return ErrFolderOccupiedByFile;
        }
        
        if (pathComponentErr!=0) {
            errCode = [pathComponentErr integerValue];
            *errStr = relativeParsedPath;
        }
    }
    
    if (errCode != 0) return errCode;
    
    // CREATE FOLDERS
    for (FileSystemItem *item in itemsToBeCopied) {
        NSError *err = nil;
        item.isCopied = NO;
        if (item.isDirectory) {
            
            if (!item.pathToCopyExists) {
                BOOL folderCreated = [fm createDirectoryAtPath:item.pathToCopy withIntermediateDirectories:YES attributes:0 error:&err];
                NSAssert(err==nil, @"Cannot create folder");
                if (err || !folderCreated ) {
                    *errStr = [NSString stringWithString:item.pathToCopy];
                    return ErrCouldntCreateFolder;
                }
            }
        
            // copy label color
            [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.labelNumber] forKey:NSURLLabelNumberKey error:nil];
            
            // hidden extension
            [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.hasHiddenExtension] forKey:NSURLHasHiddenExtensionKey error:nil];
            
            // set dates
            NSDate *newDate = [NSDate date];
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:newDate, NSFileModificationDate, newDate, NSFileCreationDate, nil];
            
            if (!defaultPermissions) {
                [attributes setObject:item.posix forKey:NSFilePosixPermissions];
            } else {
                short defaultPosix = [[defaultPermissions objectForKey:@"NSFilePosixPermissions"] shortValue];
                short sourcePosix = [item.posix shortValue];
                short newPosix = [TemplateDeployer combinePosixForTargetFolder:defaultPosix andSourceFolder:sourcePosix];
                [attributes setObject:[NSNumber numberWithShort:newPosix] forKey:NSFilePosixPermissions];
            }
            
            [fm setAttributes:attributes ofItemAtPath:item.pathToCopy error:&err];
            
            if (err!=nil) {
                LOG(@"Error setting permissions for %@", item.pathToCopy);
                *errStr = [item.pathToCopy copy];
                return ErrSettingPosix;
            }

            [item updateExistingStatus];
            item.isCopied = item.itemExists;
        }
    }

    // COPY FILES
    
    NSMutableString *skippedFiles = [NSMutableString string];
    for (FileSystemItem *item in itemsToBeCopied) {
        
        NSError *err = nil;
        item.isCopied = NO;
        if (!item.isDirectory) {
            
            if (!item.pathToCopyExists) {
                
                if (![item.pathToCopy isEqualToString:templateSettingsPathToBeExcluded]) {   //skip settings file
                    
                    [fm copyItemAtPath:item.pathByExpandingTildeInPath toPath:item.pathToCopy error:&err];
                    if (err) return ErrFileCopyError;
                    
                    // copy label color
                    [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.labelNumber] forKey:NSURLLabelNumberKey error:nil];
                    
                    // hidden extension
                    [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.hasHiddenExtension] forKey:NSURLHasHiddenExtensionKey error:nil];
                    
                    // set dates
                    NSDate *newDate = [NSDate date];
                    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:newDate, NSFileModificationDate, newDate, NSFileCreationDate, nil];
                    
                    if (!defaultPermissions) {
                        [attributes setObject:item.posix forKey:NSFilePosixPermissions];
                    } else {
                        short defaultPosix = [[defaultPermissions objectForKey:@"NSFilePosixPermissions"] shortValue];
                        short sourcePosix = [item.posix shortValue];
                        short newPosix = [TemplateDeployer combinePosixForTargetFolder:defaultPosix andSourceFile:sourcePosix];
                        [attributes setObject:[NSNumber numberWithShort:newPosix] forKey:NSFilePosixPermissions];
                    }
                    
                    [fm setAttributes:attributes ofItemAtPath:item.pathToCopy error:&err];
                    if (err!=nil) {
                        LOG(@"Error setting permissions for %@", item.pathToCopy);
                        *errStr = [item.pathToCopy copy];
                        return ErrSettingPosix;
                    }
                    
                    [item updateExistingStatus];
                    item.isCopied = item.itemExists;
                    
                }
            } else {
                item.isCopied = NO;
                [skippedFiles appendString:[item.path lastPathComponent]];
                [skippedFiles appendString:@"\n"];
            }
        }
    }
    if ([skippedFiles length]>0) {
        *errStr = [NSString stringWithString:skippedFiles];
        return WarnSkippedExistingFiles;
    }
    return 0;
}

-(void)writeMetadataToFolders:(NSArray *)folders involvedParametersArray:(NSArray *)parametersArray deploymentId:(NSString*)deploymentId {
    NSInteger depth = 0;
    NSInteger indexForInvolvedParameterArray = -1;
    for (FileSystemItem *folder in folders) {
        [folder updateExistingStatus];
        
        if (folder.itemExists && folder.isDirectory) {
            //remove?
        }
        
        // read existing metadata from disk
        TemplateMetadata *metadata = [[TemplateMetadata alloc] initByReadingFromFolder:folder]; // will be empty if doesnt exists
        
        TemplateMetadataItem *metadataItem = [[TemplateMetadataItem alloc] initWithTemplate:_theTemplate targetFolder:_theTargetFolder];
        
        [metadataItem setCreationMasterFolder:[folders lastObject]];
        [metadataItem setDeploymentID:deploymentId];
        [metadataItem setParentFolders:folders];
        
        if (folder.isTarget) {
            [metadataItem setAsTargetFolder];
        }
        
        if (folder.isMaster) {
            [metadataItem setAsMasterFolderAsDepthOf:depth];
            [metadataItem readTemplateDirectoryContents];
            [metadataItem readDeployedDirectoryContents];
        } else {
            [metadataItem setIsMasterFolder:[NSNumber numberWithBool:NO]];
        }
        
        if (folder.isParent){
            [metadataItem setAsParenFolderAsDepthOf:depth];
        }
     
        if (indexForInvolvedParameterArray >= 0) {
            if (indexForInvolvedParameterArray > [parametersArray count]-1) indexForInvolvedParameterArray = [parametersArray count] -1;
            [metadataItem setParametersForParentLevel:[parametersArray objectAtIndex:indexForInvolvedParameterArray]];
        }
        
        [metadata addItem:metadataItem];
        
        if (folder.itemExists && folder.isDirectory) {
            [metadata writeToFolder:folder];
        } else {
            NSLog(@"Cannot Write Metadata. Folder doesn't exist: %@", folder);
        }
        depth++;
        indexForInvolvedParameterArray++;
    }
}


#pragma mark -
#pragma mark PARAMETER PARSING

+(NSArray *)parentFoldersForTemplate:(Template *)aTemplate withTargetFolder:(FileSystemItem *)targetFolder error:(NSNumber **)err {
    NSMutableString *pathToParentFolder = [NSMutableString stringWithString:targetFolder.pathByExpandingTildeInPath];
    NSMutableArray *result = [NSMutableArray array];
    targetFolder.isTarget = YES;
    targetFolder.isParent = NO;
    [result addObject:targetFolder];
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.createParentFolder) {
            
            if (currentParameter.booleanValue || ![currentParameter.value isEqualToString:@""] ) {
                
                NSNumber *error = nil;
                NSString *parsedParentFolderName = [TemplateDeployer parseFileName:currentParameter.parentFolderNamingRule withTemplate:aTemplate error:&error];
                if (error!=nil) {
                   if(err!=NULL) *err = [error copy];
                }

                [pathToParentFolder appendString:@"/"];
                [pathToParentFolder appendString:parsedParentFolderName];
                FileSystemItem *newFolder = [[FileSystemItem alloc] initWithPath:[pathToParentFolder copy] andNickName:@""];
                newFolder.isParent = YES;
                [result addObject:newFolder];

            }
        }
    }
    return [NSArray arrayWithArray:result];
}


+(NSString*)parseFileName:(NSString*)filename withTemplate:(Template*)aTemplate error:(NSNumber **)err {
    NSString *extension = [filename pathExtension];
    NSString *base = [filename stringByDeletingPathExtension];
    NSString *parsedBase = [TemplateDeployer parseParametersForString:base withTemplate:aTemplate];
    NSString *parsedFilename= [extension isEqualToString:@""] ? parsedBase : [NSString stringWithFormat:@"%@.%@", parsedBase, extension];
    if ([parsedBase isEqualToString:@""] || parsedBase == nil || ![parsedBase isValidFileName] || ![parsedFilename isValidFileName]) {
        parsedFilename = @"<empty_string>";
        if(err!=NULL) *err = [NSNumber numberWithInteger:ErrInvalidFileOrFolderName];
    }
    return parsedFilename;
}


+(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents withTemplate:(Template*)aTemplate error:(NSNumber**)err {
    NSMutableArray *parsedArray = [NSMutableArray array];
    for (NSString *pathComponent in pathComponents) {
        if ([pathComponent isEqualToString:@"/"]) { // root?
            [parsedArray addObject:pathComponent];
        } else {
            NSNumber *error = nil;
            NSString *parsedPathComponent = [TemplateDeployer parseFileName:pathComponent withTemplate:aTemplate error:&error];
            if (error!=nil) {
                if (err!=NULL) *err = [NSNumber numberWithInteger:[error integerValue]];
            }
            [parsedArray addObject:parsedPathComponent];
            
        }
    }
    return [NSArray arrayWithArray:parsedArray];
}

+(NSString *)parseParametersForPath:(NSString *)path withTemplate:(Template *)aTemplate {
    NSArray *pathComponents = [path pathComponents];
    NSArray *parsedPathComponents = [TemplateDeployer parseParametersForPathComponents:pathComponents withTemplate:aTemplate error:nil];
    return [NSString pathWithComponents:parsedPathComponents];
                                     
}

+(NSString *)parseParametersForString:(NSString *)aString withTemplate:(Template *)aTemplate {
    NSMutableString *result = [NSMutableString stringWithString:aString];
    long replacesMade = 0;
    
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        
        NSString *tagWithBrackets = [NSString stringWithFormat:@"[%@]", currentParameter.tag];
        NSRange tagRange;
        
        do {
            tagRange = [result rangeOfString:tagWithBrackets options:NSCaseInsensitiveSearch];
            if (tagRange.length > 2) {
                NSString *extractedTag = [result substringWithRange:NSMakeRange(tagRange.location+1, tagRange.length-2)];
                Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentParameter.tag andString:extractedTag];
                replacesMade += 1;
                [result replaceCharactersInRange:tagRange withString:[currentParameter.value convertToCase:caseConversionNeeded]];
            }
            
        } while (tagRange.length > 2);
    }
    return [NSString stringWithString:[result stringByPerformingFullCleanUp]];
}

#pragma mark -
#pragma mark INVOLVED PARAMETERS

+(NSArray *)parentFolderParametersInvolved:(Template *)aTemplate {
    NSMutableArray *allParents = [[NSMutableArray alloc] init];
 //   NSMutableDictionary *allInvolvedParametersSoFar = [[NSMutableDictionary alloc] init];
    NSInteger level = 0;
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (currentParameter.createParentFolder) {
            if (currentParameter.booleanValue || ![currentParameter.value isEqualToString:@""] ) {
            
                NSDictionary *involvedParameters = [TemplateDeployer dictionaryWithInvolvedParametersTillLevel:level withTemplate:aTemplate];

//                [TemplateDeployer dictionaryWithInvolvedParametersForParentFolder:currentParameter.parentFolderNamingRule withTemplate:aTemplate];
                
           //     [allInvolvedParametersSoFar mergeWithDictionary:involvedParameters];
                [allParents addObject:involvedParameters];
           }
        }
        level++;
    }
    NSDictionary *involvedParameters = [TemplateDeployer dictionaryWithInvolvedParametersTillLevel:999999 withTemplate:aTemplate];
    [allParents removeLastObject];
    [allParents addObject:involvedParameters];
    return allParents;
}

//+(NSDictionary *)dictionaryWithInvolvedParametersForParentFolder:(NSString *)aString withTemplate:(Template *)aTemplate {
//    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
//    
//    NSMutableString *namingRuleMutatingToName = [NSMutableString stringWithString:aString];
//    
//    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
//        NSString *tagWithBrackets = [NSString stringWithFormat:@"[%@]",  currentParameter.tag];
//        NSInteger replacesMade = [namingRuleMutatingToName replaceOccurrencesOfString:tagWithBrackets withString:currentParameter.value options:NSCaseInsensitiveSearch range:NSMakeRange(0, [namingRuleMutatingToName length])];
//        if (replacesMade>0) {
//            
//            if (currentParameter.parameterType==date) {
//                [result setObject:currentParameter.dateValue forKey:[currentParameter.tag lowercaseString]];
//            } else if (currentParameter.parameterType==boolean) {
//                [result setObject:[NSNumber numberWithBool:currentParameter.booleanValue] forKey:[currentParameter.tag lowercaseString]];
//            } else {
//                [result setObject:currentParameter.value forKey:[currentParameter.tag lowercaseString]];
//            }
//            
//        }
//    }
//    return result;
//}

+(NSDictionary *)dictionaryWithInvolvedParametersTillLevel:(NSInteger)level withTemplate:(Template *)aTemplate {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSInteger levelIndex = 0;
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (levelIndex<=level) {
           // if (currentParameter.parameterType!=date && currentParameter.isHidden==NO) {
                if (currentParameter.parameterType==boolean) {
                    [result setObject:[NSNumber numberWithBool:currentParameter.booleanValue] forKey:[currentParameter.tag lowercaseString]];
                } else if (currentParameter.parameterType==date){
                    [result setObject:currentParameter.dateValue forKey:[currentParameter.tag lowercaseString]];
                } else {
                    [result setObject:currentParameter.value forKey:[currentParameter.tag lowercaseString]];
                }
           // }

        }
        levelIndex++;
    }
    return result;
}

#pragma mark -
#pragma mark SUPPORTING

+(short)combinePosixForTargetFolder:(short)targetPosix andSourceFile:(short)sourcePosix {
    short result;
    short sourceExecutableBits = sourcePosix & 0111;
    short targetWithoutExecutableBits = targetPosix & 0666;
    result = targetWithoutExecutableBits | sourceExecutableBits;
    return result;
}

+(short)combinePosixForTargetFolder:(short)targetPosix andSourceFolder:(short)sourcePosix { // doesnt do much...
    short result;
    result = targetPosix;
    return result;
}

#pragma mark -
#pragma mark INIT


-(id)initWithTemplate:(Template*)aTemplate {
    if (self = [super init]) {
        _theTemplate = aTemplate;
    }
    return self;
}

@end
