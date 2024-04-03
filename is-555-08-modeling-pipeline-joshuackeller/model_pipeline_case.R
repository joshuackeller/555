library(tidyverse)
library(tidymodels)
library(doParallel)


# 1. wine, wine_split, wine_training, wine_testing
wine_raw <- read_csv('https://www.dropbox.com/s/osrr5dk1k7phwwb/winequality.csv?dl=1') 
set.seed(42)

wine <- wine_raw %>% select(-id)

wine_split <- initial_split(wine, strata = quality)

wine_training <- wine_split %>% training()
wine_testing <- wine_split %>% testing()


# 2. wine_rec, wine_rec_prep, wine_training_baked, wine_testing_baked

wine_rec <- recipe(quality ~ .,
                   data = wine_training) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_YeoJohnson(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(type)


wine_rec_prep <- wine_rec %>% prep(training = wine_training)

wine_training_baked <- wine_rec_prep %>% bake(new_data = wine_training)
wine_testing_baked <- wine_rec_prep %>% bake(new_data = wine_testing)


# 3. wine_lm, wine_lm_fit
wine_lm <- linear_reg() %>% 
  set_engine("lm") %>% 
  set_mode("regression")

wine_lm_fit <- wine_lm %>% 
  fit(quality ~ .,
      data = wine_training_baked)

wine_lm_fit %>% tidy()


# 4. wine_pred, wine_testing_results, wine_performance, plot_1

wine_pred <- wine_lm_fit %>% 
  predict(new_data = wine_testing_baked)

wine_testing_results <- wine_testing %>% 
  bind_cols(wine_pred) 


wine_performance <- wine_testing_results %>% 
  rmse(
    truth = quality,
    estimate = .pred
  ) %>% 
  bind_rows(
    wine_testing_results %>% 
      rsq(
        truth = quality,
        estimate = .pred
      )
  )

plot_1 <- wine_testing_results %>% 
  ggplot(aes(x = quality, y = .pred, color = type)) +
  geom_point() +
  facet_wrap(~type) + 
  labs(x = "Actual Quality", y = "Predicted Quality") +
  theme_bw()

plot_1


# 5. air_split, air_training, air_testing 
air <- read_csv('https://www.dropbox.com/s/1sh4b85y52hrvwx/airlines.csv?dl=1') %>% 
  mutate(satisfied = as.factor(satisfied))
set.seed(42)


### Maybe add strata here? 
air_split <- initial_split(air, strata = satisfied)

air_training <- air_split %>% training()
air_testing <- air_split %>% testing()


# 6. air_rec_corr, air_rec_pca

air_rec_corr <- recipe(satisfied ~ .,
       data = air_training) %>% 
  step_impute_mean(all_numeric_predictors()) %>% 
  step_YeoJohnson(all_numeric_predictors()) %>% 
  step_normalize(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_nzv(all_predictors()) %>% 
  step_corr(all_numeric_predictors(), threshold = .85)

air_rec_pca <- recipe(satisfied ~ .,
       data = air_training) %>% 
  step_impute_mean(all_numeric_predictors()) %>% 
  step_YeoJohnson(all_numeric_predictors()) %>% 
  step_normalize(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_nzv(all_predictors()) %>% 
  step_pca(all_predictors())
  

# air_rec_prep_corr <- air_rec_corr %>% prep(training = air_training)
# air_rec_prep_pca <- air_rec_pca %>% prep(training = air_training)
# 
# air_rec_prep_corr %>% 
#   bake(new_data = air_training)
# 
# air_rec_prep_pca %>% 
#   bake(new_data = air_training)


# 7. lr_model, xgb_model

lr_model <- logistic_reg()

xgb_model <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")

# 8. lr_corr_wkfl, lr_pca_wkfl, xgb_corr_wkfl, xgb_pca_wkfl

lr_corr_wkfl <- workflow() %>% 
  add_model(lr_model) %>% 
  add_recipe(air_rec_corr)
  
lr_pca_wkfl <- workflow() %>% 
  add_model(lr_model) %>% 
  add_recipe(air_rec_pca)

xgb_corr_wkfl <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(air_rec_corr)

xgb_pca_wkfl <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(air_rec_pca)


# 9. lr_corr_fit, lr_pca_fit, xgb_corr_fit, xgb_pca_fit, air_models_compared
set.seed(42)

lr_corr_fit <- lr_corr_wkfl %>% 
  last_fit(split = air_split)

lr_pca_fit <- lr_pca_wkfl %>% 
  last_fit(split = air_split)

xgb_corr_fit <- xgb_corr_wkfl %>% 
  last_fit(split = air_split)

xgb_pca_fit <- xgb_pca_wkfl %>% 
  last_fit(split = air_split)


air_models_compared <- lr_corr_fit %>% collect_metrics() %>% 
  mutate(model = "lr_corr") %>% 
  bind_rows(
    lr_pca_fit %>% collect_metrics() %>% mutate(model = "lr_pca")) %>% 
  bind_rows(
    xgb_corr_fit %>% collect_metrics() %>% mutate(model = "xgb_corr")) %>% 
  bind_rows(
    xgb_pca_fit %>% collect_metrics() %>% mutate(model = "xgb_pca")) %>% 
  arrange(.metric, desc(.estimate))

air_models_compared


# 10. air_folds, cv_fit, cv_perf_summary
set.seed(42)

air_folds <- vfold_cv(air_training, v = 10, repeats = 3, strata = satisfied)

cv_fit <- xgb_corr_wkfl %>% 
  fit_resamples(resamples = air_folds)

cv_perf_summary <- cv_fit %>% collect_metrics(summarize = F) %>% 
  group_by(.metric) %>% 
  summarize(
    minimum = min(.estimate),
    mean = mean(.estimate),
    maximum = max(.estimate)
  )

cv_perf_summary

# 11. All of the rest...
lc <- read_csv('https://www.dropbox.com/s/yqjek9ve4z6lbw5/lc.csv?dl=1') %>% 
  mutate(loan_default = as.factor(loan_default))

# lc_split, lc_training, lc_testing

set.seed(42)
lc_split <- initial_split(lc)
lc_training <- lc_split %>% training()
lc_testing <- lc_split %>% testing()


# lc_rec: the (single-step) recipe
lc_rec <- recipe(
  loan_default ~ .,
  data = lc_training
  ) %>% 
  step_dummy(all_nominal_predictors())
  

# xgb_model_default: xgboost model spec with default parameters
xgb_model_default <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")

# lc_xgb_wkfl: workflow comprised of lc_rec and xgb_model_default
lc_xgb_wkfl <- workflow() %>% 
  add_model(xgb_model_default) %>% 
  add_recipe(lc_rec)

# lc_folds: the 10-fold cross-validation object
set.seed(42)
lc_folds <- vfold_cv(lc_training, v = 10, strata = loan_default)


# lc_default_fit: the fit of the 10-fold cross-validation using the default workflow

lc_default_fit <- lc_xgb_wkfl %>% 
  fit_resamples(resamples = lc_folds)

lc_default_fit %>% collect_metrics()
  
# xgb_model_tuning: a different xgboost model spec with tunable parameters
xgb_model_tuning <- boost_tree(
  min_n = tune(),
  # tree_depth = tune(),
  # learn_rate = tune(),
  # loss_reduction = tune(),
  # sample_size = tune(),
  stop_iter = tune()
  ) %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")

# lc_xgb_tune_wkfl: a different workflow that bundles lc_rec and xgb_model_tuning
lc_xgb_tune_wkfl <- workflow() %>% 
  add_model(xgb_model_tuning) %>% 
  add_recipe(lc_rec)

# lc_grid: the tuning grid (again, I would keep this sized to 10 or so unless you have lots of breathing room). You can use grid_random() to generate this, but there are others out there as well.
set.seed(42)
lc_grid <- grid_random(parameters(lc_xgb_tune_wkfl), size = 10)

# tune_fit: The result of the grid search (i.e., tune_grid())
# start <- proc.time()
# 
# set.seed(42)
# tune_fit <- lc_xgb_tune_wkfl %>% 
#   tune_grid(resamples = lc_folds,
#             grid = lc_grid)
# 
# end <- proc.time()
# total_time <- end - start
# print(total_time)

cl <- makeCluster(detectCores() - 1)
# Register cluster: 
registerDoParallel(cl)

start <- proc.time()

set.seed(42)
tune_fit <- lc_xgb_tune_wkfl %>% 
  tune_grid(resamples = lc_folds,
            grid = lc_grid)

end <- proc.time()
total_time <- end - start
print(total_time)

stopCluster(cl)

unregister_dopar <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}

unregister_dopar()

tune_fit %>% show_best(metric = "roc_auc")

# best_parameters: the best-performing parameter set from your grid search
best_parameters <- tune_fit %>% select_best(metric = "roc_auc")
best_parameters

# final_lc_wkfl: a final modeling workflow, derived from applying those best_parameters to the lc_xgb_tune_wkfl workflow.
final_lc_wkfl <- lc_xgb_tune_wkfl %>% 
  finalize_workflow(best_parameters)

# lc_final_fit: The end result, a deployable model object that results from finalizing the final_lc_wkfl with the lc_split object.
lc_final_fit <- final_lc_wkfl %>% 
  last_fit(split = lc_split)

lc_final_fit %>% collect_metrics()



# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.
# ls() %>% sort  

expected_object_names <- c(
  "air",                  "air_folds",            "air_models_compared", 
  "air_rec_corr",         "air_rec_pca",          "air_split",           
  "air_testing",          "air_training",         "best_parameters",     
  "cv_fit",               "cv_perf_summary",      "final_lc_wkfl",       
  "lc",                   "lc_default_fit",       "lc_final_fit",        
  "lc_folds",             "lc_grid",              "lc_rec",              
  "lc_split",             "lc_testing",           "lc_training",         
  "lc_xgb_tune_wkfl",     "lc_xgb_wkfl",          "lr_corr_fit",         
  "lr_corr_wkfl",         "lr_model",             "lr_pca_fit",          
  "lr_pca_wkfl",          "plot_1",               "tune_fit",            
  "wine",                 "wine_lm",              "wine_lm_fit",         
  "wine_performance",     "wine_pred",            "wine_raw",            
  "wine_rec",             "wine_rec_prep",        "wine_split",          
  "wine_testing",         "wine_testing_baked",   "wine_testing_results",
  "wine_training",        "wine_training_baked",  "xgb_corr_fit",        
  "xgb_corr_wkfl",        "xgb_model",            "xgb_model_default",   
  "xgb_model_tuning",     "xgb_pca_fit",          "xgb_pca_wkfl")

in_mem <- lapply(mget(expected_object_names), colnames)
in_mem[!unlist(lapply(in_mem,is.null))] %>%
  enframe() %>%
  unnest(value) %>%
  rename(tibble = name,
         colname = value) %>%
  write_csv('expected_cols.csv')


# Tests
expected_object_names_result <- sum(ls() %in% expected_object_names) == length(expected_object_names)

expected_cols <- read_csv('expected_cols.csv', show_col_types=F) 

if(!expected_object_names_result){
  error_content <- paste(expected_object_names[!expected_object_names %in% ls()], collapse = ',')
  stop(paste("Expected objects not found in the environment:",error_content))
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
  message('All naming tests passed. But did you restart your session and run your WHOLE script from beginning to end with no errors??')
} else {
  message("Uh oh. Couldn't find the column(s) below:")
  found_cols %>% 
    filter(is.na(was_found)) %>% 
    select(-was_found) %>% 
    print()
}

