#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))
require 'trakt'
require 'napi'


shpss = '' ## sha1(trak pass)
usr   = '' ## trakt user name
apik  = '' ## trakt api key

trakt = Trakt.new apik,usr,shpss


if ARGV.size == 1
  name = ARGV.shift.downcase
  sesn,epi,ses = trakt.getlatest name
else
  name = ARGV.shift.downcase
  sesn = ARGV.shift
  epi  = ARGV.shift
  ses   = trakt.episode_summary name,sesn,epi 
  ses   = ses["show"]
end
tname = ses["url"].split('/').last


puts "[+] Next episode: #{ses['title']} S%02d E%02d -- enjoy" % [sesn,epi]
fname = (`/home/mak/wath/gettorrent.py '#{name}' #{sesn} #{epi}`).chomp


getsubs(fname)
puts "[+] got subs for #{fname}\n[+] start playing"
`mplayer  -subcp cp1250 #{fname} >/dev/null 2>&1`

trakt.markseen tname,sesn,epi

puts "[+] #{ses['title']} S%02d E%02d -- marked seen" % [sesn,epi]
