//
//  ViewController.m
//  RuntimeTest
//
//  Created by QFPayShadowMan on 16/3/20.
//  Copyright © 2016年 xnq. All rights reserved.
//

#import "ViewController.h"
#include <objc/runtime.h>
#import "MyClass.h"
#import "IsaSwizzlingClass.h"

extern char associatedObjectKey;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//        [self testInvocation];//invocation
//        [self testMutiParams];//传递多个参数
//        [self testAutoAddMethod];//测试调用未实现的方法、
//        [self testAssociation];//关联对象
//        [self testChangeAtoB];//方法变换
//        [self testMetaClass1];//获取元类
//        [self testGetPrivateVariable];//获取类的所有方法或变量
//        [self testAmendPrivateVariable];//修改私有变量
//        [self testAmendPrivateMethod];//修改私有函数
    
    [IsaSwizzlingClass test];
    
}

- (void)testAmendPrivateMethod {
    unsigned int outCountMethod = 0;
    Method *arrMethod = class_copyMethodList([MyClass class], &outCountMethod);
    for (int i= 0; i<outCountMethod; i++) {
        Method method = arrMethod[i];
        SEL methodNameSel = method_getName(method);
        NSString *methodName = [NSString stringWithCString:sel_getName(methodNameSel) encoding:NSUTF8StringEncoding];
        //        IMP methodIMP = method_getImplementation(method);
        //        const char *methodType =  method_getTypeEncoding(method);
        //        char *methodRetureType = method_copyReturnType(method);
        if ([methodName isEqualToString:@"testPrivateMethod:"]) {
            SEL systemSel = methodNameSel;
            Method systemMethod = class_getInstanceMethod([MyClass class], systemSel);
            SEL swizzSel = @selector(testAmendMethodChangeMethod:);
            Method swizzMethod = class_getInstanceMethod([self class], swizzSel);
            //首先动态添加方法，实现是被交换的方法，返回值表示添加成功还是失败
            BOOL isAdd = class_addMethod([MyClass class], systemSel, method_getImplementation(swizzMethod), method_getTypeEncoding(swizzMethod));
            if (isAdd) {
                //如果成功，说明类中不存在这个方法的实现
                //将被交换方法的实现替换到这个并不存在的实现
                class_replaceMethod([MyClass class], swizzSel, method_getImplementation(systemMethod), method_getTypeEncoding(systemMethod));
            }
            else {//否则，交换两个方法的实现
                method_exchangeImplementations(systemMethod, swizzMethod);
            }
        }
    }
    //调用MyClass 类的私有方法
    MyClass *myCls = [[MyClass alloc] init];
    SEL mySelector = NSSelectorFromString(@"testPrivateMethod:");
    NSMethodSignature *sig = [[MyClass class] instanceMethodSignatureForSelector:mySelector];
    NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:sig];
    [myInvocation setTarget:myCls];
    [myInvocation setSelector:mySelector];
    NSString *strMy = @"hi";
    [myInvocation setArgument:&strMy atIndex:2];
    
    [myInvocation retainArguments];
    [myInvocation invoke];
    //    NSString *strResult = nil;
    //    [myInvocation getReturnValue:&strResult];
}

- (void)testAmendMethodChangeMethod:(NSString *)strString {
    NSLog(@"I have amend method A and param:%@",strString);
}

- (void)testAmendPrivateVariable {
    unsigned int outCountMember = 0;
    Ivar *members = class_copyIvarList([MyClass class], &outCountMember);
    for (int i = 0; i<outCountMember; i++) {
        Ivar var = members[i];
        const char * memberName = ivar_getName(var);
        if ([[NSString stringWithFormat:@"%s",memberName] isEqualToString:@"_str4"]) {
            MyClass *clsMy = [MyClass shareinstance];
            NSLog(@"description : %@",[clsMy description]);
            Ivar m_member = var;
            object_setIvar(clsMy, m_member, @"amend Hello world");
            NSLog(@"description ==: %@",[clsMy description]);
        }
    }
}

- (void)testGetPrivateVariable {
    //    Method myClassMethod = class_getInstanceMethod([MyClass class], @selector(appendMyString:));//获取实例方法
    unsigned int outCountMethod = 0;
    Method *arrMethod = class_copyMethodList([MyClass class], &outCountMethod);
    for (int i= 0; i<outCountMethod; i++) {
        Method method = arrMethod[i];
        SEL methodNameSel = method_getName(method);
        NSString *methodName = [NSString stringWithCString:sel_getName(methodNameSel) encoding:NSUTF8StringEncoding];
        //        IMP methodIMP = method_getImplementation(method);
        const char *methodType =  method_getTypeEncoding(method);
        char *methodRetureType = method_copyReturnType(method);
        
        unsigned int index = 0;//参数位置index
        char *methodArgument;
        do {
            methodArgument = method_copyArgumentType(method, index++);
            NSLog(@"methodArgument %s",methodArgument);
        } while (methodArgument);
        //methodArgument参数为空的情况: @ : (null)
        //methodArgument参数为一个NSString的情况: @ : @ (null)
        
        NSLog(@"methodName:%@ --- methodType:%s --- methodRetureType:%s ",methodName,methodType,methodRetureType);
    }
    unsigned int outCountMember = 0;
    Ivar *members = class_copyIvarList([MyClass class], &outCountMember);
    for (int i = 0; i<outCountMember; i++) {
        Ivar var = members[i];
        const char * memberName = ivar_getName(var);
        const char * memberType = ivar_getTypeEncoding(var);
        NSLog(@"memberName:%s ----- memberType:%s",memberName,memberType);
    }
    
    // 属性操作 获取的是：@property的变量，不管私有公有
    objc_property_t * properties = class_copyPropertyList([MyClass class], &outCountMember);
    for (int i = 0; i < outCountMember; i++) {
        objc_property_t property = properties[i];
        NSLog(@"property's name: %s", property_getName(property));
    }
}

- (void)testMetaClass1 {
    //这个例子是在运行时创建了一个NSError的子类TestClass，然后为这个子类添加一个方法testMetaClass，这个方法的实现是TestMetaClass函数。
    Class newClass = objc_allocateClassPair([NSError class], "TestClass", 0);
    class_addMethod(newClass, @selector(testMetaClass), (IMP)TestMetaClass,"v@:");//给NSError添加一个新方法testMetaClass
    objc_registerClassPair(newClass);
    const char *name = class_getName(newClass);
    NSLog(@"name %s",name);
    Class metaClass = objc_getMetaClass(name);
    NSLog(@"metaClass %@",metaClass);
    int cls_version = class_getVersion(newClass);
    IMP methodImplement =  class_getMethodImplementation(newClass, @selector(testMetaClass));//(testSwich`TestMetaClass at ViewController.m:67) 地址位置
    
    id instance = [[newClass alloc] initWithDomain:@"some domain" code:0 userInfo:nil];
    [instance performSelector:@selector(testMetaClass) withObject:nil];
}

void TestMetaClass(id self, SEL _cmd) {
    NSLog(@"this object is %p",self);
    NSLog(@"Class is %@, super class is %@",[self class],[self superclass]);
    
    Class currentClass = [self class];
    for (int i=0; i<4; i++) {
        NSLog(@"Following the isa pointer %d times gives %p",i,currentClass);
        currentClass = objc_getClass((__bridge void *)currentClass);
    }
}

- (void)testChangeAtoB {
    MyClass *mycls = [MyClass shareinstance];
    [mycls methodA];
    
}

- (void)testAssociation {
    MyClass *myClass = [MyClass shareinstance];
    NSArray *arrGetObj = objc_getAssociatedObject(myClass, &associatedObjectKey);
    NSLog(@"arrGetObj %@",arrGetObj);
}

- (void)testAutoAddMethod {
    [self performSelector:NSSelectorFromString(@"resolveAdd:") withObject:@"test"];
}

#pragma mark - NSObject method

+ (BOOL)resolveClassMethod:(SEL)sel {
    return NO;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if ([NSStringFromSelector(sel) isEqualToString:@"resolveAdd:"]) {
        class_addMethod(self, sel, (IMP)runAddMethod, "v@:");//注意这个地方只能调用c函数，而无法使用oc函数。
    }
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"anInvocation :%@",anInvocation);
}

#pragma mark - Method invoke

void runAddMethod(id self, SEL _cmd, NSString *string) {
    NSLog(@"add C IMP : %@",string);
}


#pragma mark - Test

- (void)testInvocation {
    MyClass *myClass = [[MyClass alloc] init];
    NSString *strMy = @"My string";
    
    //common selector
    NSString *normalInvokeString = [myClass appendMyString:strMy];
    NSLog(@"The normal invoke string is :%@",normalInvokeString);
    
    //NSInvocation selector
    SEL mySelector = @selector(appendMyString:);
    NSMethodSignature *sig = [[myClass class]instanceMethodSignatureForSelector:mySelector];
    
    NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:sig];
    [myInvocation setTarget:myClass];
    [myInvocation setSelector:mySelector];
    [myInvocation setArgument:&strMy atIndex:2];
    
    NSString *strResult = nil;
    [myInvocation retainArguments];
    [myInvocation invoke];
    [myInvocation getReturnValue:&strResult];
    NSLog(@"The NSInvocation invoke string is :%@",strResult);
    
}

- (void)testMutiParams {
    //test perform
    NSString *strRe = [self performSelector:@selector(appendString:String2:) withObject:@"hello" withObject:@"world"];
    NSLog(@"strRe :%@",strRe);
    
    //question ?
    NSString *strRe1 = [self performSelector:@selector(appendString:String2:String3:) withObject:@"hello" withObject:@"world"];
    NSLog(@"strRe :%@",strRe1);
    
    NSString *strMy1 = @"My string1";
    NSString *strMy2 = @"My string2";
    NSString *strMy3 = @"My string3";
    
    SEL mySelector = @selector(appendString:String2:String3:);
    NSMethodSignature *sig = [[self class]instanceMethodSignatureForSelector:mySelector];
    
    NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:sig];
    [myInvocation setTarget:self];
    [myInvocation setSelector:mySelector];
    [myInvocation setArgument:&strMy1 atIndex:2];
    [myInvocation setArgument:&strMy2 atIndex:3];
    [myInvocation setArgument:&strMy3 atIndex:4];
    
    NSString *strResult = nil;
    [myInvocation retainArguments];
    [myInvocation invoke];
    [myInvocation getReturnValue:&strResult];
    NSLog(@"The NSInvocation invoke string is :%@",strResult);
    
}

- (NSString *)appendString:(NSString *)str1 String2:(NSString *)str2 {
    return [NSString stringWithFormat:@"%@,%@",str1,str2];
}

- (NSString *)appendString:(NSString *)str1 String2:(NSString *)str2 String3:(NSString *)str3 {
    return [NSString stringWithFormat:@"%@,%@,%@",str1,str2,str3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
