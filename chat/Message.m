//
//  Message.m
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "Message.h"
#import <Parse/Parse.h>

@implementation Message

@dynamic fromUser, content, conversation;

// Needed for parse
+ (NSString *)parseModelClass{
    return NSStringFromClass([self class]);
}


// Override automatic setter from ParseModel becasue it doesn't handle enums
- (void)setContentType:(MessageContentType)contentType{
    [self.parseObject setObject:@(contentType) forKey:@"contentType"];
}
- (MessageContentType)contentType{
    return (MessageContentType)[self.parseObject[@"contentType"] intValue];
}


#pragma mark JSQMessageData protocol methods
- (NSString *)senderId{
    return self.fromUser.username;
}

- (NSString *)senderDisplayName {
    return self.fromUser.username;
}

- (NSDate *)date {
    return self.parseObject.createdAt;
}

- (BOOL)isMediaMessage{
    return self.contentType > MessageContentTypeText;
}

- (NSString *)text{
    if (self.contentType == MessageContentTypeText){
        return self.content;
    }
    return @"";
}

@end
