library(sf)
library(magrittr)
library(tidyverse)

dat <- read.csv("~/ROS/cville-airbnb/nyc_expample/airbnb/airbnb_manhattan.csv")

tracts <- read_sf("https://opendata.arcgis.com/datasets/63f965c73ddf46429befe1132f7f06e2_15.geojson")

dat %>%
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(tracts)) %>% 
  ggplot() +
  geom_sf(data = tracts) +
  geom_sf(alpha = .1)

table(dat$roomID) %>% hist(breaks = 34)

dat %>% add_count(roomID) %>% filter(n %in% 16:19) %>% View()

hist(dat$price)

dat %>% filter(price > 800)
