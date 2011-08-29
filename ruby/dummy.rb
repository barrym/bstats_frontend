require 'rubygems'
require 'bundler/setup'
require 'redis'

puts "Generating dummy data"

redis = Redis.new

@counters = [
  :facebook_user_login_success,
  :facebook_user_login_failed,
  :userpass_user_login_success,
  :userpass_user_login_failed,
  :facebook_user_registration_success,
  :facebook_user_registration_failed,
  :userpass_user_registration_success,
  :userpass_user_registration_failed,
  :pending_purchase_created,
  :purchase_delivered,
  :facebook_purchase_success,
  :facebook_purchase_failed,
  :psms_purchase_success,
  :itunes_purchase_success,
  :itunes_purchase_failed,
  :vote_recorded,
  :mt_sent,
  :mt_sending_error,
  :itunes_request_success,
  :itunes_request_failed
]

while true do
  t = Time.now
  mins = Time.at(t.to_i - t.sec)
  @counters.each do |counter|
    val = 30 + rand(3)
    redis_key = "bstats:counter:per_second:#{counter}:#{t.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 60 * 5

    redis_key = "bstats:counter:per_minute:#{counter}:#{mins.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 3600
  end
  sleep 1
end
