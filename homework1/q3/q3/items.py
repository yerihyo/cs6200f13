# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/topics/items.html

from scrapy.item import Item, Field

class HyperlinkItem(Item):
    name = Field()
    link = Field()
    # define the fields for your item here like:
    # name = Field()
    #pass

class Q3Item(Item):
    title = Field()
    link = Field()
    desc = Field()
    # define the fields for your item here like:
    # name = Field()
    #pass
