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
    stream.user { |object| process_streaming_object(object) }
  end

  def process_streaming_object(object)
    case object
    when Twitter::Streaming::FriendList
      warn 'Connected to stream'
    when Twitter::Tweet
      update_name(object) if mode.include?(:name)
      update_icon(object) if mode.include?(:icon)
      update_bio(object)  if mode.include?(:bio)
      update_location(object) if mode.include?(:location)
    end
  rescue => e
    warn "#{e.class}: #{e.message}"
  end

  # @param [Twitter::Tweet] tweet
  # @return [void]
  def update_name(tweet)
    return unless match_data = tweet.text.match(/(.+)[\(（][@＠]#{user.screen_name}[\)）]/i)
    new_name = match_data[1]
    updated_profile = twitter.update_profile(name: new_name)
    message = "@#{tweet.user.screen_name} #{updated_profile.name.gsub(/[@＠]/, '@ ')}になりました."
    warn message
    twitter.update(message, in_reply_to_status_id: tweet.id)
  end

  # @param [Twitter::Tweet] tweet
  # @return [void]
  def update_icon(tweet)
    return unless tweet.media? && tweet.text =~ /icon/i
    return unless tweet.text =~ /[@＠]#{user.screen_name}/i

    image = temp_download(tweet.media.first.media_url_https.to_s + ':large')
    twitter.update_profile_image(File.open(image.path))
    message = "@#{tweet.user.screen_name} アイコンを更新しました"
    warn message
    twitter.update_with_media(message, File.open(image.path), in_reply_to_status_id: tweet.id)
  end

  # @param [Twitter::Tweet] tweet
  # @return [void]
  def update_bio(tweet)
    return unless match_data = tweet.text.match(/^[@＠]#{user.screen_name}\s+bio\s*(.+)/i)
    new_bio = match_data[1]
    updated_profile = twitter.update_profile(description: new_bio)
    message = "@#{tweet.user.screen_name} プロフィールを更新しました: " + updated_profile.description.gsub(/[@＠]/, '@ ')
    warn message
    twitter.update(message[0...140], in_reply_to_status_id: tweet.id)
  end

  # @param [Twitter::Tweet] tweet
  # @return [void]
  def update_location(tweet)
    return unless match_data = tweet.text.match(/^[@＠]#{user.screen_name}\s+loc\s*(.+)/i)
    new_location = match_data[1]
    updated_profile = twitter.update_profile(location: new_location)
    message = "@#{tweet.user.screen_name} 場所を更新しました: " + updated_profile.location.gsub(/[@＠]/, '@ ')
    warn message
    twitter.update(message[0...140], in_reply_to_status_id: tweet.id)
  end
  private

  # @param [String] uri
  # @return [Tempfile]
  def temp_download(uri)
    file = Tempfile.open('update-icon')
    file.write(OpenURI.open_uri(uri).read)
    file.close
    file
  end

end
