//
//  ScheduledClass.h
//  RanchForecast
//
//  Created by Valeriano Della Longa on 3/30/17.
//  Copyright © 2017 Valeriano Della Longa. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const BNRScheduledClassEndDateKey;
extern NSString *const BNRScheduledClassInstructorsKey;
extern NSString *const BNRScheduledClassLocationKey;
extern NSString *const BNRScheduledClassStartDateKey;

@interface ScheduledClass : NSObject <NSCopying, NSCoding>

@property (copy) NSString *location;
@property (copy) NSString *instructors;
@property (copy) NSDate *start_date;
@property (copy) NSDate *end_date;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
