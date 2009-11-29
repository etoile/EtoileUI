/** <title>ETEventProcessor</title>

	<abstract>ETEventProcessor converts the events emitted by the widget backend 
	into ETEvent objects before forwarding them to the active instrument.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETEvent, ETUIItem, ETLayoutItem;

/** The active instrument handles the dispatch in the layout item tree. */
@interface ETEventProcessor : NSObject
{

}

+ (id) sharedInstance;
- (BOOL) processEvent: (void *)backendEvent;
- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;
- (BOOL) trySendEvent: (ETEvent *)anEvent toWidgetViewOfItem: (ETLayoutItem *)item;

@end


@interface ETAppKitEventProcessor : ETEventProcessor
{
	NSWindow *_initialKeyWindow;
	id _initialFirstResponder;
	BOOL _wasMouseDownProcessed;
}

- (BOOL) processMouseEvent: (ETEvent *)anEvent;
- (void) processMouseMovedEvent: (ETEvent *)anEvent;
- (BOOL) processKeyEvent: (ETEvent *)anEvent;

- (ETEvent *) synthetizeMouseEnteredEvent: (ETEvent *)anEvent;
- (ETEvent *) synthetizeMouseExitedEvent: (ETEvent *)anEvent;

@end
