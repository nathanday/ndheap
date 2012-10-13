//
//  main.m
//  NDHeap
//
//  Created by Nathan Day on 17/09/12.
//  Copyright (c) 2012 Nathan Day. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NDHeap.h"

static const NSUInteger		kTestSize = 40;

static NSInteger compareFunc( NSNumber * a, NSNumber * b ) { return [a compare:b]; }
static NSArray * testArray();


int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		NSUInteger		theExpectedCount = [testArray() count];
		fprintf( stderr, "Heap test start\n" );
		fprintf( stderr, "...test creation\n" );
		NDMutableHeap		* theHeap = [[NDMutableHeap alloc] initWithComparator:compareFunc array:testArray()];

		NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );

		fprintf( stderr, "...test adding\n" );
		for( id theObject in testArray() )
			[theHeap addObject:theObject];

		theExpectedCount *= 2;
		NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );

		fprintf( stderr, "...test fast enumeration\n" );
		NSMutableArray			* theEveryObject = [[theHeap everyObject] mutableCopy];
		for( NSNumber * theNumber in theHeap )
			[theEveryObject removeObject:theNumber];
		NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
		NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
		[theEveryObject release];

		fprintf( stderr, "...test NSEnumeration\n" );
		NSEnumerator		* theEnum = [theHeap objectEnumerator];
		NSNumber			* theNumber = nil;
		theEveryObject = [[theHeap everyObject] mutableCopy];
		while( (theNumber = [theEnum nextObject]) != nil )
			[theEveryObject removeObject:theNumber];
		NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
		NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
		[theEveryObject release];

		fprintf( stderr, "...test block enumeration\n" );
		theEveryObject = [[theHeap everyObject] mutableCopy];
		[theHeap enumerateObjectsUsingBlock:^(NSNumber * aNumber, BOOL * aStop) { [theEveryObject removeObject:aNumber]; }];
		NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
		NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
		[theEveryObject release];

		fprintf( stderr, "...test makeObjectsPerformSelector:object:\n" );
		theEveryObject = [NSMutableArray arrayWithCapacity:theHeap.count];
		[theHeap makeObjectsPerformSelector:@selector(addToArray:) withObject:theEveryObject];
		NSCAssert(theEveryObject.count == theHeap.count, @"Got %lu, expected %lu", theEveryObject.count, theHeap.count );
		NSCAssert(theEveryObject.count == theHeap.count, @"Got %lu, expected %lu", theEveryObject.count, theHeap.count );
		fprintf( stderr, "...test containsObject:\n" );
		for( id theObject in theEveryObject )
			NSCAssert([theHeap containsObject:theObject], @"Couldn't match %@", theObject );

		fprintf( stderr, "...test popAllObjects\n" );
		NSNumber		* thePreviousNumber = nil;
		for( NSNumber * theNumber in [theHeap popAllObjects] )
		{
			if( thePreviousNumber != nil )
				NSCParameterAssert( theNumber.integerValue >= thePreviousNumber.integerValue );
			thePreviousNumber = theNumber;
		}
		[theHeap release];

		fprintf( stderr, "...test isEqualToHeap:\n" );
		NDMutableHeap		* theCompareHeap = [NDMutableHeap heapWithComparator:theHeap.comparator],
							* theCompareHeap2 = [NDMutableHeap heapWithComparator:theHeap.comparator];
		for( NSNumber * theObject in theHeap )
		{
			[theCompareHeap addObject:[NSNumber numberWithInteger:theObject.integerValue]];
			[theCompareHeap2 addObject:[NSNumber numberWithInteger:theObject.integerValue]];
			if( theHeap.count == theCompareHeap.count )
			{
				[theCompareHeap2 addObject:[NSNumber numberWithInteger:-2000]];
				NSCParameterAssert( [theHeap isEqual:theCompareHeap] );
				NSCParameterAssert( ![theHeap isEqual:theCompareHeap2] );
			}
			else
			{
				NSCParameterAssert( ![theHeap isEqual:theCompareHeap] );
				NSCParameterAssert( ![theHeap isEqual:theCompareHeap2] );
			}
		}

		fprintf( stderr, "...test heapByAddingObject:\n" );
		NSInteger	theInteger = (random()&0xFF)-0x7F;
		NDHeap		* theNewHeap = [theHeap heapByAddingObject:[NSNumber numberWithInteger:theInteger]];
		NSCParameterAssert( theNewHeap.count == theHeap.count+1 );
		NSCParameterAssert( [theNewHeap containsObject:[NSNumber numberWithInteger:theInteger]] );

		fprintf( stderr, "...test heapByAddingObjectsFromArray:\n" );
		NSArray		* theNumbersToAdd = testArray();
		NDHeap		* theNewHeap2 = [theHeap heapByAddingObjectsFromArray:theNumbersToAdd];
		NSCParameterAssert( theNewHeap2.count == theHeap.count+theNumbersToAdd.count );
		for( id theObject in theNumbersToAdd )
			NSCParameterAssert( [theNewHeap2 containsObject:theObject] );

		fprintf( stderr, "Heap test complete\n" );
	}
    return 0;
}

NSArray * testArray()
{
	NSMutableArray		* theResult = [NSMutableArray array];
	srandom((unsigned int)time(NULL));
	for( NSUInteger i = 0; i < kTestSize; i++ )
		[theResult addObject:[NSNumber numberWithInteger:(random()&0xFF)-0x7F]];
	return theResult;
}

@implementation NSNumber (TestHeapAddition)

- (void)addToArray:(NSMutableArray *)anArray { [anArray addObject:self]; }

@end