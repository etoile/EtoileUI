/** <title>ETInstrument</title>

	<abstract>An instrument represents an interaction mode to handle and 
	dispatch events turned into actions in the layout item tree .</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETInstrument.h>

@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout, ETSelectionAreaItem;

/** A basic ETInstrument subclass which provides common UI interaction and can 
be used to click, double-click, pick and drop layout items.

The arrow tool doesn't select items when you click on them. If you want to 
react to mouse up events by selecting the clicked item, you can attach the 
select tool to the layout which should exhibit this behavior. For example, 
ETSelectTool is attached to ETIconLayout and ETFreeLayout by default. */
@interface ETArrowTool : ETInstrument
{

}

- (void) mouseUp: (ETEvent *)anEvent;

@end

/* A basic ETInstrument subclass which can be used to translate a single layout 
item at a time.

ETMoveTool doesn't support real dragging in the sense you can only translate a 
layout item within the bound of its parent item. You cannot move the item 
outside.

ETMoveTool can be subclassed as ETSelectTool does to implement more evolved 
move, translate and drag behaviors. */
@interface ETMoveTool : ETInstrument
{
	id _draggedItem;
	NSPoint _dragStartLoc; 	/** Expressed in the screen base with non-flipped coordinates */
	NSPoint _lastDragLoc;  /** Expressed in the screen base with non-flipped coordinates */
	NSSize _dragDelta; /** Expressed in the screen base with non-flipped coordinates */
	BOOL _isTranslateMode;
}

- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;

- (BOOL) isMoving;

/* Translate Action Producer */

- (void) beginTranslateItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
- (void) translateToPoint: (NSPoint)aPoint;
- (void) translateByDelta: (NSSize)aDelta;
- (void) endTranslate;
- (BOOL) isTranslating;

/* Drag Action Producer */

- (void) beginDragItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;
- (void) endDrag;
- (BOOL) isDragging;

- (id) actionHandler;

@end

//extern NSString *ETMoveToolTranslateNotification;

// TODO: ETPickDropTool : ETMoveTool and ETSelectTool : ETPickDropTool
// With -shouldProduceTranslateActions or -shouldProduceDragActions as
// overridable hooks which check the context: key modifier etc.
// ETFreeLayout configures the select tool to produce translate actions with 
// -setShouldProduceTranslateActions: YES otherwise the select tool produces 
// drag actions by default.
