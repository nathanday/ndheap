/*
	NDHeap.h

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

#import <Foundation/Foundation.h>

@interface NDHeap : NSObject <NSFastEnumeration,NSCopying,NSMutableCopying>

@property(readonly,nonatomic)		NSComparisonResult (*comparator)(id, id);
@property(readonly,nonatomic)		NSUInteger			count;
@property(readonly,nonatomic)		id					minimumObject;


+ (id)heapWithComparator:(NSComparisonResult (*)(id, id))comparator objects:(id)array, ...;
+ (id)heapWithComparator:(NSComparisonResult (*)(id, id))comparator objects:(id *)array count:(NSUInteger)count;
+ (id)heapWithComparator:(NSComparisonResult (*)(id, id))comparator array:(NSArray *)array;
+ (id)heapWithComparator:(NSComparisonResult (*)(id, id))comparator;

- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator objects:(id)array, ...;
- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator arguments:(va_list)arguments firstObject:(id)firstObject;
- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator objects:(id *)array count:(NSUInteger)count;
- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator array:(NSArray *)array;
- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator;

- (NSArray *)everyObject;

- (NSEnumerator *)objectEnumerator;
- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block;
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, BOOL *stop))block;
- (void)makeObjectsPerformSelector:(SEL)selector;
- (void)makeObjectsPerformSelector:(SEL)selector withObject:(id)object;

- (BOOL)containsObject:(id)object;
- (BOOL)isEqualToHeap:(NDHeap *)otherHeap;
- (NDHeap *)heapByAddingObject:(id)object;
- (NDHeap *)heapByAddingObjectsFromArray:(NSArray *)otherArray;
- (NDHeap *)heapByAddingObjectsFromHeap:(NDHeap *)otherHeap;

- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

- (NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate;

@end

@interface NDMutableHeap : NDHeap

- (id)initWithComparator:(NSComparisonResult (*)(id, id))comparator capacity:(NSUInteger)numItems;

- (void)removeMinimumObject;
- (void)addObject:(id)object;

- (void)addArray:(NSArray *)array;
- (void)addHeap:(NDHeap *)heap;

- (void)removeAllObjects;

- (id)popMinimumObject;
- (NSArray *)popAllObjects;

@end
