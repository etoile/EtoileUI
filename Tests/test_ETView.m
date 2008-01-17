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
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETView (UnitKitTests) <UKTest>
@end


@implementation ETView (UnitKitTests)

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
	UKFalse(NSEqualSizes([self frame].size, [mainView frame].size));
	UKTrue(NSEqualPoints(NSZeroPoint, [mainView frame].origin));
	
	UKObjectsSame(barView, [self titleBarView]);
	UKObjectsSame(self, [barView superview]);
	UKIntsEqual(0, [barView x]);	
	UKIntsEqual([mainView height], [barView y]);
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
	UKObjectsSame(self, [[self layoutItem] view]);
}

- (void) testSetLayoutItem
{
	id item = [ETLayoutItem layoutItem];
	
	[self setLayoutItem: item];

	[self testLayoutItem];
	UKObjectsSame(item, [self layoutItem]);
}

- (void) testSetLayoutItemWithoutInsertingView
{
	id item = [ETLayoutItem layoutItem];
	
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
