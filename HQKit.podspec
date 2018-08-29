Pod::Spec.new do |s|

  s.name         = "HQKit"
  s.version      = "2018.6.16"
  s.homepage     = "https://github.com/HonQii/HIComponents"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "HIComponents foundation"
  s.description  = <<-DESC
                   HQKit component; It's HIComponents UIKit
                   DESC
                   
  s.authors            = { "honqi" => "honqi3514@gmail.com" }
  s.social_media_url   = "https://blog.xxx.com"

  s.swift_version = "4.0"
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.module_name  = 'HQKit'

  s.source       = { :git => "https://github.com/HonQii/HIComponents.git", :tag => "#{s.name}.#{s.version}" }
  s.source_files = ["HQKit/HQKit/*.swift",
                     "HQKit/HQKit/**/*.swift", 
                     "HQKit/HQKit/*.h"]
  s.resources    = 'HQKit/HQKit/Assets.xcassets'
  s.dependency 'HQFoundation'

end