# Function Summary --------------------------------------------------------------------------------------

# NOTE: I've linked directly to the documentation for these functions right in the schedule item for
#       today, with individualized, separate links. (See the "Resources" item.) 
# 
# JUST TWO FUNCTIONS:
# 
# I'm going to narrate the two functions with their parameters as a new way to help...?
# 
# pivot_longer(
#   data,                             <-- The incoming tibble, usually comes in via a pipe
#   *cols,                             <-- This is where you say which columns you're pulling down to long format
#                                           (any that you don't name here are assumed to be "id columns" that 
#                                           will repeat with eachof the variables being converted to long format)
#   *names_to = "name",                <-- This is the column name that will "house" the column names that you have 
#                                           specified in the `cols` parameter. Often you can just leave this as the 
#                                           default and it will name it "name", but you can also be more descriptive
#   names_prefix = NULL,              <-- You can (optionally) indicate a text-based prefix to auto-remove as the
#                                           function is pulling the columns down. So for columns like `year1`, `year2`,
#                                           you could specify "year" as the prefix and the function would remove it.
#   names_sep = NULL,                 <-- beyond our scope - explore this on your own if you want. 
#   names_pattern = NULL,             <-- beyond our scope - explore this on your own if you want.
#   names_ptypes = NULL,              <-- beyond our scope - explore this on your own if you want.
#   names_transform = NULL,           <-- beyond our scope - explore this on your own if you want.
#   names_repair = "check_unique",    <-- beyond our scope - explore this on your own if you want.
#   *values_to = "value",              <-- this is the column that will "house" the values corresponding to each of 
#                                           the column name labels in the `names_to` column that you specified above.
#   values_drop_na = FALSE,           <-- wider data is often "sparse", meaning that it has lots of nulls when not all
#                                           rows have a value for each wide column. It's usually efficient to filter 
#                                           those out when pivoting longer, so this is an option for convenience.
#   values_ptypes = NULL,             <-- beyond our scope - explore this on your own if you want.
#   values_transform = NULL,          <-- beyond our scope - explore this on your own if you want.
# )
# 
# 
# pivot_wider(                        
#   data,                             <-- The incoming tibble, usually comes in via a pipe
#   id_cols = NULL,                   <-- "id columns" are the ones that you DON'T want to spread out as wide
#                                           columns, but you can usually ignore this parameter because you will
#                                           be explicitly specifying the `names_from` and `values_from` parameters
#   id_expand = FALSE,                <-- beyond our scope - explore this on your own if you want.
#   **names_from = name,                <-- Here you specify the column that contains the value names or "labels"
#                                           (it defaults to `name` because that's the default from `pivot_longer()`)
#   names_prefix = "",                <-- beyond our scope - explore this on your own if you want.
#   names_sep = "_",                  <-- beyond our scope - explore this on your own if you want.
#   names_glue = NULL,                <-- beyond our scope - explore this on your own if you want.
#   names_sort = FALSE,               <-- beyond our scope - explore this on your own if you want.
#   names_vary = "fastest",           <-- beyond our scope - explore this on your own if you want.
#   names_expand = FALSE,             <-- beyond our scope - explore this on your own if you want.
#   names_repair = "check_unique",    <-- beyond our scope - explore this on your own if you want.
#   **values_from = value,              <-- Here you specify the column that contains the values corresponding to the
#                                           names specified in the `names_from` parameter.
#                                           (it defaults to `value` because that's the default from `pivot_longer()`)
#   values_fill = NULL,               <-- This option allows you to provide the "default value" for any rows in the
#                                           wider data that don't have a value in the longer format list. (Leaving
#                                           this out will result in NAs in the wider data, which is usually fine.)
#   values_fn = NULL,                 <-- beyond our scope - explore this on your own if you want.
#   unused_fn = NULL,                 <-- beyond our scope - explore this on your own if you want.
# )

# Sample Code -------------------------------------------------------------------------------------------

library(tidyverse)


drinks <- tribble(
  ~country,  ~soda, ~tea,  ~sparkling_water,
  'China',     79,    192,     8,
  'Italy',     85,     42,   237,
  'USA',      249,     58,    84
)

# Let's make it more tidy. pivot_longer
drinks %>% 
  pivot_longer(c(soda, tea, sparkling_water),
               names_to = 'drink_type',
               values_to = 'liters_per_capita')



# New data:
gap <- read_csv('https://www.dropbox.com/s/dv1a1ldkuyoftn2/gap_smaller.csv?dl=1')

# Start with just country, year, lifeExp, pivot wider
gap %>% 
  select(country, year, lifeExp) %>% 
  pivot_wider(names_from = year,
              values_from = lifeExp)


# Now let's go the other way: pivot all three measures longer
gap %>% 
  pivot_longer(
    cols = lifeExp:gdpPercap,
    names_to = 'measure',
    values_to = 'value'
  )





# Pivot all three measures wider. Gets messy, but 
# sometimes data comes to you in this format
gap %>% 
  pivot_wider(names_from = year,
              values_from = c(lifeExp, pop, gdpPercap))

gap_wide <- gap %>% 
  pivot_wider(names_from = year,
              values_from = c(lifeExp, pop, gdpPercap))

# figure this out...
gap_wide %>% 
  pivot_longer(lifeExp_1952:gdpPercap_2007,
               names_sep = '_',
               names_to = c('year','name'))



# New data:
ri <- read_csv('https://www.dropbox.com/s/dfjgfytyek44u61/rel_inc.csv?dl=1')
bnames <- read_csv('https://www.dropbox.com/s/6bck5fy4aag76kw/baby_names.csv?dl=1')
bob <- read_csv('https://www.dropbox.com/s/mozqpceit51hia7/bob_ross.csv?dl=1')

# see if you can pivot the religious income data into a tidier format
# show only the top income BRACKET (>150k) for each religion
ri %>% 
  pivot_longer(cols = !religion,
               names_to = 'income_bracket',
               values_to = 'household_count') %>% 
  filter(income_bracket == ">150k")
  
ri %>% select(`<$10k`:`Don't know/refused`)
# see if you can widen the baby names into a format with one row per name (and sex)
bnames

# make the bob ross data tidier, then:
# episodes that depict some sort of "frame"
# next, show the episodes that depict some sort of "frame" but not any bridges
# count the episodes with paintings that contain "MOUNTAIN" that depict objects containing the string "tree" 
this <- bob %>% 
  pivot_longer(apple_frame:wood_framed,
               names_to = 'item',
               values_to = 'is_present') %>% 
  filter(
    (str_detect(item, 'frame') & is_present == 1) |
      (item == 'bridge' & is_present == 0)) %>% 
  distinct(episode)
  
bob %>% distinct(episode) %>% 
  filter(!episode %in% this$episode)

bob %>% filter(episode == 'S03E06') %>% 
  select(contains('frame'), bridge) %>% 
  glimpse

bob %>% 
  select(episode, contains('frame'), bridge)
  