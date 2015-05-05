//
//  PreferencesController.h
//  Lonkero
//
//  Created by Kati Haapamäki on 6.11.2013.
//  Copyright (c) 2013 Kati Haapamäki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"
@class Preferences;

@interface PreferencesController : NSWindowController <NSWindowDelegate> {
    Preferences *preferencesToBeEdited;
    NSModalSession _prefsModalSession;
}

@property NSMutableArray *templateFolderArray;
@property (unsafe_unretained) IBOutlet NSTableView *templateFoldersTableView;
@property (strong) IBOutlet NSArrayController *templateFoldersArrayController;

@property (strong) IBOutlet NSPanel *preferencesWindow;

- (IBAction)savePreferences:(id)sender;
- (IBAction)cancel:(id)sender;

-(void) editPreferences:(Preferences *) prefs;

- (IBAction)addFolder:(id)sender;
- (IBAction)removeFolder:(id)sender;
- (IBAction)moveUpFolder:(id)sender;
- (IBAction)moveDownFolder:(id)sender;

- (void)moveUpItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;
- (void)moveDownItemInMutableArray:(NSMutableArray *)anArray atTableView:(NSTableView *)aTableView;

@end
