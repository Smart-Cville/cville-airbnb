# Scrapy-Splash

The original scraper work is from this repo bu [Alex Dodd](https://github.com/adodd202/Airbnb_Scraping).

To run either the `airbnb` or `vrbo` scraper:

```
# fire ups the spash backend
docker run -p 8050:850 scrapinghub/splash

# change into the proper project
cd airbnb

# release the spider!
scrapy crawl airbnb_spider
```

The output file `airbnb_cville.csv` with be generated.

