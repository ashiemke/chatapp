//
//  Conversation.h
//  chat
//
//  Created by Adam Shiemke on 11/6/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "ParseModel.h"

@interface Conversation : ParseModel

// Backed by parse
@property (nonatomic, strong) NSArray *participants;

// Not backed by parse
@property (nonatomic, strong) NSMutableArray *messages;

@end
