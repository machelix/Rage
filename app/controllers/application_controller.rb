require 'twitter'
require 'google/api_client'
require 'instagram'
require 'json'
require 'date'
#require 'oauth/oauth_util'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  http_basic_authenticate_with name: "admin", password: "alphabetagamma" # except: :index


  def index

  end

  def twitter
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "wBeywo2OBKkqLMJ6nfEWeQ"
      config.consumer_secret     = "bYB8v67jLtbhk14uLvIIVk21I2yE5UR8z4ikTIs0"
      config.access_token        = "53943523-rHqZMPzAbvReVz80t9wsiealmQYxnk70wjzNKjfFN"
      config.access_token_secret = "B7sXvIxpcDdC4FIBebRRJcECp2eIujo6y9X9ui651dd1t"
    end

    #logger.info request.body.read

    #{ geocode: '-22.912214,-43.230182,1mi'}
    tweet_point = "#{params[:lat]}," + "#{params[:lng]}," + "#{params[:radius]}"
    current_ts = Time.now.strftime("%Y-%m-%d")

    @tweets = @client.search('', { geocode: tweet_point, result_type: "recent" , count: 100, since: current_ts} )

    twitter_api_response = {}
    @tweets.collect do |tweet|
      #move to next element if tweet is a retweet
      next if tweet.retweeted_status.class != Twitter::NullObject

      (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates
      twitter_api_response.merge!("#{tweet.id}" => { "name" => "#{tweet.user.name}", "handle" => "#{tweet.user.screen_name}", "text" => "#{tweet.text}",
                          "ts" => "#{tweet.created_at}" , "loc" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates})
    end

    logger.info twitter_api_response.to_json

    respond_to do |format|
      format.html
      format.json { render :json => twitter_api_response.to_json }
    end

  end

  def instagram
    Instagram.configure do |config|
      config.client_id ="ecbe626fd1fc411fbde97c976883d75c"
      config.client_secret = "62e542b3ccac4263b1090170a0f0abaf"
    end
    ## Default Radius is 1000m(1km) : maximum 5000m
    search_point = "#{params[:lat]}," + "#{params[:lng]}," + "#{params[:radius]}"
    additional_search_options = { distance: params[:radius] }

    instagram_api_response = {}
    #instagram_api_response = Instagram.media_search("37.7808851","-122.3948632")
    # Get a list of media close to a given latitude and longitude
    @instagrams =  Instagram.media_search(params[:lat],params[:lng],additional_search_options)


    @instagrams.collect do |instagram|

      instagram_api_response.merge!("#{instagram.id}" => { "instagram_url" => "#{instagram.link}", "username" => "#{instagram.user.username}", "user_full_name" => "#{instagram.user.full_name}", "instagram_type" => "#{instagram.type}",
                                                     "ts" => "#{instagram.created_time}" , "tags" => "#{instagram.tags}", "lat" => "#{instagram.location.latitude}", "long" => "#{instagram.location.longitude}" })

    end

    logger.info instagram_api_response.to_json

    respond_to do |format|
      format.html
      format.json { render :json => instagram_api_response.to_json }
    end
  end


  def youtube
    @client = Google::APIClient.new(
        :application_name => 'Rage Ruby application',
        :application_version => '1.0.0'
    )

    # An OAuth 2 access scope that allows for full read/write access.
    youtube_readonly_scope = 'https://www.googleapis.com/auth/youtube'
    youtube_api_service_name = 'youtube'
    youtube_api_version = 'v3'

    @youtube = @client.discovered_api(youtube_api_service_name, youtube_api_version)

    # Initialize OAuth 2.0 client
    @client.authorization.client_id = '825232626336-ktufk4ivq970ls2h06v2h2jgui4hafbv.apps.googleusercontent.com'
    @client.authorization.client_secret = 'QEXEHnvzP9jrWj7UAIdHJ1bN'
    @client.authorization.redirect_uri = 'https://localhost/oauth2callback'
    @client.authorization.scope = youtube_readonly_scope
    @client.authorization.refresh_token = true

    # Request authorization
    redirect_uri = @client.authorization.authorization_uri

    # Wait for authorization code then exchange for token
    @client.authorization.code = params[:code]
    @client.authorization.fetch_access_token!

    #auth_util = CommandLineOAuthHelper.new(youtube_readonly_scope)
    #@client.authorization = auth_util.authorize()

    # Make an API call
    puts @result = @client.execute(
        :api_method => @youtube.activities.list,
        :parameters => {      :part => 'snippet',
                              :maxResults => 50
        }
    )
    unless result.response.status == 401
      p "#{JSON.parse(result.body)}"
    else
      redirect "/oauth2authorize"
    end
  end
end
