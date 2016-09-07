/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETApplication.h"
#import "ETArrowTool.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETLayer.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItemFactory.h"
#import "ETLineLayout.h"
#import "ETScrollableAreaItem.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"
#define _ISOC99_SOURCE 
#include <math.h>

@interface ETLayoutItem (Private)
- (NSRect) bounds;
@end

@interface TestHitTest : TestEvent <UKTest>
@end

@implementation TestHitTest

- (void) testLocationInWindow
{
	ETEvent *evt = [self createEventAtPoint: NSMakePoint(3, 3) clickCount: 1 inWindow: [self window]];
	NSEvent *backendEvt = (NSEvent *)[evt backendEvent];
	NSPoint backendWindowLoc = [backendEvt locationInWindow];

	/* We pass an event at a point which is always in backend window 
	   coordinates which are always non-flipped. Hence we expect 
	   -locationInWindowItem to return another location when the 
	   window item is flipped. */
	UKTrue([mainItem isFlipped]);
	UKPointsEqual(NSMakePoint(3, 3), backendWindowLoc);
	UKPointsNotEqual(backendWindowLoc, [evt locationInWindowContentItem]);
	UKPointsNotEqual(backendWindowLoc, [evt locationInWindowItem]);
	CGFloat windowItemLocY = [[self window] frame].size.height - backendWindowLoc.y; 
 	UKPointsEqual(NSMakePoint(backendWindowLoc.x, windowItemLocY), [evt locationInWindowItem]);

	[mainItem setFlipped: NO]; /* For all the tests that follow */	
	UKPointsEqual(NSMakePoint(3, 3), backendWindowLoc);
	UKPointsEqual(backendWindowLoc, [evt locationInWindowItem]);
#ifdef GNUSTEP
	UKPointsNotEqual([evt locationInWindowContentItem], [evt locationInWindowItem]);
#else /* bottom window border is O px on Mac OS X */
	UKPointsEqual([evt locationInWindowContentItem], [evt locationInWindowItem]);
#endif
}

- (void) testCreateEventAtContentPoint
{
	ETEvent *evt = [self createEventAtContentPoint: NSZeroPoint clickCount: 1 inWindow: [self window]];
	ETWindowItem *windowItem = [mainItem windowItem]; 

	UKPointsEqual(NSZeroPoint, [evt locationInWindowContentItem]);
	UKPointsEqual([windowItem convertDecoratorPointFromContent: NSZeroPoint], [evt locationInWindowItem]);

	NSPoint p1 = NSZeroPoint;
	NSPoint p2 = [[[self window] contentView] convertPoint: p1 toView: nil];

	[mainItem setFlipped: NO];
	UKFalse([[[self window] contentView] isFlipped]);
	UKPointsNotEqual(p2, [[[self window] contentView] convertPoint: p1 toView: nil]);
} 

- (void) testHitTest
{

	ETEvent *evtWithoutWindow = [self createEventAtPoint: NSZeroPoint clickCount: 1 inWindow: nil];
	/* Because -locationInWindowContentItem and -locationInWindowItem will 
	   automatically convert/correct -locationInWindow when the content view
	   uses flipped coordinates, we have to express the event point in 
	   non-flipped coordinates. */
	//ETEvent *evtTitleBar = MAKE_EVENT(NSMakePoint(3, -5), YES, [self window]);
	//ETEvent *evtCloseToTitleBar = [self createEventAtContentPoint: NSMakePoint(3, -([self titleBarHeight] + 1))];

	UKObjectsSame([itemFactory windowGroup], [tool hitTestWithEvent: evtWithoutWindow]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(4, 4)]);

	//UKObjectsSame(mainItem, [tool hitTestWithEvent: evtTitleBar]);
	//UKObjectsSame([itemFactory windowGroup], [tool hitTestWithEvent: evtCloseToTitleBar]);
}

- (void) testHitTestInWindowLayer
{
	// NOTE: [[ETApp mainMenu] menuBarHeight]; returns 0 because there is no 
	// menu bar with ukrun and a test bundle.
	NSRect frame = [[NSScreen mainScreen] frame];
	// TODO: Use [[NSScreen mainScreen] visibleFrame]; on GNUstep once 
	// improved as explained in -rootWindowFrame.
	NSRect visibleFrame = [(ETWindowLayer *)[itemFactory windowGroup] rootWindowFrame];
	CGFloat menuBarHeight = frame.size.height - (visibleFrame.size.height + visibleFrame.origin.y);
	ETEvent *evt = [self createEventAtScreenPoint: NSMakePoint(600, menuBarHeight) isFlipped: YES];

	UKObjectsSame([itemFactory windowGroup], [tool hitTestWithEvent: evt]);
	UKObjectsSame([itemFactory windowGroup], [evt layoutItem]);
	UKPointsEqual(NSMakePoint(600, 0), [evt locationInLayoutItem]);

	UKObjectsSame([itemFactory windowGroup], [tool hitTestWithEvent: EVT(-100, -100)]);
}

// TODO: Finish to implement or remove
- (void) testHitTestInWindowLayerWithCustom
{
	/*[layer setLayout: [ETFreeLayout layout]];

	ETTool *tool = [[layer layout] attachedTool];
	
	UKObjectKindOf(tool, ETSelectTool);
	UKObjectsSame([ETTool activeTool], [[layer layout] attachedTool]);*/	
}

/* This method test we react precisely as NSView to pointer events that happen on 
a layout item edges. A hit test exactly on an item bottom or right edge should 
result in a hit on the item beneath. If the hit test is inset by one pixel on 
a single edge or both, then the hit is on the item to which the edges belong to.  
See -[NSView mouse:inRect:]. 

An F-script session is pasted at the file end to understand that more easily. */
- (void) testHitTestBoundaryDetection
{
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	[mainItem addItem: item1];

	UKTrue([mainItem isFlipped]);
	// FIXME: Problem inside -contentItemForEvent:
	//UKObjectsSame(item1, [tool hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(0, 1)]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(50, 99)]); /* Right on item1 right edge */
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(49, 100)]); /* Right on item1 bottom edge */
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(49, 101)]);

	[mainItem setFlipped: NO];
	//UKObjectsSame([mainItem parentItem], [tool hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(0, 1)]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(50, 99)]); /* Right on item1 right edge */
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(49, 100)]); /* Right on item1 bottom edge */
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(49, 101)]);
}

- (void) testHitTestZOrder
{
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: NSMakeRect(5, 5, 45, 95)];
	ETLayoutItem *item2 = [itemFactory rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	ETLayoutItem *item3 = [itemFactory rectangleWithRect: NSMakeRect(5, 5, 45, 95)];

	/* Insert by Z order */
	[mainItem addItem: item2];
	[mainItem addItem: item3];

	UKObjectsSame(item2, [tool hitTestWithEvent: EVT(4, 4)]);
	UKObjectsSame(item2, [tool hitTestWithEvent: EVT(7, 7)]);
	UKObjectsSame(item2, [tool hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(mainItem, [tool hitTestWithEvent: EVT(49, 100)]); /* Right on item2 bottom edge */
	
	[item3 setHeight: 96]; /* 5 + 96 = 101 and see -testHitTestBoundaryDetection */
	UKObjectsSame(item3, [tool hitTestWithEvent: EVT(49, 100)]);

	[mainItem insertItem: item1 atIndex: 0];
	UKObjectsSame(item2, [tool hitTestWithEvent: EVT(4, 4)]);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(7, 7)]);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(item3, [tool hitTestWithEvent: EVT(49, 100)]); /* Right on item1 and item2 bottom edge */
}

- (void) testLookUpTool
{
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	[mainItem addItem: item1];

	[tool mouseDown: EVT(4, 4)];
}

- (void) testHitTestBoundingBox
{
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: NSMakeRect(0, 0, 50, 100)];

	[item1 setBoundingBox: NSInsetRect([item1 bounds], -10, -10)];
	[mainItem addItem: item1];

	/* Hit inside mainItem, outside item1 and its bounding box */
	UKObjectsEqual(mainItem, [tool hitTestWithEvent: EVT(70, 120)]);
	/* Hit inside mainItem, outside item1 but inside its bounding box */
	UKObjectsEqual(item1, [tool hitTestWithEvent: EVT(55, 105)]);
	
	/* Shift a bit item1 to have enough space to hit test between the 
	   top left corner of the mainItem and the origin of item1. */
	[item1 setOrigin: NSMakePoint(20, 20)];
	/* Hit inside mainItem, outside item1 and its bounding box */
	UKObjectsEqual(mainItem, [tool hitTestWithEvent: EVT([item1 x] - 15, [item1 y] - 15)]);
	/* Hit inside mainItem, outside item1 but inside its bounding box */
	UKObjectsEqual(item1, [tool hitTestWithEvent: EVT([item1 x] - 5, [item1 y] - 5)]);
}

/* Verify that hit test only continues recursively when the event location is 
inside the content bounds. */
- (void) testHitTestOutsideItemFrame
{
	CGFloat width = [mainItem width] + 20;
	CGFloat height = [mainItem height] + 20;
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: NSInsetRect([mainItem bounds], -20, -20)];

	[mainItem addItem: item1];

	/* Hit outside mainItem and inside item1 */
	UKObjectsEqual([itemFactory windowGroup], [tool hitTestWithEvent: EVT(width - 5, height - 5)]);
	
	/* Shift a bit the mainItem to have enough space to hit test between the 
	   top left corner of the window layer and the origin of the main item. */
	[mainItem setOrigin: NSMakePoint(30, 30)];
	/* Hit outside mainItem and inside item1 */
	ETEvent *evt = [self createEventAtScreenPoint: NSMakePoint([mainItem x] - 5, [mainItem y] - 5) isFlipped: YES];
	UKObjectsEqual([itemFactory windowGroup], [tool hitTestWithEvent: evt]);
	
	[mainItem setBoundingBox: NSMakeRect(-10, -10, [mainItem width] + 10, [mainItem height] + 10)];
	/* Hit outside mainItem but inside its bounding box, and outside item1 but 
	   inside its bounding box  */
	evt = [self createEventAtScreenPoint: NSMakePoint([mainItem x] - 5, [mainItem y] - 5) isFlipped: YES];
	// FIXME: UKObjectsEqual(mainItem, [tool hitTestWithEvent: evt]);
	// See TODO comment in -hitTestWithEvent:
}

/* Verify that hit test only continues recursively when the event location is 
inside the content bounds. */
- (void) testHitTestDecorator
{
	NSRect contentRect = NSMakeRect(0, 0, 2000, 3000);
	ETLayoutItem *item1 = [itemFactory rectangleWithRect: contentRect];

	[mainItem addItem: item1];
	[mainItem setHasVerticalScroller: YES];
	[mainItem setHasHorizontalScroller: YES];
	// FIXME: The precondition won't work without a layout or if we move 
	// -setLayout: before the two previous lines.
	[mainItem setLayout: [ETLineLayout layoutWithObjectGraphContext: [mainItem objectGraphContext]]];
	[mainItem updateLayoutIfNeeded];

	/* Precondition */
	UKRectsEqual(contentRect, [mainItem contentBounds]);

	/* Hit inside scrollers */
	// FIXME: -setHasVerticalScroller: removes the window decorator.
	//UKObjectsEqual(mainItem, [tool hitTestWithEvent: EVT([mainItem width] - 5, [mainItem height] - 5)]);
}

- (void) testTrySendEventToWidget
{
	NSRect contentRect = NSMakeRect(0, 0, 2000, 3000);
	/* We create item1 to be able to safely ignore the window decorator that 
	   exist on mainItem in our tests */
	ETLayoutItemGroup *item1 = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 200, 100)];
	ETLayoutItem *item2 = [itemFactory rectangleWithRect: contentRect];

	[mainItem addItem: item1];
	[item1 addItem: item2];
	[item1 setHasVerticalScroller: YES];
	[item1 setHasHorizontalScroller: YES];
#ifndef GNUSTEP
	/* To turn off the new scroller style on Mac OS X 10.7 and above */
	[[[[item1 scrollableAreaItem] scrollView] ifResponds] setScrollerStyle: NSScrollerStyleLegacy];
#endif

	[mainItem updateLayout];

	/* Hit inside the scrollers */
#ifdef GNUSTEP
	// NOTE: Scroller buttons are on the left side of the window on GNUstep.
	// Moreover we have to synthetize a mouse up event otherwise the run loop 
	// gets stuck waiting a mouse up event to exit -trackMouse:inRect:ofView:.
	ETEvent *evt = EVT(5, [item1 height] - 5);
	[NSApp postEvent: [NSEvent mouseEventWithType: NSLeftMouseUp
	                                     location: [(NSEvent *)[evt backendEvent] locationInWindow]
	                                modifierFlags: 0
                                            timestamp: [NSDate timeIntervalSinceReferenceDate]
	                                 windowNumber: [evt windowNumber]
	                                      context: [NSGraphicsContext currentContext]
	                                  eventNumber: 0
	                                   clickCount: 1
	                                     pressure: 0.0] atStart: NO];
#else
	ETEvent *evt = EVT([item1 width] - 5, [item1 height] - 5);
#endif

	[tool trySendEventToWidgetView: evt];

	UKTrue([evt wasDelivered]);
	UKObjectsEqual(item1, [evt layoutItem]);

	 /* Hit inside the scrollable content */
	evt = EVT(50, 50);
	[tool trySendEventToWidgetView: evt];

	UKFalse([evt wasDelivered]);
	UKObjectsEqual(item2, [evt layoutItem]);
	
	/* Hit outside item1 */
	evt = EVT([item1 width] + 25, [item1 height] + 25);
	[tool trySendEventToWidgetView: evt];

	UKFalse([evt wasDelivered]);
	UKObjectsEqual(mainItem, [evt layoutItem]);
	
	/* Hit outside item1 but inside its bounding box

	   We want to be sure we won't hit item2 whose extent (2000, 3000) 
	   intersects the item2 bounding box outside the scrollable area item. 
	   At the drawing level, the scrollable area item clips the item2. At the 
	   event handling level, the hit test phase implemented by EtoileUI must 
	   behave similarly. */
	[item1 setBoundingBox: NSMakeRect(0, 0, [item1 width] + 30, [item1 height] + 30)];
	evt = EVT([item1 width] + 25, [item1 height] + 25);
	[tool trySendEventToWidgetView: evt];

	UKFalse([evt wasDelivered]);
	UKObjectsEqual(item1, [evt layoutItem]);
}

@end

/* Addendum F-Script session on NSView hit test:

> v := NSView alloc initWithFrame: (0<>0 extent:50<>100)

> z := NSView alloc initWithFrame: (0<>0 extent: 100<>200)

> z addSubview: v

> v hitTest: (0<>0)
nil

> v hitTest: (0<>1)
<NSView: 0x15c32890>

> v hitTest: (0<>99)
<NSView: 0x15c32890>

> v hitTest: (0<>100)
<NSView: 0x15c32890>

> v hitTest: (0<>101)
nil

> s := NSSlider alloc initWithFrame: (0<>0 extent:100<>200)

> s isFlipped
true

> s addSubview: v

> v hitTest: (0<>0)
<NSView: 0x15c32890>

> v hitTest: (0<>1)
<NSView: 0x15c32890>

> v hitTest: (0<>99)
<NSView: 0x15c32890>

> v hitTest: (0<>100)
nil

> v hitTest: (0<>101)
nil */
