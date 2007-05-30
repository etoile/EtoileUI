//
//  ETLayoutItem.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETLayoutItem.h"
#import "GNUstep.h"

@interface ETLayoutItem (Private)
- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;
@end


@implementation ETLayoutItem

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithView: view]);
}

- (ETLayoutItem *) initWithValue: (id)value
{
	return [self initWithView: nil value: value representedObject: nil];
}

- (ETLayoutItem *) initWithRepresentedObject: (id)object
{
	return [self initWithView: nil value: nil representedObject: object];
}

- (ETLayoutItem *) initWithView: (NSView *)view
{
	return [self initWithView: view value: nil representedObject: nil];
}

- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
    self = [super init];
    
    if (self != nil)
    {
		ASSIGN(_view, view);
		ASSIGN(_value, value);
		ASSIGN(_modelObject, repObject);
		
		_modelObject = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void) dealloc
{
    DESTROY(_view);
	DESTROY(_value);
	DESTROY(_modelObject);
    
    [super dealloc];
}

- (id) value
{
	return _value;
}

- (void) setValue: (id)value
{
	ASSIGN(_value, value);
}

/** Returns model object which embeds the representation of what the layout 
	item displays. When a new layout item is created, by default it uses a
	dictionary as a rudimentary model object. */
- (id) representedObject
{
	return _modelObject;
}

/** Sets model object which embeds the representation of what the layout 
	item displays. 
	If you want to restore default model object initally set, pass a mutable 
	dictionary instance as parameter to this method.
	See -representedObject for more details. */
- (void) setRepresentedObject: (id)modelObject
{
	ASSIGN(_modelObject, modelObject);
}

- (NSView *) view
{
	return _view;
}

- (void) setView: (NSView *)view
{
	ASSIGN(_view, view);
}

/*- (ETContainer *) container
{
	return _container;
}*/

/** Returns a value of the model object -representedObject, usually by 
	calling -valueForProperty: else -valueForKey: with key parameter. By default 
	the model object is a simple dictionary which gets returned by both this 
	method and -representedObject method.
	When the model object is a custom one, it must implement -valueForProperty:
	and -setValue:forProperty: or conform to NSKeyValueCoding protocol. */
- (id) valueForProperty: (NSString *)key
{
	if ([_modelObject respondsToSelector: @selector(valueForProperty:)])
	{
		return [_modelObject valueForProperty: key];
	}
	else
	{
		return [_modelObject valueForKey: key];
	}
}

/** Sets a value identified by key of the model object returned by 
	-representedObject. 
	See -valueForProperty: for more details. */
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	if ([_modelObject respondsToSelector: @selector(setValue:forProperty:)])
	{
		return [_modelObject setValue: value forProperty: key];
	}
	else
	{
		// FIXME: Catch key value coding exception here
		[_modelObject setValue: value forKey: key];
		return YES;
	}
}

- (NSView *) displayView
{
	return _view;
}

- (void) setSelected: (BOOL)selected
{
	_selected = selected;
}

- (BOOL) isSelected
{
	return _selected;
}

/** Override */
- (void) render
{

}

@end
