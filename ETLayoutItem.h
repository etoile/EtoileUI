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
	id _repObject;
	NSView *_view;
	NSMutableDictionary *_properties;
	BOOL _selected;
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view;

- (ETLayoutItem *) initWithValue: (id)value;
- (ETLayoutItem *) initWithRepresentedObject: (id)object;
- (ETLayoutItem *) initWithView: (NSView *)view;

- (id) value;
- (void) setValue: (id)value;

- (id) representedObject;
- (void) setRepresentedObject: (id)object;

- (NSView *) view;
- (void) setView: (NSView *)view;

- (NSMutableDictionary *) properties;

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
