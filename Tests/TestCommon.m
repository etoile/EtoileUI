/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COObjectGraphContext.h>
#import "TestCommon.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETTool.h"
#import "ETView.h"
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

/* Does a set up similar to ETApplicationMain().

GNUstep doesn't take care of calling -[NSApp sharedApplication] if your code 
doesn't. Unlike Cocoa, it just raises an exception if you try to create a window.

First we must create the app object, because on Mac OS X in 
UKTestClasseNamesFromBundle(), we have -bundleForClass: that invokes 
class_respondsToSelector() which results in +initialize being called and 
+[NSWindowBinder initialize] has the bad idea to use +sharedApplication. When no 
app object is available yet, an NSApplication instance will be created rather 
than the subclass instance we might want. */
+ (void) willRunTestSuite
{
	id app = [ETApplication sharedApplication];

	ETAssert([app isKindOfClass: [ETApplication class]]);
	
	[app setUp];
}

+ (void) didRunTestSuite
{

}

- (id) init
{
	SUPERINIT;

    /* Delete existing db file in case -dealloc didn't run */
    [self deleteStore];

	// NOTE: For now, ETApp registers aspects in the aspect repository with
	// the +defaultTransientObjectGraphContext rather than creating an object
	// graph context just for the repository and its aspects.
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	[[ETUIObject defaultTransientObjectGraphContext] discardAllChanges];
    [ETUIObject clearRecordedDeallocations];

	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ETAssert([[itemFactory objectGraphContext] hasChanges] == NO);

	return self;
}

- (void) dealloc
{
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	[[itemFactory objectGraphContext] discardAllChanges];
    [ETUIObject clearRecordedDeallocations];

	DESTROY(itemFactory);

    [self deleteStore];
	[super dealloc];
}

- (NSURL *)storeURL
{
	return [NSURL fileURLWithPath: [@"~/TestEtoileUIStore.store" stringByExpandingTildeInPath]];
}

- (void)deleteStore
{
	if ([[NSFileManager defaultManager] fileExistsAtPath: [[self storeURL] path]] == NO)
		return;
	
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath: [[self storeURL] path]
	                                           error: &error];
	ETAssert(error == nil);
}

- (void) checkWithExistingAndNewRootObject: (COObject *)rootObject 
                                   inBlock: (void (^)(COObjectGraphContext *context, BOOL isNew, BOOL isCopy))block
{
    if ([rootObject rootObject] == nil)
    {
        [[rootObject objectGraphContext] setRootObject: rootObject];
    }
    ETAssert([rootObject isRoot]);
    [self checkWithExistingAndNewContext: [rootObject objectGraphContext]
                                 inBlock: block];
}

- (void) checkWithExistingAndNewContext: (COObjectGraphContext *)existingContext
                                inBlock: (void (^)(COObjectGraphContext *context, BOOL isNewContext, BOOL isCopy))block

{
    /* Run the tests in the existing context */

    block(existingContext, NO, NO);

    /* Commit the object graph, reload it in a new context and run the tests */

    COEditingContext *editingContext = [COEditingContext contextWithURL: [self storeURL]];
    COPersistentRoot *persistentRoot =
        [editingContext insertNewPersistentRootWithRootObject: [existingContext rootObject]];
   
    ETAssert([editingContext commit]);

    COEditingContext *newEditingContext = [COEditingContext contextWithURL: [self storeURL]];
    COPersistentRoot *newPersistentRoot =
        [newEditingContext persistentRootForUUID: [persistentRoot UUID]];

    block([newPersistentRoot objectGraphContext], YES, NO);
    
    /* Copy the object graph into the existing context and run the tests */

    [[existingContext rootObject] copyToObjectGraphContext: existingContext];
    
    block(existingContext, NO, YES);

    /* Copy the object graph into a new context and run the tests */

    // FIXME: Fix COCopier to handle non-composite refs (aka cross persistent
    // root refs) if the source is a transient object graph context.
#if 0
    COObjectGraphContext *copyContext = [COObjectGraphContext objectGraphContext];

    [[existingContext rootObject] copyToObjectGraphContext: copyContext];

    block(copyContext, YES, YES);
#endif
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

@implementation ETUIObject (ETUIObjectTestAdditions)

static NSMutableSet *deallocatedObjectUUIDs = nil;

- (void) recordDeallocation
{
    if (deallocatedObjectUUIDs == nil)
    {
        deallocatedObjectUUIDs = [NSMutableSet new];
    }
    [deallocatedObjectUUIDs addObject: [self UUID]];
}

+ (void) clearRecordedDeallocations
{
    [deallocatedObjectUUIDs removeAllObjects];
}

+ (BOOL) isObjectDeallocatedForUUID: (ETUUID *)aUUID
{
    return [deallocatedObjectUUIDs containsObject: aUUID];
}

@end


@implementation ETTool (ETToolTestAdditions)

+ (id) tool
{
	return [self toolWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
}

@end

@implementation ETLayoutItem (ETLayoutItemTestAdditions)

+ (NSRect) defaultItemRect
{
	return NSMakeRect(100, 50, 300, 250);
}

@end

@implementation ETDecoratorItem (ETDecoratorTestAdditions)

/* For test, patch the framework implementation. */
+ (ETDecoratorItem *) itemWithDummySupervisorView
{
	ETView *view = AUTORELEASE([[ETView alloc] init]);
	return AUTORELEASE([[ETDecoratorItem alloc]
		initWithSupervisorView: view objectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);
}

@end
