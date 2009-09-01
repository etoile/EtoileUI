/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>

#define WINDOW_CONTENT_RECT NSMakeRect(200, 200, 600, 300)

@implementation NSWindow (Etoile)

+ (unsigned int) defaultStyleMask
{
	return (NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask 
		| NSMiniaturizableWindowMask);
}

// FIXME: Window closing doesn't work on GNUstep when YES is passed for defer, 
// the window remains on screen.

- (id) init
{
	return [self initWithContentRect: WINDOW_CONTENT_RECT
					       styleMask: [NSWindow defaultStyleMask]
							 backing: NSBackingStoreBuffered
							   defer: NO];
}

- (id) initWithFrame: (NSRect)frame styleMask: (unsigned int)windowStyle
{
	NSRect contentRect = [NSWindow contentRectForFrameRect: frame 
	                                             styleMask: windowStyle];
	return [self initWithContentRect: contentRect
					       styleMask: windowStyle
							 backing: NSBackingStoreBuffered
							   defer: NO];
}

- (id) initWithContentRect: (NSRect)rect styleMask: (unsigned int)windowStyle
{
	return [self initWithContentRect: rect
					       styleMask: windowStyle
							 backing: NSBackingStoreBuffered
							   defer: NO];
}

/** Returns a window copy of the receiver. 

The content view and its whole subview tree is not copied, in other words the 
new object is a shallow copy of the receiver.*/
- (id) copyWithZone: (NSZone *)zone
{
	// NOTE: For NSWindow, NSCoding is not supported on Mac OS X 
	NSRect contentRect = [self contentRectForFrameRect: [self frame]];
	NSWindow *windowCopy = [[NSWindow alloc] initWithContentRect: contentRect
	                                                   styleMask: [self styleMask] 
	                                                     backing: [self backingType] 
	                                                       defer: NO];

	// FIXME: Copy more NSWindow properties (probably not all but at least the 
	// subet that matters in our case).

	return windowCopy;
}

- (void) setFrameSizeFromTopLeft: (NSSize)size
{
	NSRect frameRect = ETMakeRect([self frame].origin, size);
	float heightDelta = [self frame].size.height - frameRect.size.height;
	
	frameRect.origin.y += heightDelta;

	[self setFrame: frameRect display: NO];
}

- (void) setContentSizeFromTopLeft: (NSSize)size
{
	NSRect frameRect = [self frameRectForContentRect: ETMakeRect(NSZeroPoint, size)];
	
	return [self setFrameSizeFromTopLeft: frameRect.size];
}

- (NSPoint) topLeftPoint
{
	return NSMakePoint(NSMinX([self frame]), NSMaxY([self frame]));
}

/** Returns the frame rect expressed in the window base coordinate space. 

This space includes the window decoration (titlebar etc.) and uses 
top left coordinates when the content view returns YES to -isFlipped.  */
- (NSRect) frameRectInContent
{
	NSRect contentRect = [self contentRectInFrame];
	NSRect rect = [self frame];

	rect.origin.x = -contentRect.origin.x;
	rect.origin.y = -contentRect.origin.y;

	return rect;
}

/** Returns the content view rect expressed in the window coordinate space. 

This coordinate space includes the window decoration (titlebar etc.) and uses 
top left coordinates when the content view returns YES to -isFlipped.  */
- (NSRect) contentRectInFrame;
{
	NSRect windowFrame = [self frame];
	NSRect rect = [self contentRectForFrameRect: windowFrame];

	NSParameterAssert(rect.size.width <= windowFrame.size.width && rect.size.height <= windowFrame.size.height);

	rect.origin.x = rect.origin.x - windowFrame.origin.x;
	rect.origin.y = rect.origin.y - windowFrame.origin.y;

	if ([[self contentView] isFlipped])
	{
		rect.origin.y = windowFrame.size.height - (rect.origin.y + rect.size.height);	
	}

	NSParameterAssert(rect.origin.x >= 0 && rect.origin.x <= rect.size.width 
		&& rect.origin.y >= 0 && rect.origin.y <= rect.size.height);

	return rect;
}

- (BOOL) isSystemPrivateWindow
{
#ifdef GNUSTEP
	BOOL isAppIconWindow = [self isKindOfClass: NSClassFromString(@"NSIconWindow")];
	BOOL isMenuWindow = [self isKindOfClass: NSClassFromString(@"NSMenuPanel")];
#else
	BOOL isAppIconWindow = NO;
	BOOL isMenuWindow = NO;
#endif
	return ([self isCacheWindow] || isAppIconWindow || isMenuWindow);
}

- (BOOL) isCacheWindow
{
#ifdef GNUSTEP
	return ([self isKindOfClass: NSClassFromString(@"GSCacheW")]);
#else
	return ([[self contentView] isKindOfClass: NSClassFromString(@"NSImageCacheView")]);
#endif
}

- (IBAction) browse: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	ETDebugLog(@"browse %@", self);
	[browser setBrowsedObject: [self contentView]];
	[[browser panel] makeKeyAndOrderFront: self];
}

@end


@implementation ETFullScreenWindow

/** Initializes and returns a new borderless window that fills the main screen. */
- (id) init
{
	return [self initWithContentRect: [[NSScreen mainScreen] frame]
	                       styleMask: NSBorderlessWindowMask
	                         backing: NSBackingStoreBuffered
	                           defer: NO];
}

- (id) initWithContentRect: (NSRect)contentRect 
                 styleMask: (NSUInteger)windowStyle
                   backing: (NSBackingStoreType)bufferingType 
                     defer: (BOOL)deferCreation
{
	self = [super initWithContentRect: contentRect
			        styleMask: windowStyle
				  backing: bufferingType
				    defer: deferCreation];

	if (self == nil)
		return nil;

	[self center];
	[self setLevel: NSFloatingWindowLevel];
	[self setHidesOnDeactivate: YES];
	[self setExcludedFromWindowsMenu: YES];

	return self;
}

/** Returns YES in all cases even when the receiver is borderless (unlike 
NSWindow implementation. */
- (BOOL) canBecomeKeyWindow
{
	return YES;
}

@end

