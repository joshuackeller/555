# Intro / Setup -----------------------------------------------------------------------------------------

library(tidyverse)

# NOTE:      For the first assignment, we had you use the `setwd()` command and then comment that command out
#            before submitting your assignment. We also had you create a local `data/` directory and read the
#            assignment data from there. For this assignment neither of those will be required. You can just 
#            read the files straight from the web using the code below.


#1 bad_drivers_wide
bad_drivers_long <- read_csv('https://www.dropbox.com/s/owbth6cwor2ugi6/bad_drivers.csv?dl=1')


bad_drivers_wide <- bad_drivers_long %>% 
  pivot_wider(
    names_from = statistic,
    values_from = num
  ) %>% 
  mutate_at(vars(contains('perc_')), ~ ./ 100 )


#2 sales_regions
addr <- read_csv('https://www.dropbox.com/s/1fb99ayyqq161hw/addresses.csv?dl=1')
regions <- read_csv('https://www.dropbox.com/s/bn4nwvvc0cv1638/us_regions.csv?dl=1')

sales_regions <- addr %>% 
  pivot_wider(
    names_from = field,
    values_from = value
  ) %>% 
  left_join(regions,by = c("state" = "state_abbr")) %>% 
  mutate(
    sales_assignment = 
      if_else(region %in% c("Midwest","Northeast"), "Jack", "Jill")
    ) %>% 
  mutate(sales_assignment = if_else(is.na(region), "Jill", sales_assignment))


  
#3 songs_time_in_100
songs <- read_csv('https://www.dropbox.com/s/85j3vgp7165i1xr/song_chart.csv?dl=1')

songs_time_in_100 <- songs %>% 
  pivot_longer(
    cols = !c(artist, track, start_date),
    names_to = "week",
    values_to = "rank"
  ) %>% 
  filter(!is.na(rank)) %>% 
  count(artist, track)


## Bonus problem
songs %>% 
  pivot_longer(
    cols = !c(artist, track, start_date),
    names_to = "week",
    values_to = "rank"
  ) %>% 
  filter(!is.na(rank)) %>% 
  count(artist) %>% 
  count(n) %>% 
  arrange(desc(nn))
  

  
#4 artist_most_at_1
artist_most_at_1 <- songs %>% 
  pivot_longer(
    cols = !c(artist, track, start_date),
    names_to = "week",
    values_to = "rank"
  ) %>% 
  filter(rank == 1) %>% 
  count(artist) %>% 
  arrange(desc(n))


#5 peak_week
peak_week <- songs %>% 
  pivot_longer(
    cols = !c(artist, track, start_date),
    names_to = "week_number",
    values_to = "rank"
  ) %>% 
  mutate(week_number = parse_double(str_remove(week_number, "wk"))) %>% 
  group_by(artist, track) %>% 
  slice_min(rank, with_ties = F)
  


#6 soccer_events_fixed
soccer <- read_csv('https://www.dropbox.com/s/y7u8v2ol7a7gcat/soccer_players.csv?dl=1')


soccer_events_fixed <- soccer %>% 
  separate(events, into = c("a", "b", "c"), " ") %>% 
  pivot_longer(
    cols = c(a, b, c),
    names_to = "letter",
    values_to = "stat"
  ) %>% 
  mutate(minute = parse_double(str_sub(stat, start = 2, end = -2))) %>% 
  arrange(round_id, match_id, team_initials, player_name, minute) %>% 
  group_by(round_id, match_id, team_initials, player_name) %>% 
  mutate(order = row_number()) %>% 
  ungroup() %>% 
  select(-c(letter, minute)) %>% 
  pivot_wider(
    names_from = order,
    values_from = stat,
    names_prefix = "event"
  )


#7 Bonus Problem!
# 
# For reference, here are what the soccer event codes mean:
# G = Goal
# I = Injury
# P = Penalty
# R = RedCard
# Y = YellowCard

# This worked, I just commented it out so it wouldn't store in memory
# Very fun problem by the way
# soccer_2 <- read_csv('https://www.dropbox.com/s/sg0pwv66lchzlxx/soccer_players_harder.csv?dl=1')
# 
# soccer_2 %>% 
#   mutate(split_events = str_split(events, " ")) %>% 
#   unnest(split_events) %>% 
#   mutate(event_code = str_sub(split_events, 1, 1)) %>% 
#   mutate(event_name = recode(
#     event_code,
#     G = "Goal",
#     I = "Injury",
#     P = "Penalty",
#     R = "RedCard",
#     Y = "YellowCard",
#     )
#   ) %>% 
#   select(-c(events, split_events, event_code)) %>% 
#   count(round_id, match_id, team_initials, player_name, event_name) %>% 
#   pivot_wider(
#     names_from = event_name,
#     values_from = n,
#     values_fill = 0,
#     names_prefix = "count"
#   )


# Finalize, Commit, Push --------------------------------------------------------------------------------

# BEFORE YOU COMMIT AND PUSH YOUR SUBMISSION
#
# Please carefully follow the (new) instructions at the end of the ReadMe document for finalizing and testing 
# your submission prior to commiting and pushing your submission.


  
