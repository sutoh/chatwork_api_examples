require 'faraday'
require 'json'
require 'pry-byebug'
require 'dotenv'
Dotenv.load

CHATWORK_TOKEN=ENV['CHATWORK_TOKEN']
ROOM_ID=ENV['ROOM_ID']
TARGET_ID=ENV['TARGET_ID']

conn = Faraday::Connection.new(url: 'https://api.chatwork.com') do |builder|
    builder.use Faraday::Request::UrlEncoded
    builder.use Faraday::Response::Logger
    builder.use Faraday::Adapter::NetHttp
end

res = conn.get do |req|
    req.url "/v1/rooms/#{ROOM_ID}/messages"
    #req.url "/v1/rooms"
    req.headers = { 'X-ChatWorkToken' => CHATWORK_TOKEN }
end

exit if res.body.empty?
json = JSON.parse(res.body)

arr = json.map{|j| next unless j["body"].match("To:#{TARGET_ID}"); j["body"]}.compact

arr.each do |a|
  a.delete!("[To:#{TARGET_ID}]")
  conn.post do |req|
    req.url "/v1/rooms/#{ROOM_ID}/messages"
    req.headers = { 'X-ChatWorkToken' => CHATWORK_TOKEN }
    req.params[:body] = "[To:#{TARGET_ID}] メッセージ来たぞ！返事しろお！ #{a.reverse}"
  end
end

