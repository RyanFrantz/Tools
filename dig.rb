#!/usr/bin/ruby

#
# dig.rb - A dig-like (lite?) resolver.
#

require 'resolv'

class Resolver

  def initialize
      # nothing to see here, move along
  end

  def getA(host)
    Resolv::DNS.open do |dns|
      # Perform CNAME lookups for this host before an A lookup.
      # Recurse no more than 4 times for CNAME lookups.
      recurse_max = 4
      recurse_level = 1
      while recurse_level <= recurse_max
        cname_host = getCNAME(host)
        if !cname_host.empty?
          host = cname_host
        else
          break
        end
        recurse_level += 1
      end
      rez = dns.getresources host, Resolv::DNS::Resource::IN::A
      rez.map { |r|
        printf("%-32s%-6s IN %-7s %-32s\n", host, r.ttl, 'A', r.address)
      }
    end
  end

  def getCNAME(host)
    Resolv::DNS.open do |dns|
      cname = dns.getresources host, Resolv::DNS::Resource::IN::CNAME
      if !cname.empty?
        cname.map { |c|
          printf("%-32s%-6s IN %-7s %-32s\n", host, c.ttl, 'CNAME', c.name)
          host = c.name.to_s
        }
        return host
      else
        return []
      end
    end
  end

  def getMX(host)
    Resolv::DNS.open do |dns|
      rez = dns.getresources host, Resolv::DNS::Resource::IN::MX
        mxIPs = Hash.new
        rez.map { |r|
          printf("%-32s%-6s IN %-7s %-5s %-32s\n", host, r.ttl, 'MX', r.preference, r.exchange)
        }
        puts
        rez.map { |r|   # gimme an A!
          getA( r.exchange )
        }
    end
  end

  def getNS(host)
    Resolv::DNS.open do |dns|
      nsIPs = Hash.new  # nameserver IPs
      rez = dns.getresources host, Resolv::DNS::Resource::IN::NS
      rez.map { |r|
        printf("%-32s%-6s IN %-7s %-32s\n", host, r.ttl, 'NS', r.name)
      }
      puts
      rez.map { |r|   # gimme an A!
        getA( r.name )
      }
    end
  end

  def getPTR(ipaddress)
    # hmm, there doesn't appear to be a method to pull in additional bits for this resource
    # TODO: Fix this so we output more DNS-like
    rez =  Resolv.getname ipaddress
    puts "#{rez}"
  end

  def getSOA(host)
    Resolv::DNS.open do |dns|
      rez = dns.getresources host, Resolv::DNS::Resource::IN::SOA
      rez.map { |r|
        printf("%-6s IN %-7s %-20s%-20s %s %s %s %s %s\n", host, r.ttl, 'SOA', r.mname, r.rname, r.serial, r.refresh, r.retry, r.expire, r.minimum)
      }
      puts
      rez.map { |r|
        getNS( host )
      }
    end
  end

end

def help_me
  puts "<link to help or other useful info>"
end

resolver = Resolver.new

if ARGV[0]
  if ARGV[0] == "help"
    help_me
    return
  end

  host = ARGV[0]
  if ARGV[1]
    recordType = ARGV[1]
  else
    if host.match('^\d+\.\d+\.\d+\.\d+$')
      recordType = "PTR"
    elsif host.match('^\w+\.\w+')
      recordType = "A"
    else
      recordType = "A"  # I don't know what we got; default to an 'A' query
    end
  end

  rr = recordType.upcase
  puts "DNS Result(s) for #{host} (Record Type: #{rr})"
  method_name = "get#{rr}"    # i.e. getA, getPTR, getSOA
  resolver.send( method_name, host ) if resolver.respond_to? method_name

else
  puts "Missing host/address!"
  help_me
end
