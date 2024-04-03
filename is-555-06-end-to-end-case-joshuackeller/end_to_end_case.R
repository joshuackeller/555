library(tidyverse)
library(lubridate)


long <- read_csv('https://www.dropbox.com/s/9luewx3rekalme9/mh_long.csv?dl=1')
wide <- read_csv('https://www.dropbox.com/s/il32xg5lrgza06m/mh_wide.csv?dl=1')


# Your Code: --------------------------------------------------------------------------------------------



######
###### Wide
######

# Remove duplicates
distinct_wide <- wide %>% 
  group_by(id) %>% 
  filter(n() != 2 | !is.na(addressLocality)) %>% 
  ungroup()

# Fill in NAs for addressLocality and postalCode
no_nas_wide <- distinct_wide %>% 
  mutate(addressLocality = if_else(id == "18ca29da-6390-4d38-bd9f-a56c1ce42f37", "Lee", 
                                   if_else(id == "21c8755a-19f0-4424-81b5-461bc756a6e9", "Allyn", addressLocality))) %>% 
  mutate(postalCode = if_else(id == "18ca29da-6390-4d38-bd9f-a56c1ce42f37", "32340", 
                                   if_else(id == "21c8755a-19f0-4424-81b5-461bc756a6e9", "98524", postalCode))) 

clean_names_wide <- no_nas_wide %>% 
  janitor::clean_names()

wide_clean <- clean_names_wide



######
###### Long
######

# Make NAs have a value of 1
remove_nas_long <- long %>% 
  mutate(value = if_else(is.na(value),"1", value))

# Get rid of duplicate key value pairs
distinct_key_values_long <- remove_nas_long %>% 
  filter(value != "Call for Price" | is.na(value)) %>% 
  group_by(id, key) %>% 
  distinct(id, key, .keep_all = T) %>% 
  ungroup()


# Pivot wider
pivoted_long <- distinct_key_values_long %>% 
  pivot_wider(
    names_from = key,
    values_from = value
  ) %>% 
  janitor::clean_names()


### FIX: Check high values for average_rent_for_park_owned_homes
# Convert price to number for price, average_mh_lot_rent, average_rent_for_park_owned_homes, average_rv_lot_rent
price_number_long <- pivoted_long %>% 
  mutate(price_usd = parse_number(price)) %>% 
  mutate(average_mh_lot_rent_usd = parse_number(average_mh_lot_rent)) %>% 
  mutate(average_rent_for_park_owned_homes_usd = parse_number(average_rent_for_park_owned_homes)) %>% 
  mutate(average_rv_lot_rent_usd = parse_number(average_rv_lot_rent))

# Remove the avg rental home prices that are too high to be realistic (all are over 300,000)
remove_bad_avg_rent_long <- price_number_long %>% 
  mutate(average_rent_for_park_owned_homes_usd = replace(average_rent_for_park_owned_homes_usd, average_rent_for_park_owned_homes_usd > 300000, NA))

# Remove the park that has a price of 1 (most likely a mistake)
remove_bad_price_long <- remove_bad_avg_rent_long %>% 
  mutate(price_usd = na_if(price_usd, 1))

# Add dummy variables for purchase columns
purchase_method_long <- remove_bad_price_long %>% 
  mutate(cash = if_else(str_detect(purchase_method, "Cash"), 1, 0)) %>% 
  mutate(seller_financing = if_else(str_detect(purchase_method, "Seller Financing"), 1, 0)) %>% 
  mutate(new_loan = if_else(str_detect(purchase_method, "New Loan"), 1, 0)) %>% 
  mutate(assumable_loan = if_else(str_detect(purchase_method, "Assumable Loan"), 1, 0)) 

# Fix dates
dates_long <- purchase_method_long %>% 
  mutate(posted_on = mdy(posted_on)) %>% 
  mutate(updated_on = mdy(updated_on))
  
# Turn characters to numbers
numbers_long <- dates_long %>% 
  mutate(number_of_mh_lots = parse_number(number_of_mh_lots)) %>% 
  mutate(singlewide_lots = parse_number(singlewide_lots)) %>% 
  mutate(number_of_park_owned_homes = parse_number(number_of_park_owned_homes)) %>% 
  mutate(doublewide_lots = parse_number(doublewide_lots)) %>% 
  mutate(number_of_rv_lots = parse_number(number_of_rv_lots)) 

# Convert percentages to value between 0 and 1
percentages_long <- numbers_long %>% 
  mutate(total_occupancy_rate = parse_number(total_occupancy) / 100) %>% 
  mutate(interest_rate = parse_number(interest_rate) / 100)

# Clean size column and convert hectares to acres
size_acres_long <- percentages_long %>% 
  mutate(size_acres = if_else(str_detect(size, "acre"), parse_number(size), parse_number(size) * 2.471)) 

# Fix year_built column and convert to number
year_built_long <- size_acres_long %>% 
  mutate(year_built = if_else(str_length(year_built) == 8, parse_number(str_sub(year_built, 1, 4)), parse_number(year_built)))

# Make year_built NA where year_built == 0
remove_bad_years <- year_built_long %>% 
  mutate(year_built = na_if(year_built, 0))

# Turn 5 variables to 1 if they were present in the original long dataset
fix_dummys_long <- remove_bad_years %>% 
  mutate(has_club_house = parse_number(replace(club_house, !is.na(club_house), 1))) %>% 
  mutate(has_handicap_accessible = parse_number(replace(handicap_accessible, !is.na(handicap_accessible), 1))) %>% 
  mutate(has_laundromat = parse_number(replace(laundromat, !is.na(laundromat), 1))) %>% 
  mutate(has_pool = parse_number(replace(pool, !is.na(pool), 1))) %>% 
  mutate(has_storage = parse_number(replace(storage, !is.na(storage), 1)))

# Remove extra columns for final dataset
remove_extra_cols_long <- fix_dummys_long %>% 
  select(-c(price, average_mh_lot_rent, average_rent_for_park_owned_homes,
            average_rv_lot_rent, size, total_occupancy, handicap_accessible,
            laundromat, pool, storage
            )) 

long_clean_pivoted <- remove_extra_cols_long



######
###### Together
######

# Join datasets
together <- wide_clean %>% 
  left_join(long_clean_pivoted)

# Add age_years
age_years_together <- together %>% 
  mutate(age_years = year(today()) - year_built)

# Calculate age_years_together
price_per_lot_together <- age_years_together %>% 
  mutate(price_per_lot_usd = price_usd / number_of_mh_lots)

together_clean <- price_per_lot_together




######
###### Plots
######

plot_1 <- together_clean %>% 
  filter(!is.na(price_usd)) %>% 
  ggplot(mapping = aes(x = price_usd)) +
  geom_density(alpha = 0.6, fill = "blue") +
  labs(x = "Price in USD", y = "Density", title = "Density Distribution of Price (USD)") +
  theme_bw()

plot_2 <- together_clean %>% 
  filter(!is.na(price_usd)) %>% 
  mutate(log_price = log(price_usd)) %>% 
  ggplot(mapping = aes(x = log_price)) +
  geom_density(alpha = 0.6, fill = "blue") +
  labs(x = "Price in USD, Log Scale", y = "Density", title = "Density Distribution of Price (USD), Log Scale") +
  theme_bw()

plot_3 <- together_clean %>% 
  filter(posted_on > ymd("2022-01-01")) %>% 
  ggplot(mapping = aes(x = posted_on)) +
  geom_histogram(bins = 30, alpha = 0.6, fill = "red") +
  labs(x = "Date Posted (30 bins)", y = "Count of Properties", title = "Property Listings over Time") +
  theme_bw()

plot_4 <- together_clean %>% 
  ggplot(mapping = aes(x = age_years)) +
  geom_histogram(bins = 30, alpha = 0.6, fill = "green") +
  labs(x = "Age (30 bins)", y = "Count of Properties", title = "Property Age in Years") +
  theme_bw()

plot_5 <- together_clean %>% 
  mutate(has_purchase_method = if_else(is.na(purchase_method), "No", "Yes")) %>% 
  ggplot(mapping = aes(x = address_region, fill = purchase_method)) +
  geom_bar() +
  facet_wrap(~has_purchase_method, ncol = 1, labeller = label_both) +
  labs(x = "US State", y = "Count", title = "Property Listings by State and Purchase Method") +
  theme_bw()

  

# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.

expected_cols_wide_clean <- c(
  'address_locality', 'address_region', 'id', 'latitude', 'longitude', 'postal_code', 
  'property_name', 'street_address'
)

expected_cols_long_clean_pivoted <- c(
  'assumable_loan', 'average_mh_lot_rent_usd', 'average_rent_for_park_owned_homes_usd', 
  'average_rv_lot_rent_usd', 'cash', 'community_type', 'debt_info', 'doublewide_lots', 
  'has_club_house', 'has_handicap_accessible', 'has_laundromat', 'has_pool', 'has_storage', 
  'id', 'interest_rate', 'new_loan', 'number_of_mh_lots', 'number_of_park_owned_homes', 
  'number_of_rv_lots', 'posted_on', 'price_usd', 'purchase_method', 'seller_financing', 
  'sewer', 'singlewide_lots', 'size_acres', 'total_occupancy_rate', 'water', 'water_paid_by', 
  'year_built'
)

expected_cols_together_clean <- c(
  'address_locality','address_region','age_years','assumable_loan','average_mh_lot_rent_usd',
  'average_rent_for_park_owned_homes_usd','average_rv_lot_rent_usd','cash','community_type',
  'debt_info','doublewide_lots','has_club_house','has_handicap_accessible','has_laundromat',
  'has_pool','has_storage','id','interest_rate','latitude','longitude','new_loan','number_of_mh_lots',
  'number_of_park_owned_homes','number_of_rv_lots','postal_code','posted_on','price_per_lot_usd',
  'price_usd','property_name','purchase_method','seller_financing','sewer','singlewide_lots','size_acres',
  'street_address','total_occupancy_rate','water','water_paid_by','year_built'
)

expected_object_names <- c('wide_clean', 'long_clean_pivoted', 'together_clean', 'plot_1', 
                           'plot_2', 'plot_3', 'plot_4', 'plot_5'
)


# Tests: All of these should return `TRUE`
expected_object_names_result <- sum(ls() %in% expected_object_names) == length(expected_object_names)

if(!expected_object_names_result){
  error_content <- paste(expected_object_names[!expected_object_names %in% ls()], collapse = ',')
  stop(paste("Expected objects not found in the environment:",error_content))
}

expected_cols_wide_clean_result <- sum(names(wide_clean) %in% expected_cols_wide_clean) == length(expected_cols_wide_clean)
expected_cols_long_clean_result <- sum(names(long_clean_pivoted) %in% expected_cols_long_clean_pivoted) == length(expected_cols_long_clean_pivoted)
expected_cols_together_clean_result <- sum(names(together_clean) %in% expected_cols_together_clean) == length(expected_cols_together_clean)


if(
  expected_object_names_result &
  expected_cols_wide_clean_result &
  expected_cols_long_clean_result &
  expected_cols_together_clean_result
){
  message('Congratulations. All naming tests passed.')
} else {
  if(!expected_cols_wide_clean_result){
    print(paste("Expected columns not found in wide_clean:"))
    print(expected_cols_wide_clean[!expected_cols_wide_clean %in% names(wide_clean)])
  }
  if(!expected_cols_long_clean_result){
    print(paste("Expected columns not found in long_clean_pivoted:"))
    print(expected_cols_long_clean_pivoted[!expected_cols_long_clean_pivoted %in% names(long_clean_pivoted)])
  }
  if(!expected_cols_together_clean_result){
    print(paste("Expected columns not found in together_clean:"))
    print(expected_cols_together_clean[!expected_cols_together_clean %in% names(together_clean)])
  }
  stop('Uh oh. One or more tests failed.')
}

