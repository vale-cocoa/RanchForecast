//
//  BNRCoursesFetcher.h
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/31/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ActiveCourse;
@class ScheduledClass;

extern NSString *const BNRURLForCoursesJSON;

@interface BNRCoursesFetcher : NSObject

@property (strong, nonatomic, readonly) NSArray <ActiveCourse *> *courses;
@property (assign, getter=isFetching, readonly) BOOL fetching;
@property (strong, readonly) NSURLResponse *lastFetchResponse;
@property (strong, readonly) NSError *error;
@property (strong, readonly) NSNumber *countToFetch;
@property (strong, readonly) NSNumber *indexOfFetch;

- (IBAction)toggleFetch:(id _Nullable)sender;

#pragma mark - KVC courses relationship
- (void)insertObject:(ActiveCourse *)object inCoursesAtIndex:(NSUInteger)index;
- (void)removeObjectFromCoursesAtIndex:(NSUInteger)index;
- (NSArray <ActiveCourse *> *)coursesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceCoursesAtIndexes:(NSIndexSet *)indexes withCourses:(NSArray <ActiveCourse *> *)array;

@end

NS_ASSUME_NONNULL_END
