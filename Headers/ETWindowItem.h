/**  <title>ETWindowItem</title>

	<abstract>ETDecoratorItem subclass which makes possibe to decorate any 
	layout items with a window.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileUI/ETResponder.h>

// FIXME: Don't expose NSWindow in the public API.
@class NSWindow;
@class COObjectGraphContext;
@class ETEvent;

/** A decorator which can be used to put a layout item inside a window.

With the AppKit widget backend, the window is an NSWindow object.

Once the window is managed by a window item, you must not call the following 
NSWindow methods: -setDelegate:, -setAcceptsMouseMovedEvents: and 
-registerForDraggedTypes:.

The NSWindow object is not in the EtoileUI responder chain, but common actions 
such as -performClose: are forwarded to the NSWindow. */
@interface ETWindowItem : ETDecoratorItem <ETFirstResponderSharingArea>
{
	@private
	NSWindow *_itemWindow;
	int _oldDecoratedItemAutoresizingMask; /* Autoresizing mask to restore */
	BOOL _usesCustomWindowTitle;
	BOOL _flipped;
	BOOL _shouldKeepWindowFrame;
	ETLayoutItem *_activeFieldEditorItem;
	ETLayoutItem *_editedItem;
	ETLayoutItem *_oldFocusedItem;
}

/** @taskunit Factory Methods */

+ (ETWindowItem *) itemWithWindow: (NSWindow *)window
               objectGraphContext: (COObjectGraphContext *)aContext;
+ (ETWindowItem *) panelItemWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETWindowItem *) fullScreenItemWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETWindowItem *) transparentFullScreenItemWithObjectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Initialization */

- (instancetype) initWithWindow: (NSWindow *)window
   objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Main Accessors */

@property (nonatomic, readonly, strong) NSWindow *window;
@property (nonatomic, readonly) BOOL usesCustomWindowTitle;
@property (nonatomic, readonly) BOOL isUntitled;
@property (nonatomic) BOOL shouldKeepWindowFrame;
@property (nonatomic, readonly) CGFloat titleBarHeight;

/** @taskunit Customized Decorator Methods */

@property (nonatomic, readonly) NSView *view;
@property (nonatomic, readonly) NSRect decorationRect;
@property (nonatomic, readonly) NSRect contentRect;

- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item;
- (BOOL) canDecorateItem: (id)item;

/** @taskunit First Responder Sharing Area */

- (BOOL) makeFirstResponder: (id <ETResponder>)aResponder;

@property (nonatomic, readonly) id<ETResponder> firstResponder;
@property (nonatomic, readonly) ETLayoutItem *focusedItem;
@property (nonatomic, readonly) ETLayoutItem *activeFieldEditorItem;
@property (nonatomic, readonly) ETLayoutItem *editedItem;

- (void) setActiveFieldEditorItem: (ETLayoutItem *)editorItem 
                       editedItem: (ETLayoutItem *)editedItem;
- (void) removeActiveFieldEditorItem;
- (ETLayoutItem *) hitTestFieldEditorWithEvent: (ETEvent *)anEvent;

/** @taskunit Actions */

- (IBAction) performClose:(id)sender;
- (IBAction) performMiniaturize:(id)sender;
- (IBAction) performZoom:(id)sender;

/** @taskunit Framework Private */

+ (NSRect) convertRectToWidgetBackendScreenBase: (NSRect)rect;
+ (NSRect) convertRectFromWidgetBackendScreenBase: (NSRect)windowFrame;
- (void) postFocusedItemChangeNotificationIfNeeded;

@end
