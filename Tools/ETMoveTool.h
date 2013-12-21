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

@class ETEvent, ETLayoutItem;

/* A basic ETTool subclass which can be used to translate a single layout 
item at a time.

ETMoveTool doesn't support real dragging in the sense you can only translate a 
layout item within the bound of its parent item. You cannot move the item 
outside.

ETMoveTool can be subclassed as ETSelectTool does to implement more evolved 
move, translate and drag behaviors. */
@interface ETMoveTool : ETTool
{
	@private
	ETLayoutItem *_draggedItem;
	NSPoint _dragStartLoc; 	/** Expressed in the screen base with non-flipped coordinates */
	NSPoint _lastDragLoc;  /** Expressed in the screen base with non-flipped coordinates */
	BOOL _shouldProduceTranslateActions;
}

- (BOOL) shouldProduceTranslateActions;
- (void) setShouldProduceTranslateActions: (BOOL)translate;

- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;

- (BOOL) isMoving;
- (id) movedItem;

/* Translate Action Producer */

- (void) beginTranslateItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
- (void) translateToPoint: (NSPoint)eventLoc;
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
