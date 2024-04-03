library(tidyverse)

# (starwars tibble is always present when the tidyverse is loaded)
# assign it to a separate variable for protection, though
df <- starwars 

df %>% glimpse()

# group by species and summarize. Pay attention to NAs
df %>% 
  group_by(species) %>% 
  summarise(avg_height = mean(height, na.rm = TRUE),
            min_height = min(height, na.rm = TRUE))

# Note that the group_by() creates 38 species, and 38 is the distinct count of species values in the data:
df %>% distinct(species)
df %>% count(species)

# We investigated why (without the `na.rm = TRUE` addition) the avg and minimum heights show NA for droids
# It's because any NAs in the group will result in a summarized NA unless we are explicit about it.
df %>% 
  filter(species == 'Droid')



# top 5 tallest people overall - without grouping this is simply finding the top five across all characters
df %>% 
  arrange(desc(height)) %>% 
  slice_head(n=5)

# Here's another way to accomplish the same thing (note that slice_max/slice_min allow ties)
df %>% 
  slice_max(height, n = 5)

# vs. shortest 2 of each species. 
# When doing these operations withing the grouping, we get very different results. You can play around a bit
# with the ordering of the piped commands to make sure you get a feel for what is going on.
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
# This is a simply example, but it groups first by homeworld, then within each homeworld it groups by gender
df %>% 
  group_by(homeworld,gender) %>% 
  summarize(count = n())



# Grouping, then ungrouping, then grouping again:
# find average mass for each sex, but only for the tallest of each species.
# Again, a very contrived example, but understanding what's happening here will be a good way for you 
# to convince yourself that you've got a good handle on the idea of grouping.
df %>% 
  group_by(species) %>% 
  slice_max(height) %>% 
  ungroup() %>% 
  group_by(sex) %>% 
  summarize(avg_mass = mean(mass, na.rm = T))
  


