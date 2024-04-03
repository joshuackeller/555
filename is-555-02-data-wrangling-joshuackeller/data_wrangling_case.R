# Intro / Setup -----------------------------------------------------------------------------------------

# First let's load the tidyverse package so we have all of the manipulation functions we'll need:
install.packages("janitor")
library(janitor)
library(tidyverse)

# Download the csv file from the following link: https://www.dropbox.com/s/3ju75xnkxqombe5/flights.csv?dl=1

# Place that file you just downloaded in a subfolder called "data' in your project folder.
# Now use the `setwd()` command to point the R environment to your project folder. (NOT the data folder.)
# setwd('/Users/joshuakeller/Repos/555/is-555-02-data-wrangling-joshuackeller')

# Read the data in from the csv file. The variable name for the resulting tibble should be `flights_raw`.
flights_raw <- read_csv("./data/flights.csv")

# Now let's look at the data to get a feel for it. Display the data in the console, first by simply calling its
# variable name, then by using the `glimpse()` function, and finally using RStudio's data viewer. The data viewer can
# be launched by clicking the name of the tibble variable over in the "Environment" pane to the right ----->
# But also note the command that is called in the console when you click on it (`View()`).
flights_raw
glimpse(flights_raw)
View(flights_raw)

# As you examined the tibble in the console in the previous step, hopefully those variable names made your
# eyes hurt a bit. Spaces?!? Tick marks?!? Yuck. Let's clean up those names using the janitor package. Write
# code below to install the janitor package (if you haven't yet), load the package, then use its
# `clean_names()` function to clean up the column names. Preserve your raw data rather in the `flights_raw`
# tibble, placing the newly cleaned data in `flights_clean`. Then output the tibble to the console again
# to examine your handiwork.
flights_clean <- flights_raw %>% clean_names()
flights_clean

# Much better! Just to get familiar a few more options from the clean_names() function, pipe the raw data
# tibble into the clean_names function (without saving the result to a variable) and figure out how to convert
# the column names into all caps and then into big (or upper) camel case. (No need to save either.)
flights_raw %>% clean_names(case = c("all_caps"))
flights_raw %>% clean_names(case = c("upper_camel"))


# Filter, Arrange, Mutate, Rename -----------------------------------------------------------------------
flights_clean %>% select(carrier, tail_num, actual_elapsed_time)
selection_with_taxi <- flights_clean %>% select(carrier, tail_num, dep_delay, contains("taxi"))

delta_delayed <- selection_with_taxi %>% 
  filter(carrier == "DL", dep_delay > 0)

longest_delay <- selection_with_taxi %>% 
  filter(carrier == "DL", dep_delay > 0) %>% 
  arrange(desc(dep_delay)) %>% 
  slice(1)

american_fast_flights <- flights_clean %>% 
  filter(carrier == "AA") %>% 
  select(tail_num, origin, actual_elapsed_time) %>% 
  arrange(actual_elapsed_time) %>% 
  slice(1)

flights_clean %>% 
  select(distance, time_in_air) %>% 
  mutate(speed = distance / time_in_air * 60)

flights_clean <- mutate(flights_clean, speed = distance / time_in_air * 60)

top_speed <- flights_clean %>% 
  select(speed) %>% 
  arrange(desc(speed)) %>% 
  slice(1)

carriers_distinct <- flights_clean %>% 
  select(carrier) %>% 
  distinct(carrier)

renamed_1 <- flights_clean %>% 
  rename(month_number = month, was_diverted = diverted, distance_in_miles = distance) %>% 
  select(month_number, was_diverted, distance_in_miles, year, everything())

renamed_2 <- flights_clean %>% 
  rename(month_number = month, was_diverted = diverted, distance_in_miles = distance) %>% 
  relocate(month_number, was_diverted, distance_in_miles, year)

#flights_clean %>% 
#  filter(arrival_delay > 120, dep_delay <= 0, carrier == c("AA", "AS", "CO", "DL", "F9", "FL", 'MQ', "OO", "WN", "XE", "YV"))

miracle_departures <- flights_clean %>% 
  filter(arrival_delay > 120, dep_delay <= 0, carrier %in% c("AA", "AS", "CO", "DL", "F9", "FL", 'MQ', "OO", "WN", "XE", "YV"))

# Grouping, Summarizing, Counting -----------------------------------------------------------------------

flights_per_day <- flights_clean %>% 
  group_by(day_of_week) %>% 
  summarize(flight_count = n())


flights_per_day_2 <- flights_clean %>% 
  count(day_of_week)

overall_time_in_air <- flights_clean %>% 
  summarize(mean_tia = mean(time_in_air, na.rm = T))

airline_delays <- flights_clean %>% 
  group_by(carrier) %>% 
  summarize(mean_dep_delay  = mean(dep_delay, na.rm = T)) %>% 
  arrange(mean_dep_delay)

most_delayed <- flights_clean %>% 
  group_by(dest) %>% 
  slice_max(dep_delay) %>% 
  select(dest, dep_delay, departure_time)

most_flights <- flights_clean %>% 
  group_by(dest) %>% 
  summarize(
    count = n(),
    unique_tails = n_distinct(tail_num),
    mean_arrival_delay = mean(arrival_delay, na.rm = T),
    mean_dep_delay = mean(dep_delay, na.rm = T)
    ) %>% 
  arrange(desc(count)) %>% 
  slice(1:5)

group_ungroup_group <- flights_clean %>% 
  group_by(carrier) %>% 
  slice_max(arrival_delay, n = 3) %>% 
  ungroup() %>% 
  group_by(day_of_week) %>% 
  summarize(
    ave_taxi_in = mean(taxi_in, na.rm = T),
    ave_speed = mean(speed, na.rm = T)
  )


long_delays_each <- flights_clean %>% 
  filter(month <=6) %>% 
  group_by(dest, carrier) %>% 
  slice_max(dep_delay) %>% 
  select(carrier, dest, time_in_air, dep_delay)


# Binding, Joining --------------------------------------------------------------------------------------
lat_long_1 <- read_csv("./data/airport_lat_long_1.csv")
lat_long_2 <- read_csv("./data/airport_lat_long_2.csv")

lat_long_2 <- lat_long_2 %>% 
  rename(airport_code = airprt_code)

lat_long <- bind_rows(lat_long_1, lat_long_2)

flights_origin_latlong <- flights_clean %>% 
  left_join(lat_long, by = c("origin" = "airport_code")) %>% 
  select(carrier, origin, dest, airport_lat, airport_long)

flights_latlong <- flights_clean %>% 
  left_join(lat_long, by = c("origin" = "airport_code")) %>% 
  left_join(lat_long, by = c("dest" = "airport_code"), suffix = c("_origin", "_dest"))

# There are ~200 airports that are repeated in lat_long (distinct(airport_code) reduces the count by 200)
join_issue_1 <- lat_long %>% 
  distinct(airport_code)

flights_latlong %>% 
  filter(is.na(airport_lat_origin))
flights_latlong %>% 
  filter(is.na(airport_lat_dest))

# flights_lat_long only has 4 destinations where the airport_long_dest or the airport_lat_dest is missing
flights_latlong %>% 
  filter(is.na(airport_long_dest) | is.na(airport_lat_dest)) %>% 
  distinct(dest)
# The records with missing lat and long are all missing from lat_long
join_issues_2 <- lat_long %>% 
  filter(airport_code %in% c("ABQ", "AVL", "BFL", "BKG"))

flights_latlong_inner <- flights_clean %>% 
  inner_join(lat_long %>% distinct(airport_code, .keep_all = T), by = c("origin" = "airport_code")) %>% 
  inner_join(lat_long %>% distinct(airport_code, .keep_all = T), by = c("dest" = "airport_code"), suffix = c("_origin", "_dest"))


# Finalize, Commit, Push --------------------------------------------------------------------------------


