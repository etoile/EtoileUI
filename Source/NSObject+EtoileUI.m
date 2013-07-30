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
#import "ETModelDescriptionRenderer.h"
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

- (ETLayoutItemGroup *) itemRepresentation
{
	ETLayoutItemGroup *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	[entityItem setAutoresizingMask: ETAutoresizingFlexibleWidth];
	return entityItem;
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
	[[[ETLayoutItemFactory factory] windowGroup] addItem: [self itemRepresentation]];
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
	ETViewModelLayout *layout = [ETViewModelLayout layoutWithObjectGraphContext: [item objectGraphContext]];

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
	return [[self stripTypePrefix] stringBySpacingCapitalizedWords];
}

/** Overrides. */
+ (NSString *) baseClassName
{
	return @"Object";
}

/* Removes type prefix of class names. */
+ (NSString *) stripTypePrefix
{
	NSString *className = [self className];
	
	if (([[self typePrefix] length] > 0 && [className hasPrefix: [self typePrefix]] == NO))
	{
		ETLog(@"Type prefix %@ doesn't match class name %@ ", [self typePrefix], className);
		return className;
	}
	
	// TODO: Implement -stringByRemovingPrefix: and use it.
	unsigned int prefixLength = [[self typePrefix] length];
	NSRange range = NSMakeRange(prefixLength, [className length] - prefixLength);
	
	return [className substringWithRange: range];
}

/* Removes type prefix and base suffix of class names.
 
If +baseClassName returns an empty string, the type prefix is removed. */
+ (NSString *) stripClassName
{
	NSString *className = [self className];

	if (([[self typePrefix] length] > 0 && [className hasPrefix: [self typePrefix]] == NO)
	 || ([[self baseClassName] length] > 0 && [className hasSuffix: [self baseClassName]] == NO))
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

/** Returns YES if the receiver is an ETLayout class or subclass instance,
otherwise returns NO. */
- (BOOL) isLayout
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

	// FIXME: Call constraint check elsewhere because it's very slow.
	// NSMutableArray *warnings = [NSMutableArray array];
	//[aRepository checkConstraints: warnings];
	// ETAssert([warnings isEmpty]);
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
	NSString *newGetterName = [aKey stringByAppendingString: capitalizedFieldName];
	SEL newGetterSelector = NSSelectorFromString(newGetterName);
	ETAssert(newGetterSelector != NULL);
	
	if ([self respondsToSelector: newGetterSelector])
	{
		return newGetterName;
	}
		 
	NSString *builtInGetterName =
		[NSString stringWithFormat: @"synthesized%@%@Accessor", aScalarType, capitalizedFieldName];
	SEL builtInGetterSelector = NSSelectorFromString(builtInGetterName);
	ETAssert(builtInGetterSelector != NULL);
	Method builtInGetter = class_getInstanceMethod([self class], builtInGetterSelector);
	IMP builtInGetterIMP = method_getImplementation(builtInGetter);
	ETAssert (builtInGetterIMP != NULL);
	const char *getterTypeEncoding = method_getTypeEncoding(builtInGetter);

	BOOL success = class_addMethod([self class], newGetterSelector, builtInGetterIMP, getterTypeEncoding);
	
	if (success == NO)
		return NO;
	
	// TODO: Don't install for a read-only property description
	NSString *capitalizedKey = [aKey stringByCapitalizingFirstLetter];
	NSString *newSetterName =
		[NSString stringWithFormat: @"set%@%@:", capitalizedKey, capitalizedFieldName];
	SEL newSetterSelector = NSSelectorFromString(newSetterName);
	ETAssert(newSetterSelector != NULL);
	
	NSString *builtInSetterName =
		[NSString stringWithFormat: @"synthesized%@%@Accessor:", aScalarType, capitalizedFieldName];
	SEL builtInSetterSelector = NSSelectorFromString(builtInSetterName);
	ETAssert(builtInSetterSelector != NULL);
	Method builtInSetter = class_getInstanceMethod([self class], builtInSetterSelector);
	IMP builtInSetterIMP = method_getImplementation(builtInSetter);
	ETAssert (builtInSetterIMP != NULL);
	const char *setterTypeEncoding = method_getTypeEncoding(builtInSetter);

	success = class_addMethod([self class], newSetterSelector, builtInSetterIMP, setterTypeEncoding);
	
	if (success == NO)
		return NO;

	[self addPropertyDescriptionWithName: newGetterName
	                                type: @"CGFloat"
	                        inRepository: aRepository];
	return newGetterName;
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

- (void) synthesizedNSPointXAccessor: (CGFloat)x
{
	NSString *key = NSStringFromSelector(_cmd);

	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 2];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSPoint point = NSMakePoint(x, [[self valueForKey: scalarKey] pointValue].y);
	
	return [self setValue: [NSValue valueWithPoint: point] forKey: scalarKey];
}

- (void) synthesizedNSPointYAccessor: (CGFloat)y
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 2];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSPoint point = NSMakePoint([[self valueForKey: scalarKey] pointValue].x, y);
	
	return [self setValue: [NSValue valueWithPoint: point] forKey: scalarKey];
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

- (void) synthesizedNSSizeWidthAccessor: (CGFloat)width
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 6];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSSize size = NSMakeSize(width, [[self valueForKey: scalarKey] sizeValue].height);
	
	return [self setValue: [NSValue valueWithSize: size] forKey: scalarKey];
}

- (void) synthesizedNSSizeHeightAccessor: (CGFloat)height
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 7];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSSize size = NSMakeSize([[self valueForKey: scalarKey] sizeValue].width, height);
	
	return [self setValue: [NSValue valueWithSize: size] forKey: scalarKey];
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

- (void) synthesizedNSRectXAccessor: (CGFloat)x
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 2];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSRect oldRect = [[self valueForKey: scalarKey] rectValue];
	NSRect newRect = NSMakeRect(x, oldRect.origin.y, oldRect.size.width, oldRect.size.height);
	
	return [self setValue: [NSValue valueWithRect: newRect] forKey: scalarKey];
}

- (void) synthesizedNSRectYAccessor: (CGFloat)y
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 2];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSRect oldRect = [[self valueForKey: scalarKey] rectValue];
	NSRect newRect = NSMakeRect(oldRect.origin.x, y, oldRect.size.width, oldRect.size.height);
	
	return [self setValue: [NSValue valueWithRect: newRect] forKey: scalarKey];
}

- (void) synthesizedNSRectWidthAccessor: (CGFloat)width
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 6];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSRect oldRect = [[self valueForKey: scalarKey] rectValue];
	NSRect newRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y, width, oldRect.size.height);
	
	return [self setValue: [NSValue valueWithRect: newRect] forKey: scalarKey];
}

- (void) synthesizedNSRectHeightAccessor: (CGFloat)height
{
	NSString *key = NSStringFromSelector(_cmd);
	NSString *scalarKey = [key substringFromIndex: 3 toIndex: [key length] - 7];
	scalarKey = [scalarKey stringByLowercasingFirstLetter];
	NSRect oldRect = [[self valueForKey: scalarKey] rectValue];
	NSRect newRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y, oldRect.size.width, height);
	
	return [self setValue: [NSValue valueWithRect: newRect] forKey: scalarKey];
}

@end


@implementation NSImage (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation ETKeyValuePair (EtoileUI)
/** Returns the icon bound to the -value object. */
- (NSImage *) icon { return [[self value] icon]; }
@end

