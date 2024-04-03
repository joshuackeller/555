library(tidyverse)

# Person 1: Edit this section ---------------------------------------------------------------------------

data_raw <- read_csv('https://www.dropbox.com/s/7skk5ynuu7pj6iy/nyc_data_raw.csv?dl=1')

data_clean_names <- data_raw %>% 
  janitor::clean_names()

# Person 2: Edit this section ---------------------------------------------------------------------------
library(lubridate)

data_clean_2 <- data_clean_names %>% 
  mutate(sale_date = mdy(sale_date)) %>% 
  mutate(year = year(sale_date)) %>% 
  mutate(quarter = quarter(sale_date)) %>% 
  mutate(month = month(sale_date)) %>% 
  mutate(building_class_cat_num = str_remove(building_class_cat_num ,"category no:"))


# Person 3: Edit this section ---------------------------------------------------------------------------

categories_raw <- read_csv('https://www.dropbox.com/s/hpqf73n41cgxewg/nyc_data_bldg_cats.csv?dl=1')

categories_clean <- categories_raw %>%
  janitor::clean_names()

clean_with_categories <- data_clean_2 %>%
  left_join(categories_clean, by = c("building_class_cat_num" = "category_number")) %>%
  arrange(sale_date)


# Person 4: Edit this section ---------------------------------------------------------------------------

quarterly_summary <- clean_with_categories %>% 
  group_by(neighborhood, year, quarter) %>% 
  summarize(
    count_of_sales = n(),
    mean_sale_price = mean(sale_price)
  ) %>% 
  pivot_longer(cols = c(count_of_sales, mean_sale_price),
               names_to = 'measure',
               values_to = 'value')
