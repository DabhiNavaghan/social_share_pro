Pod::Spec.new do |s|
  s.name             = 'social_share_pro'
  s.version          = '1.0.0'
  s.summary          = 'Share to Instagram Stories, Facebook Stories, WhatsApp Status and Instagram Direct from Flutter.'
  s.description      = <<-DESC
Flutter plugin that shares image stickers with background images or gradients to Instagram Stories
and Facebook Stories, posts images to WhatsApp Status, opens Instagram Direct with text and saves
images to the photo library.
                       DESC
  s.homepage         = 'https://github.com/DabhiNavaghan/social_share_pro'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Navaghan Dabhi' => 'https://github.com/DabhiNavaghan' }
  s.source           = { :path => '.' }
  s.source_files     = 'social_share_pro/Sources/social_share_pro/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
  s.resource_bundles = { 'social_share_pro_privacy' => ['social_share_pro/Sources/social_share_pro/PrivacyInfo.xcprivacy'] }
end
