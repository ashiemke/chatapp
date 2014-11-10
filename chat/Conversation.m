//
//  Conversation.m
//  chat
//
//  Created by Adam Shiemke on 11/6/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "Conversation.h"

@implementation Conversation

@dynamic participants;

@synthesize messages;

+ (NSString *)parseModelClass{
    return NSStringFromClass([self class]);
}


@end
