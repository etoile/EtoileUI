/**
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETTool.h>

@class ETEvent, ETLayoutItem;

/** @group Tools

@abstract A basic ETTool subclass which can be used to translate a single layout 
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
	/** Expressed in the screen base with non-flipped coordinates */
	NSPoint _dragStartLoc;
	/** Expressed in the screen base with non-flipped coordinates */	
	NSPoint _lastDragLoc; 
	BOOL _shouldProduceTranslateActions;
}

/** @taskunit Interaction Settings */

- (BOOL) shouldProduceTranslateActions;
- (void) setShouldProduceTranslateActions: (BOOL)translate;

/** @taskunit Event Handlers */

- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;

/** @taskunit Interaction Status */

- (BOOL) isMoving;
- (id) movedItem;

/** @taskunit Translate Action Producer */

- (void) beginTranslateItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
- (void) translateToPoint: (NSPoint)eventLoc;
- (void) translateByDelta: (NSSize)aDelta;
- (void) endTranslate;
- (BOOL) isTranslating;

/** @taskunit Drag Action Producer */

- (void) beginDragItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;
- (void) endDrag;
- (BOOL) isDragging;

/** @taskunit Targeted Action Handler */

- (id) actionHandler;

@end
