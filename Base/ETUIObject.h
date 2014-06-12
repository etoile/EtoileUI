/**
	<abstract>EtoileUI basic object class</abstract>

	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.math@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETCompatibility.h>
#import <CoreObject/COObject.h>

@class COObjectGraphContext;

@interface ETUIObject : COObject <NSCopying>
{

}

/** @taskunit Aspect Sharing */

- (BOOL) isShared;

/** @taskunit Copying */

- (id) copyToObjectGraphContext: (COObjectGraphContext *)aContext;
- (id) copyWithZone: (NSZone *)aZone;
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/** @taskunit Serialization */

- (id) serializedRepresentationForObject: (id)anObject;
- (NSString *) serializedValueForWeakTypedReference: (id)value;
- (id) weakTypedReferenceForSerializedValue: (NSString *)value;

/** @taskunit Persistency */

- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId;
- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId
					metadata: (NSDictionary *)additionalMetadata;

/** @taskunit Framework Private */

+ (COObjectGraphContext *) defaultTransientObjectGraphContext;

@end


@protocol COForeignObjectSerialization <NSObject>
- (id) initWithSerializedRepresentation;
- (id) serializedRepresentation;
@end
