library(tidyverse)

## Joining and Binding
# install.packages('nycflights13')
library(nycflights13)
df_flights <- flights
df_airlines <- airlines
df_planes <- planes


df_flights %>% glimpse

# Note the differences between these two airport columns... that's relevant for the assignment
df_flights %>% count(origin)
df_flights %>% count(dest)

# Get a smaller set of columns that will be easier to see
flights2 <- df_flights %>% 
  select(year:day, hour, origin, dest, tailnum, carrier)

# Join in carrier names, hopefully specifying the key explicitly to avoid surprises
flights2 %>% 
  left_join(df_airlines, by = 'carrier')

# Just an example for when the keys aren't identical:
alternative_name <- df_airlines %>% rename(car_code = carrier)

flights2 %>% 
  left_join(alternative_name, by = c('carrier' = 'car_code'))

# This is a silly dataset with duplication to explore what happens in a left_join 
# when there is duplication in the right side of the join:
airlines_bad <- airlines %>% slice(1:8) %>% bind_rows(airlines) %>% rename(car_code = carrier)

# Scary!
flights2 %>% 
  left_join(airlines_bad, by = c('carrier' = 'car_code'))

# A few things to explore why:
airlines_bad %>% 
  count(car_code)

# This is an arbitrary way to fix duplication, but it's not usually a good idea because you don't know
# what rows will be thrown away why it removes duplication on the `car_code` column.
airlines_bad %>% 
  distinct(car_code, .keep_all = T)





# Just a reminder of the datasets we have:
df_flights
df_airlines
df_planes

# This is a mostly useless question, but we used it to illustrate what happens when naming conflicts occur 
# during a join.
# 
# What is the average "birth year" of planes associated with delayed departures among flights to Atlanta?

# Joining the data to get the "birth year" in creates unexpected results with the two year columns. 
# Notice the mostly empty columns from the `df_planes` tibble... this is because the join is attempting
# to join on both tailnum and year, and the years mean different things
df_flights %>% 
  left_join(df_planes) %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()

# Here's one strategy: just rename the right-side year on the fly to something useful. Name conflict solved.
df_flights %>% 
  left_join(df_planes %>% select(tailnum, year) %>% rename(mfctr_year = year), by = 'tailnum') %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()

# Or you could do it as a separate operation... with more lines of code :(
fixed_planes <- df_planes %>% select(tailnum, year) %>% rename(mfctr_year = year)

df_flights %>% 
  left_join(fixed_planes, by = 'tailnum') %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()

# Finally, the suffix parameter lets you pass an automatic "label" for each side that gets appended in any 
# case where there is a naming conflict.
df_flights %>% 
  left_join(df_planes %>% select(tailnum, year), by = 'tailnum', suffix = c("_flight", "_mfctr")) %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()



# Binding data - stacking chunks with bind_rows()

# I'm just manually splitting this data into two tibbles with the same columns and two chunks of the full data:

flights_half1 <- flights %>% 
  slice(1:199388)

flights_half2 <- flights %>% 
  slice(199389:336776)

flights_half1
flights_half2



# I usually like to use bind rows outside a pipe because it can take any number of tibble as parameters, and
# that can get confusing in a piped scenario. (I'm obviously piping it after the bind_rows so we can see what
# it looks like after.)
bind_rows(flights_half1, flights_half2) %>% 
  glimpse




# Let's just assume that one of the halves has a column naming issue:
flights_half3 <- flights_half2 %>% rename(month_num = month)

# In this case, the bind rows will stack what it can match, but it'll tack the non-matching column
# over on the right side, and it'll be empty on the top half
bind_rows(flights_half1, flights_half3) %>% 
  glimpse


# Notice also that on the bottom half of the result, the emptyness is swapped. Now the month_num has values 
# but the month column does not:
bind_rows(flights_half1, flights_half3) %>% 
  slice_tail(n=20) %>% 
  glimpse
