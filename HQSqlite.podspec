Pod::Spec.new do |s|

  s.name         = "HQSqlite"
  s.version      = "2018.12.8"
  s.homepage     = "https://github.com/HonQii/HIComponents"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.summary      = "HIComponents foundation"
  s.description  = <<-DESC
                   HQSqlite component; It's HIComponents SQLite
                   DESC
                   
  s.authors            = { "honqi" => "honqi3514@gmail.com" }
  s.social_media_url   = "https://honqii.github.io"

  s.swift_version = "4.0"
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.module_name  = 'HQSqlite'

  s.source       = { :git => "https://github.com/HonQii/HIComponents.git", :tag => "#{s.name}.#{s.version}" }
  s.source_files = ["HQSqlite/HQSqlite/*.swift",
                     "HQSqlite/HQSqlite/**/*.swift", 
                     "HQSqlite/HQSqlite/*.h"]

end