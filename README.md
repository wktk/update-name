# update-name

## Installation

    git clone https://git.github.com/wktk/update-name.git
    cd update-name
    heroku create
    git push heroku master
    heroku config:add \
      TWITTER_CONSUMER_KEY=XXX \
      TWITTER_CONSUMER_SECRET=XXX \
      TWITTER_ACCESS_TOKEN=XXX \
      TWITTER_ACCESS_TOKEN_SECRET=XXX
    heroku ps:scale worker=1

## Updating profile

| What | How |
|:-----|----:|
| Name | New name (@user) |
| Description | @user bio New description |
| Location | @user loc New location |
| Icon | @user icon pic.twitter.com/xxx |

### Advanced

Update name and icon: Tweet `New name (@user) icon pic.twitter.com/xxx`

## License

MIT
