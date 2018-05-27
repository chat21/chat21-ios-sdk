//
//  ChatSynchDelegate.h
//
//  Created by Andrea Sponziello on 10/10/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

@protocol ChatSynchDelegate
@required
- (void)synchEnd;
- (void)synchStart;
@end

