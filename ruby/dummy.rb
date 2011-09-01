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

@counters.each do |counter|
  redis.sadd "bstats:counters", counter
end

@values = {}

while true do
  t = Time.now
  mins = Time.at(t.to_i - t.sec)
  hours = Time.at(t.to_i - t.min * 60 - t.sec)

  @counters.each do |counter|
    @values[counter] ||= 0

    if @values[counter] >= 50
      weight = 4
    else
      weight = 3
    end

    case rand(weight)
    when 0:
      @values[counter] += 1 + rand(2)
    when 1:
    when 2:
      @values[counter] -= (1 + rand(2))
      if @values[counter] <= 0
        @values[counter] = 0
      end
    end
    val = @values[counter]

    redis_key = "bstats:counter:per_second:#{counter}:#{t.to_i}"
    redis.set redis_key, val
    redis.expire redis_key, 60 * 5

    redis_key = "bstats:counter:per_minute:#{counter}:#{mins.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 3600

    redis_key = "bstats:counter:per_hour:#{counter}:#{hours.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 3600 * 24
  end
  puts t.to_i
  puts @values[:vote_recorded]
  sleep 0.8
end
