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

# lots of dups due to multiple prices
airbnb %>%
  group_by(roomID) %>% 
  summarise_if(is.numeric, mean) -> vrbo

hist(airbnb$price,
     breaks = seq(0,1000, 50))

vrbo <- read.csv("scrapy-splash/vrbo/vrbo_cville.csv") %>% 
  filter(!is.na(longitude))

vrbo %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(tracts)) %>% 
  ggplot() +
  geom_sf(data = tracts) +
  geom_sf(alpha = .1)

# no dups, bc it's hand-crafted

hist(vrbo$price,
     breaks = seq(0, 3000, 200))
