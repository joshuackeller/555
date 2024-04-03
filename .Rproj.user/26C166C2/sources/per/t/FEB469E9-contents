library(tidyverse)

# We'll be using the following packages; install them if you haven't:
library(car)
library(ggcorrplot)


wine_raw <- read_csv('https://www.dropbox.com/s/osrr5dk1k7phwwb/winequality.csv?dl=1') 

# 1. wine
wine <- wine_raw %>% 
  mutate(quality_class = if_else(quality < 6, "1_low", 
                                 if_else(quality >= 8, "3_high", "2_med"))
  )


# 2. missingness_summary

missingness_summary <- wine %>% 
  mutate(across(everything(), as.character)) %>% 
  pivot_longer(
    cols=everything(),
    names_to="column",
    values_to="value"
  ) %>% 
  group_by(column) %>% 
  summarize(
    non_missing_count = sum(!is.na(value)),
    distinct_count = n_distinct(value),
    na_count = sum(is.na(value)),
    percent_missing = sum(is.na(value)) / n()
  ) %>% 
  arrange(desc(percent_missing))

# 3. wine_imputed
wine_imputed <- wine %>% 
  mutate(across(c(where(is.numeric), -quality), ~replace_na(.x, median(.x, na.rm = T)))) 

# 4. plot_1

plot_1 <- wine_imputed %>% 
  pivot_longer(
    cols=c(where(is.numeric), -quality),
    names_to="variable",
    values_to="value"
  ) %>% 
  ggplot(aes(x = quality_class, y = value, type = type, fill = type)) +
  geom_boxplot() +
  facet_wrap(~variable, ncol = 4, scales = "free") +
  labs(x = "Metric Value", y = "Wine Quality", title = "Boxplots across wine type and quality") +
  theme_bw()


# 5 cap_reference
cap_reference <- wine_imputed %>% 
  pivot_longer(
    cols=c(where(is.numeric), -quality),
    names_to="column",
    values_to="value"
  ) %>% 
  group_by(column) %>% 
  summarize(
    cap_95 = quantile(value, .95),
    cap_99 = quantile(value, .99)
  ) %>% 
  arrange(column)


# 6 cap_counts

cap_counts <- wine_imputed %>% 
  pivot_longer(
    cols= -c(id, type, quality, quality_class),
    names_to="column",
    values_to="value"
  ) %>% 
  left_join(
    cap_reference,
    by = join_by(column)
  ) %>% 
  mutate(
    is_out95 = if_else(value > cap_95, 1, 0),
    is_out99 = if_else(value > cap_99, 1, 0)
  ) %>% 
  group_by(column) %>% 
  summarize(
    outliers_95 = sum(is_out95),
    outliers_99 = sum(is_out99),
    perc_capped_95 = sum(is_out95) / n(),
    perc_capped_99 = sum(is_out99) / n()
  )



# 7 wine_corked
wine_corked <- wine_imputed %>% 
  mutate(across(c(where(is.numeric), -quality), ~if_else(.x > quantile(.x, .99), quantile(.x, .99), .x)))



# 8 plot_2
plot_2 <- wine_corked %>% 
  pivot_longer(
    cols=c(where(is.numeric), -quality),
    names_to="variable",
    values_to="value"
  ) %>% 
  ggplot(aes(x = quality_class, y = value, type = type, fill = type)) +
  geom_boxplot() +
  facet_wrap(~variable, ncol = 4, scales = "free") +
  labs(x = "Metric Value", y = "Wine Quality", title = "Boxplots across wine type and quality (outliers capped)") +
  theme_bw()




# 9 skewness_summary
skewness <-  function(x) {
  m3 <- mean((x - mean(x))^3)
  skewness <- m3/(sd(x)^3)
  skewness
}

skewness_summary <- wine_corked %>% 
  pivot_longer(
    cols = c(where(is.numeric), -quality),
    names_to="column",
    values_to="value"
  )  %>% 
  group_by(column) %>% 
  summarize(skewness = skewness(value)) %>% 
  arrange(desc(skewness))

# 10 wine_transformed

wine_transformed <- wine_corked %>% 
  mutate(
    chlorides = log(chlorides * 100),
    volatile_acidity = log(volatile_acidity * 100),
    sulphates = log(sulphates * 100),
    fixed_acidity = log(fixed_acidity),
    residual_sugar = log(residual_sugar)
    )


# 11 plot_3
plot_3 <- wine_transformed %>% 
  pivot_longer(
    cols=c(where(is.numeric), -quality),
    names_to="variable",
    values_to="value"
  ) %>% 
  ggplot(aes(x = quality_class, y = value, type = type, fill = type)) +
  geom_boxplot() +
  facet_wrap(~variable, ncol = 4, scales = "free") +
  labs(x = "Metric Value", y = "Wine Quality", title = "Boxplots across wine type and quality (transformed)") +
  theme_bw()


# 12 wine_scaled

wine_scaled <- wine_transformed %>% 
  mutate(across(c(where(is.numeric), -quality), ~as.numeric(scale(.x))))
 
# 13 plot_4

plot_4 <- wine_scaled %>% 
  pivot_longer(
    cols=c(where(is.numeric), -quality),
    values_to="value"
  ) %>% 
  ggplot(aes(x = quality_class, y = value, type = type, fill = type)) +
  geom_boxplot() +
  facet_wrap(~variable, ncol = 4, scales = "free") +
  labs(x = "Metric Value", y = "Wine Quality", title = "Boxplots across wine type and quality (scaled)") +
  theme_bw()


# 14 plot_5

plot_5 <- ggcorrplot(
    cor(wine_scaled %>% select(
      quality, alcohol, chlorides, citric_acid, density, fixed_acidity, free_sulfur_dioxide,
      p_h, residual_sugar, sulphates, total_sulfur_dioxide, volatile_acidity
    )),
    type = "lower",
    lab = T
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))


# 15 vif_results

vif_results <- lm(quality ~ .,
   data = wine_scaled %>% select(where(is.numeric))
  ) %>% 
  vif()


# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.

expected_object_names <- c(
  "cap_counts", "cap_reference", "missingness_summary", "plot_1", "plot_2", "plot_3", "plot_4", "plot_5", 
  "skewness_summary", "vif_results", "wine", "wine_corked", "wine_imputed", "wine_raw", "wine_scaled", 
  "wine_transformed")

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
  message('All naming tests passed. But did you restart your session and run your WHOLE script from beginnin to end??')
} else {
  message("Uh oh. Couldn't find the column(s) below:")
  found_cols %>% 
    filter(is.na(was_found)) %>% 
    select(-was_found) %>% 
    print()
}
