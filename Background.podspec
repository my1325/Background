Pod::Spec.new do |s|
 s.name             = "Background"
 s.version           = "0.0.1"
 s.summary         = "Background for my's ioser"
 s.homepage        = "https://github.com/my1325/Background.git"
 s.license            = "MIT"
 s.platform          = :ios, "12.0"
 s.authors           = { "mayong" => "1173962595@qq.com" }
 s.source             = { :git => "https://github.com/my1325/Background.git", :tag => "#{s.version}" }
 s.swift_version = '5.1'
 s.source_files = 'Classes/*.swift'
end 