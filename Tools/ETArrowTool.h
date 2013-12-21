/**
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETTool.h>

@class ETEvent, ETLayoutItem;
@protocol ETKeyInputAction, ETTouchAction;

/** @group Tools

@abstract The actions which can be produced by ETArrowTool. */
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

/** @group Tools

@abstract A basic ETTool subclass which provides common UI interaction and can
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
	 /** The item initially touched on mouse down */
	ETLayoutItem *_firstTouchedItem;
	BOOL _isTrackingTouch;
}

/** @taskunit Event Handlers */

- (void) mouseDown: (ETEvent *)anEvent;
- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;

@end
