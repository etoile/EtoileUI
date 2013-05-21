/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETItemValueTransformer.h"

@implementation ETItemValueTransformer

@synthesize transformBlock = _transformBlock, reverseTransformBlock = _reverseTransformBlock;

- (void) dealloc
{
	DESTROY(_transformBlock);
	DESTROY(_reverseTransformBlock);
	[super dealloc];
}

- (id) transformedValue: (id)value
                 forKey: (NSString *)key
                 ofItem: (ETLayoutItem *)item
{
	if (_transformBlock != nil)
	{
		return _transformBlock(value, key, item);
	}
	return [self transformedValue: value];
}

- (id) reverseTransformedValue: (id)value
                        forKey: (NSString *)key
                        ofItem: (ETLayoutItem *)item
{
	if (_reverseTransformBlock != nil)
	{
		return _reverseTransformBlock(value, key, item);
	}
	return [self reverseTransformedValue: value];
}

@end

