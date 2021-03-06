
#import "NSMutableDictionary-merge.h"
#import "Merge.h"

#define MERGE_DEBUG 0

#if MERGE_DEBUG
#   define MERGE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define MERGE_LOG(...)
#endif

@implementation NSMutableDictionary (merge)

- (void)mergeWithObj:(NSObject*)obj
{
    NSAssert([obj isKindOfClass:[NSDictionary class]],@"Attempted to merge objects of different types: %@\n,\n %@", [self description], [obj description]);
    
    [self mergeWithDictionary:(NSDictionary*)obj];
}

- (BOOL)canMergeWithObj:(NSObject*)obj
{
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)isMutableObj
{
    BOOL mutable = YES;
    @try {
        self[[NSNull null]] = [NSNull null];
    }
    @catch (NSException *exception) {
        mutable = NO;
    }
    
    if (mutable) {
        [self removeObjectForKey:[NSNull null]];
    }
    return mutable;
}

- (void)mergeWithDictionary:(NSDictionary*)dict
{
    NSEnumerator* ke = [dict keyEnumerator];
    
    for (id<NSCopying> key in ke) {
        id myObj = self[key];
        id obj = dict[key];
        if (!myObj) {
            // The key was not already in self, so simply add it.
            MERGE_LOG(@"inserted new object for key: %@", key);
            
            self[key] = obj;
        } else {
            id result = nil;
            if ([Merge mergeObj:myObj withObj:obj result:&result]) {
                self[key] = result;
                MERGE_LOG(@"merged objects for key: %@", key);
            } else {
                MERGE_LOG(@"could not merge objects for key: %@", key);
            }
        }
    }
}

@end