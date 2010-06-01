/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2008
	License:  Modified BSD (see COPYING)
 */

#import <CoreObject/COObjectContext.h>
#import "ETPersistencyController.h"
#import "ETApplication.h"

#define OK 1
#define CANCEL 0

@implementation ETPersistencyController

static ETPersistencyController *sharedInstance = nil;

/** Returns the shared persistency controller */
+ (id) sharedInstance
{
	if (sharedInstance == nil)
		sharedInstance = [[ETPersistencyController alloc] init];

	return sharedInstance;
}

/** Returns the current object context on which history actions such as undo/redo 
    are applied to. */
- (COObjectContext *) currentObjectContext
{
	return [COObjectContext currentContext];
}

/* History related Actions (API subject to changes) */

/** Asks the current object context to undo the lastest recorded change. */
- (IBAction) undo: (id)sender
{
	[[self currentObjectContext] undo];
}

/** Asks the current object context to redo the lastest undone change. */
- (IBAction) redo: (id)sender
{
	[[self currentObjectContext] redo];
}

/** Displays a dialog that requests the user to enter the context version he 
    wants to restore, then asks the current object context to restore to 
    this version. */
- (IBAction) restoreTo: (id)sender
{
	[NSBundle loadNibNamed: @"RevertToPanel" owner: self];

	int dialogResult = [NSApp runModalForWindow: _revertToPanel];
	
	[_revertToPanel orderOut: nil];
	if (dialogResult != OK)
		return;

	[[self currentObjectContext] restoreToVersion: [_revertedVersionField intValue]];
}

/** Displays a dialog that requests the user to enter the context version he 
    wants to restore for the selected objects of the focused item, then asks 
    the current object context to restore and merge the temporal instances 
    that existed for the selected objects at this context version. */
- (IBAction) restoreSelectionTo: (id)sender
{
	// TODO: Implement
}

/** Displays a dialog that requests the user to enter the object version he 
    wants to restore for the selected object of the focused item, then asks 
    the current object context to restore and merge the temporal instance
    identified by this object version.
    If more than one layout item is selected in the focused item, this method 
    does nothing. */
- (IBAction) restoreObjectTo: (id)sender
{
	// TODO: Implement
}

/* Private */

- (IBAction) endRestoreToDialog: (id)sender
{
	if ([[sender stringValue] isEqual: _(@"OK")])
	{
		[NSApp stopModalWithCode: OK];
	}
	else
	{
		[NSApp stopModalWithCode: CANCEL];
	}
}

@end
