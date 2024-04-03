library(tidymodels)
# install.packages('ranger')

data(ames)
housing <- ames %>% janitor::clean_names()
housing %>% glimpse

set.seed(42)
housing_split <- initial_split(housing, strata = sale_price)

housing_training <- housing_split %>% training()
housing_testing <- housing_split %>% testing()

housing_training %>% 
  glimpse

# Build feature engineering pipeline
housing_rec <- recipe(sale_price ~ .,
                      data = housing_training) %>% 
  step_corr(all_numeric_predictors(), threshold = 0.85) %>% 
  step_nzv(all_predictors()) %>% 
  step_YeoJohnson(all_numeric_predictors()) %>% 
  step_normalize(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors())

housing_rf_model <- rand_forest() %>% 
  set_engine('ranger') %>% 
  set_mode('regression')

# show_engines('rand_forest')

# create a reusable workflow

housing_wkfl <- workflow() %>% 
  add_model(housing_rf_model) %>% 
  add_recipe(housing_rec)



# First, just do an overall shortcut to fit/evaluate

single_result <- housing_wkfl %>% 
  last_fit(split = housing_split)

single_result %>% collect_metrics()
single_result %>% collect_predictions()

# Now some k-fold validation
set.seed(42)
housing_folds <- vfold_cv(housing_training, v = 10, strata = sale_price)


cv_results <- housing_wkfl %>% 
  fit_resamples(resamples = housing_folds)



cv_results %>% collect_metrics()
cv_results %>% collect_metrics(summarize = F)

# Use collect_metrics with and without summarization

# Now let's specify a new model where trees and min_n are tuned as hyperparameters

housing_rf_tunable <- rand_forest(
  trees = tune(),
  min_n = tune()
) %>% 
  set_engine('ranger') %>% 
  set_mode('regression')


# We could redefine a workflow from scratch OR we could re-use our 
# previous workflow and just swap out the model specification.
tunable_wkfl <- workflow() %>% 
  add_model(housing_rf_tunable) %>% 
  add_recipe(housing_rec)

tunable_wkfl <- housing_wkfl %>% 
  update_model(housing_rf_tunable)

# now let's setup a grid of possible parameters to iterate through.
set.seed(42)
tuning_grid <- grid_random(parameters(tunable_wkfl),
            size = 5)

# Now we can use our tuning workflow to test out those combinations
set.seed(42)
tuning_results <- tunable_wkfl %>% 
  tune_grid(resamples = housing_folds,
            grid = tuning_grid)


# we use collect_metrics, with and withouth grouping/summarization, to get a feel for 
# how robust the model is, then show_best() and select_best() to help us choose
tuning_results %>% collect_metrics()
tuning_results %>% collect_metrics(summarize = F)


tuning_results %>% show_best()
tuning_results %>% show_best(metric = 'rsq')
best_parameters <- tuning_results %>% select_best()

# That best setup can be passed to finalize_workflow() to setup a final workflow to finish our pipeline
finalized_wkfl <- tunable_wkfl %>% 
  finalize_workflow(best_parameters)



# Now we use last_fit()
final_fit <- finalized_wkfl %>% 
  last_fit(split = housing_split)

final_fit %>% collect_metrics()
final_fit %>% collect_predictions()

