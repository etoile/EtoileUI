/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License: Modified BSD (see COPYING)
 */

#import "NSImage+Etoile.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"

@interface NSImage (EtoilePrivate)
- (void) takeSnapshotFromRect: (NSRect)sourceRect inView: (NSView *)view;
@end

static NSWindow *snapshotWindow = nil;

@implementation NSImage (Etoile)

/** Initializes and returns an NSImage instance which is snapshot of the view
parameter. The snapshot is taken at the time this method is called.

When the view isn't backed by a window, the view will be moved temporarily 
moved to a window to be snapshotted (not yet working). */
- (NSImage *) initWithView: (NSView *)view fromRect: (NSRect)rect
{
	NSParameterAssert(nil != view);
	if (NSIsEmptyRect(rect) || rect.size.width < 1 || rect.size.height < 1)
		return nil;

	self = [self initWithSize: rect.size];
	if (nil == self)
		return nil;

	//ETLog(@"Take snapshot %@ in superview %@ and %", view, [view superview], 
	//	[view window]);

	NSView *originalSuperview = nil;

	RETAIN(view);

	if (nil == [view window])
	{
		if (nil == snapshotWindow)
		{
			snapshotWindow = [[NSWindow alloc] init];
		}
		// FIXME: This code doesn't work, the window border seems to be snapshotted
		[snapshotWindow setContentSizeFromTopLeft: [view frame].size];
		originalSuperview = [view superview];
		[snapshotWindow setContentView: view];
	}


	[self takeSnapshotFromRect: rect inView: view];
	//ETDebugLog(@"New snapshot with reps %@ based on view %@", 
	//	[self representations], view);

	if (nil != originalSuperview)
	{
		[snapshotWindow setContentView: nil];
		[originalSuperview addSubview: view];
	}

	RELEASE(view);
	
	return self;
}

#if 1

// NOTE: PDF snapshots are slow, especially when they involve drawing big images
- (void) takeSnapshotFromRect: (NSRect)sourceRect inView: (NSView *)view
{
	NSBitmapImageRep *rep = nil;
	
	if ([view canDraw] == NO)
	{
		ETLog(@"WARNING: Impossible to snapshot view %@", view);
		return;
	}

	[view lockFocus];
	// NOTE: -bitmapImageRepForCachingDisplayInRect: could be used on Mac OS 10.4
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: sourceRect];
	[view unlockFocus];

	[self addRepresentation: rep];
	RELEASE(rep);
}

#else 

- (void) takeSnapshotFromRect: (NSRect)sourceRect inView: (NSView *)view
{
	NSBitmapImageRep *rep = nil;
	
	if ([view canDraw] == NO)
	{
		ETLog(@"WARNING: Impossible to snapshot view %@", view);
		return;
	}
	
	[view lockFocus];
	#ifdef GNUSTEP
	rep = [NSEPSImageRep imageRepWithData: 
		[view dataWithEPSInsideRect: sourceRect]];
	#else
	// NOTE: -dataWithEPSInsideRect: doesn't work on Mac OS X and PDF isn't
	// supported on GNUstep
	rep = [NSPDFImageRep imageRepWithData: 
		[view dataWithPDFInsideRect: sourceRect]];
	#endif
	[view unlockFocus];

	[self addRepresentation: rep];
}

#endif

/** Returns the receiver. */
- (NSImage *) icon
{
	return self;
}

@end
