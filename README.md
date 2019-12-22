# cville-airbnb
Data and analysis of AirBnB activity in Charlottesville, VA

Aim: Identify properties being used full-time as rentals on AirBnB.

Context: AirBnB is a global rental agency that gives property owners the ability to sell short-term rentals of their homes. Currently Charlottesville has an affordable housing shortage and there is concern that these owner-rentals are contributing to the lack of supply. The city needs data to better understand the volume and location of AirBnB usage, so they appropriatly adapt policy for this new market.

Data: 

* List of short-term rental permits (available: City Planning Office)
* Zoning maps of the Charlottesville (available: [Open Data Portal](https://opendata.charlottesville.org/datasets/zoning-multiple-area)
* AirBnB inventory (scrapable?)

### Scraping AirBnB

The bulk of this project is focused on contructing a useful dataset of AirBnB activity in the city. There are multiple github projects: 

* [Airbnb web scraper](https://github.com/tomslee/airbnb-data-collection/)
* [NYC scrape project](https://github.com/adodd202/Airbnb_Scraping)

and scraping tools available:

* [Parsehub](https://www.parsehub.com/blog/scrape-airbnb-listing-data/)
* [Octoparse](https://www.octoparse.com/tutorial-7/scrape-room-data-from-airbnb) **Windows only**
* [Video tutorials](https://stevesie.com/apps/airbnb-api)

We want to establish durable methods (language/tool agnostic) that can build a similar data collection for properties located within the city limits.
