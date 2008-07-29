/*  <title>ETViewModelLayout</title>

	ETViewModelLayout.m
	
	<abstract>A property inspector implemented as a pluggable layout which 
	supports introspecting an object as both view and model.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 
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

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileUI/ETViewModelLayout.h>
#import <EtoileUI/ETLayoutItem+Reflection.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETViewModelLayout

- (void) awakeFromNib
{
	ETLog(@"Awaking from nib for %@", self);

	/* Configure propertyView outlet */
	[propertyView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];	
	[propertyView setSource: self];
	[propertyView setDelegate: self];
	[propertyView setDoubleAction: @selector(doubleClickInPropertyView:)];
	[propertyView setTarget: self];
	[propertyView setHasVerticalScroller: YES];
	[propertyView setHasHorizontalScroller: YES];

	/* Finish init */
	[self setDisplayMode: ETLayoutDisplayModeViewProperties];
}

- (NSString *) nibName
{
	return @"ViewModelPrototype";
}

- (void) setUpLayoutView
{
	[super setUpLayoutView];
	// FIXME: When a container is used as a layout view we usually need to 
	// unflip the coordinates in order to have subviews positioned as expected
	// (container coordinates are flipped by default).
	//[[self layoutView] setFlipped: NO];
}

- (ETLayoutDisplayMode) displayMode
{
	return _displayMode;
}

- (void) setDisplayMode: (ETLayoutDisplayMode)mode
{
	_displayMode = mode;
	[propertyView reloadAndUpdateLayout];
}

- (void) switchDisplayMode: (id)sender
{
	NSAssert1([sender isKindOfClass: [NSPopUpButton class]], 
		@"-switchDisplayMode: must be sent by an instance of NSPopUpButton class "
		@"kind unlike %@", sender);
	[self setDisplayMode: [[sender selectedItem] tag]];
}

- (void) setLayoutContext: (id <ETLayoutingContext>)context
{
	[super setLayoutContext: context];
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if ([self container] == nil)
	{
		ETLog(@"WARNING: Layout context %@ must have a container otherwise "
			@"view-based layout %@ cannot be set", [self layoutContext], self);
		return;
	}

	[self setUpLayoutView];
	[propertyView reloadAndUpdateLayout];
}

- (void) doubleClickInPropertyView: (id)sender
{
	ETLayoutItem *item = [[[self container] items] objectAtIndex: [propertyView selectionIndex]];
	
	[[[item inspector] window] makeKeyAndOrderFront: self];
}

/* Object Inspection */

- (ETLayoutItem *) object: (id)inspectedObject itemRepresentingSlotAtIndex: (int)index
{
	ETLayoutItem *propertyItem = AUTORELEASE([[ETLayoutItem alloc] init]);
	
	if (inspectedObject != nil)
	{
		NSArray *ivars = [inspectedObject instanceVariables];
		NSArray *methods = [inspectedObject methods];
		NSArray *slots = [[NSArray arrayWithArray: ivars] 
					arrayByAddingObjectsFromArray: methods];
		id slot = [slots objectAtIndex: index];
	
		[propertyItem setValue: [slot name] forProperty: @"slot"];
		if ([slot isKindOfClass: [ETInstanceVariable class]])
		{
			id ivarValue = [slot value];
			NSString *ivarType = [ivarValue typeName];
			
			if (ivarValue == nil)
				ivarValue = @"nil";
			[propertyItem setValue: [ivarValue description] forProperty: @"value"];
			if (ivarType == nil)
				ivarType = @"";
			[propertyItem setValue: ivarType forProperty: @"type"];
		}
		else if ([slot isKindOfClass: [ETMethod class]])
		{
			[propertyItem setValue: @"method (objc)" forProperty: @"value"];
		}
	}
	
	return propertyItem;
}

- (int) numberOfSlotsInObject: (id)inspectedObject
{
	int nbOfSlots = 0;
	
	if (inspectedObject != nil)
	{
		NSArray *ivars = [inspectedObject instanceVariables];
		NSArray *methods = [inspectedObject methods];
		NSArray *slots = [[NSArray arrayWithArray: ivars] 
					arrayByAddingObjectsFromArray: methods];
	
		nbOfSlots = [slots count];
	}
	
	return nbOfSlots;
}

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	/* Verify the layout is currently bound to a layout context like a container */
	if ([self layoutContext] == nil)
	{
		ETLog(@"WARNING: Layout context is missing for -numberOfItemsInContainer: in %@", self);
		return 0;
	}

	id inspectedItem = [self layoutContext];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	ETLayoutItem *metaItem = 
		[ETLayoutItem layoutItemWithRepresentedItem: inspectedItem snapshot: NO];
	int nbOfItems = 0;

	if ([self displayMode] == ETLayoutDisplayModeViewProperties)
	{
		/* By using a meta layout item, the inspected item ivars which are 
		   implicit properties get transparently reified into properties. This 
		   happens when the inspected item becomes the model (or represented 
		   object) of the meta item. 
		   See -[ETLayoutItem properties] to know which ivars/accessors are 
		   reified into properties. */
		nbOfItems = [[metaItem properties] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelProperties)
	{
		nbOfItems = [[inspectedModel properties] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewContent)
	{
		if ([inspectedItem isCollection])
			nbOfItems = [[(id <ETCollection>)inspectedItem contentArray] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelContent)
	{
		if ([inspectedModel isCollection])
			nbOfItems = [[inspectedModel contentArray] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewObject)
	{
		nbOfItems = [self numberOfSlotsInObject: inspectedItem];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelObject)
	{
		nbOfItems = [self numberOfSlotsInObject: inspectedModel];
	}
	else
	{
		ETLog(@"WARNING: Unknown display mode %d in -numberOfItemsInContainer: "
			"of %@", [self displayMode], self);
	}
	
	//ETLog(@"Returns %d as number of property or slot items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtIndex: (int)index
{
	id inspectedItem = [self layoutContext];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	// FIXME: Regenerating a meta layout item for the same layout context/item 
	// on each -container:itemAtIndex: call is expansive (see 
	// -[ETLayoutItemGroup copyWithZone:]. ... Caching the meta layout item is
	// probably worth to do.
	ETLayoutItem *metaItem =
		[ETLayoutItem layoutItemWithRepresentedItem: inspectedItem snapshot: NO];
	ETLayoutItem *propertyItem = AUTORELEASE([[ETLayoutItem alloc] init]);
	
	/* Inspected item is used as model */
	if (inspectedModel == nil)
		inspectedModel = inspectedItem;
	
	NSAssert1(inspectedModel != nil, @"Layout context of % must not be nil.", self);
	
	if ([self displayMode] == ETLayoutDisplayModeViewProperties)
	{
		NSString *property = [[metaItem properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		// FIXME: Instead using -description, write a generic ETObjectFormatter
		// For example, on table view display, the value is copied when passed 
		// in parameter to -[NSCell setObjectValue:]. If the value like an 
		// NSView instance doesn't implement -copyWithZone:, it leads to a 
		// crash. That's why having a generic formatter or always passing the
		// object description string is critical.
		[propertyItem setValue: [[metaItem valueForProperty: property] stringValue] forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelProperties)
	{
		NSString *property = [(NSArray *)[inspectedModel properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		[propertyItem setValue: [inspectedModel valueForProperty: property] forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewContent)
	{
		NSAssert2([inspectedItem isCollection], 
			@"Inspected item %@ must conform to protocol ETCollection "
			@"since -numberOfItemsInContainer: returned a non-zero value in %@",
			inspectedItem, self);

		ETLayoutItem *child = [[(id <ETCollection>)inspectedItem contentArray] objectAtIndex: index];

		[propertyItem setValue: [NSNumber numberWithInt: index] forProperty: @"content"];
		[propertyItem setValue: child forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelContent)
	{
		NSAssert2([inspectedModel isCollection], 
			@"Inspected model %@ must conform to protocol ETCollection "
			@"since -numberOfItemsInContainer: returned a non-zero value in %@",
			inspectedModel, self);
			
		id child = [[(id <ETCollection>)inspectedModel contentArray] objectAtIndex: index];

		[propertyItem setValue: [NSNumber numberWithInt: index] forProperty: @"content"];
		[propertyItem setValue: child forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewObject)
	{
		propertyItem = [self object: inspectedItem itemRepresentingSlotAtIndex: index];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelObject)
	{
		propertyItem = [self object: inspectedModel itemRepresentingSlotAtIndex: index];
	}
	else
	{
		ETLog(@"WARNING: Unknown display mode %d in -container:itemAtIndex: "
			"of %@", [self displayMode], self);
	}

	//ETLog(@"Returns property or slot item %@ at index %d in %@", propertyItem, index, container);
	
	return propertyItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	NSArray *displayedProperties = nil;

	switch ([self displayMode])
	{
		case ETLayoutDisplayModeViewProperties:
		case ETLayoutDisplayModeModelProperties:
			displayedProperties = [NSArray arrayWithObjects: @"property", @"value", nil];
			break;
		case ETLayoutDisplayModeViewContent:
		case ETLayoutDisplayModeModelContent:
			displayedProperties = [NSArray arrayWithObjects: @"content", @"value", nil];
			break;
		case ETLayoutDisplayModeViewObject:
		case ETLayoutDisplayModeModelObject:
			displayedProperties = [NSArray arrayWithObjects: @"slot", @"type", @"value", nil];
			break;
	}
	
	return displayedProperties;
}

@end
