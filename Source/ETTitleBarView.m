/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  August 2009
 License:  Modified BSD  (see COPYING)
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

- (void) mouseUp: (NSEvent *)anEvent
{
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

- (void) drawRect:(NSRect)rect
{
	//NSLog(@"Draw ETTitleBarView");
	[[NSColor headerColor] setFill];
	NSRectFill([self bounds]);
}

- (BOOL) isFlipped
{
	return YES;
}

@end
