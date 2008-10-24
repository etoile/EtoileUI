/*
	ETPersistencyController.h
	
	A persistency controller that integrates CoreObject with EtoileUI and 
	provides UI facilities to control the history of the core objects.
 
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
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class COObjectContext;

/** Class only available if CoreObject is linked.
    This shared persistency controller is inserted at the end of the responder 
    chain (see -[ETApplication targetForAction:]). It allows native 
    EtoileUI-based applications to integrate transparently with CoreObject 
    without writing any code. This controller catches actions such as undo/redo 
    not handled in the responder and turns them into messages to COObjectContext.
    History actions are by default applied to the current object context.
    These actions are typically set on menu items.
    TODO: Might be used it to register persistent documents managed by 
    CoreObject and dispatch actions to these documents. It might make more sense 
    to inherit from ETLayoutItemGroup. This way, registered/opened documents 
    would just be child items. */
@interface ETPersistencyController : NSObject
{
	IBOutlet NSPanel *_revertToPanel;
	IBOutlet NSTextField *_revertedVersionField;
}

+ (id) sharedInstance;

- (COObjectContext *) currentObjectContext;

/* History related Actions (API subject to changes) */

- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;
- (IBAction) restoreTo: (id)sender;
- (IBAction) restoreSelectionTo: (id)sender;
- (IBAction) restoreObjectTo: (id)sender;

/* Private */

- (IBAction) endRestoreToDialog: (id)sender;

@end
