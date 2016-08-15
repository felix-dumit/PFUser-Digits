Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = "PFUser+Digits"
  s.summary = "Easily authenticate Parse Users using Twitter Digits"
  s.version = "1.0.0"
  s.license = { :type => "MIT", :file => "LICENSE" }

  s.author = { "Felix Dumit" => "felix.dumit@gmail.com" }
  s.homepage = "https://github.com/felix-dumit/PFUser+Digits"
  s.source = { :git => "https://github.com/felix-dumit/PFUser+Digits.git", :tag => "#{s.version}"}
  s.dependency 'Bolts/Tasks'
  s.dependency 'Parse'
  s.dependenct 'Digits'
  s.source_files = "PFUser+Digits.{h,m}"
end