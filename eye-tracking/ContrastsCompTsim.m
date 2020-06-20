%% Contrasts experiment: visual world paradigm testing color and size adjective interpretation
%%% Intended to be run in 2 blocks. Order of trials determined during first
%%% block.
%%% Outputs a .mat file with the order of trials, a .csv file with trial
%%% info and click responses for each block, a .txt file with eye-tracking
%%% data for each block.
%%% Requires Psychtoolbox, GP3_functions from Ringo Huang
%%% (https://github.com/RingoHHuang/gazepoint-matlab-toolbox), and
%%% img_to_tex.m and read_in_audiofile.m
%%% Gazepoint Control needs to be open for eye-tracking to work.
%%%
%%% Rachel Ryskin 8/3/2018

clear all;
Screen('Preference', 'VisualDebuglevel', 3);%gets rid of graphics check screen
%rand('twister',sum(100*clock)) %resets the random number generator.
nums=rand*99;
sran=round(nums);
srand=num2str(sran);

%% Inputs
subject= input('Enter Subject Number, e.g. "06".  ', 's');
subnum=str2num(subject);

counterbalancelist = input('Enter List Number (1 or 2): ');

blocknum = input('Enter Block Number (1 or 2): ');

if blocknum == 2
    if ~exist(['output/Contrasts_pilot' subject '.mat'],'file')
        error('There is no block 1 for this participant.');
    end
end

dummy= input('Run in dummy mode? (y/n) ', 's');
if strcmp(dummy,'y')
    dum = 1;
else 
    dum = 0;
end


%% folders and output files
pics_dir = 'Stimuli/'; %The location of the picture files to be used in the experiment

audio_version = 'MP3'; % choose MP3 or WAV
sounds_dir = ['TsimaneRecordings/' audio_version '/']; %The location where the audio files are stored.

%% Generate path to GP3 subfolders
[mainDir,~,~] = fileparts(mfilename('fullpath'));
addpath(genpath(mainDir));

%% Set Screen things
%Screen('Preference','VBLTimestampingMode',-1); %This setting can be turned on if you have video driver problems.
Screen('Preference', 'SkipSyncTests', 0);%The last # should be "1" for testing mode only.

white=[255 255 255];
purple=[255 40 200];
black=[0 0 0];
green=[34 139 34];
red = [255 0 0];
gray=[3 3 3];

rect=[0 0 1920 1080];%screen size

%% Initialize Audio
InitializePsychSound;
freq = 44100; % high frequency for high-quality audio recordings.
numchannels = 2;%1- mono sound; 2- stereo
audiochannel = PsychPortAudio('Open', [], 1, 1, freq, numchannels, 120); 

%% Open a graphics window on the main screen using the PsychToolbox's Screen function.
screenNumber=max(Screen('Screens'));
[window, winsize]=Screen('OpenWindow', screenNumber, white);
%Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

clearmode = 2;
filtermode = 0;

%% setting up picture ports
xcenter= winsize(3)/2;
ycenter=winsize(4)/2;
x0=winsize(1)+30;
y0=winsize(2)+20;
x3=winsize(3)-30;
y3=winsize(4)-20;

width=(winsize(3)-x0)/3-40; 
height=width*0.5;%(winsize(4)-40-y0)/3; 

%ports for determining if click was accurate - use same for all tasks
%(split screen in 4)
big_port1=[winsize(1) winsize(2) xcenter ycenter];
big_port3=[winsize(1) ycenter xcenter winsize(4)];
big_port2=[xcenter y0 winsize(3) ycenter];
big_port4=[xcenter ycenter winsize(3) winsize(4)]; 

%getting coordinates of centers of ports (this lets me paste different sized textures into same
%ports
p1x=xcenter/2;
p1y=ycenter/2;
p2x=xcenter+(winsize(3)-xcenter)/2;
p2y=ycenter/2;
p3x=xcenter/2;
p3y=ycenter+(winsize(4)-ycenter)/2;
p4x=xcenter+(winsize(3)-xcenter)/2;
p4y=ycenter+(winsize(4)-ycenter)/2;

shrink=0.65; % option to shrink all pictures by the same amount

%% TRIAL INFO
numTrials=120; %full experiment is 120 ; change if add any trials or want to test with fewer trials

if blocknum == 1
    blockStart = 1;
    blockEnd = 60;

    %% reads in trial list
     TrialList = readtable(['ContrastsComp_L', num2str(counterbalancelist), '.txt']); 
     TrialList.audio = cellfun(@(x) [char(x) '.' lower(audio_version)], TrialList.audio,'UniformOutput', false); % makes it .mp3 or.wav based on what was selected above
   
     %% determine order of trials for this subject
     % currently hard-coded which is lame. would be good to fix so this
     % doesn't break if the file is sorted wrong!!
    % putting 3 random fillers first and randomizing the rest (filler trials
    % are in rows 101 through 120)
    fillerIndeces=101:1:120; 
    randFillers=fillerIndeces(randperm(20));
    firstThree=randFillers(1:3);
    remainingTrials=setdiff(1:1:120,firstThree);
    randomOrder=randperm(length(remainingTrials));

    %the full order for this subject
    trialOrder=[firstThree,remainingTrials(randomOrder)];

    %% Create order of trials for the whole experiment
    design_array{120,17} = [];
    design_array(:,1) = {subject};
    design_array(:,2) = num2cell(1:120);
    design_array(:,3) = TrialList.trialID(trialOrder);
    design_array(:,4) = TrialList.trialType(trialOrder); 
    design_array(:,5) = TrialList.cond(trialOrder); 
    design_array(:,6) = TrialList.animacy(trialOrder); 
    design_array(:,7) = TrialList.Target(trialOrder);
    design_array(:,8) = TrialList.Contrast(trialOrder); 
    design_array(:,9) = TrialList.Competitor(trialOrder); 
    design_array(:,10) = TrialList.Distractor(trialOrder); 
    design_array(:,11) = TrialList.audio(trialOrder); 
    
    save(['output/Contrasts_Tsim' subject '.mat'],'design_array');

else
    blockStart = 61;
    blockEnd = 120;
    
    % load design_array created during block 1
    load(['output/Contrasts_Tsim' subject '.mat']);
    
end
 
%% read in audio files
audio_mat = cellfun(@(x) read_in_audiofile(sounds_dir,audiochannel,x), design_array(blockStart:blockEnd,11));

%% read in images/ create textures
[target_tex, target_h, target_w, target_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(blockStart:blockEnd,7));
[contrast_tex, contrast_h, contrast_w, contrast_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(blockStart:blockEnd,8));
[compet_tex, compet_h, compet_w, compet_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(blockStart:blockEnd,9));
[distract_tex, distract_h, distract_w, distract_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(blockStart:blockEnd,10));

listOfPorts = {'target','contrast','compet','distract'};
 
%% randomizing location of pictures on screen
orders = zeros(numTrials/2,4);
port1_tex = zeros(numTrials/2,3);
port2_tex = zeros(numTrials/2,3);
port3_tex = zeros(numTrials/2,3);
port4_tex = zeros(numTrials/2,3);

for q = 1:numTrials/2
    orders(q,:) = randperm(4);
    prt1 = listOfPorts(orders(q,:)== 1); % 1 = target, 2 = contrast, 3 = compet, 4 = distract in listOfPorts/ order of columns
    prt2 = listOfPorts(orders(q,:)== 2); 
    prt3 = listOfPorts(orders(q,:)== 3); 
    prt4 = listOfPorts(orders(q,:)== 4); 
    port1_tex(q,1) = eval([char(prt1),'_tex(q)']); %texture numbers
    port2_tex(q,1) =  eval([char(prt2),'_tex(q)']);
    port3_tex(q,1) =  eval([char(prt3),'_tex(q)']);
    port4_tex(q,1) =  eval([char(prt4),'_tex(q)']);
    port1_tex(q,2) = eval([char(prt1),'_w(q)'])*shrink; %texture widths
    port2_tex(q,2) =  eval([char(prt2),'_w(q)'])*shrink;
    port3_tex(q,2) =  eval([char(prt3),'_w(q)'])*shrink;
    port4_tex(q,2) =  eval([char(prt4),'_w(q)'])*shrink;
    port1_tex(q,3) = eval([char(prt1),'_h(q)'])*shrink; %texture heights
    port2_tex(q,3) =  eval([char(prt2),'_h(q)'])*shrink;
    port3_tex(q,3) =  eval([char(prt3),'_h(q)'])*shrink;
    port4_tex(q,3) =  eval([char(prt4),'_h(q)'])*shrink;

end

% save locations to design_array
design_array(blockStart:blockEnd,12:15) = num2cell(orders(:,1:4));%targport, contport,competport,distractport

%pre-allocate matrices for click coordinates
click_coords = zeros(numTrials/2,2);
    
%% Eyetracker Setup
%% Set-up Matlab to GP3 session1 socket
commandwindow;

if dum == 0
    session1_client = ConnectToGP3;

%% Spawn a second Matlab session2 that records GP3 data to output file
    outputFileName = ['EToutput/contrasts_tsim' subject '_b' num2str(blocknum) '_' srand '.txt'];
    ExecuteRecordGP3Data(session1_client,outputFileName,...
        'ENABLE_SEND_POG_BEST','ENABLE_SEND_PUPIL_LEFT','ENABLE_SEND_BLINK');
    StartCalibration(session1_client,15);
    %split = SendCalMsgToGP3(session1_client)
end

% Display green arrow so people can get ready
Screen('FillPoly',window,green,[xcenter-50 xcenter+50 xcenter-50; ycenter-50 ycenter ycenter+50]')
Screen('Flip',window, 0); 
GetClicks();

%% Begin TRIAL LOOP
for t=1:numTrials/2
    ct = t + 60*(blocknum-1);
    if dum == 0
        flushinput(session1_client);%% ADDED THIS BASED ON GAZEPOINTREALTIMELRF...
    end
    %clears screen for new trial
    Screen('Flip', window,0);
    WaitSecs(1);
    
    PsychPortAudio('FillBuffer', audiochannel, audio_mat(t));
    
    Screen('DrawTexture', window,port1_tex(t,1),[],[p1x-port1_tex(t,2)/2 p1y-port1_tex(t,3)/2 p1x+port1_tex(t,2)/2 p1y+port1_tex(t,3)/2]);
    Screen('DrawTexture', window,port2_tex(t,1),[],[p2x-port2_tex(t,2)/2 p2y-port2_tex(t,3)/2 p2x+port2_tex(t,2)/2 p2y+port2_tex(t,3)/2]);
    Screen('DrawTexture', window,port3_tex(t,1),[],[p3x-port3_tex(t,2)/2 p3y-port3_tex(t,3)/2 p3x+port3_tex(t,2)/2 p3y+port3_tex(t,3)/2]);
    Screen('DrawTexture', window,port4_tex(t,1),[],[p4x-port4_tex(t,2)/2 p4y-port4_tex(t,3)/2 p4x+port4_tex(t,2)/2 p4y+port4_tex(t,3)/2]);
    Screen('DrawingFinished',window,clearmode);
    Screen('Flip', window,[],clearmode);

    if dum == 0
        SendMsgToGP3(session1_client,['START' num2str(ct)]); %send msg trigger for onset of new stimuli
    end
    
    %preview time
    WaitSecs(2);
    
    %% START PLAYING AUDIO with fast latency
     PsychPortAudio('Start',audiochannel,[],[],1); 
%     audiostatus2=PsychPortAudio('GetStatus',audiochannel);%to check if working

    if dum == 0
        %SendMsgToGP3(session1_client,['audio-stimuli_s' subject '_' char(trialID) '_' audio_file '_trial' pstr]); %send msg trigger for onset of audio stimuli
        SendMsgToGP3(session1_client,['STIM' num2str(ct)]); %send msg trigger for onset of audio stimuli
    end
    
    %% wait for mouse click to END TRIAL
     [clicks,x,y,whichButton] = GetClicks(window,0); 
     click_coords(t,1) = x;
     click_coords(t,2) = y;

     PsychPortAudio('Stop',audiochannel); % stop the audio channel
     
     %% close the textures we just used
     Screen('Close',[port1_tex(t,1),port2_tex(t,1),port3_tex(t,1),port4_tex(t,1)]);
     
end%end trial loop  

% design_array(:,1) = {subject};
% design_array(:,2) = num2cell(1:120);
% design_array(:,3) = TrialList.trialID(trialOrder);
% design_array(:,4) = TrialList.trialType(trialOrder); 
% design_array(:,5) = TrialList.cond(trialOrder); 
% design_array(:,6) = TrialList.animacy(trialOrder); 
% design_array(:,7) = TrialList.Target(trialOrder);
% design_array(:,8) = TrialList.Contrast(trialOrder); 
% design_array(:,9) = TrialList.Competitor(trialOrder); 
% design_array(:,10) = TrialList.Distractor(trialOrder); 
% design_array(:,11) = TrialList.audio(trialOrder); 
% design_array(:,12:15) = num2cell(orders(:,1:4));%targport, contport,competport,distractport

design_array(blockStart:blockEnd,16:17) = num2cell(click_coords(:,:)); 
output_table = cell2table(design_array(blockStart:blockEnd,:),'VariableNames',...
    {'Subject','trialOrder','trialID','trialType','Condition','Animacy',...
    'Target','Contrast','Competitor','Distractor','Audio','TargetLoc',...
    'ContrastLoc','CompetLoc','DistractLoc','ResponseX','ResponseY'});
name_of_file=['output/Contrasts_pilot_S' subject '_b' num2str(blocknum) '_' srand '.csv'];
writetable(output_table,name_of_file);

%% Stop collecting data in client2
if dum == 0
    fprintf('Stop recording\n')
    SendMsgToGP3(session1_client,'STOP_EYETRACKER');

%% Clean-up socket
    CleanUpSocket(session1_client);
end

%% Close Audio
PsychPortAudio('Close', audiochannel);

%% display red square
 Screen('Flip', window,0);
Screen('FillRect',window,red,[xcenter-50 ycenter-50 xcenter+50 ycenter+50])
Screen('Flip',window, [],1); 
WaitSecs(1);

  
fclose all;
Screen('CloseAll');

    