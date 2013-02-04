

require 'open-uri'
require 'json'
require 'uri'
require 'net/http'


class Trakt

  def initialize(apikey,username,passwd=nil)
    @apikey = apikey
    @passwd = passwd
    @username = username
    @endpoint = 'api.trakt.tv'
  end

  def parse(result)
    result = result.body if result.respond_to?(:body)
    parsed =  JSON.parse result
    if parsed.kind_of? Hash and parsed['status'] and parsed['status'] == 'failure'
      raise Error.new(parsed['error'])
    end
    return parsed
  end

  def post(path,data={})
    data.merge!({
     'username' => @username,
     'password' => @passwd
    })
    uri = path.dup
    uri << @apikey

    http = Net::HTTP.new(@endpoint)
    data = JSON.dump(data)
    r = http.post2(uri,data)
    parse(r)

  end

  def get(path,*data)
    uri = 'http://'
    uri << @endpoint + '/'
    uri << path
    uri << @apikey
    x = *data.compact.map {|t| t.to_s}
    uri = URI.parse(File.join(uri,x))
    parse(uri.open.read)
  end

  def mywatched
    get('/user/library/shows/watched.json/',*[@username])
  end

  def episode_summary(name,*args)
    name=name.downcase; name.gsub!(/ /,'-');
    get("/show/episode/summary.json/",name,*args)
  end

  def getlatest(show)
    show.downcase!
    a = mywatched
    ses = a.select {|ser| ser["title"].downcase  =~ /#{show}/ }.first
    tmp = ses["seasons"].max{|a,b| a["season"] <=> b["season"]}

    epi = tmp["episodes"].max+1
    ses2 = tmp["season"]
    return [ses2,epi,ses]
  end

  def seen(data)
    post('/show/episode/seen/',data)
  end

  def markseen(show,ses,epi)
    info = episode_summary(show,ses,epi)
    data = {}
    data[:imbd_id] = info["show"]["imbd_id"]
    data[:tvdb_id] = info["show"]["tvdb_id"]
    data[:title]   = info["show"]["title"]
    data[:year]    = info["show"]["year"]
    data[:episodes] = [{:season => ses, :episode => epi}]
    seen(data)
  end


end
