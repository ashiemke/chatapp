//
//  MessagesViewController.h
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"

@class Conversation;
@class JSQMessagesBubbleImage;

@interface MessagesViewController : JSQMessagesViewController

@property (nonatomic, strong) Conversation* conversation;
@property (nonatomic, strong) JSQMessagesBubbleImage* outgoingBubble;
@property (nonatomic, strong) JSQMessagesBubbleImage* incomingBubble;


@end
