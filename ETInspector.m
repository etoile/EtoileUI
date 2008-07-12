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
	// TODO: Next line shouldn't be needed, ETEtoileUIBuilder should be invoked 
	// transparently on nib loading.
	// FIXME: item implies a memory leak, the container bound to this item must
	// be assigned to self and this item discarded.
	//id item = [[ETEtoileUIBuilder builder] renderWindow: window];
	[[ETEtoileUIBuilder builder] renderWindow: window];

	[itemGroupView setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
	[itemGroupView setSource: self];
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
	/*[itemGroupView setSource: self];
	[itemGroupView setDelegate: self];*/
	ETLog(@"Selection did change for %@ received in %@", [notif object], self);
	
	[propertyView reloadAndUpdateLayout];
}

- (void) doubleClickInPropertyView: (id)sender
{
	ETLayoutItem *item = [[propertyView items] objectAtIndex: [propertyView selectionIndex]];
	
	[[[item inspector] window] makeKeyAndOrderFront: self];
}

- (int) container: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)path
{
	int nbOfItems = 0;
	
	if ([container isEqual: itemGroupView])
	{
		nbOfItems =	[self itemGroupView: container numberOfItemsAtPath: path];
	}
	else if ([container isEqual: propertyView])
	{
		nbOfItems = [self propertyView: container numberOfItemsAtPath: path];
	}
	
	return nbOfItems;
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtPath: (NSIndexPath *)path
{
	ETLayoutItem *item = nil;
	
	if ([container isEqual: itemGroupView])
	{
		item =	[self itemGroupView: container itemAtPath: path];
	}
	else if ([container isEqual: propertyView])
	{
		item = [self propertyView: container itemAtPath: path];
	}
	
	return item;
}

- (int) itemGroupView: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)indexPath 
{
	int nbOfItems = 0;

	NSAssert(indexPath != nil, @"Index path %@ passed to "
		@"data source must not be nil");	
	/*NSAssert1([keyPath characterAtIndex: 0] == '/', @"First character of key "
		@"path %@ passed to data source must be /", keyPath);*/
	
	if ([indexPath length] == 0)
	{
		nbOfItems = [[self inspectedItems] count];
	}
	else
	{
		unsigned int index = [indexPath firstIndex];
		NSIndexPath *indexSubpath = [indexPath indexPathByRemovingFirstIndex];
		
		/*NSAssert1(index == 0 && [pathComp isEqual: @"0"] == NO,
			@"Path components must be indexes for key path %@", keyPath);*/
		NSAssert2(index < [[self inspectedItems] count], @"First index %d in "
			@"index path %@ must be inferior to inspected item number", 
			index, indexPath);
	
		ETLayoutItem *item = [[self inspectedItems] objectAtIndex: index];
		
		NSAssert1([item isGroup], @"For "
			@"-numberOfItemsAtPath:, path %@ must reference an instance of "
			@"ETLayoutItemGroup kind", indexPath);
		
		if ([indexSubpath length] > 0)
			item = [(ETLayoutItemGroup *)item itemAtIndexPath: indexSubpath];
		
		if (item != nil)
		{
			nbOfItems = [[(ETLayoutItemGroup *)item items] count];
		}
		else
		{
			ETLog(@"WARNING: Found no item at subpath %@ for inspector %@", indexSubpath, self);
		}
	}
	
	//ETLog(@"Returns %d as number of items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) itemGroupView: (ETContainer *)container itemAtPath: (NSIndexPath *)indexPath
{
	unsigned int index = [indexPath firstIndex];
	NSIndexPath *indexSubpath = [indexPath indexPathByRemovingFirstIndex];
	
	/*NSAssert1(index == 0 && [pathComp isEqual: @"0"] == NO,
		@"Path components must be indexes for key path %@", keyPath);*/
	
	NSAssert3(index < [[self inspectedItems] count], @"Index %d in key "
		@"path %@ position %d must be inferior to inspected item number", 
		index, 0, indexPath);

	ETLayoutItem *item = [[self inspectedItems] objectAtIndex: index];
	
	if ([indexSubpath length] > 0)
		item = [(ETLayoutItemGroup *)item itemAtIndexPath: indexSubpath];
	if (item == nil)
		ETLog(@"WARNING: Found no item at subpath %@ for inspector %@", indexSubpath, self);

	/* Create a meta layout item */
	if ([item isGroup])
	{
		item = [ETLayoutItem layoutItemWithRepresentedItem: item snapshot: YES];
	}
	else
	{
		item = [ETLayoutItem layoutItemWithRepresentedItem: item snapshot: YES];
	}
	
	//ETLog(@"Returns item %@ at path %@ in %@", item, indexSubpath, container);

	return item;
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
	
	//ETLog(@"Returns %d as number of property items in %@", nbOfPropertyItems, container);
	
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
	//ETLog(@"Returns property item %@ at index %d in %@", item, index, container);
	
	AUTORELEASE(propertyItem);
	
	return propertyItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	NSArray *displayedProperties = nil;

	if ([container isEqual: itemGroupView])
	{
		displayedProperties = [NSArray arrayWithObjects: @"icon", 
			@"displayName", @"UIMetalevel", nil];
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
		case 7:
			layoutClass = [ETViewModelLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	id firstSelectedItem = [[itemGroupView selectedItemsInLayout] firstObject];
	id representedItem = [firstSelectedItem representedObject];
	
	if ([representedItem respondsToSelector: @selector(setLayout:)])
		[representedItem setLayout: (ETLayout *)AUTORELEASE([[layoutClass alloc] init])];
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
		[itemGroupView reloadAndUpdateLayout];
	}
	[self setRepresentedObject: nil];
	
	/* Update inspector window title */ 
	id inspectedItem = [[self inspectedItems] firstObject];
	
	if (inspectedItem != nil)
	{
		NSString *name = [inspectedItem displayName];
		NSString *inspectorTitle = nil;
		
		[self setRepresentedObject: inspectedItem];
		
		if ([name length] > 25)
			name = [[name substringToIndex: 25] append: @"…"];
		inspectorTitle = [NSString stringWithFormat: @"%@ (M%d UI)", name,
			[self UIMetalayer]];
		[[self window] setTitle: inspectorTitle];
	}
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
