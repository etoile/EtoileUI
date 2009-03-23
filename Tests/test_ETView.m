/*
	test_ETView.m

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <Foundation/NSDebug.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

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
	item = [ETLayoutItem item];
	[item setSupervisorView: view];
	id parent = [[ETLayoutItemGroup alloc] init];

	[parent addItem: item];

	UKIntsEqual(3, [item retainCount]);
	UKIntsEqual(2, [[item supervisorView] retainCount]);
	UKIntsEqual(1, [parent retainCount]); /* Not retained by item */
	RELEASE(view);
	UKIntsEqual(1, [[item supervisorView] retainCount]);
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
	item = [ETLayoutItem item];
	[item setSupervisorView: view2];
	parent = [[ETLayoutItemGroup alloc] init];
	[parent setSupervisorView: view1];
	id ancestor = [ETLayoutItem itemGroup];

	[ancestor addItem: parent];	
	[parent addItem: item]; /* Inserts view2 into view1 */

	UKIntsEqual(3, [item retainCount]); /* Retained by view2 and parent */
	UKIntsEqual(3, [view2 retainCount]); /* Retained by item and view1 (parent view) */
	UKIntsEqual(3, [parent retainCount]); /* Retained by view1 ancestor */
	UKIntsEqual(2, [view1 retainCount]); /* Retained by parent */
	UKIntsEqual(1, [ancestor retainCount]); /* Retained by nobody */

	RELEASE(view1);
	UKIntsEqual(1, [view1 retainCount]);
	UKIntsEqual(3, [item retainCount]);

	RELEASE(item);
	RELEASE(parent);
	UKIntsEqual(2, [item retainCount]);
	UKIntsEqual(3, [view2 retainCount]);
	UKIntsEqual(2, [parent retainCount]);
	UKIntsEqual(1, [view1 retainCount]);

	UKIntsEqual(allocCount + 5, GSDebugAllocationCount([ETLayoutItem class])
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
	id item = [ETLayoutItem item];
	
	[self setLayoutItem: item];

	[self testLayoutItem];
	UKObjectsSame(item, [self layoutItem]);
}

- (void) testSetLayoutItemWithoutInsertingView
{
	id item = [ETLayoutItem item];
	
	[self setLayoutItemWithoutInsertingView: item];
	
	UKNotNil([self layoutItem]);
	UKObjectsSame(item, [self layoutItem]);
	UKNil([item view]);
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
