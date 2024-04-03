
library(tidyverse)

df <- starwars

df
# (starwars tibble is always present when the tidyverse is loaded)
# Glimpse turns a data frame on its side. Super useful.
df %>% 
  glimpse()

# iteratively add operations: 
# height > 100, sex == female, choose name, height, mass, species, films, 
# mass > 50, arrange by mass
# note: columns can contain lists; more on that later
# note: filtering on some logical excludes NAs
df %>% 
  filter(height > 100,
         sex == 'female') %>% 
  select(name, height, mass, species, films) %>% 
  arrange(desc(mass)) %>% 
  filter(mass>50 | mass<49)

df %>% count(homeworld)

df %>% 
  filter(homeworld == 'Alderaan' | 
         homeworld == 'Bespin' | 
           homeworld == 'Cerea')


the_ones_I_want <- c('Alderaan', 'Bespin', 'Cerea')

  
df %>% 
  filter(homeworld %in% c('Alderaan', 'Bespin', 'Cerea'))
  


# calculate a new column,weight_lbs = mass * 2.204623
# Make sure it gets saved to the tibble...
df %>% 
  mutate(weight_lbs = mass * 2.204) %>% 
  mutate(is_large = ifelse(mass > 100, 1,0)) %>% 
  glimpse

  df

# group and summarize. Pay attention to NAs
# get a count and mean mass by species



# why does Chagrian have a weird NaN?


# top 5 tallest overall - using slice_head


# or just using slice_max


# what is the shortest character for each species? 




# ALso summarize isn't always the goal what if we want a relative 
# comparison of height for each species? I.e., are you tall for a human?
# calculate tallest for each species without summarizing, convert to percentile, show a few of the columns, sort





# Grouping by multiple
# Was is the average birth year for each gender from each homeworld




# Grouping, then ungrouping, then grouping again:
# find average mass for each sex, but only for the tallest of each species.




# Other useful things to play with ----------------------------------------------------------------------

# Sometimes it's useful to pull a set of values out into a vector for
# use later in some filtering logic. 
# Example: we want to do a bunch of checks or logic with just humans from Tatooine.
tatooine_humans <- starwars %>% 
  filter(homeworld == 'Tatooine',
         species == 'Human') %>%
  pull(name)
# I'll often do this when cleaning data, sometimes to denote a subset of the data that
# I want to check later or that needs cleaning, or that I want to piece together with
# another set of data down the line.
starwars %>% count(homeworld) %>% View()

# Vectors like these are especially useful in filtering functions and can help you
# avoid a big chain of ifelse() statements. Here's a few (silly) examples:

# filter to homewors that start with s (this is much simpler than a bunch of ifelse()'s)
starwars %>% 
  filter(homeworld %in% c("Stewjon", "Socorro", "Sullust", "Serenno", "Skako", "Shili"))

# assign a binary flag for "is this character at risk for sunburn" under the basic assumption
# that humans on the desert planet will all eventually get sunburned.
starwars %>% 
  mutate(sunburn_risk = ifelse(name %in% tatooine_humans, 1, 0))