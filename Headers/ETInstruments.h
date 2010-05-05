/** <title>ETTool</title>

	<abstract>An tool represents an interaction mode to handle and 
	dispatch events turned into actions in the layout item tree .</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETTool.h>

@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout, ETSelectionAreaItem;
@protocol ETKeyInputAction, ETTouchAction;

/** The actions which can be produced by ETArrowTool. */
@protocol ETArrowToolActionConsumer
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
- (void) handleDoubleClickItem: (ETLayoutItem *)item;
- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta;
- (void) handleEnterItem: (ETLayoutItem *)item;
- (void) handleExitItem: (ETLayoutItem *)item;
- (void) handleEnterChildItem: (ETLayoutItem *)childItem;
- (void) handleExitChildItem: (ETLayoutItem *)childItem;
- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item;
@end

/** A basic ETTool subclass which provides common UI interaction and can 
be used to click, double-click, pick and drop layout items.

ETArrowTool produce the actions listed in ETArrowToolActionConsumer protocol.<br />
When -handleBeginTouch:atPoint:onItem: returns YES in an action handler, 
-handleClickItem:atPoint:, -handleDoubleClickItem: and -handleDragItem: are not 
emitted by the tool.

You should generally use the more high-level methods in the action handler 
such as -handleClickItem:atPoint:, -handleEnterChildItem: etc. unless you want to 
implement your own tracking behavior at the action handler level (e.g. button 
highlighting that is inversed every time the item is entered/exited while the 
mouse button is kept pressed). 
Tracking actions are -handleBeginTouch:atPoint:onItem:, 
-handleContinueTouch:atPoint:onItem: and -handleEndTouch:onItem:. These action 
sequence methods will be invoked on the same item even when the event location 
moves outside the item on which the touch began. The item argument will be the 
item on which the touch was initiated and to which the action handler is bound 
as expected. You can easily know whether a touch is still inside the first 
touched item by checking whether -[<ETTouchAction> layoutItem] is equal to it.

The arrow tool doesn't select items when you click on them. If you want to 
react to mouse up events by selecting the clicked item, you can attach the 
select tool to the layout which should exhibit this behavior. For example, 
ETSelectTool is attached to ETIconLayout and ETFreeLayout by default. */
@interface ETArrowTool : ETTool
{
	@private
	ETLayoutItem *_firstTouchedItem; /* The item initially touched on mouse down */
	BOOL _isTrackingTouch;
}

- (void) mouseDown: (ETEvent *)anEvent;
- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;

@end

/* A basic ETTool subclass which can be used to translate a single layout 
item at a time.

ETMoveTool doesn't support real dragging in the sense you can only translate a 
layout item within the bound of its parent item. You cannot move the item 
outside.

ETMoveTool can be subclassed as ETSelectTool does to implement more evolved 
move, translate and drag behaviors. */
@interface ETMoveTool : ETTool
{
	id _draggedItem;

	@private
	NSPoint _dragStartLoc; 	/** Expressed in the screen base with non-flipped coordinates */
	NSPoint _lastDragLoc;  /** Expressed in the screen base with non-flipped coordinates */
	BOOL _isTranslateMode;
}

- (BOOL) shouldProduceTranslateActions;
- (void) setShouldProduceTranslateActions: (BOOL)translate;

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
