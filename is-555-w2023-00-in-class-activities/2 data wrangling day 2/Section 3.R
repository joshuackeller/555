library(tidyverse)

# (starwars tibble is always present when the tidyverse is loaded)
# Glimpse turns a data frame on its side. Super useful.
df <- starwars 

df %>% glimpse()

# group by species and summarize. Pay attention to NAs
# average
df %>% 
  filter(!is.na(mass)) %>% 
  group_by(species) %>% 
  summarize(count = n(),
            avg_mass = mean(mass, na.rm = TRUE),
            min_mass = min(mass, na.rm = T))

df %>% 
  filter(species == 'Chagrian')

df %>% 
  filter(species == 'Droid')




# top 5 tallest people overall
df %>% 
  # arrange(desc(height)) %>% 
  slice_head(n=5)

df %>% 
  slice_max(height, n=5)

df %>% 
  mutate(count = n()) %>% 
  glimpse

# vs. shortest 2 of each species. 
df %>% 
  group_by(species) %>% 
  mutate(count = n(),
         max_height = max(height, na.rm = T)) %>% 
  slice_min(height, n = 2) %>% 
  select(name, species, height, count, max_height) %>% 
  mutate(height_difference = max_height - height) %>% 
  print(n=20)



# Grouping by multiple categoricals
# Was is the average birth year for each gender from each homeworld
df %>% 
  group_by(homeworld,gender) %>% 
  summarize(count = n())



# Grouping, then ungrouping, then grouping again:
# find average mass for each sex, but only for the tallest of each species.




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




# What is the average "birth year" of planes associated with delayed departures flights to Atlanta?



# Watch for exploding data, also keys don't often match...
# airlines_bad
x



# Binding data - stacking chunks with bind_rows()
flights_half1
flights_half2




