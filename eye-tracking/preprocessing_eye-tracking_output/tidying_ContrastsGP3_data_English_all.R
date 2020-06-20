# cleaning and tidying eye-tracking data from Contrasts experiment

library(tidyverse)
library(stringi)

#setwd("~/Dropbox (MIT)/tsimane/eye-tracking/contrasts_experiment/scripts")

samples_rel_time<-read_csv('../processed_data/eye-tracking_data_raw_timelocked_English_allsubj.csv')

# categorize samples 
samples_categorized <- samples_rel_time %>% 
  filter(BPOGV == 1 & !str_detect(trialType,'filler') ) %>% 
  mutate(gaze_x = BPOGX*1920,
         gaze_y = BPOGY*1080,
         gaze_location = case_when(
           gaze_x > port1[1] & gaze_x < port1[3] & gaze_y > port1[2] & gaze_y < port1[4] ~ 'port1',
           gaze_x > port2[1] & gaze_x < port2[3] & gaze_y > port2[2] & gaze_y < port2[4] ~ 'port2',
           gaze_x > port3[1] & gaze_x < port3[3] & gaze_y > port3[2] & gaze_y < port3[4] ~ 'port3',
           gaze_x > port4[1] & gaze_x < port4[3] & gaze_y > port4[2] & gaze_y < port4[4] ~ 'port4'
         )) %>% 
  #select(subject,trialnum,trialid,time_in_ms,time_rel_adj_onset,time_rel_noun_onset, gaze_x,gaze_y,gaze_location) %>% 
  #left_join(trial_display_info, by = c(c('subject' = 'subject','trialnum'='trialnum'))) %>% 
  mutate(gaze_location_category = case_when(
    gaze_location == str_c('port',TargetLoc) ~ 'TargetLook',
    gaze_location == str_c('port',ContrastLoc)  ~ 'ContrastLook',
    gaze_location == str_c('port',CompetLoc)  ~ 'CompetLook',
    gaze_location == str_c('port',DistractLoc)  ~ 'DistractLook'
  ),
  TargetLooks = if_else(gaze_location_category == 'TargetLook',1,0),
  ContrastLooks = if_else(gaze_location_category == 'ContrastLook',1,0),
  CompetLooks = if_else(gaze_location_category == 'CompetLook',1,0),
  DistractLooks = if_else(gaze_location_category == 'DistractLook',1,0)) 


## CLEANING

validity_per_subject_per_block <- read_csv('../processed_data/eye-tracking_English_allsubj_data_validity_checks.csv')

# Tossing:
# Incorrect trials
# Subjects with accuracy < 80%
# Blocks with valid samples < 50%
# Blocks with dropped STIM Messages > 50%
# Samples with eye-tracker error where there are 0s in BPOGX and BPOGY

good_samples_categorized <- samples_categorized %>% 
  left_join(validity_per_subject_per_block, by = c('subject'='subject', 'block.x' = 'block.x')) %>% 
  filter(keep ==1) %>% 
  group_by(subject) %>% 
  mutate(subjAcc = mean(Accuracy,na.rm=TRUE)) %>% 
  filter(Accuracy == 1  & subjAcc > 0.8) 

# FORMAT FOR PLOTTING

fiftyMSbins_ETdata_for_plotting <- good_samples_categorized %>% 
  mutate(time_rel_adj_onset_50ms = round(as.numeric(time_rel_adj_onset)/50)*50) %>% 
  group_by(subject,block.x, trialorder,trialType,Condition,time_rel_adj_onset_50ms,trialID) %>% 
  summarise(avgTargetLooksPerBin = mean(TargetLooks,na.rm=TRUE),
            avgContrastLooksPerBin = mean(ContrastLooks,na.rm=TRUE),
            avgCompetLooksPerBin = mean(CompetLooks,na.rm=TRUE),
            avgDistractLooksPerBin = mean(DistractLooks,na.rm=TRUE)) %>% 
  ungroup() %>% 
  mutate(binaryTargetLooks = if_else(avgTargetLooksPerBin >0,1,0),
         binaryContrastLooks = if_else(avgContrastLooksPerBin >0,1,0),
         binaryCompetLooks = if_else(avgCompetLooksPerBin >0,1,0),
         binaryDistractLooks = if_else(avgDistractLooksPerBin >0,1,0)) %>% 
  filter(time_rel_adj_onset_50ms > -500 & time_rel_adj_onset_50ms < 4000) 

write_csv(fiftyMSbins_ETdata_for_plotting,'../processed_data/categorized_eye-tracking_data_English_allsubj_for_plotting.csv')

# FORMAT FOR ANALYSIS 

tenMSbins_ETdata <- good_samples_categorized %>% 
  #sample_n(1000) %>% 
  mutate(time_rel_adj_onset_10ms = round(as.numeric(time_rel_adj_onset)/10)*10) %>% 
  group_by(subject,block.x, trialorder,trialType,Condition,time_rel_adj_onset_10ms,trialID) %>% 
  summarise(avgTargetLooksPerBin = mean(TargetLooks,na.rm=TRUE),
            avgContrastLooksPerBin = mean(ContrastLooks,na.rm=TRUE),
            avgCompetLooksPerBin = mean(CompetLooks,na.rm=TRUE),
            avgDistractLooksPerBin = mean(DistractLooks,na.rm=TRUE)) %>% 
  ungroup() %>% 
  mutate(binaryTargetLooks = if_else(avgTargetLooksPerBin >0,1,0),
         binaryContrastLooks = if_else(avgContrastLooksPerBin >0,1,0),
         binaryCompetLooks = if_else(avgCompetLooksPerBin >0,1,0),
         binaryDistractLooks = if_else(avgDistractLooksPerBin >0,1,0)) %>% 
  group_by(subject,trialID) %>% 
  mutate(
         AR1_target = dplyr::lag(binaryTargetLooks, n = 1, order_by = time_rel_adj_onset_10ms),
         AR1_compet = dplyr::lag(binaryCompetLooks, n = 1, order_by = time_rel_adj_onset_10ms)) %>% 
    filter(time_rel_adj_onset_10ms >= -200 & time_rel_adj_onset_10ms <= 1700)

write_csv(tenMSbins_ETdata ,'../processed_data/categorized_eye-tracking_data_English_allsubs.csv')

