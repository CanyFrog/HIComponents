Pod::Spec.new do |s|

  s.name         = "HQFoundation"
  s.version      = "2018.12.8"
  s.homepage     = "https://github.com/HonQii/HIComponents"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "HIComponents foundation"
  s.description  = <<-DESC
                   HQFoundation component; It's HIComponents foundation
                   DESC
                   
  s.authors            = { "honqi" => "honqi3514@gmail.com" }
  s.social_media_url   = "https://blog.xxx.com"

  s.swift_version = "4.0"
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.module_name  = 'HQFoundation'

  s.source       = { :git => "https://github.com/HonQii/HIComponents.git", :tag => "#{s.name}.#{s.version}" }
  s.source_files = ["HQFoundation/HQFoundation/*.swift",
                     "HQFoundation/HQFoundation/**/*.swift", 
                     "HQFoundation/HQFoundation/*.h"]

end