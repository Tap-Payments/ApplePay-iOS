Pod::Spec.new do |spec|
  spec.name         = "ApplePay-iOS"
  spec.version      = "0.0.4"
  spec.summary      = "A comprehensive Apple Pay integration library for iOS"
  spec.description  = <<-DESC
    ApplePay-iOS is a robust library that simplifies Apple Pay integration in iOS applications.
    It provides secure payment processing, 3D Secure support, and comprehensive callback handling.
  DESC

  spec.homepage     = "https://github.com/Tap-Payments/ApplePay-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Tap Payments" => "support@tap.company" }
  spec.social_media_url = "https://twitter.com/tappayments"

  spec.platform     = :ios
  spec.ios.deployment_target = "16.0"

  spec.source       = { :git => "https://github.com/Tap-Payments/ApplePay-iOS.git", :tag => "#{spec.version}" }

  spec.source_files = "Sources/ApplePay-iOS/**/*.swift"
  spec.resources    = "Sources/ApplePay-iOS/Resources/*.json"

  spec.dependency "SwiftyRSA", ">= 1.0.0"
  spec.dependency "SharedDataModels-iOS", ">= 0.0.1"

  spec.swift_versions = "5.0"

  spec.requires_arc  = true

  spec.frameworks = "UIKit", "Foundation", "PassKit", "WebKit"

  spec.pod_target_xcconfig = {
    "SWIFT_VERSION" => "5.0",
    "ENABLE_BITCODE" => "NO"
  }
end
