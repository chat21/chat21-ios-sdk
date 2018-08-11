Chat21 is the core of the open source live chat platform [Tiledesk.com](http://www.tiledesk.com).

# Chat21 SDK for iOS

To install and configure the SDK follow this tutorial:

[Chat21 iOS Get Started tutorial](http://www.chat21.org/docs/ios/get-started/)

# Guide




Project setup
	Firebase Lib install
	Chat21 Lib install

Chat initialization

==
[FIRApp configure];
[ChatManager configure];
==

Chat authentication

==
[ChatAuth authWithEmail:email password:password completion:^(ChatUser *user, NSError *error)
==

Initialize with a specific user

==
ChatManager *chatm = [ChatManager getInstance];
ChatUser *user; // you got this user from a previously authentication session (ex. [Chat authWithEmail])
// eventually complete user with data 
user.firstname = @"John";
user.lastname = @"Nash";
[chatm startWithUser:user];
==

# UI

Get the conversations view

[[ChatUIManager getInstance] getConversationsViewController]

// all other views... (from chat manager)



