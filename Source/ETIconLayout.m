/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETIconLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETSelectTool.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


#define ICON_VIEW_TAG 0
#define LABEL_FIELD_TAG 1
#define PLACEHOLDER_IMG [NSImage imageNamed: @"NSApplicationIcon"]

@interface ETIconTemplateView : NSView

@end

@implementation ETIconTemplateView

- (id) initWithFrame: (NSRect)rect
{
	self = [super initWithFrame: NSMakeRect(0, 0, 80, 80)];
	if (self == nil)
		return nil;

	NSImageView *iconView = AUTORELEASE([[NSImageView alloc] initWithFrame: NSMakeRect(0, 0, 48, 48)]);
	NSTextField *labelField = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 77, 22)]);
	float viewYMargin = 3;

	[labelField setX: (([self width] - [labelField width]) / 2.)];
	[labelField setY: viewYMargin];
	[iconView setX: (([self width] - [iconView width]) / 2.)];
	[iconView setY: ([labelField y] + [labelField height] + viewYMargin)];
	
	[iconView setTag: ICON_VIEW_TAG];
	[labelField setTag: LABEL_FIELD_TAG];
	
	[labelField setDrawsBackground: NO];
	[labelField setBordered: NO];
	[labelField setEditable: YES];
	[labelField setSelectable: YES];
	[labelField setStringValue: _(@"Untitled")];
	[labelField setAlignment: NSCenterTextAlignment];
	[labelField setAutoresizingMask: NSViewWidthSizable | NSViewMaxYMargin | NSViewNotSizable];

	[iconView setAutoresizingMask: NSViewNotSizable | NSViewWidthSizable | NSViewHeightSizable];
	[iconView setImage: PLACEHOLDER_IMG];
	//[iconView setImageFrameStyle: NSImageFrameGrayBezel];

	[self addSubview: iconView];
	[self addSubview: labelField];
	[self setAutoresizingMask: NSViewNotSizable | NSViewMinYMargin | NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin];

	return self;
}

- (id) init
{
	return [self initWithFrame: NSZeroRect];
}

- (ETLayoutItem *) enclosingItem
{
	return nil;//[[self superview]
}

- (NSImageView *) imageView
{
	return [[self subviews] objectAtIndex: 0]; 
}

- (NSTextField *) labelField
{
	return [[self subviews] objectAtIndex: 1]; 
}

// TODO: Implement properly
- (NSRect) imageRectForBounds: (NSRect)bounds
{
	return [[self imageView] frame];
}

// TODO: Implement properly
- (NSRect) labelRectForBounds: (NSRect)bounds
{
	return [[self labelField] frame];
}

- (void) mouseUp: (NSEvent *)anEvent
{
	NSPoint clickLoc = [self convertPoint: [anEvent locationInWindow] fromView: nil];

	if ([anEvent clickCount] == 2)
	{
		if ([self mouse: clickLoc inRect: [self labelRectForBounds: [self bounds]]])
		{
			[[self window] makeFirstResponder: [self labelField]];
		}
		else
		{
			//[[self enclosingItem]
		}
	}
	else
	{
		[[self enclosingItem] setSelected: YES];
		[[self enclosingItem] display];
	}
}

@end

@implementation ETIconLayout

- (id) init
{
	SUPERINIT

	[self setAttachedInstrument: [ETSelectTool instrument]];
	[self setTemplateItem: [ETLayoutItem itemWithView: 
		AUTORELEASE([[ETIconTemplateView alloc] init])]];
	[self setTemplateKeys: A(@"view", @"style")];
	[self bindTemplateItemKeyPath: @"view.imageView" toItemWithKeyPath: @"icon"];
	[self bindTemplateItemKeyPath: @"view.labelField" toItemWithKeyPath: @"name"];

	return self;
}

DEALLOC(DESTROY(_itemLabelFont))

/* Mainly useful for debugging... */
- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item
{
	if (_localBindings != nil)
	{
		[super setUpTemplateElementsForItem: item];
	}
	else
	{
		ETLog(@"WARNING: Bindings missing in %@", self);
		NSImageView *iconView = [[item view] viewWithTag: ICON_VIEW_TAG];
		NSTextField *labelField = [[item view] viewWithTag: LABEL_FIELD_TAG];
		
		[iconView setImage: [item icon]];
		[labelField setStringValue: [item displayName]];
	}

	// FIXME: Shouldn't be needed if we set on the template view already
	[item setAutoresizingMask: NSViewNotSizable | NSViewMinYMargin | NSViewMinXMargin |				NSViewMaxXMargin | NSViewMaxYMargin];
}

- (void) setItemTitleFont: (NSFont *)font
{
	ASSIGN(_itemLabelFont, font);
}

@end
