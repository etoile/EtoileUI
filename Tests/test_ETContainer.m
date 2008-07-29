/*
	test_ETContainer.m

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007

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
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETContainer (UnitKitTests) <UKTest>
@end


@implementation ETContainer (UnitKitTests)

- (void) testArchiving
{
	id barView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(-20, 30, 100, 25)]);
	id mainView = AUTORELEASE([[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)]);

	[self setTitleBarView: barView];
	[self setWrappedView: mainView];
	[self setDisclosable: YES];

	id dummyView = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 50, 50)]);
	
	[self addItem: [ETLayoutItem layoutItemWithView: dummyView]];
	
	NSData *archive = [NSKeyedArchiver archivedDataWithRootObject: self];
	id view = [NSKeyedUnarchiver unarchiveObjectWithData: archive];

	//UKNil([view layoutItem]);
	UKIntsEqual(2, [[view subviews] count]);
}

@end
