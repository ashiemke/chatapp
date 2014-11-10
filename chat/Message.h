//
//  Message.h
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ParseModel/ParseModel.h>
#import <JSQMessageData.h>

@class PFUser, Conversation;

typedef NS_ENUM(NSUInteger, MessageContentType) {
    // Text type
    MessageContentTypeText = 1,
    // Media types
    MessageContentTypeAudio,
    MessageContentTypeVideo,
    MessageContentTypeImage,
};

@interface Message : ParseModel <JSQMessageData>

@property (nonatomic, strong) PFUser *fromUser;
@property (nonatomic) MessageContentType contentType;
@property (nonatomic) id content;
@property (nonatomic) Conversation* conversation;

@end
