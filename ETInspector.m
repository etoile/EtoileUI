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
#import <EtoileUI/NSObject+Etoile.h>
#import <EtoileUI/NSIndexPath+Etoile.h>
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
	[itemGroupView setLayout: AUTORELEASE([[ETOutlineLayout alloc] init])];
	[itemGroupView setSource: self];
	[itemGroupView setDelegate: self];
	[itemGroupView setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[itemGroupView setTarget: self];
	
	[propertyView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];
	[propertyView setSource: self];
	[propertyView setDelegate: self];
	[propertyView setDoubleAction: @selector(doubleClickInPropertyView:)];
	[propertyView setTarget: self];
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

- (int) container: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)indexPath 
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
		
		NSAssert1([item isKindOfClass: [ETLayoutItemGroup class]], @"For "
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

- (ETLayoutItem *) container: (ETContainer *)container itemAtPath: (NSIndexPath *)indexPath
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
		item = [item itemAtIndexPath: indexSubpath];
	if (item == nil)
		ETLog(@"WARNING: Found no item at subpath %@ for inspector %@", indexSubpath, self);

	/* Create a meta layout item */
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		item = [ETLayoutItemGroup layoutItemOfLayoutItem: item];
	}
	else
	{
		item = [ETLayoutItem layoutItemOfLayoutItem: item];
	}
	
	ETLog(@"Returns item %@ at path %@ in %@", item, indexSubpath, container);

	return item;
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
		ETLayoutItem *item = [[itemGroupView items] objectAtIndex: selection];
		
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

- (ETLayoutItem *) itemAtIndex: (int)index inPropertyView: (ETContainer *)container
{
	ETLayoutItem *item = [[itemGroupView items] objectAtIndex: [itemGroupView selectionIndex]];
	ETLayoutItem *propertyItem = [[ETLayoutItem alloc] init];
	
#if 1
	NSString *property = [[item properties] objectAtIndex: index];

	[propertyItem setValue: property forProperty: @"property"];
	[propertyItem setValue: [item valueForProperty: property] forProperty: @"value"];
#else

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
		case 7:
			layoutClass = [ETViewModelLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	ETLayoutItem *representedItem = [[itemGroupView items] objectAtIndex: 0];
	
	representedItem = (ETLayoutItem *)[representedItem representedObject];
	
	if ([[representedItem closestAncestorContainer] respondsToSelector: @selector(setLayout:)])
		[[representedItem closestAncestorContainer] setLayout: (ETLayout *)AUTORELEASE([[layoutClass alloc] init])];
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

- (IBAction) stack: (id)sender
{
	NSIndexSet *selection = [itemGroupView selectionIndexes];
	NSEnumerator *e = [[[itemGroupView layoutItem] items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		int itemIndex = [itemGroupView indexOfItem: item];
		
		if ([selection containsIndex: itemIndex] && [item isMetaLayoutItem])
		{
			ETLayoutItem *inspectedItem = (ETLayoutItem *)[item representedObject];
		
			if ([inspectedItem isKindOfClass: [ETLayoutItemGroup class]])
			{
				if ([inspectedItem isStacked])
				{
					[inspectedItem stack];
				}
				else
				{
					[inspectedItem unstack];
				}
			}
		}
	}
}

@end

@implementation ETLayoutItem (ETInspector)
/*
+ (ETLayoutItem *) layoutItemWithInspectedObject: (id)object
{
	ETLayoutItem *item = [[ETLayoutItem alloc] initWithRepresentedObject: object];
	NSArray *ivars = [[item representedObject] instanceVariables];
	NSArray *methods = [[item representedObject] methods];
	NSArray *slots = [[NSArray arrayWithArray: ivars] 
	            arrayByAddingObjectsFromArray: methods];
	NSEnumerator *e = [slots objectEnumerator];
	id slot = nil;
	
	while ((slot = [e nextObject]) != nil)
	{
		if ([slot isKindOfClass: [ETInstanceVariable class]])
		{
			id ivarValue = [slot value];
			
			if (ivarValue == nil)
			{
				ivarValue = @"nil";
			}
			[item setValue: [ivarValue description] forProperty: @"value"];
		}
		else if ([slot isKindOfClass: [ETMethod class]])
		{
			[propertyItem setValue: @"method (objc)" forProperty: @"value"];
		}
	}
	
	return AUTORELEASE(item);
}*/

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

@implementation NSObject (ETInspector)

- (id <ETInspector>) inspector
{
	ETInspector *inspector = [[ETInspector alloc] init];

	return AUTORELEASE(inspector);
}

@end

@implementation ETViewModelLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		BOOL nibLoaded = [NSBundle loadNibNamed: @"ViewModelPrototype" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib ViewModelPrototype");
			RELEASE(self);
			return nil;
		}
		
		_displayMode = ETLayoutDisplayModeView;
    }
    
	return self;
}

- (void) awakeFromNib
{
	NSLog(@"Awaking from nib for %@", self);
	
	[propertyView setLayout: AUTORELEASE([[ETTableLayout alloc] init])];
	[propertyView setSource: self];
	[propertyView setDelegate: self];
	[propertyView setDoubleAction: @selector(doubleClickInPropertyView:)];
	[propertyView setTarget: self];

	/* Because this outlet will be removed from its superview, it must be 
	   retained like any other to-one relationship ivars. 
	   If this proto view is later replaced by calling 
	   -setDisplayViewPrototype:, this retain will be balanced by the release
	   in ASSIGN. */ 
	RETAIN(_displayViewPrototype);

	/* Adjust _displayViewPrototype outlet */
	//[self setDisplayViewPrototype: _displayViewPrototype];
}

- (void) setDisplayViewPrototype: (NSView *)protoView
{
	[super setDisplayViewPrototype: protoView];

	//[tv registerForDraggedTypes: [NSArray arrayWithObject: @"ETLayoutItemPboardType"]];
	
	/*if ([tv dataSource] == nil)
		[tv setDataSource: self];
	if ([tv delegate] == nil)
		[tv setDelegate: self];*/
}


- (ETLayoutDisplayMode) displayMode
{
	return _displayMode;
}

- (void) setDisplayMode: (ETLayoutDisplayMode)mode
{
	_displayMode = mode;
}

- (void) switchDisplayMode: (id)sender
{
	if ([self displayMode] == ETLayoutDisplayModeView)
	{
		[self setDisplayMode: ETLayoutDisplayModeModel];
	}
	else
	{
		[self setDisplayMode: ETLayoutDisplayModeView];
	}
	[propertyView updateLayout]; // [self render];
}

- (void) renderWithLayoutItems: (NSArray *)items;
{
	[[self container] setDisplayView: [self displayViewPrototype]];
	[propertyView updateLayout];
}

- (void) doubleClickInPropertyView: (id)sender
{
	ETLayoutItem *item = [[[self container] items] objectAtIndex: [propertyView selectionIndex]];
	
	[[[item inspector] window] makeKeyAndOrderFront: self];
}

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	id 	inspectedObject = [self layoutContext];
	int nbOfItems = 0;
	
	/* Verify the layout is currently bound to a layout context like a container */
	if ([self layoutContext] == nil)
		return 0;
	
	if ([self displayMode] == ETLayoutDisplayModeView)
	{
		//NSAssert([inspectedObject properties] != nil, @"Represented object of a layout item should never be nil");
		ETLog(@"Found no properties for inspected object %@", inspectedObject);
		nbOfItems = [[inspectedObject properties] count];
	}
	else
	{
		if ([[self layoutContext] isKindOfClass: [ETLayoutItem class]])
		{
			inspectedObject = [inspectedObject representedObject];
		}
		else if ([[self layoutContext] isKindOfClass: [ETContainer class]])
		{
			// FIXME: Remove this branch when represented object and source have 
			// been unified at layout item level for ETContainer
			inspectedObject = [inspectedObject source];	
		}
		
		if (inspectedObject != nil)
		{
			NSArray *ivars = [inspectedObject instanceVariables];
			NSArray *methods = [inspectedObject methods];
			NSArray *slots = [[NSArray arrayWithArray: ivars] 
	                    arrayByAddingObjectsFromArray: methods];
		
			nbOfItems = [slots count];
		}
	}
	
	ETLog(@"Returns %d as number of property or slot items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container
{
	id inspectedObject = [self layoutContext];
	ETLayoutItem *propertyItem = [[ETLayoutItem alloc] init];
	
	NSAssert1(inspectedObject != nil, @"Layout context of % must not be nil.", self);
	
	if ([self displayMode] == ETLayoutDisplayModeView)
	{
		NSString *property = [[inspectedObject properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		[propertyItem setValue: [inspectedObject valueForProperty: property] forProperty: @"value"];
	}
	else
	{
		if ([[self layoutContext] isKindOfClass: [ETLayoutItem class]])
		{
			inspectedObject = [inspectedObject representedObject];
		}
		else if ([[self layoutContext] isKindOfClass: [ETContainer class]])
		{
			// FIXME: Remove this branch when represented object and source have 
			// been unified at layout item level for ETContainer
			inspectedObject = [inspectedObject source];	
		}
		
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
	}
	
	ETLog(@"Returns property or slot item %@ at index %d in %@", inspectedObject, index, container);
	
	return AUTORELEASE(propertyItem);
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	NSArray *displayedProperties = nil;

	if ([self displayMode] == ETLayoutDisplayModeView)
	{
		displayedProperties = [NSArray arrayWithObjects: @"property", @"value", nil];
	}	
	else
	{
		displayedProperties = [NSArray arrayWithObjects: @"slot", @"type", @"value", nil];
	}
	
	return displayedProperties;
}

@end
