/*  <title>ETInspector</title>

	ETInspector.m
	
	<abstract>Inspector protocol and related Inspector representation class 
	which can be used as an inspector view wrapper.</abstract>
 
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

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETLayoutItem+Reflection.h>
#import <EtoileUI/ETInspector.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETLineLayout.h>
#import <EtoileUI/ETStackLayout.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/ETPaneLayout.h>
#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/ETViewModelLayout.h>
#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETCompatibility.h>

@interface ETInspector (EtoilePrivate)
- (int) itemGroupView: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)indexPath;
- (ETLayoutItem *) itemGroupView: (ETContainer *)container itemAtPath: (NSIndexPath *)indexPath;
- (int) propertyView: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)path;
- (ETLayoutItem *) propertyView: (ETContainer *)container itemAtPath: (NSIndexPath *)path;
- (void) updateInspectorWindowTitle;
@end


@implementation ETInspectorLayout

- (id) inspectedObject
{
	return [(ETLayoutItem *)[self layoutContext] representedObject];
}

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
		_inspectedObjects = nil;
		
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
	DESTROY(_inspectedObjects);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	// TODO: Next line shouldn't be needed, ETEtoileUIBuilder should be invoked 
	// transparently on nib loading.
	// FIXME: item implies a memory leak, the container bound to this item must
	// be assigned to self and this item discarded.
	//id item = [[ETEtoileUIBuilder builder] renderWindow: window];
	[[ETEtoileUIBuilder builder] renderWindow: window];

	[layoutPopup removeAllItems];
	FOREACH([ETLayout registeredLayoutClasses], layoutClass, ETLayout *)
	{
		[layoutPopup addItemWithTitle: [layoutClass displayName]];
		[[layoutPopup lastItem] setRepresentedObject: layoutClass];
	}

	[itemGroupView setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
	// TODO: Figure out a nice way to restore the layout as is because 
	// displayed properties are lost on layout changes (happens only if the 
	// user wants to customize the inspector UI).
	[[itemGroupView layout] setDisplayedProperties: 
		[NSArray arrayWithObjects: @"icon", @"displayName", @"UIMetalevel", nil]];
	[itemGroupView setSource: [itemGroupView layoutItem]];
	[itemGroupView setDelegate: self];
	[itemGroupView setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[itemGroupView setTarget: self];

	[propertyView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];
	[propertyView setSource: self];
	// NOTE: If this next line is uncommented, -containerSelectionDidChange:
	// must be updated to filter out property view related notifications.
	//[propertyView setDelegate: self];
	// NOTE: The following code is commented out to enable property editing
	// instead of browsing.
	//[propertyView setDoubleAction: @selector(doubleClickInPropertyView:)];
	//[propertyView setTarget: self];
}

- (void) containerSelectionDidChange: (NSNotification *)notif
{
	ETDebugLog(@"Selection did change for %@ received in %@", [notif object], self);
	
	[propertyView reloadAndUpdateLayout];
}

- (void) doubleClickInPropertyView: (id)sender
{
	ETLayoutItem *item = [[propertyView items] objectAtIndex: [propertyView selectionIndex]];
	
	[[[item inspector] window] makeKeyAndOrderFront: self];
}

- (int) itemGroup: (ETLayoutItemGroup *)baseItem numberOfItemsAtPath: (NSIndexPath *)path
{
	NSAssert([[baseItem supervisorView] isEqual: propertyView], @"Inspector must only receive"
		@"propertyView as first parameter in source methods");
	
	return [self propertyView: [baseItem supervisorView] numberOfItemsAtPath: path];
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtPath: (NSIndexPath *)path
{
	NSAssert([[baseItem supervisorView] isEqual: propertyView], @"Inspector must only receive"
		@"propertyView as first parameter in source methods");

	return [self propertyView: [baseItem supervisorView] itemAtPath: path];
}

- (int) propertyView: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)path
{
	int nbOfPropertyItems = 0;
	ETLayoutItem *item = [[itemGroupView selectedItemsInLayout] firstObject];
	
	if (item != nil)
	{
		item = [item representedObject];
		
		NSAssert([item properties] != nil, @"Represented object of a layout item should never be nil");
		#if 1
		nbOfPropertyItems = [[item properties] count];
		#else
		
		NSArray *ivars = [[item representedObject] instanceVariables];
		NSArray *methods = [[item representedObject] methods];
		NSArray *slots = [[NSArray arrayWithArray: ivars] 
	                arrayByAddingObjectsFromArray: methods];
		
		nbOfPropertyItems = [slots count];
		#endif
	}
	
	//ETDebugLog(@"Returns %d as number of property items in %@", nbOfPropertyItems, container);
	
	return nbOfPropertyItems;
}

- (ETLayoutItem *) propertyView: (ETContainer *)container itemAtPath: (NSIndexPath *)path
{
	ETLayoutItem *item = [[[itemGroupView selectedItemsInLayout] firstObject] representedObject];
	ETLayoutItem *propertyItem = [[ETLayoutItem alloc] init];
	int index = [path lastIndex];
	
#if 1
	NSString *property = [[item properties] objectAtIndex: index];
	ETProperty *propertyRep = [ETProperty propertyWithName: property representedObject: item];
	
	[propertyItem setRepresentedObject: propertyRep];
#else
	NSString *property = [[item properties] objectAtIndex: index];

	[propertyItem setValue: property forProperty: @"property"];
	// FIXME: Instead using -description, write a generic ETObjectFormatter
	[propertyItem setValue: [[item valueForProperty: property] description] forProperty: @"value"];
#endif

#if 0

	NSArray *ivars = [[item representedObject] instanceVariables];
	NSArray *methods = [[item representedObject] methods];
	NSArray *slots = [[NSArray arrayWithArray: ivars] 
	            arrayByAddingObjectsFromArray: methods];
	id slot = [slots objectAtIndex: index];
	
	[propertyItem setValue: [slot name] forProperty: @"property"];
	if ([slot isKindOfClass: [ETInstanceVariable class]])
	{
		id ivarValue = [slot value];
		
		if (ivarValue == nil)
		{
			ivarValue = @"nil";
		}
		[propertyItem setValue: [ivarValue description] forProperty: @"value"];
	}
	else if ([slot isKindOfClass: [ETMethod class]])
	{
		[propertyItem setValue: @"method (objc)" forProperty: @"value"];
	}
#endif	
	//ETDebugLog(@"Returns property item %@ at index %d in %@", item, index, container);
	
	AUTORELEASE(propertyItem);
	
	return propertyItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	NSAssert([container isEqual: propertyView], @"Inspector must only receive"
		@"propertyView as first parameter in source methods");

	return [NSArray arrayWithObjects: @"property", @"value", nil];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = [[sender selectedItem] representedObject];
	
	id firstSelectedItem = [[itemGroupView selectedItemsInLayout] firstObject];
	id representedItem = [firstSelectedItem representedObject];
	
	if ([representedItem respondsToSelector: @selector(setLayout:)])
		[representedItem setLayout: [layoutClass layout]];
}

- (NSArray *) inspectedObjects
{
	return _inspectedObjects;
}

- (void) setInspectedObjects: (NSArray *)objects
{
	if ([objects isEmpty])
	{
		ASSIGN(_inspectedObjects, nil);
	}
	else
	{
		ASSIGN(_inspectedObjects, objects);
		[[itemGroupView layoutItem] setRepresentedObject: _inspectedObjects];
		[itemGroupView reloadAndUpdateLayout];
	}
	[self setRepresentedObject: nil];
	
	[self updateInspectorWindowTitle];
}

- (void) updateInspectorWindowTitle
{
	id inspectedItem = [[self inspectedObjects] firstObject];
	
	if (inspectedItem == nil)
		return;

	NSString *name = [inspectedItem displayName];
	NSString *inspectorTitle = nil;
	
	[self setRepresentedObject: inspectedItem];
	
	if ([name length] > 25)
		name = [[name substringToIndex: 25] append: @"…"];
	inspectorTitle = [NSString stringWithFormat: @"%@ (M%d UI)", name,
		[self UIMetalayer]];
	[[self window] setTitle: inspectorTitle];
}

- (NSWindow *) window
{
	return window;
}

- (NSPanel *) panel
{
	return (NSPanel *)window;
}

- (IBAction) inspect: (id)sender
{
	[[NSApplication sharedApplication] sendAction: @selector(inspect:) to: nil from: sender];
}

- (IBAction) stack: (id)sender
{
	NSIndexSet *selection = [itemGroupView selectionIndexes];
	NSEnumerator *e = [[(ETLayoutItemGroup *)[itemGroupView layoutItem] items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		int itemIndex = [itemGroupView indexOfItem: item];
		
		if ([selection containsIndex: itemIndex] && [item isMetaLayoutItem])
		{
			ETLayoutItem *inspectedItem = (ETLayoutItem *)[item representedObject];
		
			if ([inspectedItem isGroup])
			{
				if ([(ETLayoutItemGroup *)inspectedItem isStacked])
				{
					[(ETLayoutItemGroup *)inspectedItem stack];
				}
				else
				{
					[(ETLayoutItemGroup *)inspectedItem unstack];
				}
			}
		}
	}
}

@end



@implementation NSObject (ETInspector)

- (id <ETInspector>) inspector
{
	ETInspector *inspector = [[ETInspector alloc] init];

	return AUTORELEASE(inspector);
}

@end
