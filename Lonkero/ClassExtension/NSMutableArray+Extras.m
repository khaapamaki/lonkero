//
//  NSMutableArray+Extras.m
//  Lonkero
//
//  Created by Kati Haapamäki on 10.1.2014.
//  Copyright (c) 2014 Kati Haapamäki. All rights reserved.
//

#import "NSMutableArray+Extras.h"

@implementation NSMutableArray (Extras)


/**
 *  Removes all objects that are empty "" strings.
 */

-(void)removeEmptyStringItems {
    if ([self count] > 0) {
        for (long index = [self count] - 1; index >= 0; index--) {
            if ([self[index] isEqualToString:@""] || self[index]  == nil) {
                [self removeObjectAtIndex:index];
            }
        }
    }
}
@end
