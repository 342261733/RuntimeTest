//
//  IsaSwizzlingClass.m
//  RuntimeTest
//
//  Created by Semyon on 2017/6/20.
//  Copyright © 2017年 xnq. All rights reserved.
//

#import "IsaSwizzlingClass.h"
#import "ISAClass.h"
#import <objc/runtime.h>

@implementation IsaSwizzlingClass

+ (void)test {
    IsaSwizzlingClass *isaCls = [[IsaSwizzlingClass alloc] init];
    NSLog(@"isa %@ super %@", isaCls, isaCls.superclass);
    
    Class newIsa = object_setClass(isaCls, [ISAClass class]);
    NSLog(@"new isa %@ super %@", newIsa, class_getSuperclass(newIsa));
    
    NSLog(@"isa after isa %@ super %@", isaCls, isaCls.superclass);
}

@end
