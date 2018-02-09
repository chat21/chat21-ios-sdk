#
# Be sure to run `pod lib lint Chat21SDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Chat21SDK'
  s.version          = '0.2.1'
  s.summary          = 'Chat21 SDK for iOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Chat21 SDK for iOS. Embed a chat into your own iOS App with few lines of code.
                       DESC

  s.homepage         = 'http://www.chat21.org'
  # s.screenshots     = 'https://user-images.githubusercontent.com/32564846/34433123-4873eca4-ec7d-11e7-8a80-4ad54def8653.png', 'https://user-images.githubusercontent.com/32564846/34433695-39e04468-ec81-11e7-84a3-920e9098a2a1.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Andrea Sponziello' => 'andrea.sponziello@frontiere21.it' }
  s.source           = { :git => 'https://github.com/chat21/chat21-ios-sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.source_files = 'Chat21SDK/**/*.{h,m}'
  
  # s.resource_bundles = {
  #   'Chat21SDK' => ['Chat21SDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Messaging'
  s.dependency 'Firebase/Storage'
end
