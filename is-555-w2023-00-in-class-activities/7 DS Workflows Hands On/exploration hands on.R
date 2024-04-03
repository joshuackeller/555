library(tidyverse)

df1 <- read_csv('https://www.dropbox.com/s/df2w04r0c09kw3f/df_1.csv?dl=1')
df2 <- read_csv('https://www.dropbox.com/s/xfp1qzxvo19ym0x/df_2.csv?dl=1')
df3 <- read_csv('https://www.dropbox.com/s/uzusr9723ffn546/df_3.csv?dl=1')
df4 <- read_csv('https://www.dropbox.com/s/js8tehtsk7btpeq/df_4.csv?dl=1')

df1 %>% summarize_all(list(mean=mean, sd=sd))
df2 %>% summarize_all(list(mean=mean, sd=sd))
df3 %>% summarize_all(list(mean=mean, sd=sd))
df4 %>% summarize_all(list(mean=mean, sd=sd))

df1 %>% summary() 
df2 %>% summary() 
df3 %>% summary() 
df4 %>% summary() 

df1 %>% cor()
df2 %>% cor()
df3 %>% cor()
df4 %>% cor()





df1 %>% summarize_all(list(mean=mean, sd=sd))

# correlation matrix:
df1 %>% cor()

# simple regression analysis:
lm(y ~ x, data = df1) %>% coefficients()
