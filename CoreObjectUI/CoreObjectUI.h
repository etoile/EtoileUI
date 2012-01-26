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

@interface ETLayoutItemFactory (CoreObjectUI) 
/** Returns a new layout item group which shows the history provided by the 
represented object, usually a CORevision object collection or a COTrack. */
- (ETLayoutItemGroup *) historyBrowserWithRepresentedObject: (id <ETCollection>)trackOrRevs;
@end

/** The controller used by the CoreObject history browser. 

See -[ETLayoutItemFactory historyBrowserWithRepresentedObject:], the controller 
can be retrieved with -[ETLayoutItemGroup controller] on the returned item. */
@interface ETHistoryBrowserController : ETController
{

}

/** @taskunit Actions */

- (IBAction) selectiveUndo: (id)sender;
- (IBAction) moveBackTo: (id)sender;
- (IBAction) moveForwardTo: (id)sender;
- (IBAction) restoreTo: (id)sender;
- (IBAction) open: (id)sender;

@end
