//
//  MyClass.h
//  testSwich
//
//  Created by QFPayShadowMan on 16/3/14.
//  Copyright © 2016年 qfpay. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MyClass : NSObject {
    NSString *_str2;
}

@property (nonatomic,copy) NSString *str4;

+ (id)shareinstance;

- (NSString *)appendMyString:(NSString *)string;


- (void)methodA;
- (void)methodB;

@end
