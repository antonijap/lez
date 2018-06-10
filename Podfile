# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'Lez' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Lez
  pod 'SnapKit', '~> 4.0.0'
  pod 'Jelly'
  pod 'GooglePlacesRow'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'FacebookShare'
  pod 'PromisesSwift', '~> 1.0'
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Alertift', '~> 3.0'
  pod 'JGProgressHUD'
  pod 'SwiftDate', '~> 4.0'
  pod 'TwitterKit'
  pod 'SwiftyStoreKit'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'Alamofire', '~> 4.7'
  pod 'AlamofireImage', '~> 3.3'
  pod 'SDWebImage', '~> 4.0'
  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git'
  pod 'ImageSlideshow', '~> 1.5'
  pod 'RangeSeekSlider', :git => 'https://github.com/WorldDownTown/RangeSeekSlider.git', :branch => 'swift_4'
  pod 'PushNotifications'
  pod 'PusherSwift'
  pod 'Toast-Swift', '~> 3.0.1'
  pod 'GBDeviceInfo'
  pod 'Fabric', '~> 1.7.7'
  pod 'Crashlytics', '~> 3.10.2'
  
  target 'LezTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'LezUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          if target.name == 'Eureka'
              target.build_configurations.each do |config|
                  config.build_settings['SWIFT_VERSION'] = '4.1'
              end
          end
      end
  end

end
