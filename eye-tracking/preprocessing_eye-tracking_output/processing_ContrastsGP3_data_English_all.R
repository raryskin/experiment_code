# processing eye-tracking data from Gazepoint eye-tracker

library(tidyverse)
library(stringi)
#library(here)

#setwd("~/Dropbox (MIT)/ONGOING_PROJECTS/tsimane/eye-tracking/contrasts_experiment/scripts")

# Port information
port1 = c(0, 0, 960, 540)
port2 = c(960, 20, 1920, 540)
port3 = c(0, 540, 960, 1080)
port4 = c(960, 540, 1920, 1080)

# Read in audio onset information
#onset_data<-bind_rows(read_csv('../onsets_wav.csv'), read_csv('../onsets_mp3.csv'))
onset_data<-read_csv('../contrasts_experiment/EnglishOnsets.csv')

# Read in GAZEPOINT OUTPUT DATA
read_subject_etdata = function(filename){
  data = read_tsv(filename) %>% 
    mutate(subject = filename) %>% 
    separate(subject, into = c('expt','subname','block','rand'),sep = '_')
  return(data)
}


data_folder = "../ETdata/EnglishData/Subject Data"
et_data_files = list.files(data_folder,pattern = '*.txt',full.names = TRUE) 

# Files that shouldn't be included:
et_data_files = et_data_files[et_data_files != "../ETdata/EnglishData/Subject Data/contrasts_eng01_b1_38.txt"] 
et_data_files = et_data_files[et_data_files != "../ETdata/EnglishData/Subject Data/contrasts_eng29_b1_4.txt"] 
et_data_files = et_data_files[et_data_files != "../ETdata/EnglishData/Subject Data/contrasts_eng58_b2_16.txt"] 
et_data_files = et_data_files[et_data_files != "../ETdata/EnglishData/Subject Data/contrasts_eng59_b2_58.txt"] 
# these are extra files of duplicate eye-tracking data (or from restarting)

et_data<-map_dfr(et_data_files,read_subject_etdata)

# Read in CLICK OUTPUT DATA
read_subject_clickdata = function(filename){
  data = read_csv(filename,col_types = 'iiccccccccciiiiii') %>% 
    mutate(subject = filename) %>% 
    separate(subject, into = c('expt','subname','block','rand'),sep = '_')
  return(data)
}

trial_info_output_files = list.files(data_folder,pattern = '*.csv',full.names = TRUE) 
trial_info_output_data<-map_dfr(trial_info_output_files,read_subject_clickdata) %>% 
  mutate(clickLoc = case_when(
    ResponseX > port1[1] & ResponseX < port1[3] & ResponseY > port1[2] & ResponseY < port1[4] ~ 1,
    ResponseX > port2[1] & ResponseX < port2[3] & ResponseY > port2[2] & ResponseY < port2[4] ~ 2,
    ResponseX > port3[1] & ResponseX < port3[3] & ResponseY > port3[2] & ResponseY < port3[4] ~ 3,
    ResponseX > port4[1] & ResponseX < port4[3] & ResponseY > port4[2] & ResponseY < port4[4] ~ 4),
    Accuracy = if_else(clickLoc == TargetLoc,1,0)
  ) 
  

# separate out trial information
messages<-et_data %>% filter(DATATYPE == 'MSG') 

summ_message = messages %>% 
  group_by(subname,block) %>% 
  summarize(n_stim_messages = sum(str_detect(LPOGX,'STIM')),
            prop_lost = 1-n_stim_messages/60)


summary_of_stim_messages = summ_message %>% 
  mutate(subj = as.numeric(str_remove(subname,'eng')))
fivenum(summary_of_stim_messages$prop_lost)
#[1] 0.00000000 0.00000000 0.00000000 0.00000000 0.08333333




# audio stim onsets
trial_onset_info = messages %>% 
  filter(str_detect(LPOGX,'STIM')) %>% 
  select(TIME,LPOGX,subname) %>% 
  mutate(audio_onset_in_ms = TIME*1000) 

# join samples and onsets
samples_rel_time<-et_data %>% 
  filter(DATATYPE == 'SMP') %>% 
  filter( str_detect(USER,'STIM') | str_detect(USER,'START') ) %>% 
  #separate(USER,into = c('stimuli','subject', 'trialid', 'other'),sep = '_', extra = 'merge') %>% 
  left_join(trial_onset_info, by = c('subname' = 'subname','USER'='LPOGX')) %>% 
  mutate(time_in_ms = TIME.x*1000,
         trialorder = readr::parse_number(USER, na = "NA")) %>% 
  #separate(USER, into = c('USER','trialorder')) %>% 
  mutate(trialorder = as.numeric(trialorder),
         subject = as.numeric(str_remove(subname,'eng'))) %>% 
  left_join(trial_info_output_data,by = c('subject' = 'Subject','trialorder'='trialOrder')) %>% 
  mutate(filename = str_remove(Audio,'.mp3')) %>% 
  left_join(onset_data, by = c('filename'='name') ) %>% 
  mutate(time_rel_adj_onset = time_in_ms - (audio_onset_in_ms + adj___xmin) ,
         time_rel_noun_onset = time_in_ms - (audio_onset_in_ms + noun___xmin) ) %>% 
  select(subject,CNT,time_in_ms,BPOGX,BPOGY,BPOGV,subname.x,block.x,rand.x,audio_onset_in_ms,adj___xmin, noun___xmin, time_rel_adj_onset,time_rel_noun_onset,trialorder,trialType,trialID,Condition,TargetLoc,ContrastLoc,CompetLoc, DistractLoc,Accuracy)

#samples_rel_time %>% group_by(subject) %>% summarise(n())->s2bysubj

write_csv(samples_rel_time,'../processed_data/eye-tracking_data_raw_timelocked_English_allsubj.csv')

validity_per_subject_per_block = samples_rel_time %>% 
  group_by(subject,block.x,rand.x) %>% 
  mutate(not_NA = if_else(!is.na(BPOGX) & !is.na(BPOGY),1,0),
         not_zeros = if_else(BPOGX != 0 & BPOGY != 0 ,1,0),
         reg_values = if_else(not_NA == 1 & not_zeros == 1 ,1,0)) %>% 
  summarise(cnt_samples = n(), 
            prop_valid = sum(BPOGV)/cnt_samples,
            prop_not_NA = sum(not_NA)/cnt_samples,
            prop_not_zeros = sum(not_zeros)/cnt_samples,
            prop_reg_values = sum(reg_values)/cnt_samples) %>% 
  left_join(summary_of_stim_messages, by=c('subject' = 'subj','block.x' = 'block')) %>% 
  mutate(keep = if_else(prop_valid > 0.5 & prop_reg_values > 0.9 & prop_lost < 0.5, 1,0))
            
good_blocks<-validity_per_subject_per_block[validity_per_subject_per_block$keep == 1,]

write_csv(validity_per_subject_per_block,'../processed_data/eye-tracking_English_allsubj_data_validity_checks.csv')

