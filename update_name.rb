# -*- coding: utf-8 -*-
require 'open-uri'
require 'tempfile'
require 'twitter'

class UpdateName

  attr_reader :mode, :stream, :twitter, :user

  def initialize(options)
    @mode = []
    @stream = Twitter::Streaming::Client.new(options)
    @twitter = Twitter::REST::Client.new(options)
    @user = twitter.current_user
  end

  def run(*mode)
    @mode = mode
    stream.user do |object|
      process_streaming_object(object)
    end
  end

  def process_streaming_object(object)
    case object
    when Twitter::Tweet
      update_name(object)
      update_icon(object)
    end
  rescue => e
    warn "#{e.class}: #{e.message}"
  end

  def update_name(tweet)
    return unless mode.include?(:name)
    return unless match_data = object.text.match(/(.+)[\(（][@＠]#{user.screen_name}[\)）]/i)
    new_name = match_data[1]
    updated_profile = twitter.update_profile(name: new_name)
    message = "@#{tweet.user.screen_name} #{updated_profile.name.gsub(/[@＠]/, '@ ')}になりました.",
    warn message
    twitter.update(message, in_reply_to_status_id: tweet.id)
  end

  def update_icon(tweet)
    return unless mode.include?(:icon) && tweet.media?
    return unless tweet.text =~ /[@＠]#{user.screen_name}\s+(?:icon|アイコン)/i

    image = Tempfile.new(['update-icon', tweet.media.first.media_url_https.extname])
    image.write(open(tweet.media.first.media_url_https.to_s + ':large').read)
    image.close

    twitter.update_profile_image(File.open(image.path))
    message = "@#{tweet.user.screen_name} アイコンを更新しました"
    warn message
    twitter.update_with_media(message, File.open(image.path))
    image.close!
  end

end
