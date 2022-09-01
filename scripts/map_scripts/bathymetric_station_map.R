# Basic Stations Map with Bathymetry

library(ggOceanMaps)
library(tidyverse)
library(readxl)

# Edit which vessels, years, or sampling event types you would like to plot
vessel <- c("TINRO", "NW", "Shimada", "Franklin", "Kaganovsky", "Legacy", "Raw_Spirit")
sampling_year <- c(2022)
#event_types could include "Trawl", "CTD" or "CTD-Rosette", "Gillnet"
event_types <- c("Trawl", "Gillnet")

iys_data <- read_csv("https://raw.githubusercontent.com/international-year-of-the-salmon/IYS-Integrated-Data-Collection/main/output_datasets/IYS_events.csv?token=GHSAT0AAAAAABYJRUOVTUZHFB3DXM4SZHSGYYRENFA") |> 
  filter(vessel_name_abbr %in% vessel,
         year %in% sampling_year,
         event_type %in% event_types) |> 
  rename("Vessel" = "vessel_name_abbr") |> 
  mutate(Vessel = ifelse(Vessel == "NW", "NW Explorer", Vessel),
         Vessel = ifelse(Vessel == "Raw_Spirit", "Raw Spirit", Vessel))

bathymetric_station_map <- 
  basemap(data = iys_data,  rotate = TRUE, bathymetry = TRUE, bathy.style = "poly_greys",
          lon.interval = 3) +
  guides(fill="none")+ # Removes bathymetry scale legend
  geom_spatial_point(data = iys_data, aes(x = longitude_start_decdeg,
                                          y = latitude_start_decdeg, 
                                          colour = Vessel,
                     size = I(5)))+
  scale_colour_discrete() +
  annotation_scale(location = "br") + 
  annotation_north_arrow(location = "tr", which_north = "true")

bathymetric_station_map

#ggsave(here("maps", "bathymetric_station_map.png"))

