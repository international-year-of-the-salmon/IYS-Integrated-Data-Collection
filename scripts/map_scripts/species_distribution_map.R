# Species distribution maps
library(ggOceanMaps) 
library(tidyverse)
library(readxl)
library(here)

# Edit which vessels, years, or sampling event types you would like to plot
vessel <- c("TINRO", "NW", "Shimada", "Franklin", "Kaganovsky", "Legacy")
sampling_year <- c(2022)
#event_types could include "Trawl", "CTD" or "CTD-Rosette", "Gillnet"
event_types <- c("Trawl")

iys_event <- read_excel(list.files(pattern = "\\.xlsx$"), 
                       sheet = "Sampling_Events") |> 
  filter(vessel_name_abbr %in% vessel,
         year %in% sampling_year,
         event_type %in% event_types) |> 
  rename("Vessel" = "vessel_name_abbr") |> 
  mutate(Vessel = ifelse(Vessel == "NW", "NW Explorer", Vessel),
         Vessel = ifelse(Vessel == "Raw_Spirit", "Raw Spirit", Vessel))

iys_catch <- read_excel(list.files(pattern = "\\.xlsx$"),
                        sheet = "Trawl_Catch_Data")

iys_species <- right_join(iys_event, iys_catch, by = "station_event_id") |> 
  select(latitude_start_decdeg, longitude_start_decdeg, Vessel, 
         scientific_name, common_name, catch_count)


spp_presence_absence_map <- function(species){
  present <- iys_species |> 
    filter(scientific_name %in% species,
           catch_count > 0)
  
  absent <- anti_join(iys_event, present) |> 
    select(latitude_start_decdeg, longitude_start_decdeg)
  
  map <- basemap(data = iys_event,  rotate = TRUE, bathymetry = TRUE, lon.interval = 3) +
    guides(fill="none")+ # Removes bathymetry scale legend
    geom_spatial_point(data = present, aes(x = longitude_start_decdeg,
                                            y = latitude_start_decdeg,
    ))+
    geom_spatial_point(data = absent, aes(x = longitude_start_decdeg,
                                          y = latitude_start_decdeg),
                       shape = 4) +
    annotation_scale(location = "br") + 
    annotation_north_arrow(location = "tr", which_north = "true") +
    ggtitle(species)
  map
}

so_map <- spp_presence_absence_map("Oncorhynchus nerka")
so_map
ggsave(here("maps", "sockeye map.png"))

pi_map <- spp_presence_absence_map("Oncorhynchus gorbuscha")
pi_map
ggsave(here("maps", "pink_map.png"))

cu_map <- spp_presence_absence_map("Oncorhynchus keta")
cu_map
ggsave(here("maps", "chum_map.png"))
            
co_map <- spp_presence_absence_map("Oncorhynchus kisutch")
co_map
ggsave(here("maps", "coho_map.png"))

ck_map <- spp_presence_absence_map("Oncorhynchus tshawytscha")
ck_map
ggsave(here("maps", "chinook_map.png"))

myctophid_map <- spp_presence_absence_map(c("Myctophidae", "Protomyctophum thompsoni"))
myctophid_map + ggtitle("Myctophids")
ggsave(here("maps", "Myctophids_map.png"))

jellies_map <- spp_presence_absence_map(c("Aequorea",
                                          "Aurelia",
                                          "Aurelia aurita",
                                          "Beroe", 
                                          "Ctenophora",
                                          "Cyanea",
                                          "Hormiphora cucumis",
                                          "Phacellophora camtschatica",
                                          "Scyphozoa",
                                          "Staurophora mertensii",
                                          "Staurophora mertensii"
                                          ))
jellies_map + ggtitle("Jellies")
ggsave(here("maps", "jellies_map.png"))

squid_map <- spp_presence_absence_map(c("Berryteuthis anonychus",
                                        "Doryteuthis opalescens",
                                        "Gonatopsis",
                                        "Gonatopsis borealis",
                                        "Gonatus",
                                        "Gonatus berryi",
                                        "Gonatus pyros",
                                        "Oegopsida",
                                        "Onychoteuthis borealijaponica",
                                        "Teuthida"
                                        ))
squid_map + ggtitle("Squid")
ggsave(here("maps", "squid_map.png"))
