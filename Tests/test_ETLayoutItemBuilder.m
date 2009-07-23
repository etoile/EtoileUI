/*
	test_ETLayoutItemBuilder.m

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
#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETEtoileUIBuilder (UnitKitTests) <UKTest>
@end

/* NSView subclass for testing -renderView */
@interface CustomView : NSView { }
@end
@implementation CustomView
@end

@implementation ETEtoileUIBuilder (UnitKitTests)

- (void) testRender
{

}


- (void) testRenderWindow
{
	int styleMask = NSTitledWindowMask | NSClosableWindowMask 
		| NSMiniaturizableWindowMask | NSResizableWindowMask;
	id window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100, 200, 400, 300) 
	                                        styleMask: styleMask 
											  backing: NSBackingStoreBuffered
											    defer: NO 
											   screen: nil];

	[window setTitle: @"My Window Title"];
	
#if 0	
	id item = [[ETEtoileUIBuilder builder] renderWindow: window];
	
	UKNotNil(item);
	UKObjectsSame(window, [[item lastDecoratorItem] representedObject]);
	UKTrue(NSEqualRects([window frame], [item frame]));
	UKObjectsEqual([window title], [item name]);
	UKObjectsSame([window contentView], [item displayView]);
#endif

	RELEASE(window);
}

- (void) testRenderView
{
	id view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview0 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview1 = AUTORELEASE([[CustomView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	//id subview10 = AUTORELEASE([[CustomView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	//id subview11 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview00 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);

	id subview01 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview010 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview02 = AUTORELEASE([[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview020 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview021 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	
	[view addSubview: subview0];
	[view addSubview: subview1];
	[subview0 addSubview: subview00];
	
	[subview0 addSubview: subview01];	
	[subview01 setWrappedView: subview010];
	[subview0 addSubview: subview02];
	[subview02 addSubview: subview020];
	[(ETContainer *)subview02 addItem: [ETLayoutItem itemWithView: subview021]];

	id rootItem = [[ETEtoileUIBuilder builder] renderView: view];
	id childItem = nil;
	
	UKObjectsNotSame(view, [rootItem view]);
	UKIntsEqual([[rootItem items] count], 2);
	/* NSView are turned into containers but NSView subclasses aren't */
	UKObjectsNotSame(subview0, [[rootItem itemAtIndex: 0] view]);
	UKObjectKindOf([[rootItem itemAtIndex: 0] supervisorView], ETView);
	//UKObjectKindOf(ETContainer, [[rootItem itemAtIndex: 0] view]);
	UKObjectsSame([[rootItem itemAtIndex: 1] view], subview1);
	childItem = [rootItem itemAtIndex: 0];
	UKObjectsNotSame([[childItem itemAtIndex: 0] view], subview00);
	
	UKFalse([(ETLayoutItem *)[childItem itemAtIndex: 1] isGroup]); // ETView item check
	childItem = [childItem itemAtIndex: 2];
	UKTrue([childItem isGroup]); // ETContainer item check
	UKIntsEqual(1, [[childItem items] count]);
	UKObjectsSame([[childItem itemAtIndex: 0] view], subview021);
}

@end
