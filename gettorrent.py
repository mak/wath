#!/usr/bin/env python2

import libtorrent as lt
import time,pprint

from urllib import urlencode,urlopen
import sys,os,re

class ProgressBar:
    def __init__(self, min_value = 0, max_value = 100, width=77,**kwargs):
        self.char = kwargs.get('char', '#')
        self.mode = kwargs.get('mode', 'dynamic') # fixed or dynamic
        if not self.mode in ['fixed', 'dynamic']:
            self.mode = 'fixed'

        self.bar = ''
        self.min = min_value
        self.max = max_value
        self.span = max_value - min_value
        self.width = width
        self.amount = 0       # When amount == max, we are 100% done
        self.update_amount(0)


    def increment_amount(self, add_amount = 1):
        """
        Increment self.amount by 'add_ammount' or default to incrementing
        by 1, and then rebuild the bar string.
        """
        new_amount = self.amount + add_amount
        if new_amount < self.min: new_amount = self.min
        if new_amount > self.max: new_amount = self.max
        self.amount = new_amount
        self.build_bar()


    def update_amount(self, new_amount = None):
        """
        Update self.amount with 'new_amount', and then rebuild the bar
        string.
        """
        if not new_amount: new_amount = self.amount
        if new_amount < self.min: new_amount = self.min
        if new_amount > self.max: new_amount = self.max
        self.amount = new_amount
        self.build_bar()


    def build_bar(self):
        """
        Figure new percent complete, and rebuild the bar string base on
        self.amount.
        """
        diff = float(self.amount - self.min)
        percent_done = int(round((diff / float(self.span)) * 100.0))

        # figure the proper number of 'character' make up the bar
        all_full = self.width - 2
        num_hashes = int(round((percent_done * all_full) / 100))

        if self.mode == 'dynamic':
            # build a progress bar with self.char (to create a dynamic bar
            # where the percent string moves along with the bar progress.
            self.bar = self.char * num_hashes
        else:
            # build a progress bar with self.char and spaces (to create a
            # fixe bar (the percent string doesn't move)
            self.bar = self.char * num_hashes + ' ' * (all_full-num_hashes)

        percent_str = str(percent_done) + "%"
        self.bar = '[ ' + self.bar + ' ] ' + percent_str


    def __str__(self):
        return str(self.bar)


def get_magnet(name,season,episode):
    ret = None
    grep = r"S%02dE%02d" % (int(season),int(episode))
    url='http://thepiratebay.se/s/?%s&page=0&orderby=7' % urlencode({'q':name})
    for l in urlopen(url).readlines():
        if re.search(grep,l) and re.search('magnet',l):
            ret = re.match('[^"]*="([^"]+)".*',l)
            break
    ret = ret.group(1) if ret != None else None
    return ret

ses = lt.session()
params = { 'save_path': '/tmp/'}
#params = {'save_path': '/torrents/' }
link = None

if len(sys.argv) == 2:
    link = sys.argv[1]
elif len(sys.argv) == 4:
    link = get_magnet(*sys.argv[1:])
else:
    exit("Wrong args number")


if link == None:
    exit('Cannot find link?')


handle = lt.add_magnet_uri(ses, link, params)

print >> sys.stderr, '[*] downloading metadata...'
while (not handle.has_metadata()): time.sleep(1)
print >> sys.stderr, '[+] got metadata, starting torrent download...'

files = handle.get_torrent_info().files()
if len(files) == 1:
#    pprint.pprint(files)
    print params['save_path'] + files[0].path

count = 0
total = 100
prog = ProgressBar(count, total, 77, mode='fixed', char='#')
while (handle.status().state != lt.torrent_status.seeding):
    count += handle.status().progress
    prog.increment_amount()
    print >> sys.stderr,  prog, '\r',
    sys.stderr.flush()
    time.sleep(1)

print >> sys.stderr , '\r\n'
sys.stderr.flush()
