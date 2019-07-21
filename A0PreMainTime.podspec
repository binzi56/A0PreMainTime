#
# Be sure to run `pod lib lint A0PreMainTime.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'A0PreMainTime'
  s.version          = '0.2.3'
  s.summary          = 'accurately measure the pre-main stage'
  s.description      = <<-DESC
To accurately measure the pre-main phase time and better time measurement.
                       DESC
  s.homepage         = 'https://github.com/binzi56/A0PreMainTime'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'firejadebin' => 'firejadebin@gmail.com' }
  s.source           = { :git => 'https://github.com/binzi56/A0PreMainTime.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.subspec 'PreMainTime' do |sPreMainTime|
      sPreMainTime.vendored_frameworks = 'A0PreMainTime/Framework/*.Framework'
  end

  s.subspec 'TimeMonitor' do |sTimeMonitor|
      sTimeMonitor.source_files = 'A0PreMainTime/TimeMonitor/*.{h,m}'
  end
end
