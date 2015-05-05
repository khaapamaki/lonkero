//
//  QuickPathSelectorHelper.m
//  Lonkero
//
//  Created by Kati Haapamäki on 16.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import "PathControlHelper.h"

@implementation PathControlHelper
/*
-(IBAction)selectPath:(id)sender
{
	NSPathComponentCell *clickedPathCell = [sender clickedPathComponentCell];
	NSURL *clickedPathURL = [clickedPathCell URL];
	NSURL *test = [pathSelector URL];
    
	if (clickedPathURL != NULL) {
        
        // CLICKED PATH
		if ([[clickedPathURL path] isEqualToString:[test path]]) {
			// Last path componenent -> Show File Open Dialog
            
			if ( [openDlg runModalForDirectory:[clickedPathURL path] file:nil] == NSOKButton )
			{
				NSArray* selectedURLS = [openDlg URLs];
				[sender setURL:[selectedURLS objectAtIndex:0]];
				[scanResult release];
				scanResult = nil;
				[btnSearch setTitle:@"Scan and Search"];
			}
		} else {
			// Not last componenent -> Truncate path
			[sender setURL:clickedPathURL];
			[scanResult release];
			scanResult = nil;
			[btnSearch setTitle:@"Scan and Search"];
		}
        
	} else {
        
        // DRAG'n'DROP PATH
		NSString *temp = [[sender URL] path];
		NSNumber *isDirectory = [NSNumber numberWithInt:0];
		NSNumber *isPackage = [NSNumber numberWithInt:0];
        
		[[sender URL] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		[[sender URL] getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
        
		if ([isDirectory boolValue]==NO || [isPackage boolValue]==YES) {
			[sender setURL:[NSURL fileURLWithPath:[temp stringByDeletingLastPathComponent]]];
		} else {
			[sender setURL:[NSURL fileURLWithPath:temp]];
		}
	}
	
    NSNumber *isVolumeRoot = [NSNumber numberWithInt:0];
    [[sender URL] getResourceValue:&isVolumeRoot forKey:NSURLIsVolumeKey error:NULL];
    int searchStringLength = [[searchField stringValue] length];
    if ( (searchStringLength > 2) && ![isVolumeRoot boolValue] ) {
        [btnSearch setEnabled:YES];
    } else {
        [btnSearch setEnabled:NO];
    }
    
    [scanResult release];
    scanResult = nil;
    
    [btnSearch setTitle:@"Scan and Search"];
}


*/

- (IBAction)userSelectedPath:(id)sender {
    NSPathComponentCell *clickedPathCell = [sender clickedPathComponentCell];
	NSURL *clickedPathURL = [clickedPathCell URL];

    if (clickedPathURL != NULL) {
        BOOL isLastPathComponent = [[clickedPathURL path] isEqualToString:[[_pathControl URL] path]];
        
		if (isLastPathComponent) {
            NSOpenPanel *openDlg = [[NSOpenPanel alloc] init];
            [openDlg setCanChooseFiles:NO];
            [openDlg setAllowsMultipleSelection:NO];
            [openDlg setCanChooseDirectories:YES];
            [openDlg setCanCreateDirectories:NO];
            [openDlg setDirectoryURL:clickedPathURL];
			if ( [openDlg runModal] == NSOKButton )
			{
				NSArray* selectedURLS = [openDlg URLs];
				[sender setURL:[selectedURLS objectAtIndex:0]];
			}
		} else {
			[sender setURL:clickedPathURL];
		}
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"targetPathChanged" object:self];
	}
}
@end
