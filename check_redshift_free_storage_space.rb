#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
# nagios plugin for Redshift free space usage
# ex)
# ruby check_rds_free_storage_space.rb -H xxxxx.ap-northeast-1.redshift.amazonaws.com -P 5439 -d my_database -u my_user -p my_password -w 50% -c 60%
#

require 'rubygems'
require 'pg'
require 'optparse'

# Get and parse option 
options = OptionParser.new do |opt|
  begin
    opt.program_name = File.basename($0)
    opt.version      = '0.0.1'
    opt.banner = "Usage: #{opt.program_name} [-H hostname] [-P port] [-d database] [-u user] [-p password] [-w warning] [-c critical]"
    opt.separator ''
    opt.separator 'Examples:'
    opt.separator "    % #{opt.program_name} -H xxxxx.ap-northeast-1.redshift.amazonaws.com -P 5439 -d my_database -u my_user -p my_password -w 50% -c 60%"
    opt.separator ''
    opt.separator 'Specific options:'
    opt.on '-u USER', '--user'
    opt.on '-p PASSWORD', '--password'
    opt.on '-H HOSTNAME', '--hostname'
    opt.on '-P PORT', '--port'
    opt.on '-d DATABASE', '--database'
    opt.on '-w WARNING', '--warning'
    opt.on '-c CRITICAL', '--critical'
    opt.separator ''
    opt.separator 'Common options:'
    opt.on_tail('-h', '--help', 'show this help message and exit') do
      puts opt
      exit
    end
    opt.on_tail('-v', '--version', 'show program\'s version number and exit') do
      puts "#{opt.program_name} #{opt.version}"
      exit
    end
    if opt.on.default_argv.length != 14 # opetion & parameter size
      raise "Option parameter is not enough"
    end
  rescue => e
    puts "ERROR: #{e}.\nSee #{opt}"
    exit
  end
end.getopts

# Remove '%' and cast integer
critical = options['critical'].delete("%").to_i
warning = options['warning'].delete("%").to_i

# Get status
begin
  connection = PG::connect(:host => options['hostname'], :port => options['port'], :user => options['user'], :password => options['password'], :dbname => options['database'])
  res = connection.exec("
    SELECT 
      SUM(capacity)/1024 AS capacity_gbytes, 
      SUM(used)/1024 AS used_gbytes, 
      (SUM(capacity) - SUM(used))/1024 AS free_gbytes 
    FROM 
      stv_partitions
    WHERE 
      part_begin=0;
  ")
  capacity_gbytes = res[0]["capacity_gbytes"]
  used_gbytes = res[0]["used_gbytes"]
  free_gbytes = res[0]["free_gbytes"]
rescue PGError => ex
  # PGError process
  print(ex.class," -> ",ex.message)
rescue => ex
  # Other Error  process
  print(ex.class," -> ",ex.message)
ensure
  connection.close if connection
end

# Check
persentage = sprintf("%f", (used_gbytes.to_f / capacity_gbytes.to_f) * 100).to_i.truncate
response = "total: #{capacity_gbytes}GB, used: #{used_gbytes}GB, free: #{free_gbytes}GB (#{persentage}%)|used=#{used_gbytes}"

# Puts result
if capacity_gbytes
  if persentage >= critical
    puts "Critical - #{response}"
    exit 2 # Critical
  elsif persentage >= warning
    puts "Warning - #{response}"
    exit 1 # Warning
  else
    puts "OK - #{response}"
    exit 0 # OK
  end
end
exit 3 # Unknown 
