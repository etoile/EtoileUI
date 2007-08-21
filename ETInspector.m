/*
	ETInspector.m
	
	Inspector protocol and related Inspector representation class which can be
	used as an inspector view wrapper.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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
 
#import <EtoileUI/ETInspector.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETLineLayout.h>
#import <EtoileUI/ETStackLayout.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/ETPaneLayout.h>
#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/GNUstep.h>

@interface ETInspector (EtoilePrivate)
- (int) numberOfItemsInItemGroupView: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inItemGroupView: (ETContainer *)container;
- (int) numberOfItemsInPropertyView: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inPropertyView: (ETContainer *)container;
@end


@implementation ETInspector

- (id) init
{
	return [self initWithView: nil value: nil representedObject: nil];
}

- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	self = (ETInspector *)[super initWithView: view value: value representedObject: repObject];
	
	if (self != nil)
	{
		_inspectedItems = nil;
		
		BOOL nibLoaded = [NSBundle loadNibNamed: @"Inspector" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib Inspector");
			RELEASE(self);
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(_inspectedItems);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[itemGroupView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];
	[itemGroupView setSource: self];
	[itemGroupView setDelegate: self];
	[itemGroupView setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[itemGroupView setTarget: self];
	
	[propertyView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];
	[propertyView setSource: self];
	[propertyView setDelegate: self];
	[propertyView setTarget: self];
}

- (void) containerSelectionDidChange: (NSNotification *)notif
{
	/*[itemGroupView setSource: self];
	[itemGroupView setDelegate: self];*/
	ETLog(@"Selection did change for %@ received in %@", [notif object], self);
	
	[propertyView updateLayout];
}

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	int nbOfItems = 0;
	
	if ([container isEqual: itemGroupView])
	{
		nbOfItems =	[self numberOfItemsInItemGroupView: container];
	}
	else if ([container isEqual: propertyView])
	{
		nbOfItems = [self numberOfItemsInPropertyView: container];
	}
	
	return nbOfItems;
}

- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container
{
	ETLayoutItem *item = nil;
	
	if ([container isEqual: itemGroupView])
	{
		item =	[self itemAtIndex: index inItemGroupView: container];
	}
	else if ([container isEqual: propertyView])
	{
		item = [self itemAtIndex: index inPropertyView: container];
	}
	
	return item;
}

- (int) numberOfItemsInItemGroupView: (ETContainer *)container
{
	int nbOfItems = [[self inspectedItems] count];
	
	//ETLog(@"Returns %d as number of items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) itemAtIndex: (int)index inItemGroupView: (ETContainer *)container
{
	ETLayoutItem *item = [[self inspectedItems] objectAtIndex: index];
	
	/* Create a meta layout item */
	item = [ETLayoutItem layoutItemOfLayoutItem: item];
	
	//ETLog(@"Returns item %@ at index %d in %@", item, index, container);

	return item;
}

- (int) numberOfItemsInPropertyView: (ETContainer *)container
{
	int selection = [itemGroupView selectionIndex];
	int nbOfPropertyItems = 0;

	if (selection != NSNotFound)
	{
		// FIXME: Don't access layout item cache here. May be add -selectedItems?
		ETLayoutItem *item = [[itemGroupView layoutItemCache] objectAtIndex: selection];
		
		NSAssert([item properties] != nil, @"Represented object of a layout item should never be nil");
		
		nbOfPropertyItems = [[item properties] count];
	}
	
	//ETLog(@"Returns %d as number of property items in %@", nbOfPropertyItems, container);
	
	return nbOfPropertyItems;
}

- (ETLayoutItem *) itemAtIndex: (int)index inPropertyView: (ETContainer *)container
{
	ETLayoutItem *item = [[itemGroupView layoutItemCache] objectAtIndex: [itemGroupView selectionIndex]];
	ETLayoutItem *propertyItem = [[ETLayoutItem alloc] init];
	NSString *property = [[item properties] objectAtIndex: index];

	[propertyItem setValue: property forProperty: @"property"];
	[propertyItem setValue: [item valueForProperty: property] forProperty: @"value"];
	
	//ETLog(@"Returns property item %@ at index %d in %@", item, index, container);
	
	AUTORELEASE(propertyItem);
	
	return propertyItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	NSArray *displayedProperties = nil;

	if ([container isEqual: itemGroupView])
	{
		displayedProperties = [NSArray arrayWithObjects: @"icon", @"name", nil];
	}	
	else if ([container isEqual: propertyView])
	{
		displayedProperties = [NSArray arrayWithObjects: @"property", @"value", nil];
	}
	
	return displayedProperties;
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layoutClass = [ETStackLayout class];
			break;
		case 1:
			layoutClass = [ETLineLayout class];
			break;
		case 2:
			layoutClass = [ETFlowLayout class];
			break;
		case 3:
			layoutClass = [ETTableLayout class];
			break;
		case 4:
			layoutClass = [ETOutlineLayout class];
			break;
		case 5:
			layoutClass = [ETBrowserLayout class];
			break;
		case 6:
			layoutClass = [ETFreeLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	//[viewContainer setLayout: (ETViewLayout *)AUTORELEASE([[layoutClass alloc] init])];
}

- (NSArray *) inspectedItems
{
	return _inspectedItems;
}

- (void) setInspectedItems: (NSArray *)items
{
	if ([items count] == 0)
	{
		ASSIGN(_inspectedItems, nil);
	}
	else
	{
		ASSIGN(_inspectedItems, items);
		[itemGroupView updateLayout];
	}
}

- (NSWindow *) window
{
	return window;
}

- (NSPanel *) panel
{
	return window;
}

- (IBAction) inspect: (id)sender
{
	[[NSApplication sharedApplication] sendAction: @selector(inspect:) to: nil from: sender];
}

@end

@implementation ETLayoutItem (ETInspector)

+ (ETLayoutItem *) layoutItemOfLayoutItem: (ETLayoutItem *)item
{
	ETLayoutItem *metaLayoutItem = [item copy];
	id propertyName = nil;
	
	[metaLayoutItem setRepresentedObject: item];
	propertyName = [metaLayoutItem valueForProperty: @"property"];
	if (propertyName != nil)
	{
		[metaLayoutItem setValue: propertyName forProperty: @"name"];
		[metaLayoutItem setValue: [metaLayoutItem valueForProperty: @"property"]
					 forProperty: @"property"];
	}
	
	return AUTORELEASE(metaLayoutItem);
}

/** Returns a dictionary mapping value classes to editor object prototypes. 
	These editor objects are UI elements like NSSlider, NSStepper, NSTextField, 
	NSButton. */
- (NSDictionary *) editorObjects
{
	/*NSButton *checkBox = [[NSButton alloc] ini

	return [NSDictionary dictionaryWithObjectsAndKeys: 
		[NS*/
	return nil;
}

- (ETView *) buildInspectorView
{
	/*NSEnumerator *e = [[self representedObject] objectEnumerator];
	id modelValue = nil
	
	while ((modelValue = [e nextObject]) != nil)
	{
		[
		
		if (
	}*/
	return nil;
}

@end
