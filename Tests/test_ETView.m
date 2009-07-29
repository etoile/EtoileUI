/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */


#import <Foundation/Foundation.h>
#import <Foundation/NSDebug.h>
#import <AppKit/AppKit.h>
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETView.h"
#import "ETCompatibility.h"
#import <UnitKit/UnitKit.h>

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface ETView (UnitKitTests) <UKTest>
@end


@implementation ETView (UnitKitTests)

- (id) initForTest
{
	return [self initWithFrame: NSMakeRect(0, 0, 50, 50)];
}

- (void) testRelease
{
#ifdef GNUSTEP
	GSDebugAllocationActive(YES);
	//GSDebugAllocationActiveRecordingObjects([ETView class]);

	int allocCount = GSDebugAllocationCount([ETView class]);
	id view = [[ETView alloc] init];

	UKIntsEqual(2, [view retainCount]);
	UKIntsEqual(1, [[view layoutItem] retainCount]);
	UKIntsEqual(allocCount + 1, GSDebugAllocationCount([ETView class]));
	RELEASE(view);
	UKIntsEqual(allocCount, GSDebugAllocationCount([ETView class]));

	//ETLog(@"Recorded object allocation: %@", 
	//	GSDebugAllocationListRecordedObjects([ETView class]));

	GSDebugAllocationActive(NO);
#endif
}

- (void) testReleaseItem
{
#ifdef GNUSTEP
	GSDebugAllocationActive(YES);
	//GSDebugAllocationActiveRecordingObjects([ETView class]);

	/* Basic retain cycle check */

	int allocCount = GSDebugAllocationCount([ETLayoutItem class]);
	id view = [[ETView alloc] init];
	id item = [[ETLayoutItem alloc] init];
	[item setSupervisorView: view];

	UKIntsEqual(2, [item retainCount]);
	UKIntsEqual(2, [[item supervisorView] retainCount]);
	RELEASE(view);
	UKIntsEqual(1, [[item supervisorView] retainCount]);
	UKIntsEqual(allocCount + 1, GSDebugAllocationCount([ETLayoutItem class]));
	RELEASE(item);
	UKIntsEqual(allocCount, GSDebugAllocationCount([ETLayoutItem class]));

	/* Check retain cycle with an autoreleased item */

	CREATE_AUTORELEASE_POOL(pool1);

	view = [[ETView alloc] init];
	item = [ETLayoutItem item];
	[item setSupervisorView: view];

	UKIntsEqual(2, [item retainCount]);
	UKIntsEqual(2, [[item supervisorView] retainCount]);
	RELEASE(view);
	UKIntsEqual(1, [[item supervisorView] retainCount]);
	UKIntsEqual(allocCount + 1, GSDebugAllocationCount([ETLayoutItem class]));
	DESTROY(pool1);
	UKIntsEqual(allocCount, GSDebugAllocationCount([ETLayoutItem class]));

	/* Check retain cycle with an item owned by a parent */

	CREATE_AUTORELEASE_POOL(pool2);

	allocCount = GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class]);
	view = [[ETView alloc] init];
	item = [[ETLayoutItem alloc] init];
	[item setSupervisorView: view];
	id parent = [[ETLayoutItemGroup alloc] init];

	[parent addItem: item];

	/* Now parent and [parent superview] retains respectively item and 
	   [item supervisorView].
	   Although parent has no supervisor view initially, one was lazily 
	   instantiated to insert [item supervisorView] as a subview on 
	   -addItem:. */
	UKIntsEqual(3, [item retainCount]);
	UKIntsEqual(3, [[item supervisorView] retainCount]);
	UKIntsEqual(2, [parent retainCount]); /* Not retained by item */
	RELEASE(view);
	UKIntsEqual(2, [[item supervisorView] retainCount]);
	UKIntsEqual(allocCount + 2, GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class]));
	RELEASE(parent);
	RELEASE(item);
	UKIntsEqual(allocCount, GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class]));

	/* Check release of a complex layout item tree */

	CREATE_AUTORELEASE_POOL(pool3);

	allocCount = GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class])
		+ GSDebugAllocationCount([ETView class]);
	id view1 = [[ETView alloc] init];
	id view2 = AUTORELEASE([[ETView alloc] init]);
	item = [[ETLayoutItem alloc] init];
	[item setSupervisorView: view2];
	parent = [[ETLayoutItemGroup alloc] init];
	[parent setSupervisorView: view1];
	id ancestor = [ETLayoutItem itemGroup];

	[ancestor addItem: parent];	
	[parent addItem: item]; /* Inserts view2 into view1 */

	UKIntsEqual(3, [item retainCount]); /* Retained by view2 and parent */
	UKIntsEqual(3, [view2 retainCount]); /* Retained by item and view1 (parent supervisor view) */
	UKIntsEqual(3, [parent retainCount]); /* Retained by view1 and ancestor */
	UKIntsEqual(3, [view1 retainCount]); /* Retained by parent and ancestor supervisor view  */
	UKIntsEqual(2, [ancestor retainCount]); /* Retained by its supervisor view (lazily created) */

	RELEASE(view1);
	UKIntsEqual(2, [view1 retainCount]);
	UKIntsEqual(3, [item retainCount]);

	RELEASE(item);
	RELEASE(parent);
	UKIntsEqual(2, [item retainCount]);
	UKIntsEqual(3, [view2 retainCount]);
	UKIntsEqual(2, [parent retainCount]);
	UKIntsEqual(2, [view1 retainCount]);

	UKIntsEqual(allocCount + 6, GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class])
		+ GSDebugAllocationCount([ETView class]));

	DESTROY(pool3);
	UKIntsEqual(allocCount, GSDebugAllocationCount([ETLayoutItem class])
		+ GSDebugAllocationCount([ETLayoutItemGroup class])
		+ GSDebugAllocationCount([ETView class]));

	//ETLog(@"Recorded object allocation: %@", 
	//	GSDebugAllocationListRecordedObjects([ETView class]));

	GSDebugAllocationActive(NO);
#endif
}

#if 0
- (void) testArchiving
{
	id barView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
	id mainView = AUTORELEASE([[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)]);

	[self setTitleBarView: barView];
	[self setWrappedView: mainView];
	[self setDisclosable: YES];

	id dummyView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 50, 50)]);
	
	[self addSubview: dummyView];
	
	NSData *archive = [NSKeyedArchiver archivedDataWithRootObject: self];
	id view = [NSKeyedUnarchiver unarchiveObjectWithData: archive];

	//UKNil([view layoutItem]);
	//UKNotNil([view renderer]);	
	UKNotNil([view wrappedView]);
	UKObjectsSame(view, [[view wrappedView] superview]);
	UKNotNil([view titleBarView]);	
	UKObjectsSame(view, [[view titleBarView] superview]);
	UKIntsEqual(3, [[view subviews] count]);
	UKTrue([view isDisclosable]);
	UKTrue([view usesCustomTitleBar]);
}
#endif

+ (void) testTitleBarViewPrototype
{
	UKNotNil([self titleBarViewPrototype]);
	UKTrue(NSEqualRects(NSMakeRect(0, 0, 100, 50), [[self titleBarViewPrototype] frame]));
}

- (NSView *) dummyView
{
	return AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
}

- (void) checkContentView: (NSView *)contentView
{
	UKRectsEqual(ETMakeRect(NSZeroPoint, [self frame].size), [contentView frame]);
	UKObjectsEqual(self, [contentView superview]);

	[self setFrame: NSZeroRect];
	UKRectsEqual(NSZeroRect, [contentView frame]);	
	
	[self setFrame: NSMakeRect(1000, -1000, 1000, 2000)];
	UKRectsEqual(NSMakeRect(0, 0, 1000, 2000), [contentView frame]);	
}

- (void) testSetTemporaryView
{
	id contentView = [self dummyView];
	[self setTemporaryView: contentView];
	[self checkContentView: contentView];
}

- (void) testSetWrappedView
{
	id contentView = [self dummyView];
	[self setWrappedView: contentView];
	[self checkContentView: contentView];
}

- (void) testTitleBarView
{
	UKNotNil([self titleBarView]);
	// FIXME: We need something like -isEqual: and -isMemberOfClass: to test 
	// whether an instance is a clone of a given object or not.
	//UKTrue([[self titleBarView] isMemberOfClass: [[self titleBarViewPrototype] class]]);
}

- (void) testSetTitleBarView
{
	id barView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
	id mainView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)]);
	
	/* Main view check */
	[self setWrappedView: mainView];
	
	UKObjectsSame(mainView, [self contentView]);
	UKObjectsSame(mainView, [self mainView]); /* May be invalid in subclasses */
	UKObjectsSame(self, [mainView superview]);
	UKTrue(NSEqualSizes([self frame].size, [mainView frame].size));
	UKTrue(NSEqualPoints(NSZeroPoint, [mainView frame].origin));
	
	/* Title bar view check */
	[self setDisclosable: YES];
	[self setTitleBarView: barView]; /* -useCustomTitleBar will now  return YES */
	
	UKObjectsSame(mainView, [self contentView]);
	UKObjectsSame(mainView, [self mainView]);
	UKObjectsSame(self, [mainView superview]);
	// NOTE: Next test will fail if the receiver frame is a zero rect because 
	// then mainView frame is set to a zero rect too in -tile. -init calls 
	// -initWithFrame: with a zero rect, hence the need for -initForTest.
	UKFalse(NSEqualSizes([self frame].size, [mainView frame].size));
	UKTrue(NSEqualPoints(NSMakePoint(0, [barView height]), [mainView frame].origin));
	
	UKObjectsSame(barView, [self titleBarView]);
	UKObjectsSame(self, [barView superview]);
	UKIntsEqual(0, [barView x]);	
	UKIntsEqual(0, [barView y]);
	UKIntsEqual([mainView width], [barView width]);
	UKIntsEqual(25, [barView height]);
	/* Flipped:	UKFloatsEqual(0, [[self titleBarView] y]); */
	
	NSLog(@"---------------- >>> rect content %@", NSStringFromRect([[self mainView] frame]));
	NSLog(@"---------------- >>> rect title bar %@", NSStringFromRect([[self titleBarView] frame]));

	id barViewProto = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
	
	/* Test usesCustomTitleBar equals YES */
	[[self class] setTitleBarViewPrototype: barViewProto];
	UKObjectsSame(barView, [self titleBarView]);
	
	/* Test usesCustomTitleBar equals NO */
	[self setTitleBarView: nil]; /* -useCustomTitleBar will now  return NO */
	[[self class] setTitleBarViewPrototype: barViewProto];
	UKNotNil([self titleBarView]);
	UKObjectsNotSame(barView, [self titleBarView]);
}

- (void) testLayoutItem
{
	UKNotNil([self layoutItem]);
	UKObjectsSame(self, [[self layoutItem] supervisorView]);
}

- (void) testSetLayoutItem
{
	id theItem = [ETLayoutItem item];
	
	[self setItem: theItem];

	[self testLayoutItem];
	UKObjectsSame(theItem, [self layoutItem]);
}

- (void) testSetLayoutItemWithoutInsertingView
{
	id theItem = [ETLayoutItem item];
	
	[self setLayoutItemWithoutInsertingView: theItem];
	
	UKNotNil([self layoutItem]);
	UKObjectsSame(theItem, [self layoutItem]);
	UKNil([theItem view]);
}

- (void) testSetDisclosable
{
	[self setDisclosable: YES];
	UKTrue([[self subviews] containsObject: [self titleBarView]]);
	
	[self setDisclosable: NO];
	
	UKFalse([[self subviews] containsObject: [self titleBarView]]);
}

- (void) testExpand
{
	[self setDisclosable: YES];
	
	[self expand: nil];
	UKTrue([[self subviews] containsObject: [self titleBarView]]);
	
	[self collapse: nil];
	[self expand: nil];
	UKTrue([[self subviews] containsObject: [self titleBarView]]);
}

- (void) testCollapse
{
	[self setDisclosable: YES];
	UKTrue([[self subviews] containsObject: [self titleBarView]]);
	
	[self setDisclosable: NO];
	
	UKFalse([[self subviews] containsObject: [self titleBarView]]);
}

@end
