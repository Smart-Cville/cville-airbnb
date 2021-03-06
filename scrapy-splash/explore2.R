#' ---
#' title: Rentals available
#' output: html_document
#' ---

#+ setup, include=FALSE
knitr::opts_chunk$set(collapse = TRUE, fig.width = 9)

#' # Airbnb search filters
#' 
#' This compares the overlap between two diferent search configurations for Airbnb:
#' 
#' * map - results filtered by a bounding box for Charlottesville
#' * map_date - map filter + M-F date restriction 2020-11-02 - 2020-11-06
#' 
#' Suprisinly small overlap in properties (62) between the two configurations.
#' 
#' ## Code
#' <details>
#+ hidden, message = FALSE, warning = FALSE, fig.width = 12

source(here::here("scrapy-splash/explore.R"))

# 1st week in October
airbnb_oct <- airbnb_readin("scrapy-splash/airbnb-oct/airbnb_oct_cville.csv") %>% 
  mutate(filters = "oct",
         site = "airbnb")
# 1st week in November
airbnb_nov <- airbnb_readin("scrapy-splash/airbnb-dates/airbnb_dates_cville.csv") %>% 
  mutate(filters = "nov",
         site = "airbnb")
# 1st week in Dec
airbnb_dec <- airbnb_readin("scrapy-splash/airbnb-dec/airbnb_dec_cville.csv") %>% 
  mutate(filters = "dec",
         site = "airbnb")

airbnb_oct %<>% airbnb_dedup() # 130
airbnb_nov %<>% airbnb_dedup() # 179
airbnb_dec %<>% airbnb_dedup() # 167

sum(airbnb_oct$room_id %in% airbnb$room_id)
sum(airbnb$room_id %in% airbnb_oct$room_id)

sum(airbnb_nov$room_id %in% airbnb$room_id)
sum(airbnb$room_id %in% airbnb_nov$room_id)

sum(airbnb_oct$room_id %in% airbnb_nov$room_id)
sum(airbnb_oct$room_id %in% airbnb_dec$room_id)
sum(airbnb_nov$room_id %in% airbnb_dec$room_id)

all <- airbnb %>% 
  mutate(filters = "map") %>% 
  bind_rows(airbnb_oct, airbnb_nov, airbnb_dec) %>% 
  mutate(site = fct_rev(site),
         row_number = 1:nrow(.),
         content = glue::glue("<a href='{url}'>{filters}--{room_id}</a>
                              <br>
                              row-num:{row_number}")) %>%
  select_if(~ !all(is.na(.)))

all %>%
  group_by(longitude, latitude, room_id) %>%
  count() %>%
  filter(n > 1) # 62 but 68 by lon/lat alone
# may be able to learn aboug geocode algo by investigating semi dupes

# de-duplicate
all %<>%
  group_by(longitude, latitude, room_id) %>% 
  mutate(filters = ifelse(n() > 1, "multiple", filters)) %>%
  slice(1) %>% 
  ungroup() # 410

#' </details>
#' ### Barchart
#+ plots

# both$filters %>% as.factor() %>% fct_relevel("map")

all$filters %>%
  tabyl() %>% 
  rename(., filters = `.`) %>% 
  mutate(filters = factor(filters, levels = c("map", "oct", "nov", "dec", "multiple"))) %>% 
  ggplot(aes("", n, fill = filters)) +
  geom_col(alpha = .25, color = "black") +
  geom_label(aes(label = n), position = "stack", alpha = .5, hjust = 1, size = 6, show.legend = FALSE) +
  scale_fill_viridis_d() +
  coord_flip() +
  labs(title = "Unique Airbnb rentals",
       x = NULL,
       y = "#",
       fill = "Search filters")


#' ### Map (listing links in popups)

pal <- colorFactor("viridis", as.factor(all$filters))

sfize(all) %>% 
  leaflet() %>%
  addTiles() %>% 
  addCircleMarkers(color = ~pal(filters), fillColor = "black", radius = 5, popup = ~content) %>% 
  addLegend("topright", pal, ~filters)


#' ## Zoning of all rentals
#' 
#' Very low overlap with areas zoned non-residential (all zones exlcuding R-1, R-1S, R-2, R-2U, R-3 )
#' 
#' ### Code
#' <details>
#+ hidden2, message = FALSE, warning = FALSE, fig.width = 12

## this is fuqd don't use it
# zoning <- read_sf("https://opendata.arcgis.com/datasets/b06e72d50d0f4715b812c1fd4a04184d_49.geojson") %>% 
#   filter(!grepl("^R", ZONE))

# pacels level data (which should have better data) ((b/c it's the city LOL))
zoning <- read_sf("https://opendata.arcgis.com/datasets/0e9946c2a77d4fc6ad16d9968509c588_72.geojson")

# wrapper for sf object conversion
sfize <- . %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(zoning))

by_right_zones <- c("D","DE", "DN", "WME", "WMW",	"CH",	"HS",
                    "NCC", "HW", "WSD", "URB", "SS", "CD", "CC")

zoning %<>% 
  mutate(area = st_area(geometry)) %>% 
  group_by(Zoning) %>% 
  summarise(size = sum(area)) %>% 
  ungroup() %>%
  mutate(by_right = Zoning %in% by_right_zones | grepl("^B", Zoning),
         by_right_color = if_else(by_right, "gold", "green"))

rentals <- bind_rows(all, vrbo) # 532

rentals_in_city <- rentals %>% 
  sfize() %>% 
  mutate(in_city = st_within(., st_union(tracts)) %>% as.numeric()) %>% 
  filter(!is.na(in_city))

zoning %<>% filter(!by_right)

rentals_in_city %<>%
  mutate(zone_id = st_within(., zoning) %>% as.numeric(),
         zone_bool = ifelse(is.na(zone_id), "by-right", "restricted"),
         content = glue::glue("<a href='{url}'>{site}--{room_id}</a>"))

#' </details>
#' ### Plots

rentals_in_city %>%
  st_set_geometry(NULL) %>% 
  tabyl(zone_bool, site) %>%
  pivot_longer(-zone_bool) %>%
  mutate(zone_bool = fct_rev(zone_bool)) %>% 
  ggplot(aes(name, value, fill = zone_bool)) +
  geom_col(alpha = .25, color = "black") +
  geom_label(aes(label = value), position = "stack", alpha = .5, hjust = 1, size = 6, show.legend = FALSE) +
  scale_fill_manual(values = c("#FF5A5F", "#007A87")) +
  coord_flip() +
  labs(title = "Zoning of all rentals",
       x = "Site",
       y = "#",
       fill = "Zoning")


#' #### Map of non-residential zones (black) and rentals (yellow)

# from library(ggtech)
# airbnb = c("#FF5A5F", "#FFB400", "#007A87",  "#FFAA91", "#7B0051"),
leaflet(zoning) %>% 
  addProviderTiles("Stamen.Toner") %>% 
  addPolygons(label = ~ Zoning, fill = "#FF5A5F", color = "#FF5A5F", fillOpacity = .5, weight = 1) %>% 
  addCircleMarkers(data = rentals_in_city, fillColor = "#007A87", color = "#007A87", radius = 5, popup = ~content, fillOpacity = .5)


