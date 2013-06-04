/**
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

@class ETLayoutItem;

typedef id (^ETItemValueTransformBlock)(id value, NSString *key, ETLayoutItem *item);

/** @group Utilities
 
A specialized NSValueTransformer dedicated to EtoileUI.
 
ETItemValueTransformer supports writing value transformer without subclassing. 
The UI builder uses this feature to support editing transformation block code
at runtime.
 
For use cases, see ETLayoutItem and -[ETLayoutItem valueTransformerForProperty:]. */
@interface ETItemValueTransformer : NSValueTransformer
{
	@private
	NSString *_name;
	ETItemValueTransformBlock _transformBlock;
	ETItemValueTransformBlock _reverseTransformBlock;
	NSString *_transformCode;
	NSString *_reverseTransformCode;
}

/** @taskunit Name */

@property (nonatomic, retain) NSString *name;
@property (nonatomic, readonly) NSString *displayName;

/** @taskunit Transformation Methods */

/** <override-dummy />
Turns the value that is bound to the given item property or key into a new 
value, and returns it.

The value arguments comes from the item subject, it has been looked up using 
the key argument and -[ETLayoutItem valueForProperty:]. See -[ETLayoutItem subject].
 
The default implementation evaluates -transformBlock using the same arguments 
and returns the block value.<br />
If there is no transform block available, it just calls -transformedValue: and 
returns its result. */
- (id) transformedValue: (id)value
                 forKey: (NSString *)key
                 ofItem: (ETLayoutItem *)item;
/** <override-dummy />
Turns the value into a new reversed value to be bound to the given item property 
or key, and returns it.
 
The value argument usually comes a UI widget object value and is going to be set 
using -[ETLayoutItem setValue:forProperty:] on the item subject. See 
-[ETLayoutItem subject].
 
The default implementation evaluates -reverseTransformBlock using the same 
arguments and returns the block value.<br />
If there is no transform block available, it just calls -reverseTransformedValue: 
and returns its result. */
- (id) reverseTransformedValue: (id)value
                        forKey: (NSString *)key
                        ofItem: (ETLayoutItem *)item;

/** @taskunit Transformation Blocks */

/** A transformation block that takes three arguments: value, key and item, 
and returns a new value.

This block provides a behavior equivalent to -transformedValue:forKey:ofItem:,  
but doesn't require any subclassing. */
@property (nonatomic, copy) ETItemValueTransformBlock transformBlock;
/** A reverse transformation block that takes three arguments: value, key and 
item, and returns a new reversed value.

This block provides a behavior equivalent to 
 -reverseTransformedValue:forKey:ofItem:, but doesn't require any subclassing. */
@property (nonatomic, copy) ETItemValueTransformBlock reverseTransformBlock;

/** @taskunit Runtime Code Editing */

@property (nonatomic, retain) NSString *transformCode;
@property (nonatomic, retain) NSString *reverseTransformCode;

@end
