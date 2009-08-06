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

/** A decorator which can be used to put a layout item inside a window.

With the AppKit widget backend, the window is an NSWindow object. */
@interface ETWindowItem : ETDecoratorItem
{
	NSWindow *_itemWindow;
	int _oldDecoratedItemAutoresizingMask; /* Autoresizing mask to restore */
	BOOL _usesCustomWindowTitle;
	BOOL _flipped;
	BOOL _shouldKeepWindowFrame;
}

- (id) initWithWindow: (NSWindow *)window;
- (id) init;

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

@end
