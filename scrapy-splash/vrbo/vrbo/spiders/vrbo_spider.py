from scrapy import Spider, Request
from vrbo.items import VrboItem
from scrapy_splash import SplashRequest
#from selenium import webdriver
import re 

#################################  IMPORTANT  ################################################
# When running this script, need to run this command in the background on a separate terminal:
# docker run -p 8050:8050 scrapinghub/splash
#################################  IMPORTANT  ################################################

class VrboSpider(Spider):

	name = "vrbo_spider"
	allowed_urls = ["https://vrbo.com"]
	start_urls = ["https://vrbo.com"]

	def parse(self, response):

	# This will become a full array of IDs and a for loop
		room_id = "7388327ha" 
		# url = "https://www.vrbo.com/7388327ha?noDates=true"
		base_url = "https://www.vrbo.com/"
		suffix_filters = "?noDates=true"

		url = base_url + room_id + suffix_filters

		yield SplashRequest(url, callback=self.parse_room, args = {"wait": 50}, endpoint = "render.html") 
		
	def parse_room(self, response):	
		item = VrboItem()

		#Extracting the roomID from url.
		try:
			roomID = re.search('com/(.*)\?.*', str(response.url)).group(1)
		except AttributeError:
			roomID = ''

		try:
			# rating = re.search('Rated ([0-5](.[0-9])?) out of 5', string1).group(1)
			details = response.xpath("//span[contains(@class, 'listing-bullets')]/text()").getall()
		except AttributeError:
			details = ''

		try:
			rating = response.xpath("//div/span[contains(@class, 'reviews-summary')]/text()").get()
		except AttributeError:
			rating = ''

		try:
			numReviews = response.xpath("//a/strong[contains(@class, 'num-reviews')]/text()").get()
		except AttributeError:
			numReviews = ''
		
		try:
			price = response.xpath('//meta[@property = "og:price:amount"]/@content').get()
		except AttributeError:
			price = ''

		try:
			x = response.xpath('//script[contains(., "relatedGeographies")]/text()').get()
			loc_pos = re.search('location', x).span()
			loc = x[loc_pos[0]+11:loc_pos[1]+37]
		except:
			loc= "?"

		item['roomID'] = roomID
		item['details'] = details
		item['rating'] = rating
		item['numReviews'] = numReviews
		item['price'] = price
		item['loc'] = loc

		yield item
