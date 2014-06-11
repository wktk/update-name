require 'open-uri'
require 'tempfile'
require 'twitter'

options = {
  consumer_key: ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
  access_token: ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET'],
}

twitter = Twitter::REST::Client.new(options)
stream = Twitter::Streaming::Client.new(options)
user = twitter.current_user

stream.user do |tweet|
  next unless tweet.is_a?(Twitter::Tweet)

  if match_data = tweet.text.match(/(.+)[（\(][@＠]#{user.screen_name}[\)）]/i)
    new_name = match_data[1]
    updated_profile = twitter.update_profile(name: new_name)
    twitter.update(
      "@#{tweet.user.screen_name} #{updated_profile.name.gsub(/[@＠]/, '@ ')}になりました.",
      in_reply_to_status_id: tweet.id
    )
  elsif tweet.text.match(/[@＠]#{user.screen_name}\s+(?:icon|アイコン)/i)
    next unless tweet.media?

    image = Tempfile.new('')
    image.write(open(tweet.media.first.media_url_https.to_s + ':large').read)
    image.close; image.open

    twitter.update_profile_image(image)
    image.close; image.open
    twitter.update_with_media("@#{tweet.user.screen_name} アイコンを更新しました: ", image) rescue nil
  end
end
