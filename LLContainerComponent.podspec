
Pod::Spec.new do |s|

  s.name         = "LLContainerComponent"
  s.version      = "1.0.4"
  s.summary      = "列表框架"
  s.description  = "列表框架"
  s.license      = {:type => 'MIT', :file => 'LICENSE'}
  s.homepage     = "https://github.com/lifuqing/LLContainerComponent"
  s.author       = { "lifuqing" => "lfqing@vip.qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/lifuqing/LLContainerComponent.git", :tag => s.name.to_s + "-" + s.version.to_s}
  s.source_files = "#{s.name}/Classes/**/*.{h,m,mm}"
  

  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'AVFoundation'

  s.dependency 'LLHttpEngine'
  s.dependency 'MJRefresh'
  s.dependency 'MBProgressHUD'
  
end
