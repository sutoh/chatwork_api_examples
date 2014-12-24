require 'faraday'
require 'json'
require 'pry-byebug'
require 'dotenv'
Dotenv.load

CHATWORK_TOKEN=ENV['CHATWORK_TOKEN']
ROOM_ID=ENV['TS1_ROOM_ID']

conn = Faraday::Connection.new(url: 'https://api.chatwork.com') do |builder|
    builder.use Faraday::Request::UrlEncoded
    builder.use Faraday::Response::Logger
    builder.use Faraday::Adapter::NetHttp
end

res = conn.get do |req|
    req.url "/v1/rooms/#{ROOM_ID}/messages?force=0"
    req.headers = { 'X-ChatWorkToken' => CHATWORK_TOKEN }
end

exit if res.body.empty?
json = JSON.parse(res.body)
arr = json.map{|j| next unless j["body"].match("@all"); j["body"]}.compact

res_member = conn.get do |req|
  req.url "/v1/rooms/#{ROOM_ID}/members"
  req.headers = { 'X-ChatWorkToken' => CHATWORK_TOKEN } 
end
block_user = [277209]
member_data = JSON.parse(res_member.body)
members = member_data.map{|j| next if block_user.include?(j["account_id"]); { :id => j["account_id"], :name => j["name"] } }.compact

arr.each do |a|
  conn.post do |req|
    req.url "/v1/rooms/#{ROOM_ID}/messages"
    req.headers = { 'X-ChatWorkToken' => CHATWORK_TOKEN }
    post_members = []
    members.each_with_object([]) do |key|
      post_members << "[To:#{key.id}] #{key.name}"
    end
    req.params[:body] = "#{post_members.join('\n')} #{a}"
  end
end

