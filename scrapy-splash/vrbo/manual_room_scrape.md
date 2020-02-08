# VRBO manual room listings

Scraping the VRBO listing page for Charlottesville has proven impossible with scrapy. However scraping the individual listing is doable with scrapy. So inorder to over come this, we build a list of roomID by hand.

Starting at this url on 2019-02-07

[https://www.vrbo.com/search/keywords:charlottesville-va-usa/@37.999184739322565,-78.53343213198241,38.07003327487784,-78.43695843813475,13z?petIncluded=false&ssr=true&adultsCount=2](https://www.vrbo.com/search/keywords:charlottesville-va-usa/@37.999184739322565,-78.53343213198241,38.07003327487784,-78.43695843813475,13z?petIncluded=false&ssr=true&adultsCount=2)

There are 123 results returned. In pages of up to 50. These resulting room IDs are in `manual_room_scrap.csv`