#' ---
#' title: Explore scraping results
#' output: html_document
#' ---

#+ setup, include=FALSE
knitr::opts_chunk$set(collapse = TRUE, fig.width = 9)

#' ## Code
#' <details>
#+ hidden, message = FALSE, warning = FALSE, fig.width = 12

library(here)
library(glue)
library(janitor)
library(sf)
library(leaflet)
library(magrittr)
library(tidyverse)

tracts <- read_sf("https://opendata.arcgis.com/datasets/63f965c73ddf46429befe1132f7f06e2_15.geojson")

# Airbnb ------------------------------------------------------------------

airbnb_readin <- . %>% 
  here() %>% 
  read_csv() %>% 
  clean_names() %>% 
  mutate_at(vars(room_id), as.character) %>% 
  mutate(url = paste0("https://www.airbnb.com/rooms/", room_id)) %>% 
  rename(unit_type = bedroom_type)

airbnb <- airbnb_readin( "scrapy-splash/airbnb/airbnb_cville.csv") %>% 
  mutate(site = "airbnb")
# lots of dups; multiple price points for the same roomID

airbnb_dedup <- . %>% 
  group_by(room_id) %>% 
  mutate(price = mean(price)) %>% 
  slice(1) %>% 
  group_by()

airbnb %<>% airbnb_dedup()

# VRBO --------------------------------------------------------------------

# this is a little messier bc I was a lot lazier in the scraper-side processing
vrbo <- read_csv(here("scrapy-splash/vrbo/vrbo_cville.csv")) %>% 
  clean_names() %>% 
  filter(!is.na(longitude)) %>% 
  mutate(details = str_remove(details, ", ,sq. ft.") %>% 
           str_replace("(\\D+),Sleeps", "\\1,0,Sleeps") %>% 
           str_replace(",Half Baths: ", "--") %>% 
           str_replace(": Studio", ": 1") %>%
           str_remove(" nights$") %>% 
           gsub(",\\D+\\: ", ",", .)
         ) %>% 
  separate(details,
           c("unit_type", "sq_ft", "num_guests", "num_beds", "num_baths", "min_nights"), 
           sep = ",") %>% 
  mutate(num_reviews = str_remove(num_reviews, " ?Reviews"),
         rating = str_replace(rating, ".* (\\d.?\\d?)/.*", "\\1"),
         url = paste0("https://www.vrbo.com/", room_id),
         site = "VRBO") %>% 
  mutate_at(vars(matches("^num"), sq_ft, rating), as.numeric)

# Both --------------------------------------------------------------------

both <- bind_rows(airbnb, vrbo) %>% 
  mutate(site = fct_rev(site),
         row_number = 1:nrow(.),
         content = glue::glue("<a href='{url}'>{site}--{room_id}</a>
                              <br>
                              row-num:{row_number}"),
         min_nights = str_remove(min_nights, "–.*") %>% 
           str_remove(" night") %>% 
           as.numeric()) %>%
  select_if(~ !all(is.na(.)))

both %>%
  group_by(longitude, latitude) %>% 
  count() %>%
  filter(n != 1) # no dupe locations

write_csv(both, "scraped_rentals.csv")

# Plots -------------------------------------------------------------------
#' </details>
#' ## Plots 
#+ plots

theme_set(theme_minimal())

both_long_n_trim <- both %>% 
  select(price, rating, matches("^num"), site) %>% 
  select(-num_rooms) %>% 
  pivot_longer(price:num_reviews)

ggplot(both_long_n_trim, aes(x = value, color = site)) +
  geom_density() +
  facet_wrap(~name, scales = "free") +
  labs(x = NULL)

#' ## Maps 
#+ maps

# wrapper for sf object conversion
sfize <- . %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(tracts))

# wrapper for reused ggplot
gg_city <- function(data) {
  ggplot(data) +
    geom_sf(data = tracts) +
    geom_sf(alpha = .1)
} 

#' ##### Where are the scraped results?
sfize(both) %>% 
  gg_city() +
  facet_wrap(~site) +
  labs(title = "Scraped locations over Census tracts")

#' ##### Feature distributions spatial
both %>% 
  sfize() %>% 
  plot(max.plot = 24)

#' ##### Numeric features
both %>% 
  select(-latitude, -longitude, -row_number) %>%
  select_if(is.numeric) %>% 
  gather() %>% 
  ggplot(aes(value)) +
  geom_histogram() +
  facet_wrap(~key, scales = "free", nrow = 3)

#' ##### Categorical features
both %>% 
  select(bath_type, bed_type, min_nights, unit_type, site) %>% 
  gather("key", "value", -site) %>% 
  count(site, key, value) %>% 
  mutate(value = fct_inorder(value)) %>% 
  ggplot(aes(value, n, fill = site)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~key, scales = "free", nrow = 3)

# attempt to filter by polygon overlap
# sfize(both) %>%
#   mutate(in_city = st_intersects(., st_union(tracts)) %>% map(~ unclass(.))) %>% pull(in_city)
# WIP

pal <- colorFactor("viridis", both$site)

sfize(both) %>% 
  leaflet() %>%
  addTiles() %>% 
  addCircleMarkers(color = ~pal(site), radius = 5, popup = ~content) %>% 
  addLegend("topright", pal, ~site)



