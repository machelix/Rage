require "rubygems"
require "instagram"

Instagram.configure do |config|
  config.client_id ="ecbe626fd1fc411fbde97c976883d75c"
  config.client_secret = "62e542b3ccac4263b1090170a0f0abaf"
end

puts Instagram.media_search("37.7808851","-122.3948632")
