/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2012
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/ETController.h>
#import <EtoileUI/ETLayoutItemFactory.h>

@protocol COTrackNode;

@interface COObject (CoreObjectUI)
/** <override-dummy />
Return additional menus for interacting with instances of the receiver class.

The menus shouldn't contain too many actions (no more than 10 or 15 entries per 
menu). No more than 2 menus should be returned. For more interaction options, 
it's better to let the user opens the selected object in a dedicated editor.
 
The returned menu items are inserted to the left of the <em>Edit</em> or 
<em>Presentation</em> standard menus.
 
Etoile built-in Object Manager and Compound Document Editor (Worktable) use 
these menus to provide basic interactions without opening the selected objects 
in their dedicated editors.

By default, returns an empty array. */
+ (NSArray *) menuItems;
@end

@interface ETLayoutItemFactory (CoreObjectUI) 
/** Returns a new layout item group which shows the history provided by the 
represented object, usually a CORevision object collection or a COTrack. */
- (ETLayoutItemGroup *) historyBrowserWithRepresentedObject: (id <ETCollection>)trackOrRevs
                                                      title: (NSString *)aTitle;
@end

/** The controller used by the CoreObject history browser. 

See -[ETLayoutItemFactory historyBrowserWithRepresentedObject:], the controller 
can be retrieved with -[ETLayoutItemGroup controller] on the returned item. */
@interface ETHistoryBrowserController : ETController
{
	@private
	id <COTrackNode> _currentNode;
}

/** @taskunit Actions */

- (IBAction) selectiveUndo: (id)sender;
- (IBAction) moveBackTo: (id)sender;
- (IBAction) moveForwardTo: (id)sender;
- (IBAction) restoreTo: (id)sender;
- (IBAction) open: (id)sender;

@end
