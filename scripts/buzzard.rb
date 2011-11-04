require 'rubygems'
require 'bundler/setup'
require 'redis'

puts "Generating dummy data"

redis = Redis.new
redis.sadd "bstats:namespaces", "buzzard"

@buzzard_events = [
  :failed_to_send_mt,
  :mt_sending_error,
  :dr_request_received,
  :mo_request_received,
  :mt_sent
]

@operators = [
  :uk_o2,
  :uk_orange,
  :uk_vodafone,
  :uk_tmobile,
  :uk_three
  # :ie_three,
  # :ie_meteor,
  # :ie_vodafone,
  # :ie_o2,
  # :ipx,
  # :reach_data
]

@counters = []
@buzzard_events.each do |event|
   @operators.each do |operator|
      @counters << "#{event}_#{operator}"
   end
end

@counters.each do |counter|
  redis.sadd "bstats:buzzard:counters", counter
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
    when 0
      @values[counter] += 1 + rand(2)
    when 1
    when 2
      @values[counter] -= (1 + rand(2))
      if @values[counter] <= 0
        @values[counter] = 0
      end
    end
    val = @values[counter]

    redis_key = "bstats:buzzard:counter:per_second:#{counter}:#{t.to_i}"
    redis.set redis_key, val
    redis.expire redis_key, 60 * 5

    redis_key = "bstats:buzzard:counter:per_minute:#{counter}:#{mins.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 3600

    redis_key = "bstats:buzzard:counter:per_hour:#{counter}:#{hours.to_i}"
    redis.incrby redis_key, val
    redis.expire redis_key, 3600 * 24
  end
  sleep 0.8
end
