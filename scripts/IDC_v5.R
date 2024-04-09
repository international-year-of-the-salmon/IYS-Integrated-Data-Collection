library(tidyverse)
library(readxl)

# This script updates the IYS Integrated Data Collection (IDC) to version 5
gsi_2022 <- read_csv("https://raw.githubusercontent.com/international-year-of-the-salmon/2022-Genetic-stock-id/main/standardized_data/gsi_2022.csv")
write_csv(gsi_2022, here::here("input_datasets", "2022", "gsi_2022.csv"))

duplicates <- gsi_2022 |> 
  group_by(specimen_id) |> 
  summarize(n = n()) |> 
  filter(n > 1)

idc_v4_data_dictionary <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "Data_Dictionary")
idc_v4_events <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "Sampling_Events")
idc_v4_specimen <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "Trawl_Specimen_Data")
idc_v4_catch <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "Trawl_Catch_Data")
idc_v4_zooplankton <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "Bongo_Specimen_Data")
idc_v4_ctd <- readxl::read_excel(here::here("IYS_Integrated_Data_Collection_V4.xlsx"), sheet = "CTD_Data")

# Add GSI data to IDC
qc_check <- anti_join(gsi_2022, idc_v4_specimen, by = "specimen_id") # result should be zero]
# Result: all specimen_ids in gsi_2022 have a match in idc_v4_specimen

qc_check2 <-semi_join(idc_v4_specimen,gsi_2022, by = "specimen_id")

idc_v5_specimen <- left_join(idc_v4_specimen, gsi_2022, by = "specimen_id") |> 
  select(station_event_id:visceral_adhesion, IAgroup, comments)

# Add DOI for the franklin zooplankton data when vessl = Franklin and event_type = Bongo dataset_doi = "https://doi.org/10.21966/ymv6-8024"
idc_v5_events <- idc_v4_events |> 
  mutate(dataset_doi = ifelse(vessel_name_abbr == "Franklin" & event_type == "Bongo", "https://doi.org/10.21966/ymv6-8024", dataset_doi))

#TODO
# As per issue at https://github.com/international-year-of-the-salmon/IYS-Integrated-Data-Collection/issues/2
#TODO Add technical parameters and weather conditions for the 2020 cruise, as provided in: https://npafc.org/wp-content/uploads/Public-Documents/2021/1930-Rev.1Second-GoA-Expedition-Summary.pdf (Table 4)
#TODO Include taxonomic rank for missing values in catch table
#TODO include LSID for Robust clubhook squid Moroteuthis robustus

library(worrms)
# Get the LSID for Robust clubhook squid Moroteuthis robustus
lsid <- worrms::wm_records_common("clubhook squid", fuzzy = TRUE)
lsid <- worrms::wm_records_taxamatch("Moroteuthis robustus")

idc_v5_specimen <- idc_v5_specimen |> 
  mutate(verbatim_identification = ifelse(scientific_name == "Moroteuthis robustus", "Moroteuthis robustus", verbatim_identification)) |> 
  mutate(scientific_name = ifelse(verbatim_identification == "Moroteuthis robustus", "Onykia robusta", scientific_name)) |> 
  mutate(scientific_name_id = ifelse(scientific_name == "Onykia robusta", lsid[[1]][["lsid"]], scientific_name_id)) |> 
  mutate(taxonomic_rank = ifelse(scientific_name == "Onykia robusta", "species", lsid[[1]][["rank"]]))

no_ranks <- idc_v5_specimen |> 
  filter(is.na(taxonomic_rank) & !is.na(scientific_name_id)) # 1 record


#add comment to event table for NW CTD events to indicate CTD was improperly deployed and data is not available
idc_v5_events <- idc_v5_events |> 
  mutate(comments = ifelse(vessel_name_abbr == "NW" & event_type == "CTD", "CTD was improperly deployed and data is not available", comments))

# Create IDC V5. excel file
out <- list("Data_Dictionary" = idc_v4_data_dictionary, 
            "Sampling_Events" = idc_v5_events,
            "Trawl_Catch_Data" = idc_v4_catch, 
            "Trawl_Specimen_Data" = idc_v5_specimen,
            "Bongo_Specimen_Data" = idc_v4_zooplankton, 
            "CTD_Data" = idc_v4_ctd)

writexl::write_xlsx(out, here::here("Draft_IDC_V5.xlsx"))

#  replace updated files in output_datasets folder
write_csv(idc_v5_specimen, here::here("output_datasets", "IYS_trawl_specimen.csv"))
write_csv(idc_v5_events, here::here("output_datasets", "IYS_events.csv"))
