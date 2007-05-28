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
		ASSIGN(_repObject, repObject);
    }
    
    return self;
}

- (void) dealloc
{
    DESTROY(_view);
	DESTROY(_value);
	DESTROY(_repObject);
    
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

- (id) representedObject
{
	return _repObject;
}

- (void) setRepresentedObject: (id)object
{
	ASSIGN(_repObject, object);
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

- (NSDictionary *) properties
{
	return nil;
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
