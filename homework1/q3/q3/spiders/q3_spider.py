from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor

from q3.items import HyperlinkItem
import re
import urlparse

class MyExtractor(SgmlLinkExtractor):
    seen_urls = {}
    
    def __init__(self, allow=(), deny=(), allow_domains=(), deny_domains=(), restrict_xpaths=(), 
                 tags=('a', 'area'), attrs=('href'), canonicalize=True, unique=True, process_value=None,
                 deny_extensions=None, seen_urls=[]):
        SgmlLinkExtractor.__init__(self,allow=allow, deny=deny, allow_domains=allow_domains, deny_domains=deny_domains, restrict_xpaths=restrict_xpaths, 
                 tags=tags, attrs=attrs, canonicalize=canonicalize, unique=unique, process_value=process_value,
                 deny_extensions=deny_extensions)
        
        print "CREATED!!~!!!!!!"
        for l in seen_urls: self.seen_urls[l]=True
    
    def is_valid_link(self,l):
        url = l.url
        p = urlparse.urlparse(url)
        if p.scheme != 'http': return False
        if p.netloc != 'www.ccs.neu.edu': return False
        if url in self.seen_urls: return False
        self.seen_urls[url] = True
        return True
    
    def extract_links(self, response):
        links = SgmlLinkExtractor.extract_links(self, response) # python's old-style super
        
        filtered_links =  filter(self.is_valid_link, links)
        return filtered_links

# class TestSpider4(CrawlSpider):
#     name = "ccs.neu.edu"
#     start_urls = ["http://www.ccs.neu.edu/"]
# 
#     extractor = SgmlLinkExtractor()
# 
#     rules = (
#         Rule(extractor,callback='parse_page',follow=True),
#         )
# 
#     def parse_start_url(self, response):
#         list(self.parse_links(response))
# 
#     def parse_links(self, response):
#         hxs = HtmlXPathSelector(response)
#         links = hxs.select('//a')
#         
#         parsed_response_url = urlparse.urlparse(response.url)
#         response_url_dirname = ''.join([parsed_response_url.scheme, '://', parsed_response_url.netloc, dirname(parsed_response_url.path),'/'])
#          
#         for link in links:
#             title = ''.join(link.select('./@title').extract())
#             url = ''.join(link.select('./@href').extract())
#             meta={'title':title,}
#             
#             parsed_url = urlparse.urlparse(url)
#             if parsed_url.scheme: cleaned_url = url
#             else: cleaned_url = "%s%s" % (response_url_dirname,url)
#             
# #             cleaned_url = "%s/?1" % url if not '/' in url.partition('//')[2] else "%s?1" % url
#             yield Request(cleaned_url, callback = self.parse_page, meta=meta,)
# 
#     def parse_page(self, response):
#         return HyperlinkItem(url=response.url)


class CCSSpider(CrawlSpider):
    name = "ccs.neu.edu"
    start_urls = [
        "http://www.ccs.neu.edu/",
    ]
    extractor = MyExtractor(seen_urls=[], unique=False)

    rules = (
        Rule(extractor, callback="parse_page",follow=True),
    )
#     def __init__(self):
#         CrawlSpider.__init__(self)
#         print "CREATED!!!!!!!!!!!!!!!!!"
    
    def parse_page(self,response):
        content_types = re.split('\s*;\s*',response.headers['Content-Type'])
        url = response.url
        if 'application/pdf' in content_types or 'text/html' in content_types: 
            yield HyperlinkItem(url=url)
        else:
            print "### Other type: [%s]" %  response.headers['Content-Type']
    
#     def parse_start_url(self, response):
#         list(self.parse_links(response))
#         
#     def parse_links(self,response):
#         parsed_response_url = urlparse.urlparse(response.url)
#         response_url_dirname = ''.join([parsed_response_url.scheme, '://', parsed_response_url.netloc, dirname(parsed_response_url.path),'/'])
#             
#         hxs = HtmlXPathSelector(response)
#         urls = hxs.select('//a/@href').extract()
#         for url in urls:
# 
#             parsed_url = urlparse.urlparse(url)
#             if parsed_url.scheme: cleaned_url = url
#             else: cleaned_url = "%s%s" % (response_url_dirname,url)
#             
#             yield Request(cleaned_url, callback = self.parse_page) #, meta=meta,)





