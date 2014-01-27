require 'twitter'
require 'google/api_client'
require 'instagram'
require 'json'
require 'date'
require 'gdata'
#require 'oauth/oauth_util'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  http_basic_authenticate_with name: "admin", password: "alphabetagamma" # except: :index


  def index

  end

  def social
    # setup social media curation clients
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "wBeywo2OBKkqLMJ6nfEWeQ"
      config.consumer_secret     = "bYB8v67jLtbhk14uLvIIVk21I2yE5UR8z4ikTIs0"
      config.access_token        = "53943523-rHqZMPzAbvReVz80t9wsiealmQYxnk70wjzNKjfFN"
      config.access_token_secret = "B7sXvIxpcDdC4FIBebRRJcECp2eIujo6y9X9ui651dd1t"
    end

    Instagram.configure do |config|
      config.client_id ="ecbe626fd1fc411fbde97c976883d75c"
      config.client_secret = "62e542b3ccac4263b1090170a0f0abaf"
    end

    youtube_client = GData::Client::YouTube.new
    youtube_client.developer_key = 'AI39si4jMJxFLi6Euv3w3C1ggAF4uK9DgJtx_1i7XnDkWn7HkZ71ygI8M3kmLB-aOYU9bQNRkp3R8hpwuI7OUCioYQyW-K5oYg'

    api_response = {}
    latitude = params[:lat]
    longitude = params[:lng]
    radius = params[:radius]
    topic = params[:topic]
    start_time = params[:start_ts]
    current_time = params[:current_ts]
    current_ts = Time.now.strftime("%Y-%m-%d")
    #current_ts = '2014-01-18'
    current_iso_8601_ts = Time.now.utc.iso8601
    current_iso_8601_ts[11..19]= "00:00:01Z"

    @tweets = twitter_client.search('', { geocode: "#{latitude},#{longitude},#{radius}", result_type: "recent" , count: 100, since: current_ts, include_entities: true } )

    @instagrams =  Instagram.media_search(params[:lat],params[:lng],{ distance: params[:radius] })

    @youtubes = youtube_client.get('https://gdata.youtube.com/feeds/api/videos?location=' + latitude + ',' + longitude + '&location-radius=' + radius + '&orderby=published&max-results=50&v=2&alt=json&ends-after=' + current_ts)

    @tweets.collect do |tweet|
      #move to next element if tweet is a retweet
      next if tweet.retweeted_status.class != Twitter::NullObject

      #(tweet.hashtags.class == Twitter::NullObject) ? nil : tweet.hashtags.each {|hashtag| puts hashtag.text}
      #(tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates
      api_response.merge!("#{tweet.id}" => { "source" => "twitter", "type" => "tweet", "full_name" => "#{tweet.user.name}", "username" => "#{tweet.user.screen_name}", "content" => "#{tweet.text}", "tags" => (tweet.hashtags.class == Twitter::NullObject) ? nil : "#{tweet.hashtags}",
                                                     "created_at" => "#{tweet.created_at.to_time.to_i}" , "lat" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates[0] , "long" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates[1]})
    end


    @instagrams.collect do |instagram|

      api_response.merge!("#{instagram.id}" => { "source" => "instagram", "type" => "#{instagram.type}", "full_name" => "#{instagram.user.full_name}", "username" => "#{instagram.user.username}", "content" => "#{instagram.link}", "tags" => "#{instagram.tags}",
                                                 "created_at" => "#{instagram.created_time}" ,  "lat" => "#{instagram.location.latitude}", "long" => "#{instagram.location.longitude}" })

    end

    if @youtubes.status_code == 200

        (JSON.parse(@youtubes.body)['feed']['entry']).collect do |youtube|
          ## Solve empty lat/long problem
          if youtube['georss$where'].class == NilClass
            lat = nil
            long = nil
          else
            lat = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[0]
            long = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[1]
          end

          id = youtube['id']['$t'].class != NilClass ? youtube['id']['$t'] : nil
          full_name = youtube['media$group']['media$credit'][0]['yt$display'].class != NilClass ? youtube['media$group']['media$credit'][0]['yt$display'] : nil
          user_name = youtube['media$group']['media$credit'][0]['$t'].class != NilClass ? youtube['media$group']['media$credit'][0]['$t'] : nil
          content = youtube['content']['src'].class != NilClass ? youtube['content']['src'] : nil
          tags = youtube['media$group']['media$category'][0]['label'] != NilClass ? youtube['media$group']['media$category'][0]['label'] : nil
          created_ts = (youtube['published']['$t']) != NilClass ? (youtube['published']['$t']) : nil
          title = youtube['title']['$t'] != NilClass ? youtube['title']['$t'] : nil

          api_response.merge!("#{id}" => { "source" => "youtube", "type" => "video", "full_name" => "#{full_name}" , "username" => "#{user_name}", "content" => "#{content}", "tags" => "#{tags}",
                                                            "created_at" => "#{created_ts.to_time.to_i}", "lat" => "#{lat}", "long" => "#{long}", "title" => "#{title}"})

        end
    end

    logger.info api_response.to_json

    respond_to do |format|
      format.html
      format.json { render :json => api_response.to_json }
    end
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
     @client = GData::Client::YouTube.new
     @client.developer_key = 'AI39si4jMJxFLi6Euv3w3C1ggAF4uK9DgJtx_1i7XnDkWn7HkZ71ygI8M3kmLB-aOYU9bQNRkp3R8hpwuI7OUCioYQyW-K5oYg'
     @results = @client.get('https://gdata.youtube.com/feeds/api/videos?location=37.42307,-122.08427&location-radius=100km&orderby=published&max-results=10&v=2&alt=json')

     api_response = {}
     logger.info (JSON.parse(@results.body)['feed']['entry']).to_json
     (JSON.parse(@results.body)['feed']['entry']).collect do |youtube|

       #logger.info youtube['id']['$t']
       #logger.info youtube['title']['$t']
       #logger.info youtube['media$group']['media$credit'][0]['yt$display']
       #logger.info youtube['media$group']['media$credit'][0]['$t']
       #logger.info youtube['content']['src']
       #logger.info youtube['media$group']['media$category'][0]['label']
       #logger.info youtube['published']['$t']
       #logger.info youtube['georss$where']['gml$Point']['gml$pos']['$t']

       if youtube['georss$where'].class == NilClass
         lat = nil
         long = nil
       else
         lat = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[0]
         long = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[1]
       end
       api_response.merge!("#{youtube['id']['$t']}" => { "source" => "youtube", "type" => "video", "full_name" => "#{youtube['media$group']['media$credit'][0]['yt$display']}" , "username" => "#{youtube['media$group']['media$credit'][0]['$t']}", "content" => "#{youtube['content']['src']}", "tags" => "#{youtube['media$group']['media$category'][0]['label']}",
                                                "created_at" => "#{youtube['published']['$t']}", "lat" => "#{lat}", "long" => "#{long}", "title" => "#{youtube['title']['$t']}"})
     end

     logger.info api_response.to_json
     respond_to do |format|
       format.html
       format.json { render :json => @results.to_json }
     end
  end

  def youtube1
    @client = Google::APIClient.new(
        :application_name => 'Rage Ruby application',
        :application_version => '1.0.0',
        #:key => 'AIzaSyCFfsKnB4D-tWvTK0Y3DXAYwnlkbdg8CWg',
        :authorization => nil
    )

    # An OAuth 2 access scope that allows for full read/write access.
    youtube_readonly_scope = 'https://www.googleapis.com/auth/youtube'
    api_name = 'youtube'
    api_version = 'v2.0'

    @api = @client.discovered_api(api_name, api_version)

    # Initialize OAuth 2.0 client
    #@client.authorization.client_id = '825232626336-ktufk4ivq970ls2h06v2h2jgui4hafbv.apps.googleusercontent.com'
    #@client.authorization.client_secret = 'QEXEHnvzP9jrWj7UAIdHJ1bN'
    #@client.authorization.redirect_uri = 'https://localhost/oauth2callback'
    #@client.authorization.scope = youtube_readonly_scope
    #@client.authorization.refresh_token = true

    # Request authorization
    #redirect_uri = @client.authorization.authorization_uri

    # Wait for authorization code then exchange for token
    #@client.authorization.code = params[:code]
    #@client.authorization.fetch_access_token!

    #auth_util = CommandLineOAuthHelper.new(youtube_readonly_scope)
    #@client.authorization = auth_util.authorize()

    @result = @client.execute(
        :api_method => @api.files.list,
        :parameters => {
                              :maxResults => 50,
                              :projection => 'BASIC'
        }
    )

    # Make an API call
    #@result = @client.execute(
    #    :api_method => @api.videos.list,
    #    :parameters => {      :part => 'id,snippet,recordingDetails',
    #                          :chart => 'mostPopular',
    #                          :maxResults => 50,
    #                          :regionCode => 'DE'
    #    }
    #)
    #unless result.response.status == 401
    #  p "#{JSON.parse(result.body)}"
    #else
    #  redirect "/oauth2authorize"
    #end

    logger.info @result.body

    respond_to do |format|
      format.html
      format.json { render :json => @result.to_json }
    end
  end
end
