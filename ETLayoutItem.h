//
//  ETLayoutItem.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface ETLayoutItem : NSObject 
{
	id _value;
	id _modelObject;
	NSView *_view;
	BOOL _selected;
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view;

- (ETLayoutItem *) initWithValue: (id)value;
- (ETLayoutItem *) initWithRepresentedObject: (id)object;
- (ETLayoutItem *) initWithView: (NSView *)view;

- (id) value;
- (void) setValue: (id)value;

- (id) representedObject;
- (void) setRepresentedObject: (id)modelObject;

- (NSView *) view;
- (void) setView: (NSView *)view;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

//- (ETContainer *) container;
- (NSView *) displayView;

- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;

- (void) render;

@end

/*
@interface ETLayoutItem (NSCellCompatibility)
- (NSCell *) cell;
- (void) setCell: (NSCell *)cell;
@end
*/
