
# Function Summary --------------------------------------------------------------------------------------

# NOTE: I've linked directly to the documentation for most of these functions right in the schedule item for
#       today, with individualized, separate links. (See the "Resources" item.) 
# 
# USEFUL LOGICAL OPERATORS:
# is.na()             <-- checks for missing/NA
# str_detect()        <-- checks for string match (incl. regex)

# CONDITIONAL:
# if_else()           <-- basic conditional

# FORMAT CHANGES:
# as.numeric()        <-- convert to a number (can also use as.integer or as.double)
# parse_number()      <-- smarter number conversion, tries to ignore non-number characters

# DATE FORMATTERS: 
# [all from the `lubridate` package - there are many more]
# 
# as_date()           <-- basic date converter, but not very smart
# mdy()               <-- attempts "smart pattern" date conversion based on a general pattern
# mdy_hms()           <-- attempts "smart pattern" date conversion based on a general pattern

# OTHER MUTATORS (Mutants?):
# 
# [date subtraction]  <-- most dates can be subtracted with basic operators
# 
# str_remove()        <-- removes a matching substring from string (incl. regex)
# str_extract()       <-- extracts a matching substring from string (incl. regex)
# str_replace()       <-- replaces a matching substring with a replacement (incl. regex)


# Sample Code -------------------------------------------------------------------------------------------
library(tidyverse)

df <- read_csv('https://bit.ly/ugly_fruit_555', col_types = 'ccccccc')

# filter to NA paid methods
df %>% 
  filter(is.na(paid))

df %>% 
  filter(fruit_desc == 'other,avocado')



# filter to "berry" 
# then either "berry" or "peppers
df %>% 
  filter(str_detect(fruit_desc, 'berry|peppers'))




# Hypothetical: Payments are either credit or debit. 
# Clean up that column
df %>% 
  mutate(paid_c = if_else(is.na(paid), 'debit', 
                          if_else(paid == 'Dbt', 'debit','credit'))) %>% 
  count(paid, paid_c)

df %>% 
  mutate(paid_c = if_else(is.na(paid) | paid == 'Dbt', 'debit', 'credit')) %>% 
  count(paid, paid_c)

df %>% 
  mutate(paid_c = if_else(paid != 'CCard', 'debit', 'credit')) %>% 
  mutate(paid_c = replace_na(paid_c, 'debit')) %>% 
  count(paid, paid_c)
  replace_na()



# Did we get them all? Good clean conversion? 
# count 'em




# BE DEFENSIVE
# Now let's fix it: 





# Convert tax_per to a numeric
# numeric means either integer or double
# can use as.numeric
df %>% 
  mutate(tax_per_c = as.numeric(tax_per)) %>%
  mutate(price_per_c = parse_number(price_per))
  




# Let's try it with price_per...
# Use parse_number instead.





# parse_number with amt_sold?
df %>%
  mutate(units = if_else(str_detect(amt_sold, 'kg'), 'kg', 'lbs')) %>% 
  mutate(amt_sold_c = parse_number(amt_sold)) %>% 
  mutate(amt_sold_lbs = if_else(units == 'kg', amt_sold_c * 2.2, amt_sold_c))

df %>% 
  separate(amt_sold, into = c('amt_sold_c','units'), sep = ' ', remove = F, convert = T) %>% 
  mutate(amt_sold_lbs = if_else(units == 'kg', amt_sold_c * 2.2, amt_sold_c))






# Convert some dates...which lets you do stuff
# Then check which fruit were sold before the best_by
library(lubridate)

df %>% 
  mutate(best_by_date_c = mdy(best_by_date),
         sold_date_c = mdy_hms(sold_date)) 

df %>% 
  mutate(best_by_date = mdy(best_by_date),
         sold_date = mdy_hms(sold_date)) %>% 
  mutate(bad_fruit = as_date(sold_date) - best_by_date)


# clean up the desc column.
df %>% 
  mutate(price_per_c = str_remove(price_per, '\\$ '))

df %>% 
  mutate(units = str_extract(amt_sold, 'lbs|kg')) %>% 
  mutate(category = str_extract(fruit_desc, 'other|berry'))

df %>% 
  mutate(fruit_desc_c = str_replace(fruit_desc, '--', ',')) %>% 
  separate()
  






