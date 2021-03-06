from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor

from q3.items import HyperlinkItem
import re
import urlparse
import sys
from scrapy.exceptions import CloseSpider
# from scrapy.contrib.closespider import CloseSpider

class MyExtractor(SgmlLinkExtractor):
    seen_urls = {}
    
    def __init__(self, allow=(), deny=(), allow_domains=(), deny_domains=(), restrict_xpaths=(), 
                 tags=('a', 'area'), attrs=('href'), canonicalize=True, unique=True, process_value=None,
                 deny_extensions=None, seen_urls=[]):
        SgmlLinkExtractor.__init__(self,allow=allow, deny=deny, allow_domains=allow_domains, deny_domains=deny_domains, restrict_xpaths=restrict_xpaths, 
                 tags=tags, attrs=attrs, canonicalize=canonicalize, unique=unique, process_value=process_value,
                 deny_extensions=deny_extensions)
        
        for l in seen_urls: self.seen_urls[l]=True
    
    def is_valid_link(self,l):
        url = l.url
        p = urlparse.urlparse(url)
        if p.scheme != 'http': return False
        if p.netloc != 'www.ccs.neu.edu': return False
#         if p.netloc != 'www.northeastern.edu': return False
        if url in self.seen_urls: return False
        self.seen_urls[url] = True
        return True
    
    def extract_links(self, response):
        links = SgmlLinkExtractor.extract_links(self, response) # python's old-style super
        
        filtered_links =  filter(self.is_valid_link, links)
        return filtered_links

class CCSSpider(CrawlSpider):
    name = "ccs.neu.edu"
    start_urls = [
        "http://www.ccs.neu.edu/",
#         "file:///tmp/tt",
    ]
    extractor = MyExtractor(seen_urls=[], tags=('a','area','link'), unique=False, deny_extensions=[])

    count = 0
    rules = (
        Rule(extractor, callback="parse_page", follow=True),
    )
        
    def parse(self,response):
        self.extractor.seen_urls[response.url]=True
        for i in self.parse_page(response):
            yield i
        for r in  CrawlSpider.parse(self,response):
            yield r
    
    
    def parse_page(self,response):
        content_types = re.split('\s*;\s*',response.headers['Content-Type'])
        url = response.url
        
        if 'application/pdf' in content_types or 'text/html' in content_types: 
            yield HyperlinkItem(url=url)
            
            
            self.count += 1
            if self.count>100:
                raise CloseSpider("Closing spider")




