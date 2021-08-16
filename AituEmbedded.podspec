Pod::Spec.new do |spec|
  spec.name             = 'AituEmbedded'
  spec.version          = '1.1.1'
  spec.summary          = 'Aitu inside Kundelik'
  spec.homepage         = 'https://github.com/btsdigital/AituEmbeddedIOS'
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }
  spec.authors      = {
     'Artem Mylnikov (ajjnix)' => 'ajjnix@gmail.com',
  }
  spec.source           = { :git => 'https://github.com/btsdigital/AituEmbeddedIOS.git', :tag => spec.version }

  spec.source_files = 'AituEmbedded/**/*.swift'
  spec.ios.deployment_target = '12.0'
  spec.swift_versions = ['5.1', '5.2']
end