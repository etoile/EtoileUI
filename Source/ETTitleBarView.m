/*
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)

	Contains BSD-licensed code by Stephen F. Booth <me@sbooth.org>
 */

#import <EtoileFoundation/Macros.h> 
#import "ETTitleBarView.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

#define TITLE_VIEW_TAG 0
#define DISCLOSURE_BUTTON_TAG 1


@implementation ETTitleBarView

- (id) initWithFrame: (NSRect)rect
{
	self = [super initWithFrame: rect];
	if (self == nil)
		return nil;
	
	NSTextField *labelField = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(24, 3, rect.size.width-24, 18)]);
	NSButton *disclosureButton = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 24,24)]);
	
	[disclosureButton setTag: DISCLOSURE_BUTTON_TAG];
	[disclosureButton setButtonType: NSOnOffButton];
	[disclosureButton setBezelStyle: NSDisclosureBezelStyle];
	[disclosureButton setImagePosition: NSImageOnly];
	[disclosureButton setState: NSOnState];
	
	[labelField setTag: TITLE_VIEW_TAG];
	[labelField setDrawsBackground: NO];
	[labelField setBordered: NO];
	[labelField setEditable: NO];
	[labelField setSelectable: NO];
	[labelField setStringValue: _(@"Untitled")];
	[labelField setAlignment: NSLeftTextAlignment];
	[labelField setAutoresizingMask: NSViewWidthSizable];
	[labelField setTextColor: [NSColor headerTextColor]];
	
	[self addSubview: disclosureButton];
	[self addSubview: labelField];
	[self setAutoresizesSubviews: YES];
	
	return self;
}

- (id) init
{
	return [self initWithFrame: NSMakeRect(0, 0, 100, 24)];
}
		
- (void) setTitleString: (NSString *)title
{
	[[self viewWithTag: TITLE_VIEW_TAG] setStringValue: title];
}

- (NSString *) titleString
{
	return [[self viewWithTag: TITLE_VIEW_TAG] stringValue];	
}

- (BOOL) isExpanded
{
	return [[self viewWithTag: DISCLOSURE_BUTTON_TAG] state] == NSOnState;
}

- (void) mouseDown: (NSEvent *)anEvent
{
	_highlighted = YES;
}

- (void) mouseUp: (NSEvent *)anEvent
{
	_highlighted = NO;
	[[self viewWithTag: DISCLOSURE_BUTTON_TAG] performClick: anEvent];
}

- (void) setTarget: (id)target
{
	[[self viewWithTag: DISCLOSURE_BUTTON_TAG] setTarget: target];
}

- (id) target
{
	return [[self viewWithTag: DISCLOSURE_BUTTON_TAG] target];
}

- (void) setAction: (SEL)action
{
	[[self viewWithTag: DISCLOSURE_BUTTON_TAG] setAction: action];
}

- (SEL) action
{
	return [[self viewWithTag: DISCLOSURE_BUTTON_TAG] action];
}

- (BOOL) drawsGradientFlipped
{
	return NO;
}

//#define USE_XCODE_DOC_BROWSER_GROUP_ROW_COLOR

/* Drawing code based on SFBInspectorPaneHeader by Stephen F. Booth, see COPYING
   where SFBInspectors BSD license is reproduced. */
- (void) drawRect:(NSRect)rect
{
#ifdef USE_XCODE_DOC_BROWSER_GROUP_ROW_COLOR
	NSColor *startColor = [NSColor colorWithCalibratedWhite: 0.91 alpha: 1.0];
	NSColor *endColor = [NSColor colorWithCalibratedWhite: 0.81 alpha: 1.0];
	NSColor *topBorderColor = [NSColor colorWithCalibratedWhite: 0.79 alpha: 1.0];
	NSColor *bottomBorderColor = [NSColor colorWithCalibratedWhite: 0.67 alpha: 1.0];
#else
	NSColor *startColor = [NSColor colorWithCalibratedWhite: 0.88 alpha: 1.0];
	NSColor *endColor = [NSColor colorWithCalibratedWhite: 0.77 alpha: 1.0];
	NSColor *topBorderColor = [NSColor colorWithCalibratedWhite: 0.66 alpha: 1.0];
	NSColor *bottomBorderColor = [NSColor colorWithCalibratedWhite: 0.61 alpha: 1.0];
#endif
	NSGradient *gradient = AUTORELEASE([[NSGradient alloc] initWithStartingColor: startColor endingColor: endColor]);
	float angle = ([self drawsGradientFlipped] ? 270 : 90);

	[gradient drawInRect: rect angle: angle];

	NSRect bottomBorderRect = [self bounds];
	bottomBorderRect.origin.y = [self bounds].size.height - 1;
	bottomBorderRect.size.height = 1;

	[bottomBorderColor setFill];
	[NSBezierPath fillRect: bottomBorderRect];

	NSRect topBorderRect = [self bounds];
	topBorderRect.size.height = 1;

	[topBorderColor setFill];
	[NSBezierPath fillRect: topBorderRect];

	if (_highlighted) 
	{
		[[NSColor colorWithCalibratedWhite: 0 alpha: 0.07] setFill];
		[NSBezierPath fillRect: rect];
	}
}

- (BOOL) isFlipped
{
	return YES;
}

@end
