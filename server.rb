require 'rubygems'
require 'sinatra'
require 'json'
require 'rack-cache'
require 'net/http'
require 'net/https'
require 'active_support/all'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require 'googleauth'
require 'google/api_client'

use Rack::Cache
set :public_folder, 'public'
set :bind, '0.0.0.0'
use Rack::Logger

def api_client; settings.api_client; end

def logger; settings.logger end

def analytics; settings.analytics; end

def authorization; settings.authorization; end

helpers do
  def logger
    request.logger
  end
end

if ENV['USERNAME'] && ENV['PASSWORD']
  use Rack::Auth::Basic, 'Demo area' do |user, pass|
    user == ENV['USERNAME'] && pass = ENV['PASSWORD']
  end
end

get '/' do
  html = File.read(File.join('public', 'index.html'))
  html.sub!('$PROFILE_ID', JSON.dump(ENV['PROFILE_ID']))
  html.sub!('$DOMAIN_URL', JSON.dump(ENV['GA_WEBSITE_URL']))
  return html
end

get '/realtime' do
  logger.info(params)
  parameters = { 'ids' => "ga:108779703" }.merge(params)
  result = api_client.execute(:api_method => analytics.data.realtime.get, :parameters => parameters)
  logger.info("Return from /realtime:")
  logger.info(result.body)
  result.body
end

get '/historic' do
  #parameters = { 'ids' => "ga:108779703" }.merge(params)
  parameters = params
  result = api_client.execute(:api_method => analytics.data.ga.get, :parameters => parameters)
  logger.info("Return from /historic:")
  logger.info(result.body)
  result.body
end

get '/feed' do
  http = Net::HTTP.new('www.gov.uk', 443)
  http.use_ssl = true
  req = Net::HTTP::Get.new('/government/feed.atom')
  response = http.request(req)
  Hash.from_xml(response.body).to_json
end

get '/setup' do
  File.read(File.join('public', 'setup.html'))
end

configure do
  set :protection, except: [:frame_options]
  client = Google::APIClient.new(:application_name => 'City Analytics Dashboard', :application_version => '1')
  scopes =  ['https://www.googleapis.com/auth/analytics.readonly']
  set :authorization, Google::Auth.get_application_default(scopes)

  client.authorization = authorization
  client.authorization.access_token = '123'

  set :analytics, client.discovered_api('analytics', 'v3')

  set :api_client, client

end
