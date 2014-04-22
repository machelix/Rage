require 'json'
require 'date'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  http_basic_authenticate_with name: "admin", password: "alphabetagamma" # except: :index


  def index

  end

  def social

    ## Helper to invoke api access to social media content providers
    twitter_client
    instagram_client
    youtube_client

    api_response = {}
    latitude = params[:lat]
    longitude = params[:lng]
    radius = params[:radius]
    topic = params[:topic]
    start_time = params[:start_ts]
    current_time = params[:current_ts]
    current_ts = Time.now.strftime("%Y-%m-%d")
    current_iso_8601_ts = Time.now.utc.iso8601
    current_iso_8601_ts[11..19]= "00:00:01Z"

    @tweets = twitter_client.search('', { geocode: "#{latitude},#{longitude},#{radius}", result_type: "recent" , count: 100, since: current_ts, include_entities: true } )

    @instagrams =  Instagram.media_search(params[:lat],params[:lng],{ distance: params[:radius] })

    #@youtubes = youtube_client.get('https://gdata.youtube.com/feeds/api/videos?location=' + latitude + ',' + longitude + '&location-radius=' + radius + '&orderby=published&max-results=50&v=2&alt=json&ends-after=' + current_ts)

    @tweets.collect do |tweet|
      #move to next element if tweet is a retweet
      next if tweet.retweeted_status.class != Twitter::NullObject

      api_response.merge!("#{tweet.id}" => { "source" => "twitter", "type" => "tweet", "full_name" => "#{tweet.user.name}", "username" => "#{tweet.user.screen_name}", "content" => "#{tweet.text}", "tags" => (tweet.hashtags.class == Twitter::NullObject) ? nil : "#{tweet.hashtags}",
                                                     "created_at" => "#{tweet.created_at.to_time.to_i}" , "lat" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates[0] , "long" => (tweet.geo.coordinates.class == Twitter::NullObject) ? nil : tweet.geo.coordinates[1]})
    end


    @instagrams.collect do |instagram|

      api_response.merge!("#{instagram.id}" => { "source" => "instagram", "type" => "#{instagram.type}", "full_name" => "#{instagram.user.full_name}", "username" => "#{instagram.user.username}", "content" => "#{instagram.link}", "tags" => "#{instagram.tags}",
                                                 "created_at" => "#{instagram.created_time}" ,  "lat" => "#{instagram.location.latitude}", "long" => "#{instagram.location.longitude}" })

    end

    #if @youtubes.status_code == 200

    #    (JSON.parse(@youtubes.body)['feed']['entry']).collect do |youtube|
          ## Solve empty lat/long problem
    #      if youtube['georss$where'].class == NilClass
    #        lat = nil
    #        long = nil
    #      else
    #        lat = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[0]
    #       long = youtube['georss$where']['gml$Point']['gml$pos']['$t'].split(' ')[1]
    #      end

    #      id = youtube['id']['$t'].class != NilClass ? youtube['id']['$t'] : nil
    #      full_name = youtube['media$group']['media$credit'][0]['yt$display'].class != NilClass ? youtube['media$group']['media$credit'][0]['yt$display'] : nil
    #      user_name = youtube['media$group']['media$credit'][0]['$t'].class != NilClass ? youtube['media$group']['media$credit'][0]['$t'] : nil
    #      content = youtube['content']['src'].class != NilClass ? youtube['content']['src'] : nil
    #      tags = youtube['media$group']['media$category'][0]['label'] != NilClass ? youtube['media$group']['media$category'][0]['label'] : nil
    #      created_ts = (youtube['published']['$t']) != NilClass ? (youtube['published']['$t']) : nil
    #      title = youtube['title']['$t'] != NilClass ? youtube['title']['$t'] : nil

    #      api_response.merge!("#{id}" => { "source" => "youtube", "type" => "video", "full_name" => "#{full_name}" , "username" => "#{user_name}", "content" => "#{content}", "tags" => "#{tags}",
    #                                                        "created_at" => "#{created_ts.to_time.to_i}", "lat" => "#{lat}", "long" => "#{long}", "title" => "#{title}"})

    #    end
    #end

    logger.info api_response.to_json

    respond_to do |format|
      format.html
      format.json { render :json => api_response.to_json }
    end
  end

end
