
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

# filter to NA payment methods
df %>% 
  filter(is.na(paid))

# We have done some string-base filtering with exact matches, like so:
df %>% 
  filter(amt_sold == '18 kg')

# But str_detect() is much more flexible as it performs a flexible string search (including with complex regex)
# filter to "berry" 
# then either "berry" or "peppers"
df %>% 
  filter(str_detect(fruit_desc, 'berry'))

# You could do a simple OR in the filter:
df %>% 
  filter(str_detect(fruit_desc, 'berry') | str_detect(fruit_desc, 'peppers'))

# But note that all these str_ functions also support regex:
df %>% 
  filter(str_detect(fruit_desc, 'berry|peppers'))




# Hypothetical: Payments are either credit or debit. 
# Clean up that column...because NAs are maybe supposed to be 'debit'
# One approach (which is wrong):
df %>% 
  mutate(paid_c = if_else(is.na(paid) | paid == 'Dbt', 'debit', 'credit'))

# We can see that it's wrong by using a count to look at the before and after...
df %>% 
  mutate(paid_c = if_else(is.na(paid) | paid == 'Dbt', 'debit', 'credit')) %>% 
  count(paid, paid_c)

# So the paid column has a few Dbt values. One way to account for that would be to test for CCard, which means
# that the Dbt values will be assigned appropriately. The catch is that when the column is NA, the result is
# also empty. So we can add a replace_na() to take care of that:
df %>% 
  mutate(paid_c = if_else(paid == 'CCard', 'credit', 'debit')) %>% 
  mutate(paid_c = replace_na(paid_c, 'debit')) %>% 
  count(paid, paid_c)

# The complement to replace_na() is na_if, which will convert certain values to NA if we think they should be.
na_if()



# Convert tax_per to a numeric
# numeric means either integer or double
# can use as.numeric, but that will only work with the parsing is easy.
# parse_number is much more flexible and is pretty good at getting numbers out of character strings:
df %>% 
  mutate(tax_per_c = as.numeric(tax_per)) %>% 
  mutate(price_per_c = parse_number(price_per)) 

# Parsing the amt_sold column obviously removes the units, which we should preserve. A better columns would 
# be one that was all the same unit. One strategy to get there:
df %>% 
  mutate(units = if_else(str_detect(amt_sold, 'lbs'), 'lbs', 'kg')) %>% 
  mutate(amt_sold_c = parse_number(amt_sold)) %>% 
  mutate(amt_sold_lbs = if_else(units == 'lbs', amt_sold_c, amt_sold_c * 2.2))


# Separate is a much nicer approach when you have a column like this with lots of very nice structure. 
# In this case, the column has a number and unit separated by a space. We can exploit that structure like so:
df %>% 
  separate(amt_sold, into = c('amt_sold_c', 'units'), sep = ' ', remove = F) %>% 
  mutate(amt_sold_c = parse_number(amt_sold_c))

# Note that separate can also convert to numbers as an option:
df %>% 
  separate(amt_sold, into = c('amt_sold_c', 'units'), sep = ' ', remove = F, convert = T)

# Just to demonstrate how the "into" parameter works, here's us doing something that one should never need
# to do with a date column, but it shows how all three columns are pulled from the one date column, as 
# separated by the `/` symbol:
df %>%   
    separate(best_by_date, into = c('month','day', 'year'), sep = '/', remove = F)


# Convert some dates...which lets you do stuff. LOTS of stuff.
# Then check which fruit were sold before the best_by
library(lubridate)
df %>% 
  mutate(best_by_date = mdy(best_by_date),
         sold_date = mdy_hms(sold_date)) %>% 
  mutate(day = day(sold_date),
         month = month(sold_date),
         hour = hour(sold_date)) %>% 
  mutate(bad_fruit = best_by_date - as_date(sold_date)) %>% 
  mutate(day_diff_as_number = as.numeric(bad_fruit))



# clean up the desc column. This seems like a job for:
# str_replace(), str_extract(), str_remove()

df %>% 
  mutate(price_per_c = str_remove(price_per, '\\$ ')) %>% 
  mutate(category = str_extract(fruit_desc, 'berry|peppers|other')) %>% 
  mutate(fruit_desc_c = str_replace(fruit_desc, '--', ',')) %>% 
  separate(fruit_desc_c, into = c('category','fruit'), sep = ',')



