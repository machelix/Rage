require 'twitter'
require 'google/api_client'
require 'instagram'


module ApplicationHelper

  def twitter_client()
    # setup social media curation clients
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "wBeywo2OBKkqLMJ6nfEWeQ"
      config.consumer_secret     = "bYB8v67jLtbhk14uLvIIVk21I2yE5UR8z4ikTIs0"
      config.access_token        = "53943523-rHqZMPzAbvReVz80t9wsiealmQYxnk70wjzNKjfFN"
      config.access_token_secret = "B7sXvIxpcDdC4FIBebRRJcECp2eIujo6y9X9ui651dd1t"
    end

    return twitter_client
  end

  def instagram_client()
    Instagram.configure do |config|
      config.client_id ="ecbe626fd1fc411fbde97c976883d75c"
      config.client_secret = "62e542b3ccac4263b1090170a0f0abaf"
    end
    return Instagram
  end

  def youtube_client()
    youtube_client = GData::Client::YouTube.new
    youtube_client.developer_key = 'AI39si4jMJxFLi6Euv3w3C1ggAF4uK9DgJtx_1i7XnDkWn7HkZ71ygI8M3kmLB-aOYU9bQNRkp3R8hpwuI7OUCioYQyW-K5oYg'
    return youtube_client
  end
end
