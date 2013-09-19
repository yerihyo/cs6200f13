# Scrapy settings for q3 project
#
# For simplicity, this file contains only the most important settings by
# default. All the other settings are documented here:
#
#     http://doc.scrapy.org/topics/settings.html
#

BOT_NAME = 'q3'

SPIDER_MODULES = ['q3.spiders']
NEWSPIDER_MODULE = 'q3.spiders'

DEPTH_PRIORITY = 1
SCHEDULER_DISK_QUEUE = 'scrapy.squeue.PickleFifoDiskQueue'
SCHEDULER_MEMORY_QUEUE = 'scrapy.squeue.FifoMemoryQueue'
 
DOWNLOAD_DELAY = 1
# Crawl responsibly by identifying yourself (and your website) on the user-agent
#USER_AGENT = 'q3 (+http://www.yourdomain.com)'
