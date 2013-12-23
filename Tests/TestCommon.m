/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import "TestCommon.h"
#import "ETEvent.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETTool.h"
#import "ETWindowItem.h"

@implementation Person

@synthesize name = _name, emails = _emails, groupNames = _groupNames;

- (id) init
{
	SUPERINIT;
	ASSIGN(_name, @"John");
	ASSIGN(_emails, D(@"john@etoile.com", @"Work", @"john@nowhere.org", @"Home"));
	ASSIGN(_groupNames, A(@"Somebody", @"Nobody"));
	return self;
}

- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_emails);
	DESTROY(_groupNames);
	[super dealloc];
}

- (NSArray *) propertyNames
{
	return [[super propertyNames]
			arrayByAddingObjectsFromArray: A(@"name", @"emails", @"groupNames")];
}

@end


@implementation TestCommon : NSObject

- (id) init
{
	SUPERINIT;
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(previousActiveTool, [ETTool activeTool]);
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	[ETTool setActiveTool: previousActiveTool];
	DESTROY(previousActiveTool);
	[super dealloc];
}

@end


#define WIN_WIDTH 300
#define WIN_HEIGHT 200

/* Verify that AppKit does not check whether the content view uses flipped 
coordinates or not to set the event location in the window. */
@implementation TestEvent

- (id) init
{
	SUPERINIT

	ASSIGN(mainItem, [itemFactory itemGroup]);
	[mainItem setFrame: NSMakeRect(0, 0, WIN_WIDTH, WIN_HEIGHT)];
	[[itemFactory windowGroup] addItem: mainItem];
	ASSIGN(tool, [ETTool tool]);

	return self;
}

- (void) dealloc
{
	[[itemFactory windowGroup] removeItem: mainItem];
	DESTROY(mainItem); 
	DESTROY(tool);
	[super dealloc];
}

- (NSWindow *) window
{
	return [[mainItem windowItem] window];
}

- (ETEvent *) createEventAtPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win
{
	NSParameterAssert(loc.x != NAN && loc.y != NAN);
	NSEvent *backendEvent = [NSEvent mouseEventWithType: NSLeftMouseDown
	                                           location: loc
	                                      modifierFlags: 0 
	                                          timestamp: [NSDate timeIntervalSinceReferenceDate]
	                                       windowNumber: [win windowNumber]
	                                            context: [NSGraphicsContext currentContext] 
	                                        eventNumber: 0
                                             clickCount: clickCount
	                                           pressure: 0.0];
	
	UKObjectsSame(win, [backendEvent window]); /* Paranoid check */

	return ETEVENT(backendEvent, nil, ETNonePickingMask);
}

- (ETEvent *) createEventAtContentPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win
{
	NSPoint p = loc;

	if (win != nil)
	{
		/* -convertPoint:toView: takes cares to flip p properly by checking it 
		   the content view vs the window */
		p = [[win contentView] convertPoint: p toView: nil];
	}	

	return [self createEventAtPoint: p clickCount: clickCount inWindow: win];
}

- (ETEvent *) createEventAtScreenPoint: (NSPoint)loc isFlipped: (BOOL)flip
{
	NSPoint p = loc;

	if (flip)
	{
		p.y = [[NSScreen mainScreen] frame].size.height - p.y;
	}

	return [self createEventAtPoint: p clickCount: 1 inWindow: nil];
}

@end


@implementation ETTool (ETToolTestAdditions)

+ (id) tool
{
	return [self toolWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
}

@end
