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


alternative_name <- df_airlines %>% rename(car_code = carrier)

# Join in carrier names
flights2 <- df_flights %>% 
  select(year:day, hour, origin, dest, tailnum, carrier)

flights2 %>% 
  left_join(df_airlines, by = 'carrier')

flights2 %>% 
  left_join(alternative_name, by = c('carrier' = 'car_code'))


airlines_bad <- airlines %>% slice(1:8) %>% bind_rows(airlines) %>% rename(car_code = carrier)

flights2 %>% 
  left_join(airlines_bad, by = c('carrier' = 'car_code'))

airlines_bad %>% 
  count(car_code)

airlines_bad %>% 
  distinct(car_code, .keep_all = T)


left_join(flights2, df_airlines)









df_flights
df_airlines
df_planes

# What is the average "birth year" of planes associated with delayed departures among flights to Atlanta?

fixed_planes <- df_planes %>% select(tailnum, year) %>% rename(mfctr_year = year)

df_flights %>% 
  left_join(df_planes %>% select(tailnum, year) %>% rename(mfctr_year = year), by = 'tailnum') %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()

df_flights %>% 
  left_join(df_planes %>% select(tailnum, year), by = 'tailnum', suffix = c("_flight", "_mfctr")) %>% 
  # filter(!is.na(engine)) %>% 
  glimpse()


df_planes %>% 
  filter(year == 2013)






# Watch for exploding data, also keys don't often match...
# airlines_bad





# Binding data - stacking chunks with bind_rows()
flights_half1
flights_half2

flights_half3 <- flights_half2 %>% rename(month_num = month)


bind_rows(flights_half1, flights_half3) %>% 
  slice_tail(n=20) %>% 
  glimpse





