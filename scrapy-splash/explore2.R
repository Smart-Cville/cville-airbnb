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

airbnb2 <- airbnb_readin("scrapy-splash/airbnb-dates/airbnb_dates_cville.csv") %>% 
  mutate(filters = "map_date",
         site = "airbnb")

airbnb2 %<>% airbnb_dedup() # 179

sum(airbnb2$room_id %in% airbnb$room_id)
sum(airbnb$room_id %in% airbnb2$room_id)

both <- airbnb %>% 
  mutate(filters = "map") %>% 
  bind_rows(airbnb2) %>% 
  mutate(site = fct_rev(site),
         row_number = 1:nrow(.),
         content = glue::glue("<a href='{url}'>{filters}--{room_id}</a>
                              <br>
                              row-num:{row_number}")) %>%
  select_if(~ !all(is.na(.)))

both %>%
  group_by(longitude, latitude, room_id) %>%
  count() %>%
  filter(n > 1) # 62 but 68 by lon/lat alone
                # may be able to learn aboug geocode algo by investigating semi dupes

# de-duplicate
both %<>%
  group_by(longitude, latitude, room_id) %>% 
  mutate(filters = ifelse(n() > 1, "both", filters)) %>%
  slice(1)

#' </details>
#' ### Barchart
#+ plots

# both$filters %>% as.factor() %>% fct_relevel("map")

both$filters %>%
  tabyl() %>% 
  rename(., filters = `.`) %>% 
  mutate(filters = as.factor(filters)) %>% 
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

pal <- colorFactor("viridis", as.factor(both$filters))

sfize(both) %>% 
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


zoning <- read_sf("https://opendata.arcgis.com/datasets/b06e72d50d0f4715b812c1fd4a04184d_49.geojson") %>% 
  filter(!grepl("^R", ZONE))

# wrapper for sf object conversion
sfize <- . %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>% 
  st_set_crs(st_crs(zoning))

zoning %>%
  mutate(area = st_area(geometry)) %>%
  group_by(ZONE) %>%
  summarise(sum(area))

rentals <- bind_rows(both, vrbo) #480

rentals %<>%
  sfize() %>% 
  mutate(zone_id = st_within(., zoning) %>% as.numeric(),
         zone_bool = ifelse(is.na(zone_id), "residential or unzoned", "non-residential"),
         content = glue::glue("<a href='{url}'>{site}--{room_id}</a>"))

#' </details>
#' ### Plots


rentals %>%
  st_set_geometry(NULL) %>% 
  tabyl(zone_bool, site) %>%
  pivot_longer(-zone_bool) %>%
  mutate(zone_bool = fct_rev(zone_bool)) %>% 
  ggplot(aes(name, value, fill = zone_bool)) +
  geom_col(alpha = .25, color = "black") +
  geom_label(aes(label = value), position = "stack", alpha = .5, hjust = 1, size = 6, show.legend = FALSE) +
  scale_fill_viridis_d(option = "A") +
  coord_flip() +
  labs(title = "Zoning of all rentals",
       x = "Site",
       y = "#",
       fill = "Zoning")


#' #### Map of non-residential zones (black) and rentals (yellow)

leaflet(zoning) %>% 
  addTiles() %>% 
  addPolygons(label = ~ ZONE, fill = "#000004FF", color = "#000004FF", fillOpacity = .8) %>% 
  addCircleMarkers(data = rentals, fillColor = "#000000", color = "#FDE725FF", radius = 5, popup = ~content, fillOpacity = .5) 


