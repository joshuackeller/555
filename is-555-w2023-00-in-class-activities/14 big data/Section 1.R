# install/load packages
if (!requireNamespace("arrow", quietly = TRUE)) {
  install.packages("arrow")
}
library(tidyverse)
library(tidymodels)
library(arrow)
library(lubridate)

# "open" the dataset. 
# (Note that this doesn't read the data into memory)
dataset_path <- "~/Desktop/nyc_uber"
uber_data <- open_dataset(dataset_path, format = "parquet")

# Most of the main dplyr commands still work:
uber_data %>% 
  glimpse()

# Okay let's pull a few summarized views without destroying our computers:
uber_data %>% 
  filter(!is.na(PULocationID) & !is.na(DOLocationID)) %>%
  mutate(pickup_hour = hour(pickup_datetime)) %>%
  group_by(pickup_hour) %>%
  summarise(
    avg_trip_duration = median(trip_time, na.rm = TRUE),
    num_trips = n()
  ) %>%
  arrange(desc(num_trips)) %>% 
  collect()


uber_data %>% 
  filter(!is.na(PULocationID) & !is.na(DOLocationID) & !is.na(hour)) %>%
  select(trip_miles, driver_pay, hour, congestion_surcharge,tolls, driver_pay, trip_miles,) %>% 
  group_by(hour) %>% 
  summarize(mean_congestion_surcharge = mean(congestion_surcharge, na.rm = T),
            mean_trip_miles = mean(trip_miles, na.rm = T),
            mean_driver_pay = mean(driver_pay, na.rm = T),
            tolls = mean(tolls, na.rm = T),
            driver_pay = mean(driver_pay, na.rm = T),
            trip_miles = mean(trip_miles, na.rm = T)) %>% 
  arrange(hour) %>% 
  collect() %>% 
  print(n = 24)

# What else can you see with this data? Do some ggplot exploration to 
# explore any interesting trends









# Model Example -----------------------------------------------------------------------------------------

uber_data_sample <- uber_data %>%
  filter(!is.na(PULocationID) & !is.na(DOLocationID)) %>%
  mutate(
    pickup_hour = hour(pickup_datetime),
    pickup_delay_sec = difftime(pickup_datetime, request_datetime, units = "secs")
  ) %>%
  select(pickup_delay_sec, sales_tax, pickup_hour, trip_miles, congestion_surcharge, tips) %>%
  slice_sample(n = 100000) %>%
  collect()

model_data <- uber_data_sample %>% 
  mutate(pickup_delay_min = as.numeric(pickup_delay_sec)/60) %>% 
  mutate(tip = as.factor(if_else(tips > 0, 1, 0))) %>% 
  select(-pickup_delay_sec, -tips)

model_data %>% count(tip)

uber_split <- initial_split(model_data, strata = tip)
uber_training <- uber_split %>% training()
uber_folds <- vfold_cv(uber_training, strata = tip)

uber_rec <- recipe(tip ~ ., data = uber_training) %>% 
  step_corr(all_numeric_predictors()) %>% 
  step_normalize(all_numeric_predictors())

uber_xgb <- boost_tree() %>% 
  set_engine('xgboost') %>% 
  set_mode('classification')

uber_wkfl <- workflow() %>% 
  add_recipe(uber_rec) %>% 
  add_model(uber_xgb)

cv_results <- uber_wkfl %>% fit_resamples(resamples = uber_folds)

overall_results <- uber_wkfl %>% last_fit(split = uber_split)

cv_results %>% collect_metrics()
overall_results %>% collect_metrics()


