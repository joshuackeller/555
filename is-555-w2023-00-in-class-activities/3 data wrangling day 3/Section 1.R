library(tidyverse)

## Joining and Binding
# install.packages('nycflights13')
library(nycflights13)
df_flights <- flights
df_airlines <- airlines
df_planes <- planes

df_flights %>% glimpse
df_flights %>% count(origin)
df_flights %>% count(dest)

# Join in carrier names
flights2 <- flights %>% 
  select(year:day, hour, origin, dest, tailnum, carrier)

alternative_name <- df_airlines %>% rename(car_code = carrier)

flights2 %>% 
  left_join(alternative_name %>% rename(carrier = car_code))

flights2 %>% 
  left_join(alternative_name, by = c('carrier' = 'car_code'))

flights2


left_join(flights2, df_airlines)

airlines_bad %>% distinct(car_code)

flights2 %>% 
  left_join(airlines_bad, by = c('carrier' = 'car_code'))


airlines_bad %>% distinct()

df_flights
df_airlines
df_planes

# What is the average "birth year" of planes associated with delayed departures among flights to Atlanta?
df_flights %>% 
  left_join(df_planes %>% select(tailnum, year) %>% rename(mfctr_year = year)) %>% 
  # filter(!is.na(type)) %>% 
  glimpse

df_flights %>% 
  left_join(df_planes %>% select(tailnum, year), by = 'tailnum', suffix = c('_flight','_mfctr')) %>% 
  # filter(!is.na(type)) %>% 
  glimpse

df_planes %>% 
  distinct(tailnum, year) %>% 
  
  glimpse

df_planes %>% 
  distinct(tailnum)
df_planes %>% 
  distinct(year)

df_planes %>% arrange(year)








# Watch for exploding data, also keys don't often match...
# airlines_bad





# Binding data - stacking chunks with bind_rows()
flights_half1
flights_half2
flights_half3 <- flights_half2 %>% rename(month_num = month)

bind_rows(flights_half1,flights_half3) %>% 
  slice_tail(n = 20) %>% 
  glimpse()





