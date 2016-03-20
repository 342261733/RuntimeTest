//
//  MyClass.m
//  testSwich
//
//  Created by QFPayShadowMan on 16/3/14.
//  Copyright © 2016年 qfpay. All rights reserved.
//

#import "MyClass.h"
#include <objc/runtime.h>

NSString *strAAA = @"helloAAA";

@interface MyClass ()

@property (nonatomic,copy) NSString *str3;

@end

@implementation MyClass {
    NSString *_str1;
}

+ (MyClass *)shareinstance {
    static MyClass *dc = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (dc == nil) {
            dc = [[[self class] alloc] init];
            [dc changeAtoB];
            
            dc.str3 = @"hello3";
            dc.str4 = @"hello4";
        }
    });
    return dc;
}

- (NSString *)appendMyString:(NSString *)string {
    NSString *mString = [NSString stringWithFormat:@"%@ after append method", string];
    return mString;
}

- (void)methodA {
    NSLog(@"swizzle methodA invoke");
}

- (void)methodB {
    NSLog(@"swizzle methodB invoke");
}

- (void)changeAtoB {
    SEL systemSel = @selector(methodA);
    SEL swizzSel = @selector(methodB);
    
    Method systemMethod = class_getInstanceMethod([self class], systemSel);
    Method swizzMethod = class_getInstanceMethod([self class], swizzSel);
    
    //首先动态添加方法，实现是被交换的方法，返回值表示添加成功还是失败
    BOOL isAdd = class_addMethod([self class], systemSel, method_getImplementation(swizzMethod), method_getTypeEncoding(swizzMethod));
    if (isAdd) {
        //如果成功，说明类中不存在这个方法的实现
        //将被交换方法的实现替换到这个并不存在的实现
        class_replaceMethod([self class], swizzSel, method_getImplementation(systemMethod), method_getTypeEncoding(systemMethod));
    }
    else {//否则，交换两个方法的实现
        method_exchangeImplementations(systemMethod, swizzMethod);
    }
}

- (BOOL)test1 {
    NSLog(@"i am test 1");
    return YES;
}

+ (void)test2 {
    NSLog(@"I am test 2");
}

- (NSString *)test3:(NSString *)strSay Array:(NSArray *)arrSay Dic:(NSDictionary *)dicSay Int:(int)intSay Class:(MyClass *)classSay {
    NSLog(@"I want to say: %@",strSay);
    return [NSString stringWithFormat:@"I want to say: %@",strSay];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"str1: %@, str2: %@, str3: %@, str4: %@ ", _str1,_str2,_str3,_str4];
}

- (void)testPrivateMethod:(NSString *)strTest {
    NSLog(@"I am private Method, param : %@",strTest);
}

@end
