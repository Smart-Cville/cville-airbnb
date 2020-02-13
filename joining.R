#' ---
#' title: Joining nightmares
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

tracts <- read_sf("https://opendata.arcgis.com/datasets/63f965c73ddf46429befe1132f7f06e2_15.geojson")
