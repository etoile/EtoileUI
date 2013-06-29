/**
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

@protocol ETObjectValueFormatterDelegate;

/** @group Utilities

ETObjectValueFormatter doesn't turn strings into their object 
representations immediately, but just validates the string value to ensure it 
can be converted into an object representation later.
 
ETObjectValueFormatter is usually used together with a dedicated 
ETItemValueTransformer that know how to convert string values into object 
representations and vice-versa.
 
ETObjectValueFormatter is optional, it just improves the UI feedback because it 
prevents the user to leave a text field if the string value is not a valid 
object type (or some other object identifier).
 
A formatter cannot be used as a value transformer, because the validation 
happens multiple times during the editing, and the end of the editing doesn't 
trigger a final validation (that would be distinct from the incremental 
validation during the editing). ETItemValueTransformer are in charge of this 
final validation at the UI level before updating the model (and possibly 
resulting in a validation at the model level too).<br />
In addition, formatters are attached to -[ETLayoutItem widget] and 
-[ETWidget setObjectValue:] method copies objects passed to it, this prevents 
non-primitive object values to be edited directly (by being attached to the 
widget proxy). */
@interface ETObjectValueFormatter : NSFormatter
{
	@private
	NSString *_name;
	id _delegate;
}

@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) id <ETObjectValueFormatterDelegate> delegate;

@end

@protocol ETObjectValueFormatterDelegate <NSObject>
- (id) formatter: (ETObjectValueFormatter *)aFormatter stringValueForString: (NSString *)aString;
@optional
- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringForObjectValue: (id)aValue;
@end
