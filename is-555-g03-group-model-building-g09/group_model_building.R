library(tidyverse)
library(tidymodels)
tidymodels_prefer()

# Install these packages if you need to:
library(tidypredict)
library(yaml)
library(fs)

# And for the first time this semester, it's going to be quite important that you properly set your
# working directory to the correct folder containing this assignment's repository:
# setwd('/Users/joshuakeller/Repos/555/is-555-g03-group-model-building-g09')

# 0. Data Familiarity / Exploration / Cleaning

library(tidyverse)

# Read in the data
fraud1 <- read_csv('https://www.dropbox.com/s/w0qqbuxe5lnclrs/fraud_transaction_training.csv?dl=1')
fraud2 <- read_csv('https://www.dropbox.com/s/oe6u04o5b5wmpp0/fraud_identity_training.csv?dl=1')

# Clean the names right from the start
fraud1_clean <- fraud1 %>% 
  janitor::clean_names()

fraud2_clean <- fraud2 %>% 
  janitor::clean_names()

# Take a look at the data
#fraud1_clean %>% glimpse
#fraud2_clean %>% glimpse

# Join data together
fraud_joined <- left_join(
  fraud1_clean,
  fraud2_clean,
  by = c('transaction_id' = 'transaction_id')
)

fraud_joined %>% 
  count(is_fraud)

fraud_joined %>% 
  filter(is_fraud == 1) %>% 
  summarise(total = sum(transaction_amt))

# Slice the data to make it smaller
fraud_small <- fraud_joined %>% slice_sample(prop = .1)

# Don't select the transaction_id column
fraud_no_id <- fraud_small %>% 
  select(-transaction_id)

# Calculate the percentage of missing values for each column
missing_percentages <- tibble(
  column = names(fraud_no_id),
  missing_percent = sapply(fraud_no_id, function(col) {
    sum(is.na(col)) / length(col) * 100
  })
) %>% arrange(desc(missing_percent))

#missing_percentages %>% glimpse()

# Identify the columns with over 80% missing values
cols_to_remove <- missing_percentages$column[missing_percentages$missing_percent > 80]

# Remove the identified columns from the dataset
fraud_no_id <- fraud_no_id[, !names(fraud_no_id) %in% cols_to_remove]

#fraud_no_id %>% glimpse

# Select only the columns that we have an idea of what they are and rename columns to better understand and change billing.... to a character and is_fraud to a factor
fraud_red <- fraud_no_id %>% 
  select(is_fraud, transaction_amt, product_cd, card4, card6, addr2, r_emaildomain, p_emaildomain, id_31, device_type) %>% 
  rename(card_issuer = card4, deb_cred = card6, billing_ctry_num = addr2, operating_sys_browser = id_31) %>% 
  mutate(is_fraud = as.factor(is_fraud), billing_ctry_num = as.character(billing_ctry_num))
  #mutate(billing_ctry_num = as.factor(billing_ctry_num), is_fraud = as.factor(is_fraud))

# Convert all characters to factors to fix modeling errors
#fraud_red <- fraud_red %>% mutate_if(is.character,as.factor)

#fraud_red %>% count(operating_sys_browser) %>% arrange(desc(n))

# For billing ctry code, do top 5 values + NA
fraud_red <- fraud_red %>% 
  mutate(billing_ctry_num = if_else((billing_ctry_num %in% head(unique(na.omit(billing_ctry_num[billing_ctry_num != ""])), 5) | is.na(billing_ctry_num)), as.character(billing_ctry_num), "Other")) 

# For r_emaildomain, do top 8
fraud_red <- fraud_red %>% 
  mutate(r_emaildomain = if_else((r_emaildomain %in% head(unique(na.omit(r_emaildomain[r_emaildomain != ""])), 8) | is.na(r_emaildomain)), as.character(r_emaildomain), "Other")) 

# For p_emaildomain, do top 6
fraud_red <- fraud_red %>% 
  mutate(p_emaildomain = if_else((p_emaildomain %in% head(unique(na.omit(p_emaildomain[p_emaildomain != ""])), 8) | is.na(p_emaildomain)), as.character(p_emaildomain), "Other")) 

# For operating_sys_browser, do top 10
fraud_red <- fraud_red %>% 
  mutate(operating_sys_browser = if_else((operating_sys_browser %in% head(unique(na.omit(operating_sys_browser[operating_sys_browser != ""])), 8) | is.na(operating_sys_browser)), as.character(operating_sys_browser), "Other")) 

fraud_red <- fraud_red %>% mutate_if(is.character,as.factor)

# (No code required here other than reading in your dataset, but please follow the  
#     recommendations in this section of the assignment instructions.)

# 1. Train/Test Split
set.seed(42)

# Split the data
data_split <- initial_split(fraud_red, strata = is_fraud)

# Training data
data_training <- data_split %>% training()

# Testing data
data_testing <- data_split %>% testing()


# 2. Feature Engineering Recipes
# Recipe 1: 
# Impute mean for the only numeric column
# Normalize the numeric column
# Dummy code the 4 columns that don't have a whole lot of values
recipe_1 <- recipe(is_fraud ~ ., data = data_training) %>% 
  step_impute_mode(all_nominal_predictors()) %>% 
  step_impute_mean(all_numeric_predictors()) %>% 
  step_normalize(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors()) 

# Recipe 2: 
# Impute median for the only numeric column
# Step Yeo-Johnson transformation to the numeric column
# Normalize the numeric column -- using step_scale this time
# Dummy code the 2 columns relating to the card used
recipe_2 <- recipe(is_fraud ~ ., data = data_training) %>% 
  step_impute_mode(all_nominal_predictors()) %>% 
  step_impute_median(all_numeric_predictors()) %>% 
  step_YeoJohnson(all_numeric_predictors()) %>% 
  step_scale(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors()) 
  

# 3. Model Algorithm Specifications
# Model specs with random forest: Great starting point for binary classification and good with large numbers of categorical features.
model_spec_1 <- rand_forest() %>% 
  set_engine('ranger') %>% 
  set_mode('classification')

model_spec_2  <- rand_forest() %>% 
  set_engine('randomForest') %>% 
  set_mode('classification')

# Model spec with logistic regression: Great starting point and is simple -- good for binary classification
model_spec_3 <- logistic_reg() %>% 
  set_engine('glm') %>% 
  set_mode('classification')

#4. Workflow Objects
r1_m1_wkfl <- workflow() %>% 
  add_model(model_spec_1) %>% 
  add_recipe(recipe_1)

r1_m2_wkfl <- workflow() %>% 
  add_model(model_spec_2) %>% 
  add_recipe(recipe_1)

r1_m3_wkfl <- workflow() %>% 
  add_model(model_spec_3) %>% 
  add_recipe(recipe_1)

r2_m1_wkfl <- workflow() %>% 
  add_model(model_spec_1) %>% 
  add_recipe(recipe_2)

r2_m2_wkfl <- workflow() %>% 
  add_model(model_spec_2) %>% 
  add_recipe(recipe_2)

r2_m3_wkfl <- workflow() %>% 
  add_model(model_spec_3) %>% 
  add_recipe(recipe_2)


# 5. Initial Cross-Validated Results
set.seed(42)

# Create data_folds using vfolds_cv()
data_folds <- vfold_cv(data_training, v = 10, repeats = 3, strata = is_fraud)

# Create a custom set of evaluation metrics using metric_set(). I chose random ones, we can discuss which ones we want to use later
custom_metrics <- metric_set(roc_auc, pr_auc, precision)

# Fit each workflow to the cross-validation dataset


library(doParallel)

#### start of cluster
starttime <- Sys.time()
cl <- makeCluster(7)
registerDoParallel(cl)

r1_m1_fit <- r1_m1_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)

r1_m2_fit <- r1_m2_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)

r1_m3_fit <- r1_m3_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)
  
r2_m1_fit <- r2_m1_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)

r2_m2_fit <- r2_m2_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)

r2_m3_fit <- r2_m3_wkfl %>% 
  fit_resamples(resamples = data_folds, metrics = custom_metrics)

stopCluster(cl)
Sys.time() - starttime
#### end of cluster


# Collect metrics
r1_m1_fit_metrics <- r1_m1_fit %>% collect_metrics() %>% mutate(workflow_name = 'r1_m1_wkfl', algorithm_name = 'random forest', engine_name = 'ranger')
r1_m2_fit_metrics <- r1_m2_fit %>% collect_metrics() %>% mutate(workflow_name = 'r1_m2_wkfl', algorithm_name = 'random forest', engine_name = 'random forest')  
r1_m3_fit_metrics <- r1_m3_fit %>% collect_metrics() %>% mutate(workflow_name = 'r1_m3_wkfl', algorithm_name = 'logistic regression', engine_name = 'glm')

r2_m1_fit_metrics <- r2_m1_fit %>% collect_metrics() %>% mutate(workflow_name = 'r2_m1_wkfl', algorithm_name = 'random forest', engine_name = 'ranger')
r2_m2_fit_metrics <- r2_m2_fit %>% collect_metrics() %>% mutate(workflow_name = 'r2_m2_wkfl', algorithm_name = 'random forest', engine_name = 'random forest')
r2_m3_fit_metrics <- r2_m3_fit %>% collect_metrics() %>% mutate(workflow_name = 'r2_m3_wkfl', algorithm_name = 'logistic regression', engine_name = 'glm')

# Build summary table
workflow_perf_summary <- bind_rows(r1_m1_fit_metrics, r1_m2_fit_metrics, r1_m3_fit_metrics,
                                   r2_m1_fit_metrics, r2_m2_fit_metrics, r2_m3_fit_metrics) #%>% arrange(.metric, desc(.estimate))


workflow_perf_summary 


# 6 Promising Algorithm (Workflow) Selection 
best_initial_workflow_fit <- r1_m1_fit

# 7 Hyperparameter Tuning
set.seed(42)

model_spec_tunable <- rand_forest(
  min_n = tune()
) %>% 
  set_engine('ranger') %>% 
  set_mode('classification')

## option here to make a new recipe to improve the model
tunable_wkfl <- workflow() %>% 
  add_model(model_spec_tunable) %>% 
  add_recipe(recipe_1)


set.seed(42)
tuning_grid <- grid_random(parameters(tunable_wkfl), size = 10)


## Used only if tuning mtry 
# params_with_mtry_tune <- model_spec_tunable %>%
#   parameters() %>%
#   finalize(x = data_training %>% select(-is_fraud))
# set.seed(42)
# tuning_grid <- grid_random(params_with_mtry_tune, size = 10)


#### start of cluster
starttime <- Sys.time()
cl <- makeCluster(7)
registerDoParallel(cl)

tunable_fit <- tunable_wkfl %>% 
  tune_grid(resamples = data_folds,
            grid = tuning_grid,
            metrics = custom_metrics)

stopCluster(cl)
Sys.time() - starttime
#### end of cluster

tunable_fit %>% collect_metrics() %>% 
  arrange(.metric, desc(mean)) %>% 
  print(n = 27)


# 8. Finalize your Model
set.seed(42)

tunable_fit %>% show_best(metric = "precision")

best_parameters <- tunable_fit %>% select_best("precision")

finalized_wkfl <- tunable_wkfl %>% 
  finalize_workflow(best_parameters)

final_fit <- finalized_wkfl %>% 
  last_fit(split = data_split, metrics = custom_metrics)

# 9. Summarize Model Performance

best_initial_workflow_fit %>% collect_metrics() %>% filter(.metric == "precision") 
final_fit %>% collect_metrics() %>% filter(.metric == "precision")

test_results <- final_fit %>% collect_predictions()
write_csv(test_results, "test_set_results.csv")

test_results %>% 
  filter(.pred_class == 1)


#graph
library(ggplot2)
library(dplyr)

perf_plot <- test_results %>% 
  roc_curve(truth = is_fraud, .pred_0) %>% 
  autoplot()

perf_plot %>% ggsave('perf_plot.png', plot = ., 
                     device = 'png', width = 14, height = 9)
  

# 10. Prep for Deployment

final_fit <- finalized_wkfl %>% 
  last_fit(split = data_split, metrics = custom_metrics)

trained_workflow <- extract_workflow(final_fit)
model_object <- extract_fit_parsnip(final_fit)



final_fit %>% write_rds('final_fit.rds')
trained_workflow %>% write_rds('trained_workflow.rds')
model_object %>% write_rds('model_object.rds')

fraud_red %>% 
  count(is_fraud)

#for testing RDS worked properly 
# read_rds("./final_fit.rds")

# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.
# ls() %>% sort  

expected_object_names <- c(
  "best_initial_workflow_fit", "best_parameters",           "custom_metrics",           
  "data_folds",                "data_split",                "data_testing",             
  "data_training",             "final_fit",                 "finalized_wkfl",           
  "model_spec_1",              "model_spec_2",             
  "model_spec_3",              "model_spec_tunable",                  
  "perf_plot",                 "r1_m1_fit",                 "r1_m1_wkfl",               
  "r1_m2_fit",                 "r1_m2_wkfl",                "r1_m3_fit",                
  "r1_m3_wkfl",                "r2_m1_fit",                 "r2_m1_wkfl",               
  "r2_m2_fit",                 "r2_m2_wkfl",                "r2_m3_fit",                
  "r2_m3_wkfl",                "recipe_1",                  "recipe_2",                 
  "test_results",              "trained_workflow",         
  "tunable_fit",               "tunable_wkfl",              "tuning_grid",              
  "workflow_perf_summary"   
)

expected_files <- c(
  "final_fit.rds",         
  "perf_plot.png",
  "test_set_results.csv",  "trained_workflow.rds"  
)

in_mem <- lapply(mget(expected_object_names), colnames)
in_mem[!unlist(lapply(in_mem,is.null))] %>%
  enframe() %>%
  unnest(value) %>%
  rename(tibble = name,
         colname = value) %>%
  write_csv('expected_cols.csv')

found_files <- dir_ls(getwd()) %>% path_file()

# Tests
expected_object_names_result <- sum(ls() %in% expected_object_names) == length(expected_object_names)
found_files_result <- sum(found_files %in% expected_files) == length(expected_files)

expected_cols <- read_csv('expected_cols.csv', show_col_types=F) 

if(!expected_object_names_result){
  error_content <- paste(expected_object_names[!expected_object_names %in% ls()], collapse = ',')
  stop(paste("Expected objects not found in the environment:",error_content))
}
if(!found_files_result){
  error_content <- paste(expected_files[!expected_files %in% found_files], collapse = ',')
  stop(paste("Expected files not found in the working directory:",error_content))
}

in_mem <- lapply(mget(expected_object_names), colnames)

found_cols <- expected_cols %>% 
  left_join(in_mem[!unlist(lapply(in_mem,is.null))] %>%
              enframe() %>%
              unnest(value) %>%
              rename(tibble = name,
                     colname = value) %>% 
              mutate(was_found = 1),
            by = c("tibble" = "tibble", "colname"="colname"))

if(sum(is.na(found_cols$was_found)) == 0){
  message('All naming tests passed.')
} else {
  message("Uh oh. Couldn't find the column(s) below:")
  found_cols %>% 
    filter(is.na(was_found)) %>% 
    select(-was_found) %>% 
    print()
}
