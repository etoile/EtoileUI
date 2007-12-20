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
#import <EtoileUI/NSObject+Etoile.h>
#import <EtoileUI/NSObject+Model.h>
#import <EtoileUI/NSIndexPath+Etoile.h>
#import <EtoileUI/ETCollection.h>
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
		item = [ETLayoutItemGroup layoutItemOfLayoutItem: item];
	}
	else
	{
		item = [ETLayoutItem layoutItemOfLayoutItem: item];
	}
	
	//ETLog(@"Returns item %@ at path %@ in %@", item, indexSubpath, container);

	return item;
}

- (int) propertyView: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)path
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

- (ETLayoutItem *) propertyView: (ETContainer *)container itemAtPath: (NSIndexPath *)path
{
	ETLayoutItem *item = [[itemGroupView items] objectAtIndex: [itemGroupView selectionIndex]];
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
		displayedProperties = [NSArray arrayWithObjects: @"icon", @"displayName", nil];
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
	
	/* If the item represents a property, the related meta layout item must 
	   represent the property name as a value of property 'kProperty' and the 
	   value of the property as a value of property 'kValue'.
	   
	   Example:
	             
					    Objects and Meta Objects                           Metalevel
				 
	   - Inspected item (layout item or model object)                    <- level 0
	       kPrice = 5 
		   kPrice is a property and 5 a value
	   - Meta Inspected item (property view root node)                   <- level 1
	       kPrice = 5 
		   kPrice is a property and 5 a value
	   - Property item (represents a single property of inspected item)  <- level 1
	       kProperty = kPrice
		   kValue = 5
		   kName = kPrice
	   So every properties of inspected item are represented by a property item
	   which is created indirectly when a meta layout item is instantiated to 
	   both play the role of the property view root node and represents the 
	   inspected item. 
	   Now if the view displaying the property item list is inspected, we must 
	   create a new meta layout item for each property item to be inspected.
	   - Meta Item of Property Item                                      <- level 2
		   kProperty = kPrice
		   kValue = 5
		   kName = kPrice
	   - Property Items for Meta Property item                           <- level 2
	     (represents a single property of inspected property item)
		 Because Meta Property Item has 3 properties, 3 property items will be
		 created to represent Meta Property Item in a property view:
	     - property item 1
	       kProperty = kProperty
		   kValue = kPrice
		   kName = KProperty
		 - property item 2
		   kProperty = kValue
		   kValue = 5
		   kName = kValue
		 - property item 3
		   kProperty = kName
		   kValue = kPrice
		   kName = kName
	   etc.
	   
	   From here, you can create new Meta Item or Property Items based on 
	   the layout items mentionned above. There are no limitations to the
	   introspection depth, but there is rarely an interest to go beyond
	   meta levels 1 or 2.
	*/
	// NOTE: this code may be better located in -[ETLayoutItem valueForProperty:]
	if ([[item properties] containsObject: @"property"])
	{
		propertyName = [metaLayoutItem valueForProperty: @"property"];
		if (propertyName != nil)
		{
			[metaLayoutItem setValue: propertyName forProperty: @"name"];
			[metaLayoutItem setValue: [metaLayoutItem valueForProperty: @"property"]
						 forProperty: @"property"];
		}
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

- (id) initWithLayoutView: (NSView *)view
{
	self = [super initWithLayoutView: view];
    
	if (self != nil)
		_displayMode = ETLayoutDisplayModeViewProperties;
    
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
	[propertyView setHasVerticalScroller: YES];
	[propertyView setHasHorizontalScroller: YES];
	[propertyView reloadAndUpdateLayout];

	/* Because this outlet will be removed from its superview, it must be 
	   retained like any other to-one relationship ivars. 
	   If this proto view is later replaced by calling 
	   -setLayoutView:, this retain will be balanced by the release
	   in ASSIGN. */ 
	RETAIN(_displayViewPrototype);

	/* Adjust _displayViewPrototype outlet */
	//[self setLayoutView: _displayViewPrototype];
}

- (NSString *) nibName
{
	return @"ViewModelPrototype";
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
	NSAssert1([sender isKindOfClass: [NSPopUpButton class]], 
		@"-switchDisplayMode: must be sent by an instance of NSPopUpButton class "
		@"kind unlike %@", sender);
	[self setDisplayMode: [[sender selectedItem] tag]];
	[propertyView reloadAndUpdateLayout]; // [self render];
}

- (void) setLayoutContext: (id <ETLayoutingContext>)context
{
	[super setLayoutContext: context];
}

- (void) renderWithLayoutItems: (NSArray *)items
{
	if ([self container] == nil)
	{
		ETLog(@"WARNING: Layout context %@ must have a container otherwise "
			@"view-based layout %@ cannot be set", [self layoutContext], self);
		return;
	}

	[self setUpLayoutView];
	//[propertyView reloadAndUpdateLayout];
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
	
	return 3; //nbOfSlots;
}

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	/* Verify the layout is currently bound to a layout context like a container */
	if ([self layoutContext] == nil)
	{
		ETLog(@"WARNING: Layout context is missing for -numberOfItemsInContainer: in %@", self);
		return 0;
	}

	ETLayoutItem *inspectedItem = (ETLayoutItem *)[self layoutContext];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	ETLayoutItem *metaItem = [ETLayoutItem layoutItemOfLayoutItem: inspectedItem];
	int nbOfItems = 0;
	
	// NOTE: Fails when the inspected model is a dictionary...
	//NSAssert([inspectedModel properties] != nil, @"Represented object of a layout item should never be nil");
		
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
		/* See next method -container:itemAtIndex: to understand why we 
		   use [inspectedItem properties] and not [inspectedModel properties] */
		nbOfItems = [[inspectedItem properties] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewContent)
	{
		if ([inspectedItem conformsToProtocol: @protocol(ETCollection)])
			nbOfItems = [[(id <ETCollection>)inspectedItem contentArray] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelContent)
	{
		if ([inspectedModel conformsToProtocol: @protocol(ETCollection)])
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
	ETLayoutItem *inspectedItem = (ETLayoutItem *)[self layoutContext];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	// FIXME: Regenerating a meta layout item for the same layout context/item 
	// on each -container:itemAtIndex: call is expansive (see 
	// -[ETLayoutItemGroup copyWithZone:]. ... Caching the meta layout item is
	// probably worth to do.
	ETLayoutItem *metaItem = [ETLayoutItem layoutItemOfLayoutItem: inspectedItem];
	ETLayoutItem *propertyItem = AUTORELEASE([[ETLayoutItem alloc] init]);
	
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
		[propertyItem setValue: [[metaItem valueForProperty: property] description] forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelProperties)
	{
		/* Because [inspectedModel properties] doesn't exist we use 
		   inspectedItem instead. In this particular case, ETLayoutItem plays 
		   the role of a meta object representing the model object 
		   May be we should get rid of that by implementing -properties on 
		   NSObject (simply returning an empty array or ni by default) */
		NSString *property = [[inspectedItem properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		[propertyItem setValue: [inspectedItem valueForProperty: property] forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeViewContent)
	{
		NSAssert2([inspectedItem conformsToProtocol: @protocol(ETCollection)], 
			@"Inspected item %@ must conform to protocol ETCollection "
			@"since -numberOfItemsInContainer: returned a non-zero value in %@",
			inspectedItem, self);

		ETLayoutItem *child = [[(id <ETCollection>)inspectedItem contentArray] objectAtIndex: index];

		[propertyItem setValue: [NSNumber numberWithInt: index] forProperty: @"content"];
		[propertyItem setValue: child forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelContent)
	{
		NSAssert2([inspectedModel conformsToProtocol: @protocol(ETCollection)], 
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
