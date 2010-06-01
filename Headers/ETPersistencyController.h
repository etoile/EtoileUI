/** <title>ETPersistencyController</title>

	<abstract>A persistency controller that integrates CoreObject with EtoileUI 
	and provides UI facilities to control the history of the core objects.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2008
	License:  Modified BSD (see COPYING)
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
	@private
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
