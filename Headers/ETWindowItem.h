/**  <title>ETWindowItem</title>

	<abstract>ETDecoratorItem subclass which makes possibe to decorate any 
	layout items with a window.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileUI/ETTool.h> /* For ETFirstResponderSharingArea */

/** A decorator which can be used to put a layout item inside a window.

With the AppKit widget backend, the window is an NSWindow object.

Once the window is managed by a window item, you must not call the following 
NSWindow methods: -setDelegate:, -setAcceptsMouseMovedEvents: and 
-registerForDraggedTypes:. */
@interface ETWindowItem : ETDecoratorItem <ETFirstResponderSharingArea>
{
	NSWindow *_itemWindow;
	int _oldDecoratedItemAutoresizingMask; /* Autoresizing mask to restore */
	BOOL _usesCustomWindowTitle;
	BOOL _flipped;
	BOOL _shouldKeepWindowFrame;
	ETLayoutItem *_activeFieldEditorItem;
	ETLayoutItem *_editedItem;
}

/* Factory Methods */

+ (ETWindowItem *) itemWithWindow: (NSWindow *)window;
+ (ETWindowItem *) fullScreenItem;
+ (ETWindowItem *) transparentFullScreenItem;

/* Initialization */

- (id) initWithWindow: (NSWindow *)window;
- (id) init;

/* Main Accessors */

- (NSWindow *) window;
- (BOOL) usesCustomWindowTitle;
- (BOOL) isUntitled;
- (BOOL) shouldKeepWindowFrame;
- (void) setShouldKeepWindowFrame: (BOOL)shouldKeepWindowFrame;
- (float) titleBarHeight;

/* Customized Decorator Methods */

- (NSView *) view;
- (NSRect) decorationRect;
- (NSRect) contentRect;
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item;
- (BOOL) canDecorateItem: (id)item;

- (id) nextResponder;

/* First Responder Sharing Area */

- (ETLayoutItem *) activeFieldEditorItem;
- (ETLayoutItem *) editedItem;
- (void) setActiveFieldEditorItem: (ETLayoutItem *)anItem 
                       editedItem: (ETLayoutItem *)anItem;
- (void) removeActiveFieldEditorItem;
- (ETLayoutItem *) hitTestFieldEditorWithEvent: (ETEvent *)anEvent;

/* Framework Private */

+ (NSRect) convertRectToWidgetBackendScreenBase: (NSRect)rect;
+ (NSRect) convertRectFromWidgetBackendScreenBase: (NSRect)windowFrame;

@end
