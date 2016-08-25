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

/** @taskunit Factory Method */

+ (instancetype) sharedInstanceForObjectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Aspect Sharing */

@property (nonatomic, readonly) BOOL isShared;

/** @taskunit Copying */

- (id) copyToObjectGraphContext: (COObjectGraphContext *)aContext;
- (id) copyWithZone: (NSZone *)aZone;
- (id) copyValueForProperty: (NSString *)aProperty;

/** @taskunit Serialization */

- (BOOL) isCoreObjectReference: (id)value;
- (id) serializedRepresentationForObject: (id)anObject;
- (NSString *) serializedValueForWeakTypedReference: (id)value;
- (id) weakTypedReferenceForSerializedValue: (NSString *)value;

/** @taskunit Persistency */

- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId;
- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId
					metadata: (NSDictionary *)additionalMetadata;

/** @taskunit KVO Utilities */

- (void)startObserveObject: (id)anObject;
- (void)endObserveObject: (id)anObject;

/** @taskunit Framework Private */

+ (COObjectGraphContext *) defaultTransientObjectGraphContext;
- (void)prepareTransientState;

@end


@protocol COForeignObjectSerialization <NSObject>
- (instancetype) initWithSerializedRepresentation;
@property (nonatomic, readonly) id serializedRepresentation;
@end
