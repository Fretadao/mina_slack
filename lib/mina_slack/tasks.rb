require 'json'
require 'net/http'
require 'openssl'

# ## Settings
# Any and all of these settings can be overriden in your `deploy.rb`.

# ### slack_api_token
set :slack_url, ''

# ### slack_channels
# Sets the channels where notifications will be sent to.
set :slack_channels, []

set :slack_username, 'Mina'

set :slack_environment, -> { fetch(:rails_env) }

# ### slack_username
set :slack_deployer, -> { ENV['GIT_AUTHOR_NAME'] || %x[git config user.name].chomp  }

#### slack_link_names
set :slack_link_names, 1

# ### slack_parse
set :slack_parse, 'full'

# ### icon_url
# URL to an image to use as the icon for this message
set :slack_icon_url, ''

# ### icon_emoji
# Sets emoji to use as the icon for this message. Overrides `slack_icon_url`
set :slack_icon_emoji, ':rocket:'

# ## Control Tasks
namespace :slack do

  # ## slack:notify_deploy_started
  desc "Send slack notification about new deploy start"
  task :notify_deploy_started => :environment do
    text = "#{fetch(:slack_deployer)} has started deploying branch #{fetch(:branch)} of #{fetch(:application)} to #{fetch(:slack_environment)}"

    for channel in fetch(:slack_channels)
      send_message(
        channel: channel,
        text:    text
      )
    end
  end

  # ## slack:notify_deploy_finished
  desc "Send slack notification about deploy finish"
  task :notify_deploy_finished => :environment do
    text = "#{fetch(:slack_deployer)} has finished deploying branch #{fetch(:branch)} of #{fetch(:application)} to #{fetch(:slack_environment)}"

    for channel in fetch(:slack_channels)
      send_message(
        channel:     channel,
        text:        text
      )
    end
  end

  def send_message(params = {})
    uri = URI.parse(fetch(:slack_url))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    payload = {
      "parse"       => "full",
      "channel"     => params[:channel],
      "username"    => fetch(:slack_username),
      "text"        => params[:text],
      "icon_emoji"  => fetch(:slack_icon_emoji)
    }

    # Create the post request and setup the form data
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(:payload => payload.to_json)

    # Make the actual request to the API
    http.request(request)
  end
end
