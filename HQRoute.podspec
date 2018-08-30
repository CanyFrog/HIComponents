Pod::Spec.new do |s|

  s.name         = "HQRoute"
  s.version      = "2018.8.30"
  s.homepage     = "https://github.com/HonQii/HIComponents"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "HIComponents foundation"
  s.description  = <<-DESC
                   HQRoute component; It's HIComponents Router
                   DESC
                   
  s.authors            = { "honqi" => "honqi3514@gmail.com" }
  s.social_media_url   = "https://blog.xxx.com"

  s.swift_version = "4.0"
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.module_name  = 'HQRoute'

  s.source       = { :git => "https://github.com/HonQii/HIComponents.git", :tag => "#{s.name}.#{s.version}" }
  s.source_files = ["HQRoute/HQRoute/*.swift",
                     "HQRoute/HQRoute/**/*.swift", 
                     "HQRoute/HQRoute/*.h"]

end