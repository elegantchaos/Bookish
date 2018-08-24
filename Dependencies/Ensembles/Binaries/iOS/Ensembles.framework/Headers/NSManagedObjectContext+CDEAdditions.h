//
//  NSManagedObjectContext+CDEAdditions.h
//  Ensembles Mac
//
//  Created by Drew McCormack on 14/04/14.
//  Copyright (c) 2014 Drew McCormack. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (CDEAdditions)

- (BOOL)cde_enumerateObjectsForFetchRequest:(NSFetchRequest *)fetch withBatchSize:(NSUInteger)batchSize withBlock:(void(^)(NSArray *objects, NSUInteger batchesRemaining, BOOL *stop))block;

@end
