/**	<title>ETUIItem</title>

	<abstract>An abstract class/mixin that provides some basic behavior common 
	to both ETLayoutItem and ETDecoratorItem.</abstract>

	Copyright (C) 20O9 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

@class ETDecoratorItem, ETLayoutItemGroup, ETView;


// TODO: Turn this class into a mixin and a protocol 
@interface ETUIItem : ETStyle
{
	ETDecoratorItem *_decoratorItem; // next decorator
	ETView *_view;
}

+ (NSRect) defaultItemRect;

- (BOOL) usesWidgetView;

- (BOOL) isFlipped;
- (id) supervisorView;
- (void) setSupervisorView: (ETView *)aView;
- (ETView *) displayView;
- (void) beginEditingUI;
/*- (BOOL) isEditingUI;
- (void) commitEditingUI;*/

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view;

/* Decoration */

- (ETDecoratorItem *) decoratorItem;
- (void) setDecoratorItem: (ETDecoratorItem *)decorator;
- (void) removeDecoratorItem: (ETDecoratorItem *)decorator;
- (id) lastDecoratorItem;
- (ETUIItem *) decoratedItem;
- (id) firstDecoratedItem;
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item;
- (NSRect) decorationRect;

- (ETUIItem *) decoratorItemAtPoint: (NSPoint)aPoint;

- (BOOL) isDecoratorItem;
- (BOOL) isWindowItem;

/* Enclosing Item */

- (id) enclosingItem;
- (NSRect) convertRectToEnclosingItem: (NSRect)aRect;
- (NSPoint) convertPointToEnclosingItem: (NSPoint)aPoint;

/* Framework Private */

- (void) didChangeDecoratorOfItem: (ETUIItem *)item;
- (BOOL) shouldSyncSupervisorViewGeometry;
- (NSRect) convertDisplayRect: (NSRect)rect 
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItemGroup *)parent;
- (ETUIItem *) decoratedItemAtPoint: (NSPoint)aPoint;

@end

