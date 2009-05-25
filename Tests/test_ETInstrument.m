/*
	test_ETInstrument.m

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETHandle.h"
#import "ETInstrument.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Factory.h"
#import "ETCompatibility.h"
#import <UnitKit/UnitKit.h>
#define _ISOC99_SOURCE 
#include <math.h>

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface BasicEventTest : NSObject <UKTest>
{
	ETLayoutItemGroup *mainItem;
	ETInstrument *instrument;
}

@end

#define WIN_WIDTH 300
#define WIN_HEIGHT 200

/* Verify that AppKit does not check whether the content view uses flipped 
coordinates or not to set the event location in the window. */
@implementation BasicEventTest

- (id) init
{
	SUPERINIT

	ASSIGN(mainItem, [ETLayoutItem itemGroupWithContainer]);
	[mainItem setFrame: NSMakeRect(0, 0, WIN_WIDTH, WIN_HEIGHT)];
	[[ETLayoutItem windowGroup] addItem: mainItem];
	ASSIGN(instrument, [ETInstrument instrument]);

	return self;
}

DEALLOC(DESTROY(mainItem); DESTROY(instrument))

- (NSWindow *) window
{
	return [[mainItem windowDecoratorItem] window];
}

- (ETEvent *) createEventAtPoint: (NSPoint)loc inWindow: (NSWindow *)win
{
	NSParameterAssert(loc.x != NAN && loc.y != NAN);
	NSEvent *backendEvent = [NSEvent mouseEventWithType: NSLeftMouseDown
	                                           location: loc
	                                      modifierFlags: 0 
	                                          timestamp: [NSDate timeIntervalSinceReferenceDate]
	                                       windowNumber: [win windowNumber]
	                                            context: [NSGraphicsContext currentContext] 
	                                        eventNumber: 0
                                             clickCount: 1 
	                                           pressure: 0.0];
	
	UKObjectsSame(win, [backendEvent window]); /* Paranoid check */

	return ETEVENT(backendEvent, nil, ETNonePickingMask);
}

- (ETEvent *) createEventAtContentPoint: (NSPoint)loc inWindow: (NSWindow *)win
{
	NSPoint p = loc;

	if (win != nil)
	{
		/* -convertPoint:toView: takes cares to flip p properly by checking it 
		   the content view vs the window */
		p = [[win contentView] convertPoint: p toView: nil];
	}	

	return [self createEventAtPoint: p inWindow: win];
}

- (ETEvent *) createEventAtScreenPoint: (NSPoint)loc isFlipped: (BOOL)flip
{
	NSPoint p = loc;

	if (flip)
	{
		p.y = [[NSScreen mainScreen] frame].size.height - p.y;
	}

	return [self createEventAtPoint: p inWindow: nil];
}

/* Uses EVT, MAKE_EVENT or MAKE_EVENT_IN if you want to create an event with 
a point expressed in the main item coordinates. The main item is the window content. */
#define MAKE_EVENT_IN(p1, w) [self createEventAtContentPoint: p1 inWindow: w]
#define MAKE_EVENT(p2) MAKE_EVENT_IN(p2, [self window])
#define EVT(x, y) MAKE_EVENT(NSMakePoint(x, y))

- (void) testLocationInWindow
{
	ETEvent *evt = [self createEventAtPoint: NSMakePoint(3, 3) inWindow: [self window]];
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
	float windowItemLocY = [[self window] frame].size.height - backendWindowLoc.y; 
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
	ETEvent *evt = [self createEventAtContentPoint: NSZeroPoint inWindow: [self window]];
	ETWindowItem *windowItem = [mainItem windowDecoratorItem]; 

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

	ETEvent *evtWithoutWindow = [self createEventAtPoint: NSZeroPoint inWindow: nil];
	/* Because -locationInWindowContentItem and -locationInWindowItem will 
	   automatically convert/correct -locationInWindow when the content view
	   uses flipped coordinates, we have to express the event point in 
	   non-flipped coordinates. */
	//ETEvent *evtTitleBar = MAKE_EVENT(NSMakePoint(3, -5), YES, [self window]);
	//ETEvent *evtCloseToTitleBar = [self createEventAtContentPoint: NSMakePoint(3, -([self titleBarHeight] + 1))];

	UKObjectsSame([ETLayoutItem windowGroup], [instrument hitTestWithEvent: evtWithoutWindow]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(4, 4)]);

	//UKObjectsSame(mainItem, [instrument hitTestWithEvent: evtTitleBar]);
	//UKObjectsSame([ETLayoutItem windowGroup], [instrument hitTestWithEvent: evtCloseToTitleBar]);
}

- (void) testHitTestInWindowLayer
{
	BOOL isFullScreenFrame = NSEqualRects([[NSScreen mainScreen] visibleFrame], [[NSScreen mainScreen] frame]);
	float menuBarHeight = (isFullScreenFrame ? 0 : [[ETApp mainMenu] menuBarHeight]);
	ETEvent *evt = [self createEventAtScreenPoint: NSMakePoint(600, menuBarHeight) isFlipped: YES];

	UKObjectsSame([ETLayoutItem windowGroup], [instrument hitTestWithEvent: evt]);
	UKObjectsSame([ETLayoutItem windowGroup], [evt layoutItem]);
	UKPointsEqual(NSMakePoint(600, 0), [evt locationInLayoutItem]);

	UKObjectsSame([ETLayoutItem windowGroup], [instrument hitTestWithEvent: EVT(-100, -100)]);
}

// TODO: Finish to implement or remove
- (void) testHitTestInWindowLayerWithCustom
{
	/*[layer setLayout: [ETFreeLayout layout]];

	ETInstrument *instrument = [[layer layout] attachedInstrument];
	
	UKObjectKindOf(instrument, ETSelectTool);
	UKObjectsSame([ETInstrument activeInstrument], [[layer layout] attachedInstrument]);*/	
}

/* This method test we react precisely as NSView to pointer events that happen on 
a layout item edges. A hit test exactly on an item bottom or right edge should 
result in a hit on the item beneath. If the hit test is inset by one pixel on 
a single edge or both, then the hit is on the item to which the edges belong to.  
See -[NSView mouse:inRect:]. 

An F-script session is pasted at the file end to understand that more easily. */
- (void) testHitTestBoundaryDetection
{
	ETLayoutItem *item1 = [ETLayoutItem rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	[mainItem addItem: item1];

	UKTrue([mainItem isFlipped]);
	// FIXME: Problem inside -contentItemForEvent:
	//UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(0, 1)]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(50, 99)]); /* Right on item1 right edge */
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(49, 100)]); /* Right on item1 bottom edge */
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(49, 101)]);

	[mainItem setFlipped: NO];
	//UKObjectsSame([mainItem parentItem], [instrument hitTestWithEvent: EVT(0, 0)]);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(0, 1)]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(50, 99)]); /* Right on item1 right edge */
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(49, 100)]); /* Right on item1 bottom edge */
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(49, 101)]);
}

- (void) testHitTestZOrder
{
	ETLayoutItem *item1 = [ETLayoutItem rectangleWithRect: NSMakeRect(5, 5, 45, 95)];
	ETLayoutItem *item2 = [ETLayoutItem rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	ETLayoutItem *item3 = [ETLayoutItem rectangleWithRect: NSMakeRect(5, 5, 45, 95)];

	/* Insert by Z order */
	[mainItem addItem: item2];
	[mainItem addItem: item3];

	UKObjectsSame(item2, [instrument hitTestWithEvent: EVT(4, 4)]);
	UKObjectsSame(item2, [instrument hitTestWithEvent: EVT(7, 7)]);
	UKObjectsSame(item2, [instrument hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(mainItem, [instrument hitTestWithEvent: EVT(49, 100)]); /* Right on item2 bottom edge */
	
	[item3 setHeight: 96]; /* 5 + 96 = 101 and see -testHitTestBoundaryDetection */
	UKObjectsSame(item3, [instrument hitTestWithEvent: EVT(49, 100)]);

	[mainItem insertItem: item1 atIndex: 0];
	UKObjectsSame(item2, [instrument hitTestWithEvent: EVT(4, 4)]);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(7, 7)]);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(49, 99)]);
	UKObjectsSame(item3, [instrument hitTestWithEvent: EVT(49, 100)]); /* Right on item1 and item2 bottom edge */
}

- (void) testLookUpInstrument
{
	ETLayoutItem *item1 = [ETLayoutItem rectangleWithRect: NSMakeRect(0, 0, 50, 100)];
	[mainItem addItem: item1];

	ETInstrument *activeInstrument = [ETInstrument activeInstrument];

	[activeInstrument mouseDown: EVT(4, 4)];
	
}

@end


@interface ETFreeLayoutEventTest : BasicEventTest
{
	ETLayoutItemGroup *rootItem;
	ETLayoutItem *item1;
	ETLayoutItemGroup *item2;
	ETLayoutItem *item21;
}

@end

@implementation ETFreeLayoutEventTest

- (id) init
{
	SUPERINIT

	[mainItem setLayout: [ETFreeLayout layout]];
	ASSIGN(instrument, [[mainItem layout] attachedInstrument]);
	ASSIGN(rootItem, [[mainItem layout] rootItem]);
	ASSIGN(item1, [ETLayoutItem rectangleWithRect: NSMakeRect(50, 30, 50, 30)]);
	ASSIGN(item2, [ETLayoutItem graphicsGroup]);
	[item2 setFrame: NSMakeRect(0, 0, 100, 50)];
	ASSIGN(item21, [ETLayoutItem rectangleWithRect: NSMakeRect(10, 10, 80, 30)]);
	
	[mainItem addItem: item1];
	[item2 addItem: item21]; /* Test methods insert item2 as they want */

	return self;
}

DEALLOC(DESTROY(rootItem); DESTROY(item1); DESTROY(item2); DESTROY(item21))

- (void) testFreeLayoutInit
{
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKObjectKindOf([item2 layout], ETFreeLayout);
}

- (void) testShowAndHideHandles
{
	[item1 setSelected: YES];

	UKIntsEqual(1, [rootItem numberOfItems]);
	[item1 setSelected: NO];
	UKIntsEqual(0, [rootItem numberOfItems]);	
}

- (void) testShowAndHideHandlesInTree
{
	[item1 setSelected: YES];
	[mainItem addItem: item2];
	[item2 setSelected: YES];
	[item21 setSelected: YES];

	UKIntsEqual(2, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] rootItem] numberOfItems]);	
	
	[item2 setSelected: NO];
	UKIntsEqual(1, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] rootItem] numberOfItems]);

	[item21 setSelected: NO];
	UKIntsEqual(0, [[[item2 layout] rootItem] numberOfItems]);
}

- (void) testHitTestHandle
{
	[item1 setSelected: YES];

	ETResizeRectangle *handleGroup1 = (ETResizeRectangle *)[rootItem firstItem];
	ETHandle *handle1 = [handleGroup1 topLeftHandle];

	UKObjectKindOf(handleGroup1, ETResizeRectangle);
	UKObjectsSame(item1, [instrument hitTestWithEvent: EVT(75, 45)]);
	UKObjectsSame(handle1, [instrument hitTestWithEvent: EVT(47, 27)]);
	UKObjectsSame(handle1, [instrument hitTestWithEvent: EVT(50, 30)]);
	UKObjectsSame(handle1, [instrument hitTestWithEvent: EVT(53, 33)]);
}

- (void) testHitTestHandleWithoutFlip
{
	[mainItem setFlipped: NO];
	[self testHitTestHandle];
}

- (void) testHitTestHandleInTree
{
	[mainItem addItem: item2];

	[item1 setSelected: YES];
	[item2 setSelected: YES];
	[item21 setSelected: YES];

	UKIntsEqual(2, [rootItem numberOfItems]);

	ETResizeRectangle *handleGroup1 = (ETResizeRectangle *)[rootItem firstItem];
	ETResizeRectangle *handleGroup2 = (ETResizeRectangle *)[rootItem itemAtIndex: 1];
	ETHandle *handle2 = [handleGroup2 topRightHandle];

	UKObjectsSame([handleGroup1 topLeftHandle], [instrument hitTestWithEvent: EVT(47, 27)]);
	UKObjectsSame([handleGroup1 bottomRightHandle], [instrument hitTestWithEvent: EVT(103, 63)]);
	UKObjectsSame(handle2, [instrument hitTestWithEvent: EVT(97, 3)]);
	UKObjectsSame(handle2, [instrument hitTestWithEvent: EVT(100, 3)]);
	UKObjectsSame(handle2, [instrument hitTestWithEvent: EVT(103, 3)]);
	UKObjectsSame(handle2, [instrument hitTestWithEvent: EVT(103, 3)]);
}

- (void) testHitTestHandleInTreeWithoutFlip
{
	[mainItem setFlipped: NO];
	// FIXME: Work that out...
	//[self testHitTestHandleInTree];
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
