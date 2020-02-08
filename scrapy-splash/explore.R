library(sf)
library(magrittr)
library(tidyverse)

tracts <- read_sf("https://opendata.arcgis.com/datasets/63f965c73ddf46429befe1132f7f06e2_15.geojson")

airbnb <- read.csv("scrapy-splash/airbnb/airbnb_cville.csv")

# see what's in the city
airbnb %>%
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(tracts)) %>% 
  ggplot() +
  geom_sf(data = tracts) +
  geom_sf(alpha = .1)



table(airbnb$roomID) %>% hist(breaks = 34)

airbnb %>% add_count(roomID) %>% filter(n %in% 16:19) %>% View()

hist(dat$price)

dat %>% filter(price > 800)
