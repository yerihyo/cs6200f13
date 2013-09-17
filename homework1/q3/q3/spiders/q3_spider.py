from scrapy.spider import BaseSpider
from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor
from scrapy.selector import HtmlXPathSelector

from q3.items import HyperlinkItem
from scrapy.http import Request

class CCSSpider(CrawlSpider):
    name = "ccs.neu.edu"
    allowed_domains = ["ccs.neu.edu"]
    #allowed_domains = ["dmoz.org"]
    start_urls = [
        "http://www.ccs.neu.edu/",
        #"http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        #"http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
    ]
    extractor = SgmlLinkExtractor()
    #SgmlLinkExtractor(allow=('*\.php', ), deny=('subsection\.php', ))

    rules = (
        Rule(extractor, callback="parse_link", follow=True),
    )

    def parse_links(self, response):
        hxs = HtmlXPathSelector(response)
        hyperlinks = hxs.select('//a')
        for link in hyperlinks:
            title = ''.join(link.select('./@title').extract())
            url = ''.join(link.select('./@href').extract())
            meta={'title':title,}
            
            cleaned_url = "%s/?1" % url if not '/' in url.partition('//')[2] else "%s?1" % url
            yield Request(cleaned_url, callback = self.parse_page, meta=meta,)


    def parse_page(self, response):
        hxs = HtmlXPathSelector(response)
        item = HyperlinkItem()
        item['url'] = response.url
        item['title']=response.meta['title']
        item['h1']=hxs.select('//h1/text()').extract()
        return item

class CCSBaseSpider(BaseSpider):
    name = "ccs.neu.edu"
    allowed_domains = ["ccs.neu.edu"]
    #allowed_domains = ["dmoz.org"]
    start_urls = [
        "http://www.ccs.neu.edu/",
        #"http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        #"http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
    ]

    def parse(self, response):
        hxs = HtmlXPathSelector(response)
        hyperlinks = hxs.select('//a')
        items = []
        for l in hyperlinks:
            item = HyperlinkItem()
            item['name'] = l.select('text()').extract()
            item['link'] = l.select('@href').extract()
            items.append(item)
        return items



"""
class Q3Spider_original(BaseSpider):
    name = "q3"
    #allowed_domains = ["www.ccs.neu.edu"]
    allowed_domains = ["dmoz.org"]
    start_urls = [
        #"http://www.ccs.neu.edu/",
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
    ]

    def parse(self, response):
        hxs = HtmlXPathSelector(response)
        sites = hxs.select('//ul/li')
        items = []
        for site in sites:
            item = Q3Item()
            item['title'] = site.select('a/text()').extract()
            item['link'] = site.select('a/@href').extract()
            item['desc'] = site.select('text()').extract()
            items.append(item)
        return items

#    def parse(self, response):
#        filename = response.url.split("/")[-2]
#        open(filename, 'wb').write(response.body)
"""
