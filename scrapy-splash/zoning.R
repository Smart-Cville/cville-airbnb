#' ---
#' title: Zoning overlap
#' output: html_document
#' ---

#' ## Code
#' <details>
#+ hidden, message = FALSE, warning = FALSE

library(here)
library(glue)
library(janitor)
library(sf)
library(leaflet)
library(magrittr)
library(tidyverse)

# data sucks
# zoning <- read_sf("https://opendata.arcgis.com/datasets/b06e72d50d0f4715b812c1fd4a04184d_49.geojson")

# using PAD data
zoning <- read_sf("https://opendata.arcgis.com/datasets/0e9946c2a77d4fc6ad16d9968509c588_72.geojson")

# wrapper for sf object conversion
sfize <- . %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(zoning))

rentals <- read_csv("scraped_rentals.csv") %>% sfize()

zoning %<>% 
  mutate(area = st_area(geometry)) %>% 
  group_by(Zoning) %>% 
  summarise(size = sum(area)) %>% 
  ungroup() %>%
  mutate(by_right = Zoning %in% c("D","DE", "DN", "WME", "WMW",	"CH",	"HS",
                                  "NCC", "HW", "WSD", "URB", "SS", "CD", "CC") |
           grepl("^B", Zoning),
         by_right_color = if_else(by_right, "gold", "green"))

leaflet(zoning) %>% 
  addTiles() %>% 
  addCircleMarkers(data = rentals, radius = 1) %>% 
  addPolygons(label = ~ Zoning, color = ~by_right_color)
