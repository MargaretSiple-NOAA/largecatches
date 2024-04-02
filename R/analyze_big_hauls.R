# Filter_data

library(tidyverse)

haul0 <- read.csv("data/racebase_haul.csv")
catch0 <- read.csv("data/racebase_catch.csv")

head(haul0)
head(catch0)
unique(catch0$REGION)

hauls_catch <- haul0 |>
  right_join(catch0, by = c("CRUISEJOIN", "HAULJOIN", "REGION", "CRUISE", "VESSEL", "HAUL")) |>
  group_by(HAULJOIN, REGION, VESSEL, CRUISE, HAUL, ABUNDANCE_HAUL, DURATION, PERFORMANCE, DISTANCE_FISHED, SUBSAMPLE) |>
  summarize(TOTAL_CATCH_KG = sum(WEIGHT, na.rm = TRUE)) |> # I think KG is the units of the CATCH table WEIGHT column.
  ungroup() |>
  filter(REGION %in% c("AI", "GOA"))


table(hauls_catch$REGION)
# AI   GOA
# 7043 27524


bighauls <- hauls_catch |>
  filter(TOTAL_CATCH_KG > 5000) |>
  mutate(YEAR = as.numeric(stringr::str_extract(CRUISE, "^\\d{4}"))) |>
  filter(YEAR > 2010) |>
  mutate(APPROX_ONBOTTOMTIME = DISTANCE_FISHED / 0.0926) # in mins

table(bighauls$REGION)
# AI GOA
# 474 440

any(duplicated(bighauls$HAULJOIN))


# Plot of all hauls + big hauls over time ---------------------------------
nb.cols <- 24
mycolors <- colorRampPalette(RColorBrewer::brewer.pal(8, "Accent"))(nb.cols)

p1 <- bighauls |>
  filter(APPROX_ONBOTTOMTIME < 50) |> # take out weird outliers, not sure what's up w those
  ggplot(aes(APPROX_ONBOTTOMTIME, TOTAL_CATCH_KG / 1e3, color = factor(PERFORMANCE))) +
  geom_point(alpha = 0.8) +
  geom_vline(xintercept = 15, color = "red", lty = 2) +
  geom_abline(slope = 1) +
  facet_grid(~ABUNDANCE_HAUL) +
  scale_color_manual("Performance code", values = mycolors) +
  xlab("Approximate on-bottom time (mins)") +
  ylab("Total catch (mt)") +
  labs(title = "Big (>5000 kg) hauls after 2010") +
  theme_light(base_size = 14)

ggsave(filename = "output/onbottom_time_vs_total_catch.png", plot = p1, width = 8, height = 4, units = "in", dpi = "retina")

# What are the species compositions of the big hauls? ---------------------
catch_bighauls <- catch0 |>
  filter(HAULJOIN %in% bighauls$HAULJOIN) |>
  left_join(bighauls) |>
  group_by(HAULJOIN, REGION) |>
  summarize(DOM_SPECIES = SPECIES_CODE[which.max(WEIGHT)])

p2 <- catch_bighauls |>
  ggplot(aes(x = factor(DOM_SPECIES))) +
  geom_bar() +
  xlab("Dominant species") +
  ylab("Frequency") +
  facet_wrap(~REGION, nrow = 2, scales = "free_y") +
  theme_light(base_size = 14) +
  labs(title = "Dominant species in big (>5000 kg) hauls", subtitle = "All years after 1992")

ggsave(filename = "output/dominant_species.png", plot = p2, width = 8, height = 7, units = "in", dpi = "retina")
