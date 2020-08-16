library(magrittr)
library(tidyverse)

# Import ------------------------------------------------------------------
source(here::here("scrapy-splash/explore.R"))

# 1st week in October
airbnb_oct <- airbnb_readin("scrapy-splash/airbnb-oct/airbnb_oct_cville.csv") %>% 
  airbnb_dedup() %>% 
  mutate(filters = "oct",
         site = "airbnb")
# 1st week in November
airbnb_nov <- airbnb_readin("scrapy-splash/airbnb-dates/airbnb_dates_cville.csv") %>% 
  airbnb_dedup() %>% 
  mutate(filters = "nov",
         site = "airbnb")
# 1st week in Dec
airbnb_dec <- airbnb_readin("scrapy-splash/airbnb-dec/airbnb_dec_cville.csv") %>% 
  airbnb_dedup() %>% 
  mutate(filters = "dec",
         site = "airbnb")

all <- bind_rows(airbnb_oct, airbnb_nov, airbnb_dec) %>% 
  mutate(site = fct_rev(site),
         row_number = 1:nrow(.),
         content = glue::glue("<a href='{url}'>{filters}--{room_id}</a>
                              <br>
                              row-num:{row_number}")) %>%
  select_if(~ !all(is.na(.)))

# roll-up multi-month properties
all %<>% 
  group_by(room_id) %>% 
  mutate(months = n_distinct(filters),
         price = mean(price)) %>% 
  slice(1) %>%
  ungroup() %>% 
  select(-filters)

# filter to larger units only
all %<>% filter(num_beds >= 2)

all %<>%
  sfize() %>% 
  mutate(in_city = st_within(., st_union(tracts)) %>% as.numeric()) %>% 
  filter(!is.na(in_city))

all %<>% mutate(tract_no = st_within(., tracts) %>% as.numeric())

counts_by_tracts <- all %>% 
  group_by(tract_no) %>% 
  count() %>% 
  as.data.frame() %>% 
  select(-geometry)

tracts %<>% rename(tract_no = OBJECTID)

tracts %<>% inner_join(counts_by_tracts)

p1 <- ggplot(tracts, aes(fill = as.factor(tract_no))) +
  geom_sf(show.legend = FALSE) +
  scale_fill_brewer(palette = "Paired") +
  theme_void()

p2 <- counts_by_tracts %>% 
  arrange(n) %>% 
  mutate(tract_no = fct_inorder(as.character(tract_no))) %>% 
  ggplot(aes(x = n, y = as.factor(tract_no), fill = as.factor(tract_no))) +
  geom_col(color = "black", show.legend = F) +
  scale_fill_brewer(palette = "Paired") +
  labs(x = "Airbnb rentals",
       y = NULL)

cowplot::plot_grid(p1, p2, rel_widths = c(.3, .6))
  
ggplot(tracts) +
  geom_sf(show.legend = FALSE) +
  geom_sf(data = all, alpha = .2)

ggplot(tracts, aes(fill = n)) +
  geom_sf() +
  geom_sf_text(aes(label = n), color = "white", fontface = "bold", size = 4,
               fun.geometry = sf::st_centroid) +
  theme_void() +
  theme(legend.position = "bottom", 
        legend.direction = "horizontal",
        legend.key.width = unit(1, "cm")) +
  labs(title = "Full-time 2+ bedroom short-term rentals",
       subtitle = "by Census tract",
       caption = "133 units in total",
       fill = "# Short-term\n   Rentals")

ggsave("map_post.png", width = 6, height = 4)
