
require 'open-uri'
require 'digest/md5'
require 'tempfile'


def md5(f)
  File.open(f) do |fh|
    Digest::MD5.hexdigest(fh.read(10485760))
  end
end

def chksum(md5)
  idx = [0xe, 0x3,  0x6, 0x8, 0x2 ]
  mul = [2,   2,    5,   4,   3 ]
  add = [0, 0xd, 0x10, 0xb, 0x5 ]

  b = ''
  add.zip(mul,idx) do |a,m,i|
    t = a + md5[i].to_i(16)
    v = md5[t,2].to_i(16)
    b << ('%x' % (v*m))[-1]
  end
  return b
end


def extract(fl)
  return `7za x -y -so-bd -piBlm8NTigvru0Jr0 #{fl} 2>/dev/null`
end

def getsubs(fl)
  m = md5(fl)
  c = chksum(m)

  url='http://napiprojekt.pl/unit_napisy/dl.php?'
  url << "l=PL&f=#{m}&t=#{c}&v=other&kolejka=false&nick=&pass=&napios=posix"
  data = open(url).read
  tmp = Tempfile.new('napisy')
  tmp.write(data)
  tmp.rewind
  tmp.close(false)

  data = extract(tmp.path)
  txtfl = fl.split('.');txtfl.pop
  txtfl.push('txt')
  txtfl = txtfl.join('.')

  File.write(txtfl,data)
  tmp.unlink
end
