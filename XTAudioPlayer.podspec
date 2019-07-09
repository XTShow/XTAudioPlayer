
Pod::Spec.new do |s|

  s.name         = "XTAudioPlayer"
  s.version      = "0.0.2"
  s.summary      = "Playback an audio/video while caching the media file."
  s.homepage     = "https://github.com/XTShow"
  s.license      = "MIT"
  s.author       = { "XTShow" => "447800853@qq.com" }
  
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/XTShow/XTAudioPlayer.git", :tag => s.version }
  s.source_files  = "XTAudioPlayer/*.{h,m}"

  s.frameworks = "AVKit", "AVFoundation", "UIKit"

end
