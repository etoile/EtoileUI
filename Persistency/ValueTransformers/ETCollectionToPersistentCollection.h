/**
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2014
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface ETCollectionToPersistentCollection : NSValueTransformer
{
	@private
	NSString *_valueTransformerName;
	NSString *_keyTransformerName;
}

@property (nonatomic, retain) NSString *valueTransformerName;
@property (nonatomic, retain) NSString *keyTransformerName;

@end
