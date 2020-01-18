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
		# CALLS PARSERS ON EVERY PRICE POINT FOR PLACES IN MANHATTAN
		# WE COULD EXPAND THIS TO OTHER BOROS BY APPENDING THEIR NAMES TO NEW LISTS.
		# OR IN OTHER SIMILAR FASHIONS.

		# Construction of URLs
		URL_frag1 = "https://www.vrbo.com/search/keywords:charlottesville-va-usa/@37.991310323299125,-78.56478535689695,38.09662320062766,-78.41767155684812,13z/minNightlyPrice/"
		URL_frag2 = "/maxNightlyPrice/"
		URL_frag3 = "?petIncluded=false&ssr=true"

		lastURL = "https://www.vrbo.com/search/keywords:charlottesville-va-usa/@37.991310323299125,-78.56478535689695,38.09662320062766,-78.41767155684812,13z/minNightlyPrice/700?petIncluded=false&ssr=true"

		# for price in range(1, 700, 100):
		# 	print(price)
		# 	url = URL_frag1 + str(price) + URL_frag2 + str(price + 99) + URL_frag3
		# 	if price == 601: 
		# 		url = lastURL
		# 	yield SplashRequest(url, callback=self.parse_PriceRange, args = {"wait": 5}, endpoint = "render.html", meta = {"price":price})

		url = "https://www.vrbo.com/7388327ha?noDates=true"

		yield SplashRequest(url, callback=self.parse_room, args = {"wait": 5}, endpoint = "render.html") 
		
	def parse_room(self, response):	
		item = VrboItem()

		#Extracting the roomID from url.
		try:
			roomID = re.search('com/(.*)\?.*', str(response.url)).group(1)
		except AttributeError:
			roomID = ''

		try:
			# rating = re.search('Rated ([0-5](.[0-9])?) out of 5', string1).group(1)
			rating = response.xpath("//span[contains(@class, 'listing-bullets')]/text()").getall()
		except AttributeError:
			rating = ''

		try:
			numReviews = re.search('from ([0-9]*) reviews', response.text).group(1)
		except AttributeError:
			numReviews = ''
		try:
			price = response.xpath('//span[contains(@class, "rental-price__amount")]/text()').getall()
		except AttributeError:
			price = ''

		item['roomID'] = roomID
		item['rating'] = rating
		item['numReviews'] = numReviews
		item['price'] = price

		yield item



	# def parse_PriceRange(self, response):
	# 	# GOAL HERE:
	# 	# CALL A PARSER TO GO THROUGH EACH PAGE AT ANY GIVEN PRICE POINT

	# 	price = response.meta['price']
	# 	URL_frag1 = response.url
	# 	urls = [(URL_frag1 + "&section_offset=" + str(i)) for i in range(14)]

	# 	#Checking if we have any urls at this price point
	# 	if response.xpath('//h1[@class="_tpbrp"]/text()').extract_first() != "No results":
	# 		for url in urls:
	# 			yield SplashRequest(url, callback=self.parse_OnePage, args = {"wait": 5}, endpoint = "render.html")



	# def parse_Room(self, response):
	# 	# GOAL HERE:
	# 	# CALL A PARSER TO GO THROUGH EACH LISTING ON PAGE

	# 	URL_frag1 = 'https://www.vrbo.com' # removed trailing /
	# 	room_url_parts = response.xpath('//div/a[contains(@href,"rooms")]/@href').extract()

	# 	# Getting prices here (at the multiple listings page), because they are difficult to get in the 
	# 	# actual listing.
	# 	prices = (re.findall('"amount_formatted":"\$([0-9]{2,6})",', response.text))
		
	# 	#There is a chance that there will be no listings, so we want to account for this.
	# 	if room_url_parts:
	# 		urls = [(URL_frag1 + room_url_parts[i]) for i in range(len(room_url_parts))]

	# 		# Iterating through all of the listings in the list "urls"
	# 		i = 0
	# 		for url in urls:
	# 			price = prices[i]
	# 			i += 1
	# 			yield SplashRequest(url, callback=self.parse_details, args = {"wait": 2}, endpoint = "render.html", meta = {'price':price})#,'listDataSingle':listDataSingle})



	# def parse_details(self, response):
	# 	# GOAL HERE:
	# 	# GET ALL OF THE DETAILS OF THE PAGE HERE
	# 	# WITH SCRAPY SPLASH WE CAN GET THE TEXT BODY OF THE RESPONSE. 
	# 	# WITH THIS, WE CAN REGEX THE ENTIRE BODY TO GET MOST OF THE INFORMATION.

	# 	print("-" * 50)

	# 	item = VrboItem()

	# 	#Extracting the roomID from url.
	# 	try:
	# 		roomID = re.search('rooms/([0-9]*)\?location', str(response.url)).group(1)
	# 	except AttributeError:
	# 		roomID = ''

	# 	# Extracting rating and numReviews from below xpath object string.
	# 	string1 = str(response.xpath('//button[@class="_ff6jfq"]/@aria-label').extract_first())

	# 	try:
	# 		rating = re.search('Rated ([0-5](.[0-9])?) out of 5', string1).group(1)
	# 	except AttributeError:
	# 		rating = ''

	# 	try:
	# 		numReviews = re.search('from ([0-9]*) reviews', string1).group(1)
	# 	except AttributeError:
	# 		numReviews = ''

	# 	price = response.meta['price']

	# 	###########################  Overview  #######################
	# 	item['roomID'] = roomID
	# 	item['numReviews'] = numReviews
	# 	item['price'] = price
	# 	# this line was causing:
	# 	# 	AttributeError: 'NoneType' object has no attribute 'group'
	# 	# item['shortDesc'] = (re.search('"localized_room_type":"(.{1,50})","city',response.text)).group(1)


	# 	#######################  Host   ##############################
	# 	item['numHostReviews'] = response.xpath('//span[@class="_e296pg"]/span[@class="_1uhfauip"]/text()').extract_first()
	# 	# item['isSuperhost'] = (re.search('"is_superhost":(.{1,5}),',response.text)).group(1)


	# 	#################  Numbers of rooms/baths/guests  ############
	# 	item['numBaths'] = (re.search('"bathroom_label":"([0-9]\.?[0-9]?).*","bed_label"', response.text)).group(1)
	# 	item['numBeds'] = (re.search('"bed_label":"(.).*","bedroom_label"', response.text)).group(1)

	# 	if re.search('"bedroom_label":"([0-9][0-9]?).*","guest_label"', response.text) != None:
	# 		item['numRooms'] = (re.search('"bedroom_label":"([0-9][0-9]?).*","guest_label"', response.text)).group(1)
	# 	else:
	# 		item['numRooms'] = 0
	# 	if re.search('"guest_label":".{1,8}([0-9][0-9]?).{1,8}",', response.text) != None:
	# 		item['numGuests'] = (re.search('"guest_label":".{1,8}([0-9][0-9]?).{1,8}",', response.text)).group(1)
	# 	else:
	# 		item['numGuests'] = (re.search('"guest_label":"([0-9][0-9]?) guest.*', response.text)).group(1)


	# 	############## Types of rooms/baths/guests  ###################
	# 	item['bathType'] = (re.search('"bathroom_label":"[0-9].?[0-9]? (.*)","bed_label"', response.text)).group(1)
	# 	if re.search('"bedroom_label":"[0-9] (.*)","guest_label"', response.text) != None:
	# 		item['bedroomType'] = (re.search('"bedroom_label":"[0-9] (.*)","guest_label"', response.text)).group(1)
	# 	else:
	# 		item['bedroomType'] = (re.search('"bedroom_label":"(..?.?.?.?.?.?.?.?.?.?.?)","guest_label"', response.text)).group(1)
	# 	item['bedType'] = (re.search('"bed_label":"[0-9] (.*)","bedroom_label"', response.text)).group(1)


	# 	########################  Coordinates  ########################
	# 	coordinates = re.search('"listing_lat":([0-9]{2}.[0-9]*),"listing_lng":(-[0-9]{2}.[0-9]*),', response.text)
	# 	item['latitude'] = coordinates.group(1)
	# 	item['longitude'] = coordinates.group(2)


	# 	##########################  Ratings  ##########################
	# 	# Sometimes the ratings are not available...
	# 	if numReviews:
	# 		item['rating'] = rating
	# 		item['accuracy'] = (re.search('"accuracy_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['communication'] = (re.search('"communication_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['cleanliness'] = (re.search('"cleanliness_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['location'] = (re.search('"location_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['checkin'] = (re.search('"checkin_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['value'] = (re.search('"cleanliness_rating":([0-9][0-9]?),"', response.text)).group(1)
	# 		item['guestSatisfaction'] = (re.search('"guest_satisfaction_overall":([0-9][0-9][0-9]?),"', response.text)).group(1)
	# 	else:
	# 		item['rating'] = ''
	# 		item['accuracy'] = ''
	# 		item['communication'] = ''
	# 		item['cleanliness'] = ''
	# 		item['location'] = ''
	# 		item['checkin'] = ''
	# 		item['value'] = ''
	# 		item['guestSatisfaction'] = ''


	# 	yield item
