library(tidyverse)

# (starwars tibble is always present when the tidyverse is loaded)
# Glimpse turns a data frame on its side. Super useful.
df <- starwars 

df %>% glimpse()

df %>% distinct(species)
df %>% count(species)

# group by species and summarize. Pay attention to NAs
# average
df %>% 
  group_by(species) %>% 
  summarise(avg_height = mean(height, na.rm = TRUE),
            min_height = min(height, na.rm = TRUE))


df %>% 
  filter(species == 'Droid')


df
# why NaN?

# top 5 tallest people overall
df %>% 
  arrange(desc(height)) %>% 
  slice_head(n=5)

df %>% 
  slice_max(height, n = 5)

# vs. shortest 2 of each species. 
df %>% 
  select(name, species, height) %>%
  group_by(species) %>% 
  mutate(species_count = n(),
         species_max = max(height, na.rm = T)) %>% 
  mutate(difference_from_max = species_max - height) %>% 
  slice_min(height, n=2) %>% 
  arrange(species, height) %>% 
  print(n=20)




# Grouping by multiple categoricals
# Was is the average birth year for each gender from each homeworld




# Grouping, then ungrouping, then grouping again:
# find average mass for each sex, but only for the tallest of each species.
df %>% 
  group_by(species) %>% 
  slice_max(height) %>% 
  ungroup() %>% 
  group_by(sex) %>% 
  summarize(avg_mass = mean(mass, na.rm = T))
  


# Joining and Binding
install.packages('nycflights13')
library(nycflights13)
df_flights <- flights
df_airlines <- airlines
df_planes <- planes

airlines_bad

# Join in carrier names
flights2 <- flights %>% 
  select(year:day, hour, origin, dest, tailnum, carrier)


flights2 %>% 
  left_join(df_airlines)

flights2 %>% 
  left_join(airlines_bad, by = c('carrier' = 'car_code'))

# What is the average "birth year" of planes associated with delayed departures flights to Atlanta?



# Watch for exploding data, also keys don't often match...
# airlines_bad
x



# Binding data - stacking chunks with bind_rows()
flights_half1
flights_half2




