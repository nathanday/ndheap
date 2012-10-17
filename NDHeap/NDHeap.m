/*
	NDHeap.m

	Created by Nathan Day on 17/09/2012 under a MIT-style license.
	Copyright (c) 2012 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the \"Software\"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NDHeap.h"

static const NSUInteger			kConcurrentFragmentSize = 100;

static inline NSUInteger parentIndexOfNodeIndex( NSUInteger n ) { NSCParameterAssert(n > 0); return (n-1)>>1; }
static inline NSUInteger childrenIndiciesOfNodeIndex( NSUInteger n ) { return (n<<1)+1; }
static inline void swapObjects( id __strong a[], id __strong b[] ) { id  temp = *a; *a = *b; *b = temp; }

static BOOL verifyHeapState( id __strong a[], NSUInteger c, NSComparator comp, NSUInteger n )
{
	BOOL	theResult = YES;
	if( n < c )
	{
		if( n > 0 )
			theResult = comp( a[parentIndexOfNodeIndex(n)], a[n] ) != NSOrderedDescending;
		if( theResult )
			theResult = verifyHeapState( a, c, comp, childrenIndiciesOfNodeIndex( n ) ) && verifyHeapState( a, c, comp, childrenIndiciesOfNodeIndex( n+1 ) );
	}
	return theResult;
}

static void downHeapNodeN( id __strong a[], NSUInteger c, NSComparator aComparator, NSUInteger n )
{
	NSUInteger	theChildIndex = childrenIndiciesOfNodeIndex( n );
	if( theChildIndex < c )
	{
		NSUInteger		theSwapChild = theChildIndex;
		if( theChildIndex + 1 < c )
		{
			if( aComparator( a[theSwapChild], a[theChildIndex+1] ) == NSOrderedDescending )
				theSwapChild = theChildIndex+1;
		}
		if( aComparator( a[n], a[theSwapChild] ) == NSOrderedDescending )
		{
			swapObjects( &a[n], &a[theSwapChild] );
			downHeapNodeN( a, c, aComparator, theSwapChild );
		}
	}
}

static void upHeapNodeN( id __strong a[], NSUInteger c, NSComparator aComparator, NSUInteger n )
{
	if( n > 0 )
	{
		NSUInteger	theParentIndex = parentIndexOfNodeIndex(n);
		if( aComparator( a[theParentIndex], a[n] ) == NSOrderedDescending )
		{
			swapObjects( &a[theParentIndex], &a[n] );
			upHeapNodeN( a, c, aComparator, theParentIndex );
		}
	}
}

BOOL recursiveContainsObject( id __strong a[], NSUInteger c, NSComparator aComparator, NSUInteger n, id anObject )
{
	BOOL		theResult = NO;
	if( n < c )
	{
		NSComparisonResult		theComparison = aComparator( a[n], anObject );
		if( theComparison != NSOrderedDescending )
		{
			theResult = theComparison == NSOrderedSame && [a[n] isEqual:anObject];
			if(  !theResult )
			{
				NSUInteger		theChild = childrenIndiciesOfNodeIndex( n );
				theResult = recursiveContainsObject( a, c, aComparator, theChild, anObject )
						|| recursiveContainsObject( a, c, aComparator, theChild+1, anObject );
			}
		}
	}
	return theResult;
}

NSUInteger recursiveCountContainsObject( id __strong a[], NSUInteger c, NSComparator aComparator, NSUInteger n, id anObject )
{
	BOOL		theResult = 0;
	if( n < c )
	{
		NSComparisonResult		theComparison = aComparator( a[n], anObject );
		if( theComparison != NSOrderedDescending )
		{
			NSUInteger		theChild = childrenIndiciesOfNodeIndex( n );
			theResult = (theComparison == NSOrderedSame && [a[n] isEqual:anObject]) ? 1 : 0;
			theResult += recursiveContainsObject( a, c, aComparator, theChild, anObject ) + recursiveContainsObject( a, c, aComparator, theChild+1, anObject );
		}
	}
	return theResult;
}

static void heapifyArray( id __strong a[], NSUInteger c, NSComparator aComparator )
{
	for( NSInteger i = c>>1; i >= 0; i-- )
		downHeapNodeN( a, c, aComparator, i );
}

@interface NDHeapEnumerator : NSEnumerator
{
	__strong NDHeap					* _heap;
	const __strong id				* _everyObject;
	NSUInteger						_position,
									_count;
}

- (id)initWithHeap:(NDHeap *)aHeap everyObject:(const __strong id*)anEveryObject;

@end

@interface NDHeap ()
{
@protected
	__strong id				* _everyObject;
	NSUInteger				_count,
							_size;
	__strong NSComparator	_comparator;
}

@end

@implementation NDHeap

@synthesize		count = _count,
				comparator = _comparator;

- (id)minimumObject { return self.count > 0 ? *_everyObject : nil; }

static void deleteNodeN( NDHeap * self, NSUInteger n )
{
#if !__has_feature(objc_arc)
	[self->_everyObject[n] release];
#endif
	self->_everyObject[n] = self->_everyObject[self->_count-1], self->_everyObject[self->_count-1] = nil;
	self->_count--;

	downHeapNodeN( self->_everyObject, self->_count, self->_comparator, n );
}

static void addObject( NDHeap * self, id anObject )
{
	self->_count++;
	if( self->_count >= self->_size )
	{
		if( self->_size == 0 ) self->_size = 1;
		self->_size <<= 1;
		self->_everyObject = (__strong id*)reallocf(self->_everyObject, self->_size*sizeof(*self->_everyObject) );
		NSCAssert(self->_everyObject != nil, @"memory error" );
	}
#if !__has_feature(objc_arc)
	[anObject retain];
#endif
	self->_everyObject[self->_count-1] = anObject;
	upHeapNodeN( self->_everyObject, self->_count, self->_comparator, self->_count-1 );
}

static void addObjects( NDHeap * self, va_list anArgList, id aFirstObject )
{
	id			theObject = aFirstObject;
	while( theObject != nil )
	{
		if( self->_count >= self->_size )
		{
			if( self->_size == 0 ) self->_size = 1;
			while( self->_count >= self->_size ) self->_size <<= 1;
			self->_everyObject = (__strong id*)reallocf( self->_everyObject, self->_size*sizeof(*self->_everyObject) );
			NSCAssert( self->_everyObject != nil, @"memory error" );
		}
#if !__has_feature(objc_arc)
		[theObject retain];
#endif
		self->_everyObject[self->_count] = theObject;
		self->_count++;
		theObject = va_arg ( anArgList, id );
	}
	heapifyArray( self->_everyObject, self->_count, self->_comparator );
}

static void addNObjects( NDHeap * self, const __strong id * anObjects, NSUInteger aCount )
{
	NSUInteger		theOriginalCount = self->_count;
	self->_count += aCount;
	if( self->_count >= self->_size )
	{
		if( self->_size == 0 ) self->_size = 1;
		while( self->_count >= self->_size ) self->_size <<= 1;
		self->_everyObject = (__strong id *)reallocf( self->_everyObject, self->_size*sizeof(*self->_everyObject) );
		NSCAssert( self->_everyObject != nil, @"memory error" );
	}
#if __has_feature(objc_arc)
	memcpy( (void*)&(self->_everyObject[theOriginalCount]), (void*)anObjects, aCount*sizeof(*anObjects) );
#else
	for( NSUInteger i = 0; i < aCount; i++ )
		self->_everyObject[theOriginalCount+i] = [anObjects[i] retain];
#endif
	heapifyArray( self->_everyObject, self->_count, self->_comparator );
}

static void addArray( NDHeap * self, NSArray * anArray )
{
	NSUInteger		theLastIndex = self->_count;
	self->_count += anArray.count;
	if( self->_count >= self->_size )
	{
		if( self->_size == 0 ) self->_size = 1;
		while( self->_count >= self->_size ) self->_size <<= 1;
		self->_everyObject = (__strong id *)reallocf( self->_everyObject, self->_size*sizeof(*self->_everyObject) );
		NSCAssert( self->_everyObject != nil, @"memory error" );
	}
	for( id theObject in anArray )
	{
#if !__has_feature(objc_arc)
		[theObject retain];
#endif
		self->_everyObject[theLastIndex++] = theObject;
	}
	heapifyArray( self->_everyObject, self->_count, self->_comparator );
}

+ (id)heapWithComparator:(NSComparator)aComparator objects:(id)anObject, ...
{
	va_list		theArgList;
	va_start(theArgList, anObject);
	id		theResult = [[self alloc] initWithComparator:aComparator arguments:theArgList firstObject:anObject];
	va_end(theArgList);
#if __has_feature(objc_arc)
	return theResult;
#else
	return [theResult autorelease];
#endif
}

+ (id)heapWithComparator:(NSComparator)aComparator objects:(const id *)anArray count:(NSUInteger)aCount
{
#if __has_feature(objc_arc)
	return [[self alloc] initWithComparator:aComparator objects:anArray count:aCount];
#else
	return [[[self alloc] initWithComparator:aComparator objects:anArray count:aCount] autorelease];
#endif
}

+ (id)heapWithComparator:(NSComparator)aComparator array:(NSArray *)anArray
{
#if __has_feature(objc_arc)
	return [[self alloc] initWithComparator:aComparator array:anArray];
#else
	return [[[self alloc] initWithComparator:aComparator array:anArray] autorelease];
#endif
}

+ (id)heapWithComparator:(NSComparator)aComparator
{
#if __has_feature(objc_arc)
	return [[self alloc] initWithComparator:aComparator];
#else
	return [[[self alloc] initWithComparator:aComparator] autorelease];
#endif
}

- (id)initWithComparator:(NSComparator)aComparator objects:(id)anObject, ...
{
	if( (self = [self initWithComparator:aComparator]) != nil )
	{
		va_list		theArgList;
		va_start(theArgList, anObject);
		addObjects( self, theArgList, anObject );
		va_end(theArgList);
		NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
	}
	return self;
}

- (id)initWithComparator:(NSComparator)aComparator arguments:(va_list)anArguments firstObject:(id)aFirstObject
{
	if( (self = [self initWithComparator:aComparator]) != nil )
	{
		addObjects( self, anArguments, aFirstObject );
		NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
	}
	return self;
}

- (id)initWithComparator:(NSComparator)aComparator objects:(const id *)anObjects count:(NSUInteger)aCount
{
	if( (self = [self initWithComparator:aComparator]) != nil )
	{
		addNObjects( self, anObjects, aCount );
		NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
	}
	return self;
}

- (id)initWithComparator:(NSComparator)aComparator array:(NSArray *)anArray
{
	if( (self = [self initWithComparator:aComparator]) != nil )
	{
		addArray( self, anArray );
		NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
	}
	return self;
}

- (id)initWithComparator:(NSComparator)aComparator
{
	if( (self = [super init]) != nil )
		_comparator = aComparator;
	return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
	for( NSUInteger i = 0, c = self.count; i < c; i++ )
		[_everyObject[i] release];
	free(_everyObject), _everyObject = NULL;
	[super dealloc];
}
#endif

- (NSArray *)everyObject { return [NSArray arrayWithObjects:_everyObject count:self.count]; }

- (NSEnumerator *)objectEnumerator
{
	NSEnumerator		* theResult = [[NDHeapEnumerator alloc] initWithHeap:self everyObject:_everyObject];
#if !__has_feature(objc_arc)
	[theResult autorelease];
#endif
	return theResult;
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))aBlock { [self enumerateObjectsWithOptions:0 usingBlock:aBlock]; }

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)anOptions usingBlock:(void (^)(id obj, BOOL *aStop))aBlock
{
	if( (anOptions&NSEnumerationConcurrent) && self.count > kConcurrentFragmentSize )
	{
		NSUInteger			theCount = self.count;
		NSOperationQueue	* theOperationQueue = [NSOperationQueue mainQueue];
		[theOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];

		for( NSUInteger i = 0, c = theOperationQueue.maxConcurrentOperationCount; i < c; i++ )
		{
			[theOperationQueue addOperationWithBlock:^{
				BOOL	theStop = NO;
				for( NSUInteger j = 0; j < theCount/c+1 && j+i < theCount && !theStop; j++ )
					aBlock( _everyObject[i+j], &theStop );
			}];
		}
	}
	else
	{
		BOOL	theStop = NO;
		for( id theObject in self )
			aBlock( theObject, &theStop );
	}
}

- (void)makeObjectsPerformSelector:(SEL)aSelector
{
	for( id theObject in self )
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[theObject performSelector:aSelector];
#pragma clang diagnostic pop
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
	for( id theObject in self )
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[theObject performSelector:aSelector withObject:anObject];
#pragma clang diagnostic pop
}

- (BOOL)containsObject:(id)anObject { return recursiveContainsObject( self->_everyObject, self.count, self->_comparator, 0, anObject ); }

- (BOOL)isEqual:(NDHeap *)anObject { return [anObject isKindOfClass:[NDHeap class]] && [self isEqualToHeap:anObject]; }
- (BOOL)isEqualToHeap:(NDHeap *)anOtherHeap
{
	BOOL	theResult = YES;
	if( self.count == anOtherHeap.count && [[self minimumObject] isEqual:[anOtherHeap minimumObject]] )
	{
		for( id theObject in self )
		{
			theResult = recursiveCountContainsObject( anOtherHeap->_everyObject, anOtherHeap.count, anOtherHeap->_comparator, 0, theObject ) == recursiveCountContainsObject( self->_everyObject, self.count, self->_comparator, 0, theObject );
			if( theResult == NO )
				break;
		}
	}
	else
		theResult = NO;
	return theResult;
}

- (NDHeap *)heapByAddingObject:(id)anObject
{
	NDHeap		* theResult = [NDHeap heapWithComparator:_comparator objects:_everyObject count:self.count];
	addObject(theResult, anObject);
	return theResult;
}

- (NDHeap *)heapByAddingObjectsFromArray:(NSArray *)anArray
{
	NDHeap		* theResult = [NDHeap heapWithComparator:_comparator objects:_everyObject count:self.count];
	addArray( theResult, anArray );
	return theResult;
}

- (NDHeap *)heapByAddingObjectsFromHeap:(NDHeap *)anOtherHeap
{
	NDHeap		* theResult = [NDHeap heapWithComparator:_comparator objects:_everyObject count:self.count];
	addNObjects( theResult, anOtherHeap->_everyObject, anOtherHeap.count );
	return theResult;
}

- (void)setValue:(id)aValue forKey:(NSString *)aKey
{
	for( id theObject in self )
		[theObject setValue:aValue forKey:aKey];
}

- (id)valueForKey:(NSString *)aKey
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:self.count];
	for( id theObject in self )
		[theResult addObject:[theObject valueForKey:aKey]];
	return theResult;
}

- (NDHeap *)filteredHeapUsingPredicate:(NSPredicate *)aPredicate
{
	NDHeap	* theResult = [NDHeap heapWithComparator:self.comparator];
	theResult->_size = self.count;
	theResult->_count = 0;
	theResult->_everyObject = (__strong id *)malloc(theResult->_size*sizeof(*theResult->_everyObject) );
	for( id theObject in self )
	{
		if( [aPredicate evaluateWithObject:theObject] )
		{
#if __has_feature(objc_arc)
			theResult->_everyObject[theResult->_count++] = theObject;
#else
			theResult->_everyObject[theResult->_count++] = [theObject retain];
#endif
		}
	}
	theResult->_size = theResult->_count;
	theResult->_everyObject = (__strong id *)reallocf(theResult->_everyObject, theResult->_size*sizeof(*theResult->_everyObject) );
	heapifyArray(theResult->_everyObject, theResult->_count, self.comparator );
	return theResult;
}

- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)aPredicate
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:self.count];
	for( id theObject in self )
	{
		if( [aPredicate evaluateWithObject:theObject] )
			[theResult addObject:theObject];
	}
	return theResult;
}

- (NSString *)description
{
	NSMutableString		* theResult = [NSMutableString stringWithString:@"{"];
	for( id theObject in self )
	{
		if( theResult.length <= 1 )
			[theResult appendFormat:@" %@", theObject];
		else
			[theResult appendFormat:@", %@", theObject];
	}
	[theResult appendString:@" }"];
	return theResult;
}

#pragma mark - NSFastEnumeration methods

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)aState objects:(id __unsafe_unretained [])aStackbuf count:(NSUInteger)aLength
{
	NSUInteger		theResult = 0;
	if(aState->state == 0)
	{
		aState->mutationsPtr = (unsigned long *)self;
		aState->itemsPtr = (id __unsafe_unretained *)_everyObject;
		aState->state = self.count;
		theResult = self.count;
	}
	return theResult;
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)aZone { return [self retain]; }

#pragma mark - NSMutableCopying methods

- (id)mutableCopyWithZone:(NSZone *)zone { return [[NDMutableHeap alloc] initWithComparator:_comparator objects:_everyObject count:self.count]; }

@end

@implementation NDMutableHeap

- (id)initWithComparator:(NSComparator)aComparator capacity:(NSUInteger)aNumItems
{
	if( (self = [super initWithComparator:aComparator]) != nil )
	{
		_size = aNumItems;
		_everyObject = (__strong id *)malloc( _size*sizeof(*_everyObject) );
	}
	return self;
}

- (void)removeMinimumObject
{
	if( self.count > 0 )
	{
		deleteNodeN(self, 0);
		_count--;
	}
	NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
}

- (void)addObject:(id)anObject
{
	addObject( self, anObject );
	NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
}
- (void)addObjectsFromArray:(NSArray *)anArray
{
	addArray(self, anArray );
	NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
}
- (void)addObjectsFromHeap:(NDHeap *)aHeap
{
	addNObjects( self, aHeap->_everyObject, self.count );
	NSParameterAssert(verifyHeapState( _everyObject, _count, _comparator, 0 ));
}

- (void)removeAllObjects
{
	for( NSUInteger i = 0, c = self.count; i < c; i++ )
	{
#if !__has_feature(objc_arc)
		[_everyObject[i] release];
#endif
	}
	free(_everyObject), _everyObject = NULL;
	_size = 0;
	_count = 0;
}

- (id)popMinimumObject
{
	id		theResult = self.minimumObject;
	[self removeMinimumObject];
	return theResult;
}

- (NSArray *)popAllObjects
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:self.count];
	while( self.count > 0 )
	{
		[theResult addObject:self.minimumObject];
		[self removeMinimumObject];
	}
	return theResult;
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)aZone { return [[NDHeap alloc] initWithComparator:_comparator objects:_everyObject count:self.count]; }

@end

@implementation NDHeapEnumerator

- (id)initWithHeap:(NDHeap *)aHeap everyObject:(__strong const id*)anEveryObject
{
	if( (self = [super init]) != nil )
	{
#if __has_feature(objc_arc)
		_heap = aHeap;
#else
		_heap = [aHeap retain];
#endif
		_everyObject = anEveryObject;
		_count = aHeap.count;
		_position = 0;
	}
	return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
	[_heap release];
	[super dealloc];
}
#endif

- (NSArray *)allObjects { return [NSArray arrayWithObjects:&_everyObject[_position] count:_count-_position]; }
- (id)nextObject
{
	id	theResult = nil;
	if( _position < _count && _everyObject != NULL )
		theResult = _everyObject[_position++];
	else
	{
		_everyObject = NULL;
#if __has_feature(objc_arc)
		_heap = nil;
#else
		[_heap release], _heap = nil;
#endif
	}
	return theResult;
}

@end


