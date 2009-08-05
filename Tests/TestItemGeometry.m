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
#import "ETUIItemFactory.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define UKSizesNotEqual(x, y) UKFalse(NSEqualSizes(x, y))

@implementation ETLayoutItem (TestItemGeometry)

/* For test, patch the framework implementation. */
+ (NSRect) defaultItemRect
{
	return NSMakeRect(100, 50, 300, 250);
}

@end

@interface TestItemGeometry : NSObject <UKTest>
{
	ETUIItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestItemGeometry

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETUIItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

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
	
	[item setView: nil];
	
	UKIntsEqual(NSViewNotSizable, [item autoresizingMask]);
	UKIntsEqual(NSViewNotSizable, [[item supervisorView] autoresizingMask]);
}

static unsigned int weirdMask = (NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable);

- (void) testAutoresizingMaskWithView
{
	[item setView: [self textFieldWithAutoresizingMask: weirdMask]];

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
	[item setView: [self textFieldWithAutoresizingMask: NSViewMaxXMargin]];
	[item setView: nil];
	[item setAutoresizingMask: NSViewMinYMargin];
	
	UKIntsEqual(NSViewMinYMargin, [[item supervisorView] autoresizingMask]);

	[item setSupervisorView: nil];
	
	UKIntsEqual(NSViewMinYMargin, [item autoresizingMask]);
}

- (void) testInvalidSetAutoresizingMask
{
	[item setView: [self textFieldWithAutoresizingMask: NSViewMaxXMargin]];	
	/* Framework user must never do that */
	[[item supervisorView] setAutoresizingMask: sizableMask];
	
	UKIntsNotEqual([item autoresizingMask], [[item supervisorView] autoresizingMask]);
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
	UKRectsEqual(rect, [item decorationRect]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
}

- (void) testDummyDecoratorGeometry
{
	ETDecoratorItem *decorator1 = [ETDecoratorItem item];
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
}

- (void) testScrollDecoratorGeometry
{
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: scrollDecorator];
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
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]); /* See -[ETDecoratorItem contentRect] doc */
}

- (void) testTooManyDecoratorGeometry
{
	ETWindowItem *windowDecorator = [ETWindowItem item];
	ETScrollableAreaItem *scrollDecorator = [ETScrollableAreaItem item];
	NSRect rect = [ETLayoutItem defaultItemRect];

	[item setDecoratorItem: scrollDecorator];
	[scrollDecorator setDecoratorItem: windowDecorator];

	UKRectsEqual([windowDecorator contentRect], [scrollDecorator decorationRect]);
	UKRectsEqual(rect, [scrollDecorator contentRect]);
	UKRectsNotEqual([scrollDecorator contentRect], [scrollDecorator visibleContentRect]);
	UKSizesEqual(rect.size, [windowDecorator decorationRect].size);
	UKSizesEqual(rect.size, [item size]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [item contentBounds]);
	UKRectsEqual([scrollDecorator contentRect], [item decorationRect]);
}

// TODO: Test the boundingBox in -testXXXGeometrySynchronization once we really 
// worked out the way it should behave

- (void) checkGeometrySynchronizationWithFrame: (NSRect)newFrame 
	oldItemOrigin: (NSPoint)oldOrigin oldItemPosition: (NSPoint)oldPosition
{
	UKRectsEqual(newFrame, [item frame]);
	UKPointsEqual(newFrame.origin, [item origin]);
	UKSizesEqual(newFrame.size, [item size]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, newFrame.size), [item contentBounds]);
	NSPoint newOrigin = newFrame.origin;
	NSPoint originDelta = NSMakePoint(newOrigin.x - oldOrigin.x, newOrigin.y - oldOrigin.y);
	NSPoint newPosition = ETSumPoint(oldPosition, originDelta);
	UKPointsEqual(newPosition, [item position]);

	UKRectsEqual(newFrame, [item decorationRect]);
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

	[item setView: slider]; /* Will insert a supervisor view */

	[self checkGeometrySynchronizationWithFrame: sliderFrame 
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
}

/* Verify that moving or resizing the supervisor view is replicated on the 
layout item internal geometry (contentBounds and position). */
- (void) testSupervisorViewToItemGeometrySynchronization
{
	[item setView: AUTORELEASE([[NSSlider alloc] init])];

	NSPoint oldPosition = [item position];
	NSPoint oldOrigin = [item origin];
	NSRect newFrame = NSMakeRect(500, 700, 30, 40);

	/* Important preconditions */
	UKPointsNotEqual([item origin], newFrame.origin);
	UKSizesNotEqual([item size], newFrame.size);

	[[item supervisorView] setFrame: newFrame];

	[self checkGeometrySynchronizationWithFrame: newFrame
		oldItemOrigin: oldOrigin oldItemPosition: oldPosition];
}

@end
