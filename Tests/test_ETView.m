/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */


#import <Foundation/Foundation.h>
#import <Foundation/NSDebug.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETView.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface ETView (TestSupervisorView) <UKTest>
@end


@implementation ETView (TestSupervisorView)

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

	/* We create a temporary pool because -addItem: requests a layout update 
	   and -[ETLayout renderXXX] methods might store items in autoreleased 
	   collections. */
	CREATE_AUTORELEASE_POOL(layoutPool2);
	[parent addItem: item];
	DESTROY(layoutPool2);

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

	CREATE_AUTORELEASE_POOL(layoutPool3); /* See layoutPool2 comment */
	[ancestor addItem: parent];	
	[parent addItem: item]; /* Inserts view2 into view1 */
	DESTROY(layoutPool3);

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

	/* We have 3 items and 3 supervisor views which raises the alloc count to 6.
	   However both parent and ancestor triggers the allocation of 
	   -[ETLayout rootItem]. Parent is now released but ancestor isn't yet. 
	   Which means we must count 7 objects to take in account 
	   [[ancestor layout] rootItem]. */
	UKIntsEqual(allocCount + 7, GSDebugAllocationCount([ETLayoutItem class])
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

- (NSView *) dummyView
{
	NSView *view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
	[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	return view;
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

- (void) testLayoutItem
{
	UKNotNil([self layoutItem]);
	UKObjectsSame(self, [[self layoutItem] supervisorView]);
}

- (void) testSetLayoutItemWithoutInsertingView
{
	id theItem = AUTORELEASE([[ETLayoutItem alloc] init]);
	
	[self setItemWithoutInsertingView: theItem];
	
	UKNotNil([self layoutItem]);
	UKObjectsSame(theItem, [self layoutItem]);
	UKNil([theItem view]);
}

@end
