/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETScrollableAreaItem.h"
#import "ETUIItem.h"
#import "ETLayoutItemFactory.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define UKSizesNotEqual(x, y) UKFalse(NSEqualSizes(x, y))

@interface ETLayoutItem (Private)
- (void) setViewAndSync: (NSView *)newView;
@end

@implementation ETLayoutItem (TestItemGeometry)

/* For test, patch the framework implementation. */
+ (NSRect) defaultItemRect
{
	return NSMakeRect(100, 50, 300, 250);
}

@end

@interface ETDecoratorItem (TestItemGeometry)
+ (ETDecoratorItem *) itemWithDummySupervisorView;
@end

@implementation ETDecoratorItem (TestItemGeometry)

/* For test, patch the framework implementation. */
+ (ETDecoratorItem *) itemWithDummySupervisorView
{
	ETView *view = AUTORELEASE([[ETView alloc] init]);
	return AUTORELEASE([[ETDecoratorItem alloc] initWithSupervisorView: view]);
}

@end

@interface TestItemGeometry : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestItemGeometry

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testNewSupervisorViewWithFrame
{
	NSRect frame = NSMakeRect(-300, 20, 500, 50);
	ETView *view = AUTORELEASE([[ETView alloc] initWithFrame: frame item: nil]);

	UKRectsEqual(frame, [view frame]);
	UKRectsEqual(frame, [[view layoutItem] frame]);
}

static unsigned int sizableMask = (NSViewWidthSizable | NSViewHeightSizable);

- (void) testAutoresizingMaskWithoutView
{
	UKIntsEqual(NSViewNotSizable, [item autoresizingMask]);

	[item setAutoresizingMask: sizableMask];
	
	UKIntsEqual(sizableMask, [item autoresizingMask]);
}

- (NSTextField *) textFieldWithAutoresizingMask: (unsigned int)aMask
{
	NSTextField *textField = AUTORELEASE([[NSTextField alloc] init]);
	[textField setAutoresizingMask: aMask];
	return textField;
}

- (void) checkViewAutoresizingMask: (unsigned int)initialMask 
{
	UKIntsEqual(initialMask, [item autoresizingMask]);
	UKIntsEqual(initialMask, [[item supervisorView] autoresizingMask]);
	UKIntsEqual(sizableMask, [[item view] autoresizingMask]);
	
	[item setViewAndSync: nil];
	
	UKIntsEqual(initialMask, [item autoresizingMask]);
	UKIntsEqual(initialMask, [[item supervisorView] autoresizingMask]);
}

static unsigned int weirdMask = (NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable);

- (void) testAutoresizingMaskWithView
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: weirdMask]];

	[self checkViewAutoresizingMask: weirdMask];
}

/* Test that ETLayoutItem handles the initialization properly since -setView: 
and -setAutoresizingMask: can potentially erase each other. */
- (void) testAutoresizingMaskWithViewFromFactory
{
	NSTextField *textField = [self textFieldWithAutoresizingMask: weirdMask];

	ASSIGN(item, [itemFactory itemWithView: textField]);
	[self checkViewAutoresizingMask: weirdMask];

	// TODO: We should probably set an autoresizing mask on returned widget item.
	/*ASSIGN(item, [itemFactory textField]);						   
	[self checkViewAutoresizingMask: sizableMask];*/
}

- (void) testAutoresizingMaskForSupervisorViewRemoval
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: NSViewMaxXMargin]];
	[item setViewAndSync: nil];
	[item setAutoresizingMask: NSViewMinYMargin];
	
	UKIntsEqual(NSViewMinYMargin, [[item supervisorView] autoresizingMask]);

	[item setSupervisorView: nil];
	
	UKIntsEqual(NSViewMinYMargin, [item autoresizingMask]);
}

- (void) testInvalidSetAutoresizingMask
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: NSViewMaxXMargin]];	
	/* Framework user must never do that */
	[[item supervisorView] setAutoresizingMask: sizableMask];
	
	UKIntsNotEqual([item autoresizingMask], [[item supervisorView] autoresizingMask]);
}

- (void) testAutoresizingMaskWithDecoratorItem
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: weirdMask]];
	[item setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];

	UKIntsEqual(weirdMask, [item autoresizingMask]);
	UKTrue(weirdMask == [item autoresizingMask]);
	UKIntsEqual(sizableMask, [[item supervisorView] autoresizingMask]);
	UKIntsEqual(sizableMask, [[item view] autoresizingMask]);
	UKIntsEqual(weirdMask, [[[item decoratorItem] supervisorView] autoresizingMask]);
}

- (void) testAutoresizingMaskForDecoratorItemRemoval
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: weirdMask]];
	[item setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	[item setDecoratorItem: nil];

	UKIntsEqual(weirdMask, [item autoresizingMask]);
	UKIntsEqual(weirdMask, [[item supervisorView] autoresizingMask]);
	UKIntsEqual(sizableMask, [[item view] autoresizingMask]);
}

- (void) testAutoresizingMaskWithScrollableAreaItem
{
	[item setViewAndSync: [self textFieldWithAutoresizingMask: weirdMask]];
	[item setDecoratorItem: [ETScrollableAreaItem item]];

	UKIntsEqual(weirdMask, [item autoresizingMask]);
	UKIntsEqual(NSViewNotSizable, [[item supervisorView] autoresizingMask]);
	UKIntsEqual(sizableMask, [[item view] autoresizingMask]);
	UKIntsEqual(weirdMask, [[[item decoratorItem] supervisorView] autoresizingMask]);
}

- (void) testConvertRectToParent
{
	[[itemFactory itemGroup] addItem: item];
	[item setOrigin: NSMakePoint(5, 2)];
	
	NSRect newRect = [item convertRectToParent: NSMakeRect(0, 0, 10, 20)];
	UKIntsEqual(5, newRect.origin.x);
	UKIntsEqual(2, newRect.origin.y);
	
	newRect = [item convertRectToParent: NSMakeRect(50, 100, 10, 20)];
	
	UKIntsEqual(55, newRect.origin.x);
	UKIntsEqual(102, newRect.origin.y);

	[item setOrigin: NSMakePoint(60, 80)];	
	newRect = [item convertRectToParent: NSMakeRect(-50, -100, 10, 20)];
	
	UKIntsEqual(10, newRect.origin.x);
	UKIntsEqual(-20, newRect.origin.y);
	UKIntsEqual(10, newRect.size.width);
	UKIntsEqual(20, newRect.size.height);
}

- (void) testConvertRectFromParent
{
	[[itemFactory itemGroup] addItem: item];
	[item setOrigin: NSMakePoint(5, 2)];
	
	NSRect newRect = [item convertRectFromParent: NSMakeRect(0, 0, 10, 20)];
	UKIntsEqual(-5, newRect.origin.x);
	UKIntsEqual(-2, newRect.origin.y);
	
	newRect = [item convertRectFromParent: NSMakeRect(50, 100, 10, 20)];
	
	UKIntsEqual(45, newRect.origin.x);
	UKIntsEqual(98, newRect.origin.y);

	[item setOrigin: NSMakePoint(60, 80)];	
	newRect = [item convertRectFromParent: NSMakeRect(-50, -100, 10, 20)];
	
	UKIntsEqual(-110, newRect.origin.x);
	UKIntsEqual(-180, newRect.origin.y);
	UKIntsEqual(10, newRect.size.width);
	UKIntsEqual(20, newRect.size.height);
}

- (void) testConvertRectFromItem
{
	ETLayoutItemGroup *parent = [itemFactory itemGroupWithItem: item];	
	ETLayoutItemGroup *ancestor = [itemFactory itemGroupWithItem: parent];

	[parent setOrigin: NSMakePoint(10, 30)];	
	[item setOrigin: NSMakePoint(5, 2)];
	NSRect rect = NSMakeRect(0, 0, 10, 20);

	/* First test with an ancestor item without a parent */
	UKRectsEqual(rect, [ancestor convertRect: rect fromItem: ancestor]);
	UKRectsEqual(rect, [parent convertRect: rect fromItem: parent]);
	UKRectsEqual(ETNullRect, [item convertRect: rect fromItem: nil]);
	UKRectsEqual(ETNullRect, [item convertRect: ETNullRect fromItem: parent]);
	UKRectsEqual(NSMakeRect(-5, -2, 0, 0), [item convertRect: NSZeroRect fromItem: parent]);
	UKRectsEqual(NSMakeRect(-15, -32, 10, 20), [item convertRect: rect fromItem: ancestor]);	
}

- (void) testAnchorPoint
{
	UKPointsEqual(NSMakePoint(150, 125), [item anchorPoint]);
	UKPointsEqual(NSMakePoint(250, 175), [item position]);

	[item setAnchorPoint: NSZeroPoint];
	UKPointsEqual(NSMakePoint(250, 175), [item position]);
	UKRectsEqual(NSMakeRect(250, 175, 300, 250), [item frame]);

	[item setAnchorPoint: NSMakePoint(-50, 500)];
	UKPointsEqual(NSMakePoint(300, -325), [item origin]);

	[item setFlipped: NO]; /* Expected to have no effects here */
	UKPointsEqual(NSMakePoint(-50, 500), [item anchorPoint]);
	UKPointsEqual(NSMakePoint(250, 175), [item position]);
	UKPointsEqual(NSMakePoint(300, -325), [item origin]);
}

- (void) testBasicGeometry
{
	NSRect rect = [ETLayoutItem defaultItemRect];

	UKTrue([item isFlipped]);
	UKPointsEqual(NSMakePoint(150, 125), [item anchorPoint]);
	UKPointsEqual(NSMakePoint(250, 175), [item position]);
	UKPointsEqual(rect.origin, [item origin]);
	UKRectsEqual(rect, [item frame]);
	UKRectsEqual(rect, [item defaultFrame]);
	UKRectsEqual(rect, [item decorationRect]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
}

- (void) testDummyDecoratorGeometry
{
	ETDecoratorItem *decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: decorator1];

	UKRectsEqual(rect, [decorator1 decorationRect]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [decorator1 contentRect]);
	UKRectsEqual([decorator1 contentRect], [decorator1 visibleContentRect]);
	UKRectsEqual(rect, [item frame]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item decorationRect]);
}

- (void) testWindowDecoratorGeometry
{
	ETWindowItem *windowDecorator = [ETWindowItem item];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: windowDecorator];
	NSSize contentSize = [[[windowDecorator window] contentView] frame].size;

	UKSizesEqual(rect.size, [windowDecorator decorationRect].size);
	UKPointsNotEqual(rect.origin, [windowDecorator contentRect].origin);
	UKSizesEqual(contentSize, [windowDecorator contentRect].size);
	UKRectsEqual([windowDecorator contentRect], [windowDecorator visibleContentRect]);
	UKRectsEqual(ETMakeRect([windowDecorator decorationRect].origin, rect.size), [item frame]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, contentSize), [item contentBounds]);
	UKRectsEqual([windowDecorator contentRect], [item decorationRect]);
	/* For Cocoa, the supervisor view frame origin will be (0, 0) unlike 
	   GNUstep where windows use a border and the origin will have strictly 
	   positive values. */
	UKSizesEqual(contentSize, [[item supervisorView] frame].size);
}

- (void) testScrollDecoratorGeometry
{
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: scrollDecorator];
	
	/* Preconditions */
	UKFalse([scrollDecorator hasHorizontalScroller]);
	UKFalse([scrollDecorator hasVerticalScroller]);

	// NOTE: -[ETScrollableAreaItem scrollView] is a private method */
	NSRect contentRect = [[[(id)scrollDecorator scrollView] contentView] frame];

	UKRectsEqual(rect, [scrollDecorator decorationRect]);
	/* NSScrollView doesn't touch the document view frame, but scrolls by 
	   altering the bounds its the content view.
	   TODO: May be be nicer to override -contentRect in ETScrollableAreaItem 
	   so that the content rect origin reflects the current scroll position. */
	UKRectsEqual(rect, [scrollDecorator contentRect]);
	UKRectsEqual(contentRect, [scrollDecorator visibleContentRect]);
	UKRectsEqual(rect, [item frame]);
	/* The two tests below only holds when -ensuresContentFillsVisibleArea is YES */
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]); /* See -[ETDecoratorItem contentRect] doc */
}

- (void) testScrollDecoratorGeometryForDecorationRectResize
{
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = NSMakeRect(0, 0, 1000, 3000);

	[item setDecoratorItem: scrollDecorator];
	[scrollDecorator setDecorationRect: rect];

	// NOTE: -[ETScrollableAreaItem scrollView] is a private method */
	NSRect contentRect = [[[(id)scrollDecorator scrollView] contentView] frame];

	UKRectsEqual(rect, [scrollDecorator decorationRect]);
	UKSizesEqual(rect.size, [scrollDecorator contentRect].size);
	UKRectsEqual(contentRect, [scrollDecorator visibleContentRect]);
	UKRectsEqual(rect, [item frame]);
	/* The two tests below only holds when -ensuresContentFillsVisibleArea is YES */
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]);
}

- (void) testScrollDecoratorGeometryForScrollViewResize
{
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = NSMakeRect(0, 0, 1000, 3000);

	[item setDecoratorItem: scrollDecorator];
	/* The scroll view is never resized directly but only through its enclosing 
	   supervisor view. That's why to simulate a user resize at UI level we 
	   won't do [[scrollDecorator scrollView] setFrame: rect] */
	[[(id)scrollDecorator supervisorView] setFrame: rect];

	// NOTE: -[ETScrollableAreaItem scrollView] is a private method */
	NSRect contentRect = [[[(id)scrollDecorator scrollView] contentView] frame];

	UKRectsEqual(rect, [scrollDecorator decorationRect]);
	UKSizesEqual(rect.size, [scrollDecorator contentRect].size);
	UKRectsEqual(contentRect, [scrollDecorator visibleContentRect]);
	UKRectsEqual(rect, [item frame]);
	/* The two tests below only holds when -ensuresContentFillsVisibleArea is YES */
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]);
}

- (void) testTooManyDecoratorGeometry
{
	ETWindowItem *windowDecorator = [ETWindowItem item];
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: scrollDecorator];
	[scrollDecorator setDecoratorItem: windowDecorator];
	
	/* Preconditions */
	UKFalse([scrollDecorator hasHorizontalScroller]);
	UKFalse([scrollDecorator hasVerticalScroller]);
	
	NSRect rectMinusTitleBar = NSMakeRect(rect.origin.x, rect.origin.y, 
		rect.size.width, rect.size.height - [windowDecorator titleBarHeight]);

	UKRectsEqual([windowDecorator contentRect], [scrollDecorator decorationRect]);
	// FIXME: Should be rect and not rectMinusTitleBar. We need to check 
	// -usesLayoutBaseFrame is YES in -clipViewFrameDidChange: in order to 
	// have the right to invoke [[decoratedItem supervisorView] setFrame:].
	// Moreover this quick hack doesn't work on GNUstep the window has a border.
#ifndef GNUSTEP
	UKRectsEqual(rectMinusTitleBar, [scrollDecorator contentRect]);
#endif
	UKRectsNotEqual(rectMinusTitleBar, [scrollDecorator visibleContentRect]);
	UKSizesEqual(rect.size, [windowDecorator decorationRect].size);
	UKSizesEqual(rect.size, [item size]);
	/* The two tests below only holds when -ensuresContentFillsVisibleArea is YES */
	// FIXME: Should be rect.size and not rectMinusTitleBar.size
#ifndef GNUSTEP
	UKRectsEqual(ETMakeRect(NSZeroPoint, rectMinusTitleBar.size), [item contentBounds]);
#endif
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]);
}

// TODO: Test the boundingBox in -testXXXGeometrySynchronization once we really 
// worked out the way it should behave

- (void) checkGeometrySynchronizationWithFrame: (NSRect)frame 
                                 oldItemOrigin: (NSPoint)oldOrigin 
                               oldItemPosition: (NSPoint)oldPosition
{
	UKRectsEqual(frame, [item frame]);
	UKPointsEqual(frame.origin, [item origin]);
	UKSizesEqual(frame.size, [item size]);

	NSPoint newOrigin = frame.origin;
	NSPoint originDelta = NSMakePoint(newOrigin.x - oldOrigin.x, newOrigin.y - oldOrigin.y);
	NSPoint newPosition = ETSumPoint(oldPosition, originDelta);
	UKPointsEqual(newPosition, [item position]);
}

- (void) checkContentGeometrySynchronizationWithFrame: (NSRect)frame
{
	UKRectsEqual(ETMakeRect(NSZeroPoint, frame.size), [item contentBounds]);
	UKRectsEqual(frame, [item decorationRect]);
}

/* Verify that a lazily inserted supervisor view size and origin are replicated 
on the layout item internal geometry (contentBounds and position). */
- (void) testSetViewGeometrySynchronization
{
	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];
	NSView *slider = AUTORELEASE([[NSSlider alloc] init]);
	NSRect sliderFrame = [slider frame];

	UKRectsNotEqual([item frame], sliderFrame); /* Important precondition */

	[item setViewAndSync: slider]; /* Will insert a supervisor view */

	[self checkGeometrySynchronizationWithFrame: sliderFrame 
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
	[self checkContentGeometrySynchronizationWithFrame: sliderFrame];
}

/* Verify that moving or resizing the supervisor view is replicated on the 
layout item internal geometry (contentBounds and position). */
- (void) testSupervisorViewToItemGeometrySynchronization
{
	[item setViewAndSync: AUTORELEASE([[NSSlider alloc] init])];

	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];
	NSRect newFrame = NSMakeRect(500, 700, 30, 40);

	/* Preconditions */
	UKPointsNotEqual([item origin], newFrame.origin);
	UKSizesNotEqual([item size], newFrame.size);

	[[item supervisorView] setFrame: newFrame];

	[self checkGeometrySynchronizationWithFrame: newFrame
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
	[self checkContentGeometrySynchronizationWithFrame: newFrame];
}

/* Verify that moving or resizing the layout item is replicated on the 
supervisor view geometry (frame). */
- (void) testItemToSupervisorViewGeometrySynchronization
{
	[item setViewAndSync: AUTORELEASE([[NSSlider alloc] init])];

	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];
	NSRect newFrame = NSMakeRect(500, 700, 30, 40);

	/* Preconditions */
	UKPointsNotEqual([item origin], newFrame.origin);
	UKSizesNotEqual([item size], newFrame.size);

	[item setFrame: newFrame];

	[self checkGeometrySynchronizationWithFrame: [[item supervisorView] frame]
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
	[self checkContentGeometrySynchronizationWithFrame: [[item supervisorView] frame]];
}

/* Verify that moving or resizing a decorated layout item is replicated on the 
supervisor view geometry (frame). */
- (void) testSupervisorViewToDecoratedItemGeometrySynchronization
{
	[item setViewAndSync: AUTORELEASE([[NSSlider alloc] init])];
	[item setDecoratorItem: [ETWindowItem item]];

	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];
	NSRect newFrame = NSMakeRect(500, 700, 30, 40);

	/* Preconditions */
	UKPointsNotEqual([item origin], newFrame.origin);
	UKSizesNotEqual([item size], newFrame.size);

	[[item supervisorView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[item setFrame: newFrame];

	[self checkGeometrySynchronizationWithFrame: newFrame
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
}

- (void) testGeometrySynchronizationForDecoratorRemoval
{
	[item setViewAndSync: AUTORELEASE([[NSSlider alloc] init])];
	[item setDecoratorItem: [ETWindowItem item]];

	NSRect newFrame = NSMakeRect(500, 700, 30, 40);

	[[item supervisorView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[item setFrame: newFrame];

	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];

	[item setDecoratorItem: nil];

	[self checkGeometrySynchronizationWithFrame: newFrame 
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
}

@end


@interface ETLayoutItem (ContentAspectPrivate)
- (NSRect) contentRectWithRect: (NSRect)aRect 
                 contentAspect: (ETContentAspect)anAspect 
                    boundsSize: (NSSize)maxSize;
@end

@interface TestItemContentAspect : TestItemGeometry <UKTest>
{
	NSRect initialContentRect;
	NSSize boundsSize;
}

@end

@implementation TestItemContentAspect

- (id) init
{
	SUPERINIT
	initialContentRect = NSMakeRect(100, 50, 40, 80);
	boundsSize = NSMakeSize(200, 100);
	return self;
}

- (void) testRectForNoneContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectNone
                                 boundsSize: boundsSize];

	UKRectsEqual(initialContentRect, rect);
}

- (void) testRectForCenteredContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectCentered
                                 boundsSize: boundsSize];

	UKRectsEqual(NSMakeRect(80, 10, 40, 80), rect);
}

- (void) testRectForStrechContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectStretchToFill
                                 boundsSize: boundsSize];

	UKRectsEqual(ETMakeRect(NSZeroPoint, boundsSize), rect);
}

- (void) testRectForFillHorizontallyContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectScaleToFillHorizontally
                                 boundsSize: boundsSize];

	UKRectsEqual(NSMakeRect(0, -150, 200, 400), rect);
}

- (void) testRectForFillVerticallyContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectScaleToFillVertically
                                 boundsSize: boundsSize];

	UKRectsEqual(NSMakeRect(75, 0, 50, 100), rect);
}

- (void) testRectForFillContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectScaleToFill
                                 boundsSize: boundsSize];

	UKRectsEqual(NSMakeRect(0, -150, 200, 400), rect);
}

- (void) testRectForFitContentAspect
{
	NSRect rect = [item contentRectWithRect: initialContentRect
	                          contentAspect: ETContentAspectScaleToFit
                                 boundsSize: boundsSize];

	UKRectsEqual(NSMakeRect(75, 0, 50, 100), rect);
}

@end
