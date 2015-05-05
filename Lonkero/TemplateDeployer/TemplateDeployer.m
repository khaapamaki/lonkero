//
//  TemplateDeployer.m
//  Lonkero
//
//  Created by Kati Haapamäki on 21.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//


#import "TemplateDeployer.h"

@implementation TemplateDeployer

#pragma mark -
#pragma mark DEPLOYMENT

-(NSInteger)deployToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr {
    _theTargetFolder = targetFolder;
    NSNumber *errCode = @(0);
    NSString *errorString = @"";
    NSInteger options = (deployTemplate | writeMetadata);
    NSString *deploymentId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];

    [self processWithTargetFolder:targetFolder options:options deploymentId:deploymentId err:&errCode errString:&errorString];
    if (errStr != NULL) *errStr = [errorString copy];
    return [errCode integerValue];
}



-(NSInteger)rewriteMetadataToTargetFolder:(FileSystemItem*)targetFolder errString:(NSString**)errStr {
    _theTargetFolder = targetFolder;
    NSNumber *errCode = @(0);
    NSString *errorString = @"";
    NSNumber *err = @0;

    
    NSArray *parentFolders = [self getParentFoldersWithError:&err];
    FileSystemItem *masterFolder = [parentFolders lastObject];
    [masterFolder updateExistingStatus];
    if (!masterFolder.itemExists || !masterFolder.isDirectory) {
        return ErrMasterFolderDoesNotExist;
    }
    TemplateMetadata *masterFolderMetadata = [[TemplateMetadata alloc] initByReadingFromFolder:masterFolder];
    if ([masterFolderMetadata count] == 0) {
        return ErrNoExistingMetadata;
    }
    
    TemplateMetadataItem *masterMetadataItem = nil;
    TemplateMetadataItem *lastPossibleMetadataItem = nil;
 
    for (NSInteger index=0; index < [masterFolderMetadata count]; index++) {
        TemplateMetadataItem *currentMetadataItem = masterFolderMetadata.metadataArray[index];
        if (currentMetadataItem.isMasterFolder) {
            if ([_theTemplate.templateId isEqualToString:masterMetadataItem.templateID]) {
                masterMetadataItem = currentMetadataItem;
            }
            lastPossibleMetadataItem = currentMetadataItem;
        }
    }
    if (lastPossibleMetadataItem==nil) {
        return ErrNoExistingMetadata;
    }
    
    if (masterMetadataItem==nil) {
        NSMutableString *info = [NSMutableString stringWithString:@""];
        [info appendFormat:@"Existing Template: %@\n   (%@)\n", lastPossibleMetadataItem.usedTemplate.name, [lastPossibleMetadataItem.usedTemplate.templateId stringByInsertingHyphensEvery:4]];
        [info appendFormat:@"Current Template: %@\n   (%@)\n", _theTemplate.name, [_theTemplate.templateId stringByInsertingHyphensEvery:4]];
        
        BOOL answer = NSRunAlertPanel(@"Metadata you are going to replace is based on the template with different id.\nYou may have wrong template selected.\nProceed anyway?", info, @"Proceed", @"Cancel", nil);
        if (!answer) return ExitOnly;
        masterMetadataItem = lastPossibleMetadataItem;
    }
    
    NSInteger options = (replaceExisitingMetadata | writeMetadata | generateNewId);
    NSString *deploymentId = masterMetadataItem.deploymentID;
    [self processWithTargetFolder:targetFolder options:options deploymentId:deploymentId err:&errCode errString:&errorString];
    if (errStr != NULL) *errStr = [errorString copy];
    return [errCode integerValue];
}

-(NSArray*)processWithTargetFolder:(FileSystemItem*)targetFolder options:(NSInteger)options deploymentId:(NSString*)deploymentId err:(NSNumber**)errNumCode errString:(NSString**)errStr {

    _deploymentStartDate = [NSDate date];
    NSNumber *err = @0;
    NSString *errString = @"";
    NSDictionary *targetFolderPermissions;
    NSInteger errcode = 0;

    _theTargetFolder = targetFolder; // store for other methods
    [_theTargetFolder updateExistingStatus];
    
    if (!_theTargetFolder.itemExists) {
        NSInteger answer = NSRunAlertPanel(@"Target folder does not exist. Do you want to create it?", targetFolder.path, @"Create", @"Cancel", nil);
        
        if (answer==NO) {
            if (errNumCode != NULL) *errNumCode = @(SkippedByUser);
            return nil;
        } else {
            errcode = [FileSystemItem createDirectoryWithIntermediatesInheritingPermissions:_theTargetFolder errString:&errString];
            if (errcode != 0) {
                if (errStr != NULL) *errStr = [NSString stringWithString:errString];
                if (errNumCode != NULL)*errNumCode = @(errcode);
                return nil;
            }
            [targetFolder setPropertiesByURL:targetFolder.fileURL];
        }
    }
    
    targetFolderPermissions = @{NSFilePosixPermissions: _theTargetFolder.posix};
    
    NSArray *parentFolders = [self getParentFoldersWithError:&err];
    
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
    if (masterFolder.itemExists && (options & deployTemplate)) {
        if (errNumCode!= NULL) *errNumCode = @(ErrMasterFolderExists);
        return nil;
    }
    
    if ([parentFolders count]>1) {  // at least one parent more than the target folder
        if ([err integerValue] !=0 ) {
            if (errStr != NULL) *errStr = masterFolder.path;
            if (errNumCode!= NULL) *errNumCode = @(ErrParameterTagsYieldedEmptyString);
            return nil;
        } else {
            // Create Parent Folders
            NSArray *parentsExcludingTarget = [NSArray arrayWithArray:[parentFolders subarrayWithRange:NSMakeRange(1, [parentFolders count] - 1)]];
            if (options & deployTemplate) {
                err = @([self createFoldersIfNeeded:parentsExcludingTarget defaultPermissions:targetFolderPermissions]);
                if ([err integerValue]!=0) {
                    if (errNumCode!= NULL) *errNumCode = [err copy];
                    return nil;
                }
            }

        }
    }
    
    // COPY FILES AND FOLDERS
    if ((options & deployTemplate)) err = @([self copyFilesToFolder:masterFolder defaultPermissions:targetFolderPermissions errString:&errString]);
    
    if ([err integerValue]!=0) {
        if (errStr != NULL) *errStr = errString;
        if (errNumCode!= NULL) *errNumCode = [err copy];
        return nil;
    }
    
    // WRITE METADATA
    
    NSArray *involvedParametersForParentFolders = [TemplateDeployer parentFolderParametersInvolved:_theTemplate];
    
    NSString *newDeploymentId;
    if (options & generateNewId || [NSString isEmptyString:deploymentId]) {
        newDeploymentId = [NSString generateRandomStringOfLength:DEFAULT_ID_LENGTH];
    } else {
        newDeploymentId = [deploymentId copy];
    }
    NSArray *metadataForAllFolders = [self generateMetadataItemArrayForFolders:parentFolders involvedParametersArray:involvedParametersForParentFolders deploymentId:newDeploymentId];
    
    if ((options & writeMetadata)) [self writeMetadataTo:parentFolders withMetadataItems:metadataForAllFolders deploymentId:deploymentId options:options];
    if (errNumCode!= NULL) *errNumCode = [err copy];
    return metadataForAllFolders;
}


#pragma mark -
#pragma mark COPYING AND FOLDER CREATION

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

#pragma mark -
#pragma markt COPY FILES AND CREATE FOLDERS

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
        
        NSNumber *shouldCopy = @YES;
        NSString *relativeParsedPath = [NSString pathWithComponents:[self parseParametersForPathComponents:[item.relativePath pathComponents] shouldUse:&shouldCopy error:&pathComponentErr]];
        if ([pathComponentErr integerValue]==0) {
            NSString *targetPath = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, relativeParsedPath];
            item.pathToCopy = targetPath;
            BOOL isDir;
            item.pathToCopyExists = [fm fileExistsAtPath:item.pathToCopy isDirectory:&isDir];
            item.pathToCopyIsDirectory = isDir;
            item.shouldCopy = [shouldCopy boolValue];
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
            [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:@(item.labelNumber) forKey:NSURLLabelNumberKey error:nil];
            
            // hidden extension
            [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.hasHiddenExtension] forKey:NSURLHasHiddenExtensionKey error:nil];
            
            // set dates
            NSDate *newDate = _deploymentStartDate;
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:newDate, NSFileModificationDate, newDate, NSFileCreationDate, nil];
            
            if (!defaultPermissions) {
                attributes[NSFilePosixPermissions] = item.posix;
            } else {
                short defaultPosix = [defaultPermissions[@"NSFilePosixPermissions"] shortValue];
                short sourcePosix = [item.posix shortValue];
                short newPosix = [TemplateDeployer combinePosixForTargetFolder:defaultPosix andSourceFolder:sourcePosix];
                attributes[NSFilePosixPermissions] = @(newPosix);
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
            
            [item updateExistingStatus];
            
            if (!item.pathToCopyExists) {
                
                if (![item.pathToCopy isEqualToString:templateSettingsPathToBeExcluded] && item.shouldCopy) {   //skip settings file
                    
                    [fm copyItemAtPath:item.pathByExpandingTildeInPath toPath:item.pathToCopy error:&err];
                    if (err) return ErrFileCopyError;
                    
                    // copy label color
                    [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:@(item.labelNumber) forKey:NSURLLabelNumberKey error:nil];
                    
                    // hidden extension
                    [[NSURL fileURLWithPath:item.pathToCopy] setResourceValue:[NSNumber numberWithInteger:item.hasHiddenExtension] forKey:NSURLHasHiddenExtensionKey error:nil];
                    
                    // set dates
                    NSDate *newDate = [NSDate date];
                    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:newDate, NSFileModificationDate, newDate, NSFileCreationDate, nil];
                    
                    if (!defaultPermissions) {
                        attributes[NSFilePosixPermissions] = item.posix;
                    } else {
                        short defaultPosix = [defaultPermissions[@"NSFilePosixPermissions"] shortValue];
                        short sourcePosix = [item.posix shortValue];
                        short newPosix = [TemplateDeployer combinePosixForTargetFolder:defaultPosix andSourceFile:sourcePosix];
                        attributes[NSFilePosixPermissions] = @(newPosix);
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



// =============
// METADATA
// =============




#pragma mark -
#pragma mark METADATA

-(void)writeMetadataTo:(NSArray *)folders withMetadataItems:(NSArray*)metadataItemArray deploymentId:(NSString*)deploymentId options:(NSInteger)options {
    
    NSInteger index = 0;
    for (FileSystemItem *folder in folders) {
        [folder updateExistingStatus];
        
        if (folder.itemExists && folder.isDirectory) {
            //remove?
        }
        
        // read existing metadata from disk
        TemplateMetadata *existingMetadata = [[TemplateMetadata alloc] initByReadingFromFolder:folder]; // will be empty if doesnt exists
       
        TemplateMetadataItem *metadataItem = metadataItemArray[index]; // item for current parental level (=index)
        
        if ((options & replaceExisitingMetadata) && [existingMetadata count] > 0 ) {
            TemplateMetadataItem *existingMetadataItem = [existingMetadata metadataItemWithId:deploymentId];
            
            if (existingMetadataItem) {
                NSDate *existingDeploymentDate = existingMetadataItem.creationDate;
                metadataItem.creationDate = [existingDeploymentDate copy]; // keep exisiting date
                metadataItem.creator = [existingMetadataItem.creator copy];
                metadataItem.creatorFullName = [existingMetadataItem.creatorFullName copy];
                metadataItem.deployedContents = [existingMetadataItem.deployedContents copy];
                metadataItem.templateContents = [existingMetadataItem.templateContents copy];
                metadataItem.isArchived = [existingMetadataItem.isArchived copy];
                metadataItem.markedToBeArchived = [existingMetadataItem.markedToBeArchived copy];
                metadataItem.isPartialDeployment = [existingMetadataItem.isPartialDeployment copy];
                metadataItem.isAdditionalDeployment = [existingMetadataItem.isAdditionalDeployment copy];
                metadataItem.archiveLocation = [existingMetadataItem.archiveLocation copy];
                metadataItem.archiveDescription = [existingMetadataItem.archiveDescription copy];
                metadataItem.isRemoved = [existingMetadataItem.isRemoved copy];
                
                [existingMetadata removeMetadataItemWithId:deploymentId];
            }
            
        }
        
        [existingMetadata addItem:metadataItem];
        
        if (folder.itemExists && folder.isDirectory) {
            [existingMetadata writeToFolder:folder];
        } else {
            NSLog(@"Cannot Write Metadata. Folder doesn't exist: %@", folder);
        }
        index++;
    }
}


-(NSArray*)generateMetadataItemArrayForFolders:(NSArray *)folders involvedParametersArray:(NSArray *)parametersArray deploymentId:(NSString*)deploymentId {
    
    NSInteger depth = 0;
    NSInteger indexForInvolvedParameterArray = -1;
    NSMutableArray *metadataItemArray = [NSMutableArray array];
    for (FileSystemItem *folder in folders) {
        [folder updateExistingStatus];
        
        if (folder.itemExists && folder.isDirectory) {
            //remove?
        }
     
        TemplateMetadataItem *metadataItem = [[TemplateMetadataItem alloc] initWithTemplate:_theTemplate targetFolder:_theTargetFolder];
        [metadataItem setCreationDate:_deploymentStartDate];
        [metadataItem setCreationMasterFolder:[folders lastObject]];
        [metadataItem setDeploymentID:[deploymentId copy]];
        [metadataItem setParentFolders:[folders copy]];
        
        if (folder.isTarget) {
            [metadataItem setAsTargetFolder];
        }
        
        if (folder.isMaster) {
            [metadataItem setAsMasterFolderAsDepthOf:depth];
            if ([NSString isNotEmptyString:metadataItem.usedTemplate.location.path]) { // voi olla tyhjä vanhoissa juduissa kun regeneroidaan metadataa
                [metadataItem readTemplateDirectoryContents];
                [metadataItem readDeployedDirectoryContents];
            }
        } else {
            [metadataItem setIsMasterFolder:@NO];
        }
        
        if (folder.isParent){
            [metadataItem setAsParenFolderAsDepthOf:depth];
        }
        
        if (indexForInvolvedParameterArray >= 0) {
            if (indexForInvolvedParameterArray > [parametersArray count]-1) indexForInvolvedParameterArray = [parametersArray count] -1;
            [metadataItem setParametersForParentLevel:parametersArray[indexForInvolvedParameterArray]];
        }
        
        [metadataItemArray addObject:metadataItem];
        
        depth++;
        indexForInvolvedParameterArray++;
    }
    return [NSArray arrayWithArray:metadataItemArray];
}



#pragma mark -
#pragma mark PARAMETER PARSING

-(NSArray *)getParentFoldersWithError:(NSNumber **)err {
    NSMutableString *pathToParentFolder = [NSMutableString stringWithString:_theTargetFolder.pathByExpandingTildeInPath];
    NSMutableArray *result = [NSMutableArray array];
    _theTargetFolder.isTarget = YES;
    _theTargetFolder.isParent = NO;
    [result addObject:_theTargetFolder];
    for (TemplateParameter *currentParameter in _theTemplate.templateParameterSet) {
        if ([NSString isNotEmptyString:currentParameter.parentFolderNamingRule]) {
            
            if (currentParameter.booleanValue || [NSString isNotEmptyString:currentParameter.stringValue] ) {
                NSNumber *error = nil;
                NSString *parsedParentFolderName = [self parseFileName:currentParameter.parentFolderNamingRule  error:&error];
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


-(NSString*)parseFileName:(NSString*)filename shouldUse:(NSNumber**)shouldUse error:(NSNumber **)err {
    NSNumber *shouldUse1 = @YES;
    NSString *extension = [filename pathExtension];
    NSString *base = [filename stringByDeletingPathExtension];
    NSString *parsedBase = [self parseParametersForString:base shouldUse:&shouldUse1];
    if (shouldUse!=NULL) *shouldUse = [shouldUse1 copy];
    NSString *parsedFilename= [extension isEqualToString:@""] ? parsedBase : [NSString stringWithFormat:@"%@.%@", parsedBase, extension];
    
    
    if ([NSString isEmptyString:parsedBase] || ![parsedBase isValidFileName] || ![parsedFilename isValidFileName]) {
        parsedFilename = @"<empty_string>";
        if(err!=NULL) *err = @(ErrInvalidFileOrFolderName);
    }

    return parsedFilename;
}

-(NSString*)parseFileName:(NSString*)filename error:(NSNumber **)err {
    NSNumber *err1 = @0;
    NSString *result =  [self parseFileName:filename shouldUse:nil error:&err1];
    if (err!=NULL) *err = [err1 copy];
    return result;
}


-(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents shouldUse:(NSNumber**)shouldUse error:(NSNumber**)err {
    NSMutableArray *parsedArray = [NSMutableArray array];
    NSNumber *shouldUse1 = @YES;
    for (NSString *pathComponent in pathComponents) {
        if ([pathComponent isEqualToString:@"/"]) { // root?
            [parsedArray addObject:pathComponent];
        } else {
            NSNumber *error = nil;
            NSString *parsedPathComponent = [self parseFileName:pathComponent shouldUse:&shouldUse1 error:&error];
            if (shouldUse!=NULL) *shouldUse = [shouldUse1 copy];
            if (error!=nil) {
                if (err!=NULL) *err = @([error integerValue]);
            }
            [parsedArray addObject:parsedPathComponent];
            
        }
    }
    return [NSArray arrayWithArray:parsedArray];}

-(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents error:(NSNumber**)err {
    NSNumber *err1 = nil;
    NSArray *result =  [self parseParametersForPathComponents:pathComponents shouldUse:nil error:&err1];
    if (err!=NULL) *err = [err1 copy];
    return result;
}


-(NSString *)parseParametersForPath:(NSString *)path {
    NSArray *pathComponents = [path pathComponents];
    NSArray *parsedPathComponents = [self parseParametersForPathComponents:pathComponents error:nil];
    return [NSString pathWithComponents:parsedPathComponents];
}

-(NSString *)parseParametersForString:(NSString *)aString shouldUse:(NSNumber**)shouldUse {
    if (shouldUse!=NULL) *shouldUse = @YES;
    NSMutableString *result = [[self parseSystemParametersForString:aString] mutableCopy];
    long replacesMade = 0;

    for (TemplateParameter *currentParameter in _theTemplate.templateParameterSet) {
        
        NSString *tagWithBrackets = [NSString stringWithFormat:@"%@%@%@", TAGCHAR_INNER_1, currentParameter.tag, TAGCHAR_INNER_2];
        NSString *extractingTagWithBrackets = [NSString stringWithFormat:@"%@%@%@", TAGCHAR_EXTRACTING_INNER_1, currentParameter.tag, TAGCHAR_INNER_2];
        NSString *brackets = [NSString stringWithFormat:@"%@%@", TAGCHAR_INNER_1, TAGCHAR_INNER_2];
        NSString *extractingBrackets = [NSString stringWithFormat:@"%@%@", TAGCHAR_EXTRACTING_INNER_1, TAGCHAR_INNER_2];
        NSRange tagRange;
        NSInteger minTagLegth;
        do {
            minTagLegth = [brackets length];
            tagRange = [result rangeOfString:tagWithBrackets options:NSCaseInsensitiveSearch];
            
            // if normal tag is not found, look for special extracting tag [-tag]
            if (tagRange.length <= [brackets length]) {
                tagRange = [result rangeOfString:extractingTagWithBrackets options:NSCaseInsensitiveSearch];
                if (tagRange.length > [extractingBrackets length]) {
                    if ([NSString isEmptyString:currentParameter.stringValue] && shouldUse!=nil) *shouldUse = @NO;
                }
                minTagLegth = [extractingBrackets length];
            }
            if (tagRange.length > minTagLegth) {
                NSString *extractedTag = [result substringWithRange:NSMakeRange(tagRange.location+minTagLegth-1, tagRange.length-minTagLegth)];
                Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentParameter.tag andString:extractedTag];
                replacesMade += 1;
                [result replaceCharactersInRange:tagRange withString:[currentParameter.stringValue convertToCase:caseConversionNeeded]];
            }
            
        } while (tagRange.length > 0);
    }
    return [NSString stringWithString:[result stringByPerformingFullCleanUp]];
}


-(NSString *)parseSystemParametersForString:(NSString *)aString  {
    
    NSMutableString *result = [NSMutableString stringWithString:aString];
    long replacesMade = 0;
    
    for (NSString *currentTag in [Definitions reservedTags]) {
        
        NSString *tagWithBrackets = [NSString stringWithFormat:@"%@%@%@", TAGCHAR_INNER_1, currentTag, TAGCHAR_INNER_2];
        NSRange tagRange;
        
        do {
            tagRange = [result rangeOfString:tagWithBrackets options:NSCaseInsensitiveSearch];
            if (tagRange.length > 2) {
                NSString *extractedTag = [result substringWithRange:NSMakeRange(tagRange.location+1, tagRange.length-2)];
                Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentTag andString:extractedTag];
                replacesMade += 1;
                
                NSString* replacement = @"";
                if ([currentTag isEqualToString:@"today"]) {
                    replacement = [_deploymentStartDate parsedDateWithFormat:[_theTemplate.dateFormatString stringByPerformingFullCleanUp]];
                }
                if ([currentTag isEqualToString:@"creator"]) {
                    replacement = NSUserName();
                }
                if ([currentTag isEqualToString:@"creator-fullname"]) {
                    replacement = NSFullUserName();
                }
                
                
                [result replaceCharactersInRange:tagRange withString:[replacement convertToCase:caseConversionNeeded]];
            }
            
        } while (tagRange.length > 2);
    }
    
    return [NSString stringWithString:[result stringByPerformingFullCleanUp]];
}

-(NSString *)parseParametersForString:(NSString *)aString {
    return [self parseParametersForString:aString shouldUse:nil];
}

+(FileSystemItem *) parsePathForFileSystemItem:(FileSystemItem*)aFileSystemItem {
    TemplateDeployer *td = [[TemplateDeployer alloc] init];
    NSString *path = aFileSystemItem.pathByExpandingTildeInPath;
    
    NSString *parsedPath = [td parseParametersForPath:path];

    return [[FileSystemItem alloc] initWithPathByAbbreviatingTildeInPath:parsedPath andNickName:aFileSystemItem.nickName];
}

#pragma mark -
#pragma mark INVOLVED PARAMETERS

+(NSArray *)parentFolderParametersInvolved:(Template *)aTemplate {
    NSAssert(@"Trying to use deprecated method", nil) ;
    
    NSMutableArray *allParents = [[NSMutableArray alloc] init];

    NSInteger level = 0;
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if ([NSString isNotEmptyString:currentParameter.parentFolderNamingRule]) {
            if (currentParameter.booleanValue || ![currentParameter.stringValue isEqualToString:@""] ) {
            
                NSDictionary *involvedParameters = [TemplateDeployer dictionaryWithInvolvedParametersTillLevel:level withTemplate:aTemplate];

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


// Level here means just an order number of all parameters in a template

+(NSDictionary *)dictionaryWithInvolvedParametersTillLevel:(NSInteger)level withTemplate:(Template *)aTemplate {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSInteger levelIndex = 0;
    for (TemplateParameter *currentParameter in aTemplate.templateParameterSet) {
        if (levelIndex<=level) {
           // if (currentParameter.parameterType!=date && currentParameter.isHidden==NO) {
                if (currentParameter.parameterType==boolean) {
                    result[[currentParameter.tag lowercaseString]] = @(currentParameter.booleanValue);
                } else if (currentParameter.parameterType==date){
                    result[[currentParameter.tag lowercaseString]] = currentParameter.dateValue;
                } else {
                    result[[currentParameter.tag lowercaseString]] = currentParameter.stringValue;
                }
           // }
        }
        levelIndex++;
    }
    return result;
}

#pragma mark -
#pragma mark SUPPORTING METHODS

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
