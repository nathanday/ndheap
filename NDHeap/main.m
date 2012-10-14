//
//  main.m
//  NDHeap
//
//  Created by Nathan Day on 17/09/12.
//  Copyright (c) 2012 Nathan Day. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NDHeap.h"

static const NSUInteger		kTestSize = 4000;

static NSInteger compareFunc( NSNumber * a, NSNumber * b ) { return [a compare:b]; }
static NSArray * sampleArray();
static NDHeap * sampleHeap();

static void testCreation();
static void testAdding();
static void testFastEnumeration();
static void testNSEnumeration();
static void testBlockEnumeration();
static void testMakeObjectsPerformSelector_object_();
static void testPopAllObjects();
static void testIsEqualToHeap_();
static void testHeapByAddingObject_();
static void testHeapByAddingObjectsFromArray_();
static void testHeapByAddingObjectsFromHeap_();
static void testValueForKey_();
static void testFilteredHeapUsingPredicate_();
static void testFilteredArrayUsingPredicate_();
static void testRemoveMinimumObject();
static void testPopMinimumObject();
static void testAddObjectsFromArray();
static void testAddObjectsFromHeap();


int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		fprintf( stderr, "Heap test start\n" );
		testCreation();
		testAdding();
		testFastEnumeration();
		testNSEnumeration();
		testBlockEnumeration();
		testMakeObjectsPerformSelector_object_();
		testPopAllObjects();
		testIsEqualToHeap_();
		testHeapByAddingObject_();
		testHeapByAddingObjectsFromArray_();
		testHeapByAddingObjectsFromHeap_();
		testValueForKey_();
		testFilteredHeapUsingPredicate_();
		testFilteredArrayUsingPredicate_();
		testRemoveMinimumObject();
		testPopMinimumObject();
		testAddObjectsFromArray();
		testAddObjectsFromHeap();
		fprintf( stderr, "Heap test complete\n" );
	}
	return 0;
}

void testCreation()
{
	fprintf( stderr, "...test creation\n" );
	NSUInteger			theExpectedCount = [sampleArray() count];
	NDHeap				* theHeap = sampleHeap();
	NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
}

void testAdding()
{
	fprintf( stderr, "...test adding\n" );
	NDMutableHeap		* theHeap = [[NDMutableHeap alloc] initWithComparator:^(id a, id b){return [a compare:b];} array:sampleArray()];
	NSUInteger			theExpectedCount = [sampleArray() count];
	for( id theObject in sampleArray() )
		[theHeap addObject:theObject];
	theExpectedCount *= 2;
	NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
}

void testFastEnumeration()
{
	fprintf( stderr, "...test fast enumeration\n" );
	NDHeap					* theHeap = sampleHeap();
	NSUInteger				theExpectedCount = theHeap.count;
	NSMutableArray			* theEveryObject = [[theHeap everyObject] mutableCopy];
	for( NSNumber * theNumber in theHeap )
		[theEveryObject removeObject:theNumber];
	NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
	NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
	[theEveryObject release];
}

void testNSEnumeration()
{
	fprintf( stderr, "...test NSEnumeration\n" );
	NDHeap				* theHeap = sampleHeap();
	NSEnumerator		* theEnum = [theHeap objectEnumerator];
	NSUInteger			theExpectedCount = theHeap.count;
	NSNumber			* theNumber = nil;
	NSMutableArray		* theEveryObject = [[theHeap everyObject] mutableCopy];
	while( (theNumber = [theEnum nextObject]) != nil )
		[theEveryObject removeObject:theNumber];
	NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
	NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
	[theEveryObject release];
}

void testBlockEnumeration()
{
	fprintf( stderr, "...test block enumeration\n" );
	NDHeap				* theHeap = sampleHeap();
	NSUInteger			theExpectedCount = theHeap.count;
	NSMutableArray		* theEveryObject = [[theHeap everyObject] mutableCopy];
	[theHeap enumerateObjectsUsingBlock:^(NSNumber * aNumber, BOOL * aStop) { [theEveryObject removeObject:aNumber]; }];
	NSCAssert(theEveryObject.count == 0, @"Got %lu, expected 0", theHeap.count );
	NSCAssert(theHeap.count == theExpectedCount, @"Got %lu, expected %lu", theHeap.count, theExpectedCount );
	[theEveryObject release];
}

void testMakeObjectsPerformSelector_object_()
{
	fprintf( stderr, "...test makeObjectsPerformSelector:object:\n" );
	NDHeap				* theHeap = sampleHeap();
	NSMutableArray		* theEveryObject = [NSMutableArray arrayWithCapacity:theHeap.count];
	[theHeap makeObjectsPerformSelector:@selector(addToArray:) withObject:theEveryObject];
	NSCAssert(theEveryObject.count == theHeap.count, @"Got %lu, expected %lu", theEveryObject.count, theHeap.count );
	NSCAssert(theEveryObject.count == theHeap.count, @"Got %lu, expected %lu", theEveryObject.count, theHeap.count );
	fprintf( stderr, "...test containsObject:\n" );
	for( id theObject in theEveryObject )
		NSCAssert([theHeap containsObject:theObject], @"Couldn't match %@", theObject );
}

void testPopAllObjects()
{
	fprintf( stderr, "...test popAllObjects\n" );
	NDMutableHeap	* theHeap = [sampleHeap() mutableCopy];;
	NSNumber		* thePreviousNumber = nil;
	for( NSNumber * theNumber in [theHeap popAllObjects] )
	{
		if( thePreviousNumber != nil )
			NSCParameterAssert( theNumber.integerValue >= thePreviousNumber.integerValue );
		thePreviousNumber = theNumber;
	}
	[theHeap release];
}

void testIsEqualToHeap_()
{
	fprintf( stderr, "...test isEqualToHeap:\n" );
	NDHeap				* theHeap = sampleHeap();
	NDMutableHeap		* theCompareHeap = [NDMutableHeap heapWithComparator:theHeap.comparator],
						* theCompareHeap2 = [NDMutableHeap heapWithComparator:theHeap.comparator];
	for( NSNumber * theObject in theHeap )
	{
		[theCompareHeap addObject:[NSNumber numberWithInteger:theObject.integerValue]];
		if( theHeap.count == theCompareHeap.count )
		{
			[theCompareHeap2 addObject:[NSNumber numberWithInteger:-2000]];
			NSCParameterAssert( [theHeap isEqual:theCompareHeap] );
			NSCParameterAssert( ![theHeap isEqual:theCompareHeap2] );
		}
		else
		{
			[theCompareHeap2 addObject:[NSNumber numberWithInteger:theObject.integerValue]];
			NSCParameterAssert( ![theHeap isEqual:theCompareHeap] );
			NSCParameterAssert( ![theHeap isEqual:theCompareHeap2] );
		}
	}
}

void testHeapByAddingObject_()
{
	fprintf( stderr, "...test heapByAddingObject:\n" );
	NSInteger	theInteger = (random()&0xFF)-0x7F;
	NDHeap				* theHeap = sampleHeap();
	NDHeap		* theNewHeap = [theHeap heapByAddingObject:[NSNumber numberWithInteger:theInteger]];
	NSCParameterAssert( theNewHeap.count == theHeap.count+1 );
	NSCParameterAssert( [theNewHeap containsObject:[NSNumber numberWithInteger:theInteger]] );
}

void testHeapByAddingObjectsFromArray_()
{
	fprintf( stderr, "...test heapByAddingObjectsFromArray:\n" );
	NDHeap		* theHeap = sampleHeap();
	NSArray		* theNumbersToAdd = sampleArray();
	NDHeap		* theNewHeap2 = [theHeap heapByAddingObjectsFromArray:theNumbersToAdd];
	NSCParameterAssert( theNewHeap2.count == theHeap.count+theNumbersToAdd.count );
	for( id theObject in theNumbersToAdd )
		NSCParameterAssert( [theNewHeap2 containsObject:theObject] );
}

void testHeapByAddingObjectsFromHeap_()
{
	fprintf( stderr, "...test heapByAddingObjectsFromHeap:\n" );
	NDHeap		* theHeap = sampleHeap();
	NDHeap		* theHeapToAdd = [NDHeap heapWithComparator:theHeap.comparator array:sampleArray()];
	NDHeap		* theNewHeap3 = [theHeap heapByAddingObjectsFromHeap:theHeapToAdd];
	NSCParameterAssert( theNewHeap3.count == theHeap.count+theHeapToAdd.count );
	for( id theObject in theHeapToAdd )
		NSCParameterAssert( [theNewHeap3 containsObject:theObject] );
}

void testValueForKey_()
{
	fprintf( stderr, "...test valueForKey:\n" );
	NDHeap		* theHeap = sampleHeap();
	NSArray		* theArray = [theHeap valueForKey:@"stringValue"];
	NSUInteger	theIndex = 0;
	for( NSNumber * theNumber in theHeap )
		NSCParameterAssert( [theNumber.stringValue isEqualToString:[theArray objectAtIndex:theIndex++]] );
}

void testFilteredHeapUsingPredicate_()
{
	fprintf( stderr, "...test filteredHeapUsingPredicate:\n" );
	NDHeap		* theHeap = sampleHeap();
	NDHeap		* theFilteredHeap1 = [theHeap filteredHeapUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue >= 0"]],
				* theFilteredHeap2 = [theHeap filteredHeapUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue < 0"]];
	NSCParameterAssert(theFilteredHeap1.count+theFilteredHeap2.count == theHeap.count );
	for( NSNumber * theNumber in theFilteredHeap1 )
		NSCParameterAssert( theNumber.integerValue >= 0 );
	for( NSNumber * theNumber in theFilteredHeap2 )
		NSCParameterAssert( theNumber.integerValue < 0 );
}

void testFilteredArrayUsingPredicate_()
{
	fprintf( stderr, "...test filteredArrayUsingPredicate:\n" );
	NDHeap		* theHeap = sampleHeap();
	NSArray		* theFilteredArray1 = [theHeap filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue >= 0"]],
				* theFilteredArray2 = [theHeap filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue < 0"]];
	NSCParameterAssert(theFilteredArray1.count+theFilteredArray2.count == theHeap.count );
	for( NSNumber * theNumber in theFilteredArray1 )
		NSCParameterAssert( theNumber.integerValue >= 0 );
	for( NSNumber * theNumber in theFilteredArray2 )
		NSCParameterAssert( theNumber.integerValue < 0 );
}

void testRemoveMinimumObject()
{
	fprintf( stderr, "...test removeMinimumObject\n" );
	NDMutableHeap		* theHeap = [NDMutableHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:sampleArray()];
	NSUInteger			theMatchCount[2] = {0,0};
	NSNumber			* theMin = [theHeap minimumObject];
	for( NSNumber * theNumber in theHeap )
	{
		NSCParameterAssert(theNumber.integerValue >= theMin.integerValue);
		theMatchCount[0] += theNumber.integerValue == theMin.integerValue;
	}
	[theHeap removeMinimumObject];
	for( NSNumber * theNumber in theHeap )
	{
		NSCParameterAssert(theNumber.integerValue >= theMin.integerValue);
		theMatchCount[1] += theNumber.integerValue == theMin.integerValue;
	}
	NSCParameterAssert(theMatchCount[0] == theMatchCount[1]+1);

	theMatchCount[1] = 0;
	theMin = [theHeap minimumObject];
	[theHeap removeMinimumObject];
	for( NSNumber * theNumber in theHeap )
	{
		NSCParameterAssert(theNumber.integerValue >= theMin.integerValue);
		theMatchCount[1] += theNumber.integerValue == theMin.integerValue;
	}
	NSCParameterAssert(theMatchCount[0] == theMatchCount[1]+1);
}

void testPopMinimumObject()
{
	fprintf(stderr, "...test popMinimumObject\n");
	NDMutableHeap		* theHeap = [NDMutableHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:sampleArray()];
	NSNumber			* theMin = nil;
	while( theHeap.count > 0 )
	{
		theMin = [theHeap minimumObject];
		NSCParameterAssert( [[theHeap popMinimumObject] isEqualToNumber:theMin] );
		for( NSNumber * theNumber in theHeap )
			NSCParameterAssert( theNumber.integerValue >= theMin.integerValue );
	}
}

void testAddObjectsFromArray()
{
	fprintf(stderr, "...test addObjectsFromArray\n");
	NSMutableArray	* theArray1 = [NSMutableArray arrayWithArray:sampleArray()];
	NSArray			* theArray2 = sampleArray();
	NDMutableHeap	* theHeap1 = [NDMutableHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:theArray1];
	[theArray1 addObjectsFromArray:theArray2];
	[theArray1 sortUsingComparator:^(id a, id b){return ^(id a, id b){return [a compare:b];}(a,b);}];
	[theHeap1 addObjectsFromArray:theArray2];
	NSCParameterAssert( theArray1.count == theHeap1.count );
	for( NSNumber * theNumber in theArray1 )
		NSCParameterAssert( [theHeap1 containsObject:theNumber] );

}

void testAddObjectsFromHeap()
{
	fprintf(stderr, "...test addObjectsFromHeap\n");
	NSMutableArray	* theArray1 = [NSMutableArray arrayWithArray:sampleArray()];
	NSArray			* theArray2 = sampleArray();
	NDMutableHeap	* theHeap1 = [NDMutableHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:theArray1];
	NDHeap			* theHeap2 = [NDHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:theArray2];
	[theArray1 addObjectsFromArray:theArray2];
	[theArray1 sortUsingComparator:^(id a, id b){return ^(id a, id b){return [a compare:b];}(a,b);}];
	[theHeap1 addObjectsFromHeap:theHeap2];
	NSCParameterAssert( theArray1.count == theHeap1.count );
	for( NSNumber * theNumber in theArray1 )
		NSCParameterAssert( [theHeap1 containsObject:theNumber] );

}

NSArray * sampleArray()
{
#if 1
	NSMutableArray		* theResult = [NSMutableArray array];
	srandom((unsigned int)time(NULL));
	for( NSUInteger i = 0; i < kTestSize; i++ )
		[theResult addObject:[NSNumber numberWithInteger:(random()&0xFFFF)-0x7FFF]];
	return theResult;
#else
	return @[@(-95), @(56), @(-1), @(-35), @(36), @(51), @(-24), @(-24), @(-111), @(72), @(88), @(18), @(-24), @(-112), @(-66), @(114), @(12), @(13), @(47), @(-16), @(-126), @(22), @(-67), @(-117), @(105), @(-55), @(-112), @(50), @(-9), @(54), @(43), @(23), @(-18), @(-86), @(115), @(-111), @(92), @(-37), @(-8), @(108)];
#endif
}

NDHeap * sampleHeap()
{
	return [NDHeap heapWithComparator:^(id a, id b){return [a compare:b];} array:sampleArray()];
}

@implementation NSNumber (TestHeapAddition)

- (void)addToArray:(NSMutableArray *)anArray { [anArray addObject:self]; }

@end