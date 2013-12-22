require 'twitter'
require 'google/api_client'
require 'json'
#require 'oauth/oauth_util'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  def index
    #@radius = 200
    #gon.token = @client.token.to_s
    #puts @client.search('AAP').to_hash.inspect
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
    tweet_point = "#{params[:lat]}," + "#{params[:lng]}," + "1mi"

    @tweets = @client.search('', { geocode: tweet_point, result_type: "recent" , count: 50} )

    api_response = {}
    @tweets.collect do |tweet|
      (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates
      api_response.merge!("#{tweet.id}" => { "name" => "#{tweet.user.screen_name}", "text" => "#{tweet.text}",
                          "ts" => "#{tweet.created_at}" , "loc" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates})
    end

    logger.info api_response.to_json

    respond_to do |format|
      format.html
      format.json { render :json => api_response.to_json }
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
    @client.authorization.client_id = '825232626336-jcicc79mkn35kvj1arpbc1ce5ogmsukk.apps.googleusercontent.com'
    @client.authorization.client_secret = 'Pkqih1-xIhGP1C7AFXiur1uR'
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
    @result = @client.execute(
        :api_method => @youtube.activities.list,
        :parameters => {      :part => 'snippet',
                              :maxResults => 50
        }
    )
  end
end
