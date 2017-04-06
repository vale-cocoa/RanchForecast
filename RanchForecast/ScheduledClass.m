//
//  ScheduledClass.m
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/30/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import "ScheduledClass.h"

NSString *const BNRScheduledClassEndDateKey = @"end_date";
NSString *const BNRScheduledClassInstructorsKey = @"instructors";
NSString *const BNRScheduledClassLocationKey = @"location";
NSString *const BNRScheduledClassStartDateKey = @"start_date";

@implementation ScheduledClass

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY/MM/dd"];
        Class nsStringClass = [NSString class];
        if ([[dictionary valueForKey:BNRScheduledClassEndDateKey] isKindOfClass:nsStringClass]) {
            _end_date = [dateFormatter dateFromString:[dictionary valueForKey:BNRScheduledClassEndDateKey]];
        }
        if ([[dictionary valueForKey:BNRScheduledClassInstructorsKey] isKindOfClass:nsStringClass]) {
            _instructors = [dictionary valueForKey:BNRScheduledClassInstructorsKey];
        }
        if ([[dictionary valueForKey:BNRScheduledClassLocationKey] isKindOfClass:nsStringClass]) {
            _location = [dictionary valueForKey:BNRScheduledClassLocationKey];
        }
        if ([[dictionary valueForKey:BNRScheduledClassStartDateKey] isKindOfClass:nsStringClass]) {
            _start_date = [dateFormatter dateFromString:[dictionary valueForKey:BNRScheduledClassStartDateKey]];
        }
    }
    return self;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_end_date forKey:BNRScheduledClassEndDateKey];
    [aCoder encodeObject:_instructors forKey:BNRScheduledClassInstructorsKey];
    [aCoder encodeObject:_location forKey:BNRScheduledClassLocationKey];
    [aCoder encodeObject:_start_date forKey:BNRScheduledClassStartDateKey];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _end_date = [aDecoder decodeObjectForKey:BNRScheduledClassEndDateKey];
        _instructors = [aDecoder decodeObjectForKey:BNRScheduledClassInstructorsKey];
        _location = [aDecoder decodeObjectForKey:BNRScheduledClassLocationKey];
        _start_date = [aDecoder decodeObjectForKey:BNRScheduledClassStartDateKey];
    }
    return self;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

@end
