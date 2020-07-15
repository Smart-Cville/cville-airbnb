#' ---
#' title: Charlottesville short-term rental summary
#' author: Nathan Day
#' output: html_document
#' ---

#+ setup0, include=FALSE, message=FALSE
source(here::here("scrapy-splash/explore.R"))

by_right_zones <- c("D","DE", "DN", "WME", "WMW",	"CH",	"HS",
                    "NCC", "HW", "WSD", "URB", "SS", "CD", "CC",
                    "B-1", "B-1C", "B-1H", "B-2", "B-2H", "B-3", "B-3H") %>% 
  sort()

#+ setup, include=FALSE
knitr::opts_chunk$set(collapse = TRUE, fig.width = 9, echo = FALSE)

#' # Total listings in Charlottesville
#' 
#' Results from map search of the Chalottesville area on Airbnb and VRBO.
#' After results were collected a geo-filter
#' was performed to select only listings within the city limits.
#' 
#' Then a zoning geo-filter was applied to identify properties as "by-right" or
#' "restricted" for short-term rental. Zoning codes considered as "by-right" are:
#' `r paste(by_right_zones, collapse = ",")`.
#' 
#' <details>
#+ hidden, message = FALSE, warning = FALSE, fig.width = 12

both %<>% 
  sfize() %>% 
  mutate(in_city = st_within(., st_union(tracts)) %>% as.numeric(),
         site = gsub("air", "Air", site)) %>% 
  filter(!is.na(in_city))

# zoning <- read_sf("https://opendata.arcgis.com/datasets/0e9946c2a77d4fc6ad16d9968509c588_72.geojson")
# 
# zoning %<>% 
#   group_by(Zoning) %>% 
#   summarise(geometry = st_union(geometry)) %>% 
#   ungroup() %>% 
#   mutate(by_right = Zoning %in% by_right_zones | grepl("^B", Zoning)) %>%
#   filter(!by_right)

# saveRDS(zoning, "zoning.RDS")
zoning <- readRDS(here::here("zoning.RDS"))

both %<>%
  mutate(zone_id = st_within(., zoning) %>% as.numeric(),
         zone_bool = ifelse(is.na(zone_id), "by-right", "restricted"),
         content = glue::glue("<a href='{url}'>{site}--{room_id}</a>"))

p0 <- ggplot(both, aes(site, alpha = zone_bool)) +
  geom_bar() +
  scale_alpha_discrete(range = c(.4, 1)) +
  labs(title = "Total short-term rentals by zoning",
       y = NULL,
       x = NULL,
       alpha = NULL,
       caption = glue("by-right zones:\n{paste(by_right_zones[1:10], collapse = ', ')}
                      {paste(by_right_zones[11:21], collapse = ', ')}"))

#' </details>

p0

#' # Airbnb listings available Monday-Friday
#' 
#' Three separate 1-week (Monday - Friday) searches for the 
#' Charlottesville area were performed on AirBnB. The first full calendar
#' week in each month was used:
#' 
#' * October 5-9
#' * November 2-6
#' * December 7-11
#' 
#' ## Code
#' <details>
#+ hidden2, message = FALSE, warning = FALSE, fig.width = 12

# 1st week in October
airbnb_oct <- airbnb_readin("scrapy-splash/airbnb-oct/airbnb_oct_cville.csv") %>% 
  mutate(month = "Oct",
         site = "Airbnb")
# 1st week in November
airbnb_nov <- airbnb_readin("scrapy-splash/airbnb-dates/airbnb_dates_cville.csv") %>% 
  mutate(month = "Nov",
         site = "Airbnb")
# 1st week in Dec
airbnb_dec <- airbnb_readin("scrapy-splash/airbnb-dec/airbnb_dec_cville.csv") %>% 
  mutate(month = "Dec",
         site = "Airbnb")

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

all <- bind_rows(airbnb_oct, airbnb_nov, airbnb_dec) %>% 
  mutate(site = fct_rev(site),
         month = factor(month, c("Oct", "Nov", "Dec"))) %>%
  select_if(~ !all(is.na(.)))

# filter to inside City and inside Zonings
all %<>%
  sfize() %>% 
  mutate(in_city = st_within(., st_union(tracts)) %>% as.numeric(),
         zone_id = st_within(., zoning) %>% as.numeric(),
         zone_bool = ifelse(is.na(zone_id), "by-right", "restricted")) %>% 
  filter(!is.na(in_city))

# check for dupes
all %>%
  group_by(room_id) %>%
  count() %>%
  filter(n > 1) # 136

p1a <- ggplot(all, aes(month, alpha = zone_bool)) +
  geom_bar(show.legend = FALSE) + 
  scale_alpha_discrete(range = c(.4, 1)) +
  labs(title = "Listings available Mon-Fri",
       y = NULL,
       x = NULL,
       caption = "For first full calendar week in each month")

p1b <- all %>%
  count(room_id, zone_bool) %>% 
  ggplot(aes(n, alpha = zone_bool)) +
  geom_bar(show.legend = FALSE) + 
  scale_alpha_discrete(range = c(.4, 1)) +
  labs(title = "Unique weekly listings",
        y = NULL,
       x = "# weeks available")

larger_units <- filter(all, num_beds >= 2)

p2a <- ggplot(larger_units, aes(month, alpha = zone_bool)) +
  geom_bar(show.legend = FALSE) + 
  scale_alpha_discrete(range = c(.4, 1)) +
  labs(title = "Larger (> 2 bedrooms) listings ",
       y = NULL,
       x = NULL)

p2b <- larger_units %>%
  count(room_id, zone_bool) %>% 
  ggplot(aes(n, alpha = zone_bool)) +
  geom_bar(show.legend = FALSE) +
  scale_alpha_discrete(range = c(.4, 1)) +
  labs(title = "Unique larger listings",
       y = NULL,
       x = "# weeks available")

# larger units + VRBO
rentals <- larger_units %>% 
  st_set_geometry(NULL) %>% 
  bind_rows(vrbo) %>% # 442
  sfize()

library(patchwork)
#' </details>

#+ plots

p1a + p1b
p2a + p2b

