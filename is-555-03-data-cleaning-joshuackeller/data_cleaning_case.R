# Intro / Setup -----------------------------------------------------------------------------------------

# First let's load the tidyverse package:
library(tidyverse)

# NOTE:      For the last assignment, we had you use the `setwd()` command and then comment that command out
#            before submitting your assignment. We also had you create a local `data/` directory and read the
#            assignment data from there. For this assignment (and actually the next several), neither of those
#            will be required. You can just read the file straight from the web using the code below.

# Read the data in from the csv file using the `read_csv()` function. 
# The variable name for the resulting tibble should be `rentals_raw`.
rentals_raw <- read_csv('https://www.dropbox.com/s/cnbc9bztrfu3ifw/brazil_rentals.csv?dl=1')

# Have a look just to get a feel for the data:
rentals_raw
rentals_raw %>% glimpse

#1 sq_meters_fixed
sq_meters_fixed <- rentals_raw %>% 
  mutate(sq_meters_c = parse_double(str_remove(sq_meters, "_m2")))


#2 property_type_fixed
rentals_raw %>% 
  separate(property_type, c("prefix","type"), ":") %>% 
  count(prefix)

property_type_fixed <- rentals_raw %>% 
  mutate(
    property_type_c = if_else(
      !str_detect(str_remove(property_type, "listingType:"), "apartment|house"), "store", str_remove(property_type, "listingType:")
      )
  ) 


#3 listing_price_fixed
listing_price_fixed <- rentals_raw %>% 
  separate(listing_price, c("price","currency"), " ") %>% 
  mutate(price = parse_double(price)) %>% 
  mutate(listing_price_usd = if_else(currency == "BRL", price / 5.2, price))


#4 floors_rooms_fixed
floors_rooms_fixed <- rentals_raw %>% 
  separate(floor_numRooms, c("floor","rooms"), ", ") %>% 
  mutate(floor_num = parse_integer(str_remove(floor, "st floor|nd floor|rd floor|th floor"))) %>% 
  mutate(room_count = parse_integer(str_remove(rooms, " rooms| room")))


#5 districts_extracted
districts_extracted <- rentals_raw %>% 
  separate(place_with_parent_names, c("delete","country","state","city","district","alsoDelete"), sep="\\|") %>% 
  select(-c(delete, alsoDelete)) %>% 
  mutate(ten_districts_name = if_else(district %in% c("Barra da Tijuca", "Jardim Goiás", "Jardim Paulista", "Moema", "Morumbi", "Panamby", "Perdizes", "Pinheiros", "Recreio dos Bandeirantes", "Vila Suzana"), district, "NA")) %>% 
  mutate(ten_districts_name = na_if(ten_districts_name, "NA")) %>% 
  mutate(common_district_1 = if_else(is.na(ten_districts_name), 0, if_else(ten_districts_name == "Barra da Tijuca", 1, 0))) %>% 
  mutate(common_district_2 = if_else(is.na(ten_districts_name), 0,if_else(ten_districts_name == "Pinheiros", 1, 0))) %>% 
  mutate(common_district_3 = if_else(is.na(ten_districts_name), 0,if_else(ten_districts_name == "Morumbi", 1, 0)))

  
#6 date_listed_converted
library(lubridate)

date_listed_converted <- rentals_raw %>% 
  mutate(date_listed_c = parse_date_time(date_listed, c("%d/%m/%Y", "%d/%m/%Y HMS"))) 


#7 date_listed_converted2

date_listed_converted2 <- date_listed_converted %>% 
  mutate(
    date_listed_fixed = if_else(date_listed_c >= ymd_hms("2100-01-01 00:00:00"), 
                                date_listed_c - years(100),
                                date_listed_c
                                )
      ) 



# Finalize, Commit, Push --------------------------------------------------------------------------------

# BEFORE YOU COMMIT AND PUSH YOUR SUBMISSION
#
# Please make sure you to do the following before you submit this assignment:
# 1. If you used the `setwd()` command near the beginning of the script, please COMMENT OUT that line before 
#    committing and pushing your code. 
# 2. The list of objects below is what I have in memory after writing this case assignment. Any of those objects 
#    are fair game for the grading procedure to evaluate. You may want to clear your R session (Session -> Restart R) 
#    and then check the list against what you have in memory after running your script from the beginning.
#    
#    Hint: you can see what's in your environment by executing the following code:
#    ls() %>% tibble() %>% print(n=30)
# 
#    1  date_listed_converted
#    2  date_listed_converted2
#    3  districts_extracted
#    4  floors_rooms_fixed
#    5  listing_price_fixed
#    6  property_type_fixed
#    7  rentals_raw
#    8  sq_meters_fixed
