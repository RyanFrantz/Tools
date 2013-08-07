#!/usr/bin/env ruby

#
# redis-perf.rb - gather some rough timing data for specific Redis commands
#

require 'benchmark'
require 'redis'
require 'choice'

# global variables
$server = "myredis.example.com"
$port = 6379
$password = ''

Choice.options do
    header ""
    header "Executes several Redis operations and generates some performance metrics based on the results."
    header "Optionally, output in CSV format."
    header ""
    header "Options:"

    option :csv, :required => false do
        short "-c"
        long "--csv"
        desc "Generate CSV output"
    end

    option :set_size, :required => false do
        short "-s"
        long "--sorted-set-size=SET_SIZE"
        desc "Set the number of members to pre-fill sorted sets before running commands on them (default: 50)"
        default 50
    end

    option :tests, :required => false do
        short "-t"
        long "--tests=*TESTS"
        desc "Define which tests to run (default: del, set, zadd, zrem, zrangebyscore, zremrangebyrank)"
        valid %w[ del set zadd zrem zrangebyscore zremrangebyrank ]
    end

    footer ""
    footer "Examples:"
    footer ""
    footer "Output results in CSV format"
    footer "$ #{File.basename( $0 )} -c"
    footer "$ #{File.basename( $0 )} --csv"
    footer ""
    footer "Set the pre-fill size of sorted sets to 5"
    footer "$ #{File.basename( $0 )} -s 5"
    footer "$ #{File.basename( $0 )} --sorted-set-size=5"
    footer ""
    footer "Test the DEL, SET, and ZADD Redis commands"
    footer "$ #{File.basename( $0 )} -t del set zadd"
    footer "$ #{File.basename( $0 )} --tests=del set zadd"
    footer ""
    footer "Test ZADD and ZRANGEBYSCORE, pre-filling by 50 (default), and output as CSV"
    footer "$ #{File.basename( $0 )} -c -t zadd zrangebyscore"
    footer ""
end

def gen_random_text
    # return 32 ASCII characters (mostly alphabetical characters with some punctuation)
    text = (0...32).map{(65+rand(57)).chr}.join
end

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

def do_command( command, prefill_max )

    if $password and !$password.empty?
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
    
        # generate a random key to fight the effect of Redis caching
        key = "perfmon-#{command}-#{gen_random_text}-#{i}"
        case command
        when "del"
            redis.set( key, i )
            time = Benchmark.measure { redis.del( key ) }
        when "set"
            time = Benchmark.measure { redis.set( key, i ) }
            redis.del( key  )
        when "zadd"
            for j in 1..prefill_max do
                redis.zadd( key, j, "#{gen_random_text}" )
            end
            member = "zadd#{prefill_max + i}"
            time = Benchmark.measure { redis.zadd( key, i, member ) }
            redis.del( key  )
        when "zrem"
            for j in 1..prefill_max do
                redis.zadd( key, j, "#{gen_random_text}" )
            end
            member = "zrem#{prefill_max + i}"
            redis.zadd( key, i, member )
            time = Benchmark.measure { redis.zrem( key, member ) }
            redis.del( key  )
        when "zrangebyscore"
            for j in 1..prefill_max do
                redis.zadd( key, j, "#{gen_random_text}" )
            end
            member = "zrangebyscore#{prefill_max + i}"
            redis.zadd( key, i, member )
            time = Benchmark.measure{ redis.zrangebyscore( key, i, "+inf" ) }
            redis.del( key )
        when "zremrangebyrank"
            for j in 1..prefill_max do
                redis.zadd( key, j, "#{gen_random_text}" )
            end
            member = "zremrangebyrank#{prefill_max + i}"
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

    command = "#{command} (Pre-fill=#{prefill_max})" if command =~ /^z/
    if Choice.choices[:csv]
        puts "#{command.upcase},#{min},#{max},#{average},#{percentile}"
    else
        puts "\n#{command.upcase}"
        puts "Min: #{min} ms"
        puts "Max: #{max} ms"
        puts "Average: #{average} ms"
        puts "95th percentile: #{percentile} ms"
    end

end

if Choice.choices[:tests]
    commands = Choice.choices[:tests]
else
    commands = [ "del", "set", "zadd", "zrem", "zrangebyscore", "zremrangebyrank" ]
end

prefill_max = Choice.choices[:set_size].to_i

if Choice.choices[:csv]
    puts "Command,Min (ms), Max (ms), Average (ms), 95th Percentile (ms)"
end

commands.each do |command|
    do_command( command, prefill_max )
end
