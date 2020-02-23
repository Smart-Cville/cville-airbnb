# Scrapy-Splash

The original scraper work is from this repo bu [Alex Dodd](https://github.com/adodd202/Airbnb_Scraping). This project would not have been possible without their contribution.

To run either the `airbnb` or `vrbo` scraper:

```
# fire ups the spash backend
docker run -p 8050:850 scrapinghub/splash

# change into the proper project
cd airbnb

# release the spider!
scrapy crawl airbnb_spider
```

This will generate the output file `airbnb_cville.csv`.

### Scrapy shell

If you need to interactively explore a page use the [shell](https://docs.scrapy.org/en/latest/topics/shell.html). This is very useful if you want to interactively test code to extract certain page elements.

``` py
url = 'https://www.vrbo.com/search/keywords:charlottesville-va-usa/@37.999184739322565,-78.53343213198241,38.07003327487784,-78.43695843813475,13z?petIncluded=false&ssr=true&adultsCount=2'

scrapy shell url
```
That `url` is for a single of the listings in Charlottesville VA with the default search params (petIncluded, adultsCount) and a map area restriction by lattitude and longitude.

If you want to try and extract chunks of the page you could do something like this in the interactive shell that is opened.

```py
response.xpath("//span[contains(@class, 'listing-bullets')]/text()").getall()
```

# Scraped data

The code lives in `explore.R`. It brings together the two scrape result CSVs and does some exploratory plots. It generates a webpage report, `explore.html`, and a santitized table combining both sources, `scraped_rentals.csv`, 
