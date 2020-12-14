#
# Be sure to run `pod lib lint RSocketSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |rsocket|
  rsocket.name             = 'RSocketSwift'
  rsocket.version          = '0.1.0'
  rsocket.summary          = 'Implementation of the RSocket protocol in Swift'

  rsocket.description      = 'Implementation of the RSocket protocol in Swift'

  rsocket.homepage         = 'https://github.com/rsocket/rsocket-swift'
  rsocket.license          = { :type => 'MIT', :file => 'LICENSE' }
  rsocket.authors          = { "Sumit Nathany" => "sumit.nathany@gmail.com",  "Samer Abdulaziz" => "samer_abdulaziz@intuit.com", "Chengappa Iychodianda" => "chengappa_iychodianda@intuit.com", "Tony Fung" => "tony_fung@intuit.com", "Aastha Gupta" => "Aastha_Gupta@intuit.com", "Prajwal Udupa" => "prajwal_udupa@intuit.com" }
  rsocket.source           = { :git => 'https://github.com/rsocket/rsocket-swift.git', :branch => 'master' }
  rsocket.social_media_url = 'https://app.slack.com/client/T9S425NA2/C01EEDCT866'


  rsocket.ios.deployment_target = '11.0'

  rsocket.default_subspecs = 'Core', 'Transport'

  rsocket.subspec 'Core' do |core|
    core.source_files = 'RSocketSwift/Core/**/*.swift'
    core.dependency 'SwiftNIO', '2.23.0'
  end

  rsocket.subspec 'Transport' do | transport |
	transport.source_files = 'RSocketSwift/Transport/**/*.swift'
	transport.dependency 'SwiftNIO', '2.23.0'
	transport.dependency 'SwiftNIOWebSocket', '2.23.0'
  end

end
