Pod::Spec.new do |s|
  s.name             = 'CaRetailBoosterSDK'
  s.version          = '1.4.2'
  s.summary          = 'Retail Booster SDK'
  s.homepage         = 'https://github.com/CyberAgentAI/caretailbooster-sdk-ios'
  s.license          = { :type => 'Proprietary', :file => 'LICENSE', :text => 'All rights reserved.' }
  s.author           = 'CyberAgent, Inc.'
  s.source           = { :git => 'https://github.com/CyberAgentAI/caretailbooster-sdk-ios.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/CaRetailBoosterSDK/**/*.swift'
  s.exclude_files = 'Sources/CaRetailBoosterSDK/Preview Content/**/*'
  s.resources = ['Sources/CaRetailBoosterSDK/PrivacyInfo.xcprivacy']
end 
