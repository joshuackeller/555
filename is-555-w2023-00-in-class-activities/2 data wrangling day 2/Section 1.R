library(tidyverse)

# (starwars tibble is always present when the tidyverse is loaded)
# Glimpse turns a data frame on its side. Super useful.
df <- starwars 

df %>% glimpse()

df %>% distinct(species)
df %>% count(species)

# group by species and summarize. Pay attention to NAs
df %>% 
  group_by(species) %>% 
  summarise(count = n(),
    avg_height = mean(height, na.rm = TRUE),
            max_height = max(height, na.rm = TRUE))



df %>% 
  filter(species == 'Droid')

# why NaN?

# top 5 tallest people overall
df %>% 
  select(height) %>% 
  arrange(desc(height)) %>% 
  slice_head(n = 5)

df %>% 
  slice_max(height, n = 5)

# vs. shortest 2 of each species. 
df %>% 
  group_by(species) %>% 
  slice_min(height, n = 2) %>% 
  # arrange(desc(height)) %>% 
  arrange(species, desc(height)) %>% 
  select(name, species, height) %>% 
  print(n=20)


# Also summarize isn't always the goal. What if we want a relative 
# comparison of height for each species? I.e., are you tall for a human?










# Grouping by multiple categoricals
# Was is the average birth year for each gender from each homeworld




# Grouping, then ungrouping, then grouping again:
# find average mass for each sex, but only for the tallest of each species.



# Joining and Binding
library(nycflights13)
df_flights <- flights
df_airlines <- airlines
df_planes <- planes


# Join in carrier names
flights2 <- flights %>% 
  select(year:day, hour, origin, dest, tailnum, carrier)



# What is the average "birth year" of planes associated with delayed departures flights to Atlanta?



# Watch for exploding data, also keys don't often match...
# airlines_bad




# Binding data - stacking chunks with bind_rows()
flights_half1
flights_half2




