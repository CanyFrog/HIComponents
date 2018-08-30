Pod::Spec.new do |s|

  s.name         = "HQCache"
  s.version      = "2018.8.30"
  s.homepage     = "https://github.com/HonQii/HIComponents"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "HIComponents foundation"
  s.description  = <<-DESC
                   HQCache component; It's HIComponents Cache
                   DESC
                   
  s.authors            = { "honqi" => "honqi3514@gmail.com" }
  s.social_media_url   = "https://blog.xxx.com"

  s.swift_version = "4.0"
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.module_name  = 'HQCache'

  s.source       = { :git => "https://github.com/HonQii/HIComponents.git", :tag => "#{s.name}.#{s.version}" }
  s.source_files = ["HQCache/HQCache/*.swift",
                     "HQCache/HQCache/**/*.swift", 
                     "HQCache/HQCache/*.h"]
  s.dependency 'HQFoundation'
  s.dependency 'HQSqlite'
end