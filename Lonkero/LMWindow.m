/**
 * Copyright (c) 2013 Micha Mazaheri
 * Released under the MIT License: http://opensource.org/licenses/MIT
 */

#define LMWindowDEBUGResponders

#ifdef LMWindowDEBUGResponders
static BOOL _showFirstResponderOverlay = YES;
#endif
#import "LMWindow.h"

@implementation LMWindow : NSWindow

/*
 * Key View Chain is Hard to Debug, here are some methods and tools that helps debug them
 */

#ifdef LMWindowDEBUGResponders

// Add Menu Items in the App Menu
- (void)becomeMainWindow
{
	static BOOL _keyViewChainDebugMenuItemsInstalled = NO;
	if (_keyViewChainDebugMenuItemsInstalled == NO) {
		NSMenu* mainMenu = [NSApp mainMenu];
		NSMenu* appMenu = [[mainMenu itemAtIndex:0] submenu];
		NSUInteger i = 0;
		[appMenu insertItem:[[NSMenuItem alloc] initWithTitle:@"Debug Key View Loop" action:@selector(_printKeyViewLoop) keyEquivalent:@"P" ] atIndex:i++];
		[appMenu insertItem:[[NSMenuItem alloc] initWithTitle:@"Show/Hide First Responder Overlay" action:@selector(_showHideFirstResponderOverlay) keyEquivalent:@"O" ] atIndex:i++];
		[appMenu insertItem:[NSMenuItem separatorItem] atIndex:i++];
		
		_keyViewChainDebugMenuItemsInstalled = YES;
	}
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"mainWindowLoaded" object:self];
}

// Show/Hide an overlay window on the first responder
- (void)_showHideFirstResponderOverlay
{
	_showFirstResponderOverlay = !_showFirstResponderOverlay;
	[self _showFirstResponderWindowIfNeeded:[self firstResponder]];
}

// Show/Hide first responder window (when _showFirstResponderOverlay == YES)
- (void)_showFirstResponderWindowIfNeeded:(NSResponder*)aResponder
{
	static NSWindow* _debugOverlayWindow = nil;
	if (_debugOverlayWindow != nil) {
		[self removeChildWindow:_debugOverlayWindow];
		_debugOverlayWindow = nil;
	}
	if (_showFirstResponderOverlay && [aResponder isKindOfClass:[NSView class]]) {
		NSRect frame = [self convertRectToScreen:[(NSView*)aResponder convertRect:[(NSView*)aResponder bounds] toView:nil]];
		_debugOverlayWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		_debugOverlayWindow.backgroundColor = [NSColor colorWithCalibratedRed:0.f green:50.f blue:100.f alpha:0.3f];
		[_debugOverlayWindow setOpaque:NO];
		[_debugOverlayWindow setIgnoresMouseEvents:YES];
		[self addChildWindow:_debugOverlayWindow ordered:NSWindowAbove];
	}
}

// Override -makeFirstResponder: to log the first responder changes
- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
	static NSMutableArray* _makeFirstResponderStack = nil;
	if (_makeFirstResponderStack == nil) {
		_makeFirstResponderStack = [NSMutableArray array];
	}
	
	if ([_makeFirstResponderStack count] == 0) {
		NSLog(@"Make First Responder:\n");
	}
	
	[_makeFirstResponderStack addObject:aResponder];
	NSLog(@"%@ %@ %@ %p",
		  [@"" stringByPaddingToLength:[_makeFirstResponderStack count] * 2 withString:@" " startingAtIndex:0],
		  NSStringFromClass([aResponder class]),
		  [aResponder isKindOfClass:[NSView class]] ? [(NSView*)aResponder identifier] : @"",
		  aResponder);
	BOOL r = [super makeFirstResponder:aResponder];
	NSLog(@"%@ %@",
		  [@"" stringByPaddingToLength:[_makeFirstResponderStack count] * 2 withString:@" " startingAtIndex:0],
		  r ? @"YES" : @"NO ");
	[_makeFirstResponderStack removeLastObject];
	
	if ([_makeFirstResponderStack count] == 0) {
		NSLog(@"--\n\n");
	}
	
	[self _showFirstResponderWindowIfNeeded:aResponder];
	
	return r;
}

// Pretty Print the Key View Loop
- (void)_printKeyViewLoop
{
	NSLog(@"printKeyViewLoop: %@ %p", NSStringFromClass([self class]), self);
	
	NSView* initialFirstResponder = [self initialFirstResponder];
	NSResponder* currentFirstResponder = [self firstResponder];
	
	NSLog(@"Current First Responder: %@ %@ %p", [currentFirstResponder class],  [currentFirstResponder isKindOfClass:[NSView class]] ? [(NSView*)currentFirstResponder identifier] : @"", currentFirstResponder);
	NSLog(@"Initial First Responder: %@", [initialFirstResponder class]);
	
	NSMutableArray* parents = [NSMutableArray array];
	
	for (NSView* responder = initialFirstResponder; responder != nil; ) {
		
		// Finding parents
		__block NSUInteger parentIndex = NSNotFound;
		[parents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id parent, NSUInteger idx, BOOL *stop) {
			if ([responder isDescendantOf:parent]) {
				parentIndex = idx;
				*stop = YES;
			}
		}];
		if (parentIndex == NSNotFound) {
			[parents setArray:@[responder]];
		}
		else {
			if (parentIndex + 1 < [parents count]) {
				[parents removeObjectsInRange:NSMakeRange(parentIndex + 1, [parents count] - parentIndex - 1)];
			}
			[parents addObject:responder];
		}
		
		NSLog(@"%@%@ %@ %@ %p",
			  [responder acceptsFirstResponder] ? @"> " : @"- ",
			  responder == currentFirstResponder ? @"##" : @"  ",
			  [[NSString stringWithFormat:@"%@%@",
				[@"" stringByPaddingToLength:(([parents count] - 1) * 2) withString:@" " startingAtIndex:0],
				[NSStringFromClass([responder class]) stringByPaddingToLength:30 withString:@" " startingAtIndex:0]]
			   stringByPaddingToLength:60 withString:@" " startingAtIndex:0],
			  [[responder identifier] ? [NSString stringWithFormat:@"%@", [responder identifier]] : @"-" stringByPaddingToLength:50 withString:@" " startingAtIndex:0],
			  responder);
		
		responder = [responder nextKeyView];
		if (responder == initialFirstResponder) {
			NSLog(@"  Loop closed");
			break;
		}
	}
	
	NSLog(@"--\n");
}
#endif

@end
