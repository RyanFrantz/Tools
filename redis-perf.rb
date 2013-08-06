#!/usr/bin/env ruby

#
# redis-perf.rb - gather some rough timing data for specific Redis commands
#

require 'benchmark'
require 'redis'

# global variables
$server = "myredis.example.com"
$port = 6379
$password = ''

def get_average( values )
    total = 0.0
    values.each do |value|
        total = total + value.to_f
    end
    average = total / values.length
    average = "%.2f" % average
end

def get_percentile( values, percentile )
    multiplier = percentile.to_f / 100
    percentile_value = 0
    numValues = values.length
    values.sort!
    if numValues > 0
        index = (numValues * multiplier).floor.to_i
        percentile_value = values[ index ]
    end
end

def get_max( values )
    values.sort!
    values[-1]
end

def get_min( values )
    values.sort!
    values[0]
end

def do_command( command )

    if $password and !$password.empty?
        puts "PASSWORD"
        redis = Redis.new( :host => $server, :port => $port, :password => $password )
    else
        redis = Redis.new( :host => $server, :port => $port )
    end
    count = 1000
    timings_cpu_user = []
    timings_cpu_sys = []
    timings_cpu_total = []
    timings_real = []

    for i in 1..count do
    
        key = "performance-monitoring#{command}"
        case command
        when "del"
            redis.set( key, i )
            time = Benchmark.measure { redis.del( key ) }
        when "set"
            time = Benchmark.measure { redis.set( key, i ) }
            redis.del( key  )
        # for all sorted set commands, methinks we should create more than single-value sets to really test the performance
        when "zadd"
            member = "zadd#{i}"
            time = Benchmark.measure { redis.zadd( key, i, member ) }
            redis.del( key  )
        when "zrem"
            member = "zrem#{i}"
            redis.zadd( key, i, member )
            time = Benchmark.measure { redis.zrem( key, member ) }
            redis.del( key  )
        when "zrangebyscore"
            member = "zrangebyscore#{i}"
            redis.zadd( key, i, member )
            time = Benchmark.measure{ redis.zrangebyscore( key, i, "+inf" ) }
            redis.del( key )
        when "zremrangebyrank"
            member = "zremrangebyrank#{i}"
            redis.zadd( key, i, member )
            time = Benchmark.measure{ redis.zremrangebyrank( key, "0", i ) }
            redis.del( key )
        end

        cpu_user, cpu_sys, cpu_total, real_time = time.to_s.match(/(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+\(\s+(\d+\.\d+)\)/).captures
        cpu_user_ms = sprintf( "%.2f", cpu_user.to_f * 1000 )
        cpu_sys_ms = sprintf( "%.2f", cpu_sys.to_f * 1000 )
        cpu_total_ms = sprintf( "%.2f", cpu_total.to_f * 1000 )
        real_time_ms = sprintf( "%.2f", real_time.to_f * 1000 )

        timings_cpu_user.push( cpu_user_ms )
        timings_cpu_sys.push( cpu_sys_ms )
        timings_cpu_total.push( cpu_total_ms )
        timings_real.push( real_time_ms )
    
    end

    min = get_min( timings_real )
    max = get_max( timings_real )
    average = get_average( timings_real )
    percentile = get_percentile( timings_real, '95' )
    puts "Min: #{min} ms"
    puts "Max: #{max} ms"
    puts "Average: #{average} ms"
    puts "95th percentile: #{percentile} ms"

end

commands = [ "del", "set", "zadd", "zrem", "zrangebyscore", "zremrangebyrank" ]
commands.each do |command|
    puts "\n#{command.upcase}"
    do_command( command )
end
