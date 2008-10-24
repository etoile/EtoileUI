/*  <title>ETPersistencyController</title>

	ETPersistencyController.m
	
	<abstract>	A persistency controller that integrates CoreObject with 
	EtoileUI and provides UI facilities to control the history of the core 
	objects.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2008
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
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
