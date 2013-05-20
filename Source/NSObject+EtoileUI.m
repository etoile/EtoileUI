/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import "NSObject+EtoileUI.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETInspector.h"
#import "ETViewModelLayout.h"
#import "ETCompatibility.h"
#include <objc/runtime.h>

@interface NSObject (EtoileUIPrivate)
+ (NSString *) stripClassName;
+ (NSString *) stringBySpacingCapitalizedWordsOfString: (NSString *)name;
@end


@implementation NSObject (EtoileUI)

/** Returns NSOrderedSame.

This NSObject extension makes possible to sort any object types, even mixed 
together, and prevent sort descriptors to raise an exception when -compare: 
is not implemented in an NSObject subclass. */
- (NSComparisonResult) compare: (id)anObject
{
	return NSOrderedSame;
}

/* Basic Properties */

/** Returns the icon used to represent unknown object.

Subclasses can override this method to return an icon that suits and describes 
better their own objects. */
- (NSImage *) icon
{
	// FIXME: Asks Jesse to create an icon representing an unknown object
	return nil;
}

/* Lively feeling */

/** Shows the receiver content in the object browser panel and allows to 
navigate the whole Étoilé environment object graph (including outside the 
application the browsed object is part of). */
- (IBAction) browse: (id)sender
{
	// FIXME: Implement
	ETDebugLog(@"browse %@", self);
}

/** Shows the layout item representing the receiver by enforcing referential 
stability (more commonly named spatiality in the case of UI objects).

If the receiver is a layout item, this layout item is simply brought to front 
and made the first responder. 

When the receiver is some other kind of objects, the object registry is looked 
up to know whether there is a layout item bound to the receiver. If the lookup 
succeeds, the matching layout item is requested to display itself by sending 
-view: to it.<br />
If no visual representation exists, a new layout item is created and bound to 
the receiver with the object registry. Then this layout item is	made visible 
and active as described in the previous paragraph. */
- (IBAction) view: (id)sender
{
	// TODO: Implement. Request the type (UTI) of the receiver, the looks up
	// in the aspect repository which item template should be used to create a
	// UI represention of the receiver. Simply copy the template and set the 
	// receiver as the represented object, then attach the copied item to the 
	// window group.
}

/** Shows an inspector which provides informations about the receiver. 

The inspector makes possible to edit the object state and behavior. 

For some objects, the built-in inspector could have been overriden by a 
third-party inspector. By inspecting a third-party inspector, you can easily 
revert it or bring back the basic inspector. */
- (IBAction) inspect: (id)sender
{
	id <ETInspector> inspector = nil;

	if ([self conformsToProtocol: @protocol(ETObjectInspection)])
		inspector = [self inspector];

	if (inspector == nil)
		inspector = [[ETInspector alloc] init]; // FIXME: Leak

	ETDebugLog(@"inspect %@", self);
	[inspector setInspectedObjects: A(self)];
	[[inspector panel] makeKeyAndOrderFront: self];
}

/** Shows a developer-centric inspector based on ETViewModelLayout which 
provides informations about the receiver object. This explorer inspector allows 
to inspect properties, instances variables, methods and also the content when 
the receiver is a collection (ETCollection protocol must be implemented).

The inspector makes possible to edit the object state and behavior. 

Unlike the inspector shown by -inspect:, this built-in inspector is not expected 
to overriden by a third-party inspector. */
- (IBAction) explore: (id)sender
{
	// TODO: Should be -itemGroupWithRepresentedObject: once ETLayoutItemGroup 
	// is able to create a container as supervisor view by itself if needed.
	ETLayoutItemGroup *item = [[ETLayoutItemFactory factory] itemGroup];
	ETViewModelLayout *layout = [ETViewModelLayout layout];

	[item setRepresentedObject: self];
	if ([self isLayoutItem])
	{
		[layout setShouldInspectRepresentedObjectAsView: YES];
		[layout setDisplayMode: ETLayoutDisplayModeViewObject];
	}
	else
	{
		[layout setDisplayMode: ETLayoutDisplayModeModelObject];
	}
	[item setLayout: layout];
	[item setName: [NSString stringWithFormat: _(@"Explorer %@"), [self primitiveDescription]]];
	[item setSize: NSMakeSize(350, 500)];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: item];
}

/** Shows a source code editor to view or edit receiver class source code.
 
For recompilable classes (implemented in Smalltalk), the editor lets you edit 
and compile the code, otherwise the source code is read-only e.g. for Objective-C. */
- (IBAction) editCode: (id)sender
{

}

/* Introspection Utility */

/** Returns the display name used to present the receiver or its instances in 
in various EtoileUI builtin facilities such as an inspector. */
+ (NSString *) displayName
{
	return [[self stripClassName] stringBySpacingCapitalizedWords];
}

/** Overrides. */
+ (NSString *) baseClassName
{
	return @"Object";
}

/* Removes collision prefix and base suffix of class names. */
+ (NSString *) stripClassName
{
	NSString *className = [self className];

	if ([className hasPrefix: [self typePrefix]] == NO 
	 || [className hasSuffix: [self baseClassName]] == NO)
	{
		ETLog(@"Type prefix %@ or base class name %@ doesn't match class name %@ ",
			[self typePrefix], [self baseClassName], className);
		return className;
	}
	
	// TODO: Implement -stringByRemovingPrefix: and use it.
	unsigned int prefixLength = [[self typePrefix] length];
	unsigned int classSuffixLength = [[self baseClassName] length];
	NSRange range = NSMakeRange(prefixLength, 
		[className length] - (prefixLength + classSuffixLength));

	if (range.length == 0)
	{
		return [self baseClassName];
	}

	return [className substringWithRange: range];
}

/** Returns the default aspect name used to register a receiver instance in
the aspect repository. */
+ (NSString *) aspectName
{
	NSString *name = [self stripClassName];

	NSAssert(name != nil, @"+stripClassName must never return nil but an empty string if needed");
	if ([name isEqual: @""])
		return name;

	NSString *lowercasedFirstLetter = [[name substringToIndex: 1] lowercaseString];

#ifdef GNUSTEP
	return [lowercasedFirstLetter stringByAppendingString: [name substringFromIndex: 1]];
#else
	return [name stringByReplacingCharactersInRange: NSMakeRange(0, 1) 
	                                     withString: lowercasedFirstLetter];
#endif
}

/** Returns YES if the receiver is an ETLayoutItem class or subclass instance, 
otherwise returns NO. */
- (BOOL) isLayoutItem
{
	return NO;
}

/** Returns YES if the receiver is an ETTool class or subclass instance, 
otherwise returns NO. */
- (BOOL) isTool
{
	return NO;
}

/** Returns YES if the receiver is an NSView class or subclass instance, 
otherwise returns NO. */
- (BOOL) isView
{
	return [self isKindOfClass: [NSView class]];
}

/* Debugging */

/** Returns the receiver archived as a XML string with NSKeyedArchiver.

When the receiver doesn't support NSCoding or keyed archiving, returns nil.

You shouldn't use this method in your code. Just use it as a debugging 
conveniency. */
- (NSString *) XMLArchive
{
	if ([self conformsToProtocol: @protocol(NSCoding)] == NO)
		return nil;

	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];

	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: self];
	[archiver finishEncoding];
	RELEASE(archiver);

	return AUTORELEASE([[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
}


#pragma mark Scalar Editing Accessors
#pragma mark -

- (void) addPropertyDescriptionWithName: (NSString *)aProperty
                                   type: (NSString *)aType
                           inRepository: (ETModelDescriptionRepository *)aRepository
{
	ETPropertyDescription *propertyDesc =
		[ETPropertyDescription descriptionWithName: aProperty
		                                      type: [aRepository descriptionForName: aType]];
	ETEntityDescription *entityDesc = [aRepository entityDescriptionForClass: [self class]];

	[entityDesc addPropertyDescription: propertyDesc];
	[aRepository addDescription: propertyDesc];

	NSMutableArray *warnings = [NSMutableArray array];
	[aRepository checkConstraints: warnings];
	// FIXME: ETAssert([warnings isEmpty]);
}

- (id) synthesizeAccessorsForFieldName: (NSString *)aFieldName
                      ofScalarProperty: (NSString *)aKey
                                  type: (NSString *)aScalarType
                          inRepository: (ETModelDescriptionRepository *)aRepository
{
	NSParameterAssert(aFieldName != nil);
	NSParameterAssert(aKey != nil);
	NSParameterAssert([S(@"NSRect", @"NSSize", @"NSPoint") containsObject: aScalarType]);

	NSString *capitalizedFieldName = [aFieldName stringByCapitalizingFirstLetter];
	NSString *newSelectorName = [aKey stringByAppendingString: capitalizedFieldName];
	SEL newSelector = NSSelectorFromString(newSelectorName);
	
	if ([self respondsToSelector: newSelector])
	{
		return newSelectorName;
	}
		 
	NSString *builtInSelectorName =
		[NSString stringWithFormat: @"synthesized%@%@Accessor", aScalarType, capitalizedFieldName];
	SEL builtInSelector = NSSelectorFromString(builtInSelectorName);
	ETAssert(builtInSelector != nil);
	Method builtInMethod = class_getInstanceMethod([self class], builtInSelector);
	IMP builtInMethodIMP = method_getImplementation(builtInMethod);
	const char *typeEncoding = method_getTypeEncoding(builtInMethod);

	ETAssert (builtInMethodIMP != NULL);

	BOOL success = class_addMethod([self class], newSelector, builtInMethodIMP, typeEncoding);
	
	if (success == NO)
		return NO;

	[self addPropertyDescriptionWithName: newSelectorName
	                                type: aScalarType
	                        inRepository: aRepository];
	return newSelectorName;
}

- (CGFloat) synthesizedNSPointXAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 1];
	
	return [[self valueForKey: scalarKey] pointValue].x;
}

- (CGFloat) synthesizedNSPointYAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 1];
	
	return [[self valueForKey: scalarKey] pointValue].y;
}

- (CGFloat) synthesizedNSSizeWidthAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 5];

	return [[self valueForKey: scalarKey] sizeValue].width;
}

- (CGFloat) synthesizedNSSizeHeightAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 6];
	
	return [[self valueForKey: scalarKey] sizeValue].height;
}

- (CGFloat) synthesizedNSRectXAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 1];
	
	return [[self valueForKey: scalarKey] rectValue].origin.x;
}

- (CGFloat) synthesizedNSRectYAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 1];
	
	return [[self valueForKey: scalarKey] rectValue].origin.y;
}

- (CGFloat) synthesizedNSRectWidthAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 5];

	return [[self valueForKey: scalarKey] rectValue].size.width;
}

- (CGFloat) synthesizedNSRectHeightAccessor
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringToIndex: [key length] - 6];
	
	return [[self valueForKey: scalarKey] rectValue].size.height;
}

@end


@implementation NSImage (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation ETKeyValuePair (EtoileUI)
/** Returns the icon bound to the -value object. */
- (NSImage *) icon { return [[self value] icon]; }
@end

