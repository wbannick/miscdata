library(tidyverse)
library(arrow)
library(willbprocessed)
# clean records data
records <- arrow::read_feather("Clean_Data/japanese_american_incarceration_records.feather")

total_records = nrow(records)

# basically stats by subregion 
stats_by_subregion <- records %>%
  filter(
    residence_state %in% c("California", "Washington", "Oregon"),
    ! residence_area %in% c("B13","California", "Washington")
    ) %>%
  group_by(residence_state, residence_area) %>%
  summarise(
    # many more stats to add here!!
    n = n(),
    percent_records = n/total_records,
    # ties to us/japan
    us_born = mean(I(birth_place == "United States"), na.rm = T),
    japan_born = mean(I(birth_place == "Japan"), na.rm = T),
    never_in_japan = mean(I(age_in_japan == "Never Lived in Japan"), na.rm = T),
    # camp locations
    mode_camp = modeest::mfv(camp_full),
    percent_mode_camp = mean(I(camp_full == mode_camp), na.rm = T),
    mode_state = modeest::mfv(relocation_state),
    percent_mode_state =  mean(I(relocation_state == mode_state), na.rm = T),
    # age
    under_18 = mean(I(age3 == "0-17"), na.rm = T),
    btw_18_49 = mean(I(age3 == "18-49"), na.rm = T),
    over_50 = mean(I(age3 == "50+"), na.rm = T)
  ) %>%
  rename(
    "state" = "residence_state",
    "subregion" = "residence_area"
  ) %>%
  mutate(
    across(matches("born|percent|never|under|over|btw"), as_percent, 1, T),
    # condensing a couple to show better in maps
    mode_camp = paste0(mode_camp, " (",percent_mode_camp, ")"),
    mode_state = paste0(mode_state, " (",percent_mode_state, ")"),
    ) %>%
  select(-all_of(c("percent_mode_camp", "percent_mode_state")))

write_feather(stats_by_subregion, "Clean_Data/incarceration_stats_by_subregion.feather")
