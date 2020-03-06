#' ---
#' title: Mon-Fri Rentals
#' output: html_document
#' ---

#+ setup, include=FALSE
knitr::opts_chunk$set(collapse = TRUE, fig.width = 9, echo = FALSE)

#' # Airbnb search filters
#' 
#' This compares the overlap between three 1-week (Monday - Friday) searches for the 
#' Charlottesville area on AirBnB.
#' 
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

all <- 
  # airbnb %>% 
  # mutate(filters = "map") %>% 
  bind_rows(airbnb_oct, airbnb_nov, airbnb_dec) %>% 
  mutate(site = fct_rev(site),
         row_number = 1:nrow(.),
         content = glue::glue("<a href='{url}'>{filters}--{room_id}</a>
                              <br>
                              row-num:{row_number}")) %>%
  select_if(~ !all(is.na(.)))

# filter to inside City
all %<>%
  sfize() %>% 
  mutate(in_city = st_within(., st_union(tracts)) %>% as.numeric()) %>% 
  filter(!is.na(in_city))

all %>%
  group_by(room_id) %>%
  count() %>%
  filter(n > 1) # 136

#' </details>
#' ### AirBnB scrapes
#+ plots

#' This plot suggests we may not being going far enough into the future for availability.


# de-duplicate
all %<>%
  group_by(room_id) %>% 
  mutate(filters = ifelse(n() > 1, as.character(n()), filters)) %>%
  slice(1) %>% 
  ungroup() # 187

all$filters %>%
  tabyl() %>% 
  rename(., filters = `.`) %>% 
  mutate(filters = factor(filters, levels = c("oct", "nov", "dec", "2", "3"))) %>% 
  ggplot(aes("", n, fill = filters)) +
  geom_col(alpha = .5, color = "black") +
  ggrepel::geom_label_repel(aes(label = n, color = filters), segment.size = 0,
                            fill = "white", position = "stack",size = 6, show.legend = FALSE) +
  ggtech::scale_fill_tech() +
  ggtech::scale_color_tech() +
  coord_flip() +
  labs(title = "Scraped AirBnB Mon-Fri rentals by search type",
       subtitle = "187 Total",
       x = NULL,
       y = "#",
       fill = "Month available:")

#' ### Larger rentals
#' Considering listings with 2 or more bedrooms as a proxy for houses that would
#' otherwise be available for rental.

larger_units <- all %<>% filter(num_beds >= 2)

tabyl(larger_units, filters) %>% 
  rename(., filters = filtersgeometry) %>% 
  mutate(filters = factor(filters, levels = c("oct", "nov", "dec", "2", "3"))) %>% 
  ggplot(aes("", n, fill = filters)) +
  geom_col(alpha = .5, color = "black") +
  ggrepel::geom_label_repel(aes(label = n, color = filters), segment.size = 0,
                            fill = "white", position = "stack",size = 6, show.legend = FALSE) +
  ggtech::scale_fill_tech() +
  ggtech::scale_color_tech() +
  coord_flip() +
  labs(title = "Rentals with >= 2 bedrooms",
       subtitle = "133 Total",
       x = NULL,
       y = "#",
       fill = "Month available:")


#' ### Map by month available

pal <- colorFactor(c("#FF5A5F", "#FFB400", "#007A87",  "#FFAA91", "#7B0051"),
                   levels(all$filters))

sfize(larger_units) %>% 
  leaflet() %>%
  addProviderTiles("Stamen.Toner") %>% 
  addCircleMarkers(color = ~pal(filters), fillColor = "black", radius = 5, popup = ~content) %>% 
  addLegend("topright", pal, ~filters)


#' ## Zoning of larger rentals
#' 
#' Very low overlap with areas zoned non-residential (all zones exlcuding R-1, R-1S, R-2, R-2U, R-3 )
#' 
#' ### Code
#' <details>
#+ hidden2, message = FALSE, warning = FALSE, fig.width = 12

# pacels level data (which should have better data)
zoning <- read_sf("https://opendata.arcgis.com/datasets/0e9946c2a77d4fc6ad16d9968509c588_72.geojson")

# wrapper for sf object conversion
sfize <- . %>% 
  st_as_sf(coords = c("longitude", "latitude"), remove = FALSE) %>% 
  st_set_crs(st_crs(zoning))

by_right_zones <- c("D","DE", "DN", "WME", "WMW",	"CH",	"HS",
                    "NCC", "HW", "WSD", "URB", "SS", "CD", "CC")

zoning %<>% group_by(Zoning) %>% summarise(geometry = st_combine(geometry))

zoning %>% st_buffer(.0001)

zoning %<>% 
  mutate(area = st_area(geometry)) %>% 
  group_by(Zoning) %>% 
  summarise(size = sum(area),
            geometry = st_union(geometry)) %>% 
  ungroup() %>% 
  mutate(by_right = Zoning %in% by_right_zones | grepl("^B", Zoning))

rentals <- larger_units %>% 
  st_set_geometry(NULL) %>% 
  bind_rows(vrbo) %>% # 442
  sfize()

rentals_in_city <- rentals %>% 
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
  labs(title = "Zoning of larger rentals",
       x = "Site",
       y = "#",
       fill = "Zoning")


#' #### "By-right" zoned map
#' 
#' A lot of restricted locations are being falsly called as "by-right" because this
#' zoning information is derived from parcel level data, which is not continuous across
#' streets and property lines.
#' 

# from library(ggtech)
# airbnb = c("#FF5A5F", "#FFB400", "#007A87",  "#FFAA91", "#7B0051"),

pal <- colorFactor(c("#007A87", "#FF5A5F"), as.factor(rentals_in_city$zone_bool))

leaflet(zoning) %>% 
  addProviderTiles("Stamen.Toner") %>% 
  addPolygons(label = ~ Zoning, fill = "#FF5A5F", color = "#FF5A5F", fillOpacity = .1, weight = 1) %>% 
  addCircleMarkers(data = rentals_in_city, fillColor = ~pal(zone_bool), color = ~pal(zone_bool),
                   radius = 5, popup = ~content, fillOpacity = .5) %>% 
  addLegend(pal = pal, values = c("restricted", "by-right"))

