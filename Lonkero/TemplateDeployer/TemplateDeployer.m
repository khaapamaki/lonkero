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
    BOOL metadataMissing = NO;
    
    NSArray *parentFolders = [self generateParentFolderArrayWithError:&err];
    FileSystemItem *masterFolder = [parentFolders lastObject];
    [masterFolder updateExistingStatus];
    if (!masterFolder.itemExists || !masterFolder.isDirectory) {
        if (errStr!=NULL) *errStr = masterFolder.pathByExpandingTildeInPath;
        return ErrMasterFolderDoesNotExistWhileUpdatingMetadata;
    }
    TemplateMetadata *masterFolderMetadata = [[TemplateMetadata alloc] initByReadingFromFolder:masterFolder];
    if ([masterFolderMetadata count] == 0) {
      //  BOOL answer = NSRunAlertPanel(@"No metadata found for master folder. Do you still want to write new metadata?", @"", @"Write Metadata", @"Cancel", nil);
      //  if (!answer) {
      //      return UserCancelled;
      //  }
        metadataMissing = YES;
        return ErrNoExistingMetadata;
    }
    
    TemplateMetadataItem *masterMetadataItem = nil;
    TemplateMetadataItem *lastPossibleMetadataItem = nil;
    NSMutableArray *matchingMetadataItems = [NSMutableArray array];
    NSMutableArray *nonMatchingMetadataItems = [NSMutableArray array];
    
    // if there are multiple saved metadata items in master folder find the matching templateId
    for (NSInteger index=0; index < [masterFolderMetadata count]; index++) {
        TemplateMetadataItem *currentMetadataItem = masterFolderMetadata.metadataArray[index];
        if (currentMetadataItem.isMasterFolder) {
            if ([_theTemplate.templateId isEqualToString:currentMetadataItem.templateID]) {
                masterMetadataItem = currentMetadataItem;
                [matchingMetadataItems addObject:currentMetadataItem];
            }
            [nonMatchingMetadataItems addObject:currentMetadataItem];
            lastPossibleMetadataItem = currentMetadataItem;
        }
    }
    if ([nonMatchingMetadataItems count]==0 || [matchingMetadataItems count]==0) {
        // no metadata at all
        
       // BOOL answer = NSRunAlertPanel(@"No existing metadata that matches with template. Do you still want to write new metadata?", @"", @"Write Metadata", @"Cancel", nil);
       // if (!answer) {
       //     return UserCancelled;
       // }
        metadataMissing = YES;
        return ErrNoExistingMetadata;
    }
    
    // no id-matching metadata found.. 
    if ([matchingMetadataItems count]==0) {
        NSMutableString *info = [NSMutableString stringWithString:@""];
        [info appendFormat:@"Existing Template: %@\n   (%@)\n", [nonMatchingMetadataItems[0] usedTemplate].name, [[nonMatchingMetadataItems[0] usedTemplate].templateId stringByInsertingHyphensEvery:4]];
        [info appendFormat:@"Current Template: %@\n   (%@)\n", _theTemplate.name, [_theTemplate.templateId stringByInsertingHyphensEvery:4]];
        
        BOOL answer = NSRunAlertPanel(@"Metadata you are going to replace is based on the template with different id.\nYou may have wrong template selected.\nProceed anyway?", info, @"Proceed", @"Cancel", nil);
        if (!answer) return ExitOnly;
        masterMetadataItem = nonMatchingMetadataItems[0];
    } else {
        masterMetadataItem = matchingMetadataItems[0];
    }
    
    NSInteger options = (replaceExisitingMetadata | writeMetadata | generateNewId);
    NSString *deploymentId = masterMetadataItem.deploymentID;
    [self processWithTargetFolder:targetFolder options:options deploymentId:deploymentId err:&errCode errString:&errorString];
    if (errStr != NULL) *errStr = [errorString copy];
    return [errCode integerValue];
}

/**
 *  Multipurpose: Deploys the template set in the object or writes its metadata, or both, depending on given options parameter.
 *
 *  @param targetFolder The target folder
 *  @param options      Options to determine the action to be performed
 *  @param deploymentId A deployment Id to be used
 *  @param errNumCode   A pointer for a returning error code
 *  @param errStr       A pointer for a returning error description
 *
 *  @return Metadata object if successful action. Nil if not.
 */

-(NSArray*)processWithTargetFolder:(FileSystemItem*)targetFolder options:(NSInteger)options deploymentId:(NSString*)deploymentId err:(NSNumber**)errNumCode errString:(NSString**)errStr {

    _deploymentStartDate = [NSDate date];
    NSNumber *err = @0;
    NSString *errString = @"";
    NSDictionary *targetFolderPermissions;
    NSInteger errcode = 0;
    NSArray *itemsToBeCopied;
    
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
    
    NSArray *parentFolders = [self generateParentFolderArrayWithError:&err];
    
    FileSystemItem *masterFolder =[parentFolders lastObject];
    /*
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
    */

    // Pitää tsekata onko master folder olemassa JA ONKO SAMAN groupin/templaten nimissä
    if (masterFolder.itemExists && (options & deployTemplate)) {
        if (errNumCode!= NULL) *errNumCode = @(ErrMasterFolderExists);
        return nil;
    }
    

    
    // GENERATE ITEMS TO BE COPIED

    
    if ((options & deployTemplate))  {
        
        itemsToBeCopied = [self generateArrayOfItemsToBeCopiedToFolder:masterFolder errCode:&err errString:&errString];
        
        if ([err integerValue]!=0) {
            if (errNumCode!=NULL) *errNumCode = [err copy];
            if (errStr!=NULL) *errStr = [errString copy];
            return nil;
        }
        
    }
    // CREATE PARENT FOLDERS
    
    if ((options & deployTemplate))  {
        
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
    }
    
    // COPY FILES AND FOLDERS FROM TEMPLATE STRUCTURE
    
    if ((options & deployTemplate)) err = @([self copyItems:itemsToBeCopied ToFolder:masterFolder defaultPermissions:targetFolderPermissions errString:&errString]);
    
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

/**
 *  Generates an array that have all the file system items that should be copied or created
 *
 *  @param folder  The target folder
 *  @param errCode A pointer for a returning error code
 *  @param errStr  A pointer for a returning error description
 *
 *  @return An array of items to be copied or created
 */

-(NSArray*)generateArrayOfItemsToBeCopiedToFolder:(FileSystemItem*)folder errCode:(NSNumber**)errCode errString:(NSString**)errStr {
    NSArray *itemCandidatesToBeCopied = [FileSystemItem getDirectoryContentForFolder:_theTemplate.location includeFiles:YES includeFolders:YES includeSubDirectories:YES];
    NSMutableArray *itemsToBeCopied = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];

    for (FileSystemItem *item in itemCandidatesToBeCopied) {
        NSNumber *pathComponentErr = nil;

        NSNumber *shouldCopy = @YES; // used to store return value
        NSString *relativeParsedPath = [NSString pathWithComponents:[self parseParametersForPathComponents:[item.relativePath pathComponents] shouldUse:&shouldCopy error:&pathComponentErr]];
        
        if ([pathComponentErr integerValue]==0) {
            NSString *targetPath = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, relativeParsedPath];
            item.pathToCopy = targetPath;
            BOOL isCopyPathDir;
            item.pathToCopyExists = [fm fileExistsAtPath:item.pathToCopy isDirectory:&isCopyPathDir];
            item.pathToCopyIsDirectory = isCopyPathDir;
            item.shouldCopy = [shouldCopy boolValue];
            if (!item.isDirectory && !item.pathToCopyIsDirectory  && item.pathToCopyExists) {
                if (errStr!=NULL) *errStr = [NSString stringWithString:item.pathToCopy];
                if (errCode!=NULL) *errCode = [NSNumber numberWithInteger:ErrFileExistsAtTarget];
                return nil;
            }
            
            if (item.isDirectory && !item.pathToCopyIsDirectory && item.pathToCopyExists ) {
                if (errStr!=NULL) *errStr = [NSString stringWithString:item.pathToCopy];
                if (errCode!=NULL) *errCode = [NSNumber numberWithInteger:ErrFolderOccupiedByFile];
                return nil;
            }
            if (!item.isDirectory && item.pathToCopyIsDirectory && item.pathToCopyExists ) {
                if (errStr!=NULL) *errStr = [NSString stringWithString:item.pathToCopy];
                if (errCode!=NULL) *errCode = [NSNumber numberWithInteger:ErrFileOccupiedByFolder];
                return nil;
            }
            
            //totalFileSize += item.fileSize;
        } else {
            if (errStr!=NULL) *errStr = [NSString stringWithString:item.path];  // relativeParsedPath;
            if (errCode!=NULL) *errCode = [pathComponentErr copy]; // [NSNumber numberWithInteger:ErrInvalidFileOrFolderName];
            return nil;
        }
        
        if (item.shouldCopy) [itemsToBeCopied addObject:item];
        if (item.shouldCopy) NSLog(@"Include: %@", item.path);
        if (!item.shouldCopy) NSLog(@"Exclude: %@", item.path);
    }
    
    return [NSArray arrayWithArray:itemsToBeCopied];
}

/**
 *  Copies file system items and creates neccessary folders to a given folder
 *
 *  @param items              Items to be copied/created as an array of FileSystemItems
 *  @param folder             A folder to copy/create items to
 *  @param defaultPermissions Default permissions as posix mask
 *  @param errStr             A pointer for a returning error descriptionting
 *
 *  @return An error code. 0 if no errors occurred.
 */

-(NSInteger)copyItems:(NSArray*)items ToFolder:(FileSystemItem*)folder
           defaultPermissions:(NSDictionary *)defaultPermissions
                    errString:(NSString**) errStr {
    
   // NSInteger errCode = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    //NSArray *itemsToBeCopied = [FileSystemItem getDirectoryContentForFolder:_theTemplate.location includeFiles:YES includeFolders:YES includeSubDirectories:YES];
   // NSInteger totalFileSize = 0;
    NSString *templateSettingsPathToBeExcluded = [NSString stringWithFormat:@"%@/%@", folder.pathByExpandingTildeInPath, TEMPLATE_SETTINGS_FILENAME];
  
    
    
    // CREATE FOLDERS
    for (FileSystemItem *item in items) {
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
    for (FileSystemItem *item in items) {
        
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
                        if (errStr!=NULL) *errStr = [item.pathToCopy copy];
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

/**
 *  Writes metadata as a batch process to every given folder in a folders array.
 *
 *  This is used to write all the metadata for all parent folders at once.
 *
 *  The method reads existing metadata from folders and appends newly created metadata items to it,
 *  and finally overwrites the existing metadata with new contents.
 *
 *  @note Metadata items are given in an array that must be in sync with a folder array,
 *  in other words, they must have the same array index.
 *
 *  @param folders           A folder array
 *  @param metadataItemArray A metadata item array
 *  @param deploymentId      A deployment id
 *  @param options           Options, not in use
 */


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



/**
 *  Generates as an batch process an array of metadata items for a set of folders
 *
 *  This is a batch process to generate new metadata for a set of folders.
 *  It is used to get all metadata for all parent folders at once with method @a writeMetadataTo:
 *
 *  @note involved parameters -konsepti pitää selittää paremmin
 *
 *  @see -(void)writeMetadataTo:(NSArray *)folders withMetadataItems:(NSArray*)metadataItemArray deploymentId:(NSString*)deploymentId options:(NSInteger)options
 *
 *  @param folders         Folders array that will be processed
 *  @param parametersArray Involved parameters
 *  @param deploymentId    Deployment Id to be set for every new metadata item
 *
 *  @return An array of metadata items
 */

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
#pragma mark ARRAY GENERATION


/**
 *  Generates the parent folder array by the contents of _theTemplate
 *
 *  Reads all the parameters and parses neccessary paths
 *
 *  @param err An error code
 *
 *  @return An array of all parent folders as filesystem items
 */

-(NSArray *)generateParentFolderArrayWithError:(NSNumber **)err {
    NSMutableString *pathToParentFolder = [NSMutableString stringWithString:_theTargetFolder.pathByExpandingTildeInPath];
    NSMutableArray *result = [NSMutableArray array];
    _theTargetFolder.isTarget = YES;
    _theTargetFolder.isParent = NO;
    [result addObject:_theTargetFolder];
    for (TemplateParameter *currentParameter in _theTemplate.templateParameterSet) {
        if ([NSString isNotEmptyString:currentParameter.parentFolderNamingRule]) {
            
            if (currentParameter.booleanValue || [NSString isNotEmptyString:currentParameter.stringValue] ) {
                NSNumber *error = nil;
                NSString *parsedParentFolderName = [self parseParametersForPathComponent:currentParameter.parentFolderNamingRule  error:&error];
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
    
    [[result lastObject] setIsParent:NO];
    [[result lastObject] setIsMaster:YES];

    return [NSArray arrayWithArray:result];
}



#pragma mark -
#pragma mark PARAMETER PARSING


-(NSString*)parseParametersForPathComponent:(NSString*)component shouldUse:(NSNumber**)shouldUse error:(NSNumber **)err {
    NSNumber *shouldUse1 = @YES;
    NSString *extension = [component pathExtension];
    NSString *base = [component stringByDeletingPathExtension];
    NSString *parsedBase = [self parseParametersForString:base shouldUse:&shouldUse1];
    if (shouldUse!=NULL) *shouldUse = [shouldUse1 copy];
    NSString *parsedFilename= [extension isEqualToString:@""] ? parsedBase : [NSString stringWithFormat:@"%@.%@", parsedBase, extension];
    
    
    if ([NSString isEmptyString:parsedBase] || ![parsedBase isValidFileName] || ![parsedFilename isValidFileName]) {
        parsedFilename = @"<empty_string>";
        if(err!=NULL && ([*shouldUse boolValue] || shouldUse==NULL)) *err = @(ErrInvalidFileOrFolderName);
    }

    return parsedFilename;
}

-(NSString*)parseParametersForPathComponent:(NSString*)component error:(NSNumber **)err {
    NSNumber *err1 = @0;
    NSString *result =  [self parseParametersForPathComponent:component shouldUse:nil error:&err1];
    if (err!=NULL) *err = [err1 copy];
    return result;
}


-(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents shouldUse:(NSNumber**)shouldUse error:(NSNumber**)err {
    NSMutableArray *parsedArray = [NSMutableArray array];
    NSNumber *shouldUse1 = @YES;
    if (shouldUse != NULL) *shouldUse = @YES;
    
    for (NSString *pathComponent in pathComponents) {
        if ([pathComponent isEqualToString:@"/"]) { // root?
            [parsedArray addObject:pathComponent];
        } else {
            NSNumber *error = nil;
            NSString *parsedPathComponent = [self parseParametersForPathComponent:pathComponent shouldUse:&shouldUse1 error:&error];
            if (shouldUse != NULL) {
                if ([shouldUse1 boolValue] == NO) *shouldUse = [shouldUse1 copy]; // shouldUse1 is return value from previous
            }
            if (error != nil) {
                if (err!=NULL) *err = @([error integerValue]);
            }
            [parsedArray addObject:parsedPathComponent];
            
        }
    }
    return [NSArray arrayWithArray:parsedArray];
}


-(NSArray*)parseParametersForPathComponents:(NSArray*)pathComponents error:(NSNumber**)err {
    NSNumber *err1 = nil;
    NSArray *result = [self parseParametersForPathComponents:pathComponents shouldUse:nil error:&err1];
    if (err != NULL) *err = [err1 copy];
    return result;
}


-(NSString *)parseParametersForPath:(NSString *)path {
    NSArray *pathComponents = [path pathComponents];
    NSArray *parsedPathComponents = [self parseParametersForPathComponents:pathComponents error:nil];
    return [NSString pathWithComponents:parsedPathComponents];
}


/**
 *  Parses a single string with tags in the template parameters
 *
 *  @note This method is the lowest level in parameter parser method hierarchy.
 *  This does the actual parsing.
 *
 *  @see -(NSString *)parseParametersForString:(NSString *)aString shouldUse:(NSNumber**)shouldUse
 *
 *  @param aString   A string to be parsed
 *  @param shouldUse A pointer to returning boolean value to send a flag if any tag determines the item to be excludedP
 *
 *  @return Parsed string
 */

/* ********* ACTUAL PARSER ******** */

-(NSString *)parseParametersForString:(NSString *)aString shouldUse:(NSNumber**)shouldUse {
    
    if (shouldUse != NULL) *shouldUse = @YES;
    NSMutableString *result = [[self parseSystemParametersForString:aString] mutableCopy];
    
    for (TemplateParameter *currentParameter in _theTemplate.templateParameterSet) {

        
        // make regexp patterns for a tag
        NSString *pattern1 = [NSString stringWithFormat:@"\\[(%@)((!=|=)([a-zA-Z0-9äöåÄÖÅ_,]*))?\\]", currentParameter.tag]; // looks for tag [tag=something], [tag!=something] or [tag]
        NSString *pattern2 = [NSString stringWithFormat:@"\\{(%@)((!=|=)([a-zA-Z0-9äöåÄÖÅ_,]*))?\\}", currentParameter.tag]; // looks for tag {tag=something}, {tag!=something} or {tag}
        NSRegularExpressionOptions regexOptions = NSRegularExpressionCaseInsensitive;
        
        NSRegularExpression *regex1 = [[NSRegularExpression alloc] initWithPattern:pattern1 options:regexOptions error:nil];
        NSRegularExpression *regex2 = [[NSRegularExpression alloc] initWithPattern:pattern2 options:regexOptions error:nil];
        
        NSTextCheckingResult *match = nil;
        BOOL overallMatch = YES;
        
        do {
            NSString *before = [result copy];
            
            BOOL replaceMode = YES;
            match = [regex1 firstMatchInString:result options:0 range:NSMakeRange(0, [result length])];
            
            if (!match) {
                replaceMode = NO;
                match = [regex2 firstMatchInString:result options:0 range:NSMakeRange(0, [result length])];
            }
            
            if (match) {
                NSRange matchRange = [match range];
                NSRange tagRange = [match rangeAtIndex:1];
                NSRange operatorRange = [match rangeAtIndex:3];
                NSRange valueRange = [match rangeAtIndex:4];
                NSString *extractedTag = nil;
                
                if (tagRange.location != NSNotFound) {
                    extractedTag = [result substringWithRange:tagRange];
                }
                NSString *operator = nil;
                if (operatorRange.location != NSNotFound) {
                    operator = [result substringWithRange:operatorRange];
                }
                NSString *value = nil;
                if (valueRange.location != NSNotFound) {
                    value = [result substringWithRange:valueRange];
                }
                
                if ([NSString isNotEmptyString:operator]) {
                    BOOL valueMatch = NO;
                    
                    // extract comma separated values when list given


                    if ([operator isEqualToString:@"!="]) {
                        valueMatch = YES;
                        NSArray *allValues = [value arrayFromCommaSeparatedList];
                        for (NSString *thisValue in allValues) {
                            if ([thisValue.lowercaseString isEqualToString:currentParameter.stringValue.lowercaseString]) valueMatch = NO; // NOT a AND NOT b.. operation
                        }
                        //valueMatch = !valueMatch;
                    } else {
                        valueMatch = NO;
                        NSArray *allValues = [value arrayFromCommaSeparatedList];
                        for (NSString *thisValue in allValues) {
                            if ([thisValue.lowercaseString isEqualToString:currentParameter.stringValue.lowercaseString]) valueMatch = YES; // OR operation
                        }
                    }
                    
                    if (!valueMatch) overallMatch = NO; // any single false conditional means shouldCopy status to be false (AND operation)
                }
                
                if (replaceMode) {
                    Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentParameter.tag andString:extractedTag];
                    [result replaceCharactersInRange:matchRange withString:[currentParameter.stringValue convertToCase:caseConversionNeeded]];
                } else {
                    [result replaceCharactersInRange:matchRange withString:@""];
                }
            }
            if ([result isEqualToString:before]) {
                
                if (match) NSLog(@"Why match when no change?");
                match = NO;
            } else {
                //NSLog(@"%@ -> %@", before, result);
            }
        } while (match);
        
        if (overallMatch == NO && shouldUse != NULL) {
             *shouldUse = @NO;
        }
    
        
    }
    
    
    return [NSString stringWithString:[result stringByPerformingFullCleanUp]];
}


//        do {
//            minTagLegth = [brackets length];
//            tagRange = [result rangeOfString:tagWithBrackets options:NSCaseInsensitiveSearch]; // search, old version
//            
//            // if normal tag is not found, look for special *conditional tag* [!tag]
//            if (tagRange.location == NSNotFound) {
//                tagRange = [result rangeOfString:conditionalTagOldFormat1 options:NSCaseInsensitiveSearch];
//                if (tagRange.location == NSNotFound) {
//                    tagRange = [result rangeOfString:conditionalTagOldFormat2 options:NSCaseInsensitiveSearch];
//                }
//                if (tagRange.location != NSNotFound) {
//                    if ([NSString isEmptyString:currentParameter.stringValue] && shouldUse!=nil) *shouldUse = @NO;
//                    if (currentParameter.parameterType == boolean && currentParameter.booleanValue == NO) *shouldUse = @NO;
//                }
//                minTagLegth = [extractingBrackets length];
//            }
//            if (tagRange.location != NSNotFound) {
//                NSString *extractedTag = [result substringWithRange:NSMakeRange(tagRange.location+minTagLegth-1, tagRange.length-minTagLegth)];
//                Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentParameter.tag andString:extractedTag];
//                replacesMade += 1;
//                [result replaceCharactersInRange:tagRange withString:[currentParameter.stringValue convertToCase:caseConversionNeeded]];
//            }
//            
//        } while (tagRange.length > 0);

    


/**
 *  Parses factory build system parameters for a string.
 *
 *  This is called by other tag parser methods as part of their process
 *
 *  Tags to be parsed: [today], [creator], [creator-full-name]
 *
 *  @param aString A string
 *
 *  @return A parsed string
 */

-(NSString *)parseSystemParametersForString:(NSString *)aString  {
    
    NSMutableString *result = [NSMutableString stringWithString:aString];
    long replacesMade = 0;
    
    for (NSString *currentTag in [Definitions reservedTags]) {
        
        NSString *tagWithBrackets = [NSString stringWithFormat:@"%@%@%@", TAGCHAR_BEGIN, currentTag, TAGCHAR_END];
        NSRange tagRange;
        
        do {
            tagRange = [result rangeOfString:tagWithBrackets options:NSCaseInsensitiveSearch];
            if (tagRange.length > 2) {
                NSString *extractedTag = [result substringWithRange:NSMakeRange(tagRange.location+1, tagRange.length-2)];
                Case caseConversionNeeded = [NSString analyzeCaseConversionBetweenString:currentTag andString:extractedTag];
                replacesMade += 1;
                
                NSString* replacement = @"";
                if (_theTemplate) {
                    if ([currentTag isEqualToString:@"today"]) {
                        replacement = [_deploymentStartDate parsedDateWithFormat:[_theTemplate.dateFormatString stringByPerformingFullCleanUp]];
                    }
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
    
    return [result copy];
}

-(NSString *)parseParametersForString:(NSString *)aString {
    return [self parseParametersForString:aString shouldUse:nil];
}

/**
 *  Parses whole path (class method)
 *
 *  @param aFileSystemItem A FileSystemItem
 *
 *  @return A new FileSystemItem
 */

+(FileSystemItem *) parsePathForFileSystemItem:(FileSystemItem*)aFileSystemItem {
    TemplateDeployer *td = [[TemplateDeployer alloc] init];
    NSString *path = aFileSystemItem.pathByExpandingTildeInPath;
    
    NSString *parsedPath = [td parseParametersForPath:path];

    return [[FileSystemItem alloc] initWithPathByAbbreviatingTildeInPath:parsedPath andNickName:aFileSystemItem.nickName];
}


#pragma mark -
#pragma mark INVOLVED PARAMETERS

/**
 *  Generates an array of arrays of involved paraters for all parent levels
 *
 *  Involved parameters is an array of parameters that have been set so far
 *  to the level of parent in the parent folder creation process.
 *
 *  To put it simpy, they are parameters and their values in a TemplateParameters object
 *  that have lower or the same index value than the parameter that causes parent folder creation.
 *  Involved parameters are stored along with other metadata.
 *
 *  The purpose for this is to quickly read used parameters and their values from a deployed folder structure.
 *
 *  @param aTemplate The template. Usually _theTemplate.
 *
 *  @return Involved parameters array.
 */

+(NSArray *)parentFolderParametersInvolved:(Template *)aTemplate {
    NSAssert(@"****************** Trying to use deprecated method", nil) ;
    
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
