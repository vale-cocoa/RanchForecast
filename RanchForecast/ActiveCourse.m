//
//  ActiveCourse.m
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/30/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import "ActiveCourse.h"
#import "ScheduledClass.h"

NSString *const BNRActiveCourseTitleKey = @"title";
NSString *const BNRActiveCourseURLKey = @"url";
NSString *const BNRActiveCourseUpcomingKey = @"upcoming";

@implementation ActiveCourse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        Class nsStringClass = [NSString class];
        if ([[dictionary valueForKey:BNRActiveCourseTitleKey] isKindOfClass:nsStringClass]) {
            _title = [dictionary valueForKey:BNRActiveCourseTitleKey];
        }
        if ([[dictionary valueForKey:BNRActiveCourseURLKey] isKindOfClass:nsStringClass]) {
            _url = [NSURL URLWithString:[dictionary valueForKey:BNRActiveCourseURLKey]];
        }
        if ([[dictionary valueForKey:BNRActiveCourseUpcomingKey] isKindOfClass:[NSArray class]]) {
            NSArray *scheduledDicts = [dictionary valueForKey:BNRActiveCourseUpcomingKey];
            NSMutableArray *scheduledClassesObjs = [NSMutableArray arrayWithCapacity:scheduledDicts.count];
            for (id aDict in scheduledDicts) {
                if ([aDict isKindOfClass:[NSDictionary class]]) {
                    ScheduledClass *aScheduledClassObj = [[ScheduledClass alloc] initWithDictionary:aDict];
                    if (aScheduledClassObj) {
                        [scheduledClassesObjs addObject:aScheduledClassObj];
                    }
                }
            }
            _upcoming = [scheduledClassesObjs copy];
        }
    }
    return self;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_title forKey:BNRActiveCourseTitleKey];
    [aCoder encodeObject:_url forKey:BNRActiveCourseURLKey];
    [aCoder encodeObject:_upcoming forKey:BNRActiveCourseUpcomingKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _title = [aDecoder decodeObjectForKey:BNRActiveCourseTitleKey];
        _url = [aDecoder decodeObjectForKey:BNRActiveCourseURLKey];
        _upcoming = [aDecoder decodeObjectForKey:BNRActiveCourseUpcomingKey];
    }
    return self;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

@end
