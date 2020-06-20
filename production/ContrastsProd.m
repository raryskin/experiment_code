%% Contrasts Production experiment: labeling task testing color and size adjective interpretation
%%% Outputs a .csv file with trial info and click responses for each trial.
%%% Requires Psychtoolbox
%%%
%%% Rachel Ryskin 8/11/2018

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

order = input('Enter Order Number (1 or 2): ');

%% folders and output files
pics_dir = 'StimuliA_Prod/'; %The location of the picture files to be used in the experiment
sounds_dir = 'ProductionRecordings/'; %The location where the audio files will be written to.

%% Set Screen things
%Screen('Preference','VBLTimestampingMode',-1); %This setting can be turned on if you have video driver problems.
Screen('Preference', 'SkipSyncTests', 0);%The last # should be "1" for testing mode only.
Screen('Preference','SyncTestSettings', 0.005, [], 0.2);

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
numchannels = 1;%1- mono sound; 2- stereo
audiochannel = PsychPortAudio('Open', [], 2, 1, freq, numchannels, 120); 

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

%% reads in trial list
 TrialList = readtable(['lists/ContrastsProd_L', num2str(counterbalancelist),'_o', num2str(order), '.txt']); 
 %TrialList.audio = cellfun(@(x) [char(x) '.' lower(audio_version)], TrialList.audio,'UniformOutput', false); % makes it .mp3 or.wav based on what was selected above

numTrials=size(TrialList,1); %full experiment is 100 ; change if add any trials or want to test with fewer trials

%  %% determine order of trials for this subject
%  % currently hard-coded which is lame. would be good to fix so this
%  % doesn't break if the file is sorted wrong!!
% % putting 3 random fillers first and randomizing the rest (filler trials
% % are in rows 101 through 120)
% fillerIndeces=101:1:120; 
% randFillers=fillerIndeces(randperm(20));
% firstThree=randFillers(1:3);
% remainingTrials=setdiff(1:1:120,firstThree);
% randomOrder=randperm(length(remainingTrials));
% 
% %the full order for this subject
% trialOrder=[firstThree,remainingTrials(randomOrder)];

%% Create order of trials for the whole experiment
design_array{numTrials,16} = [];
design_array(:,1) = {subject};
design_array(:,2) = num2cell(1:numTrials);
design_array(:,3) = num2cell(TrialList.trialID(:));
design_array(:,4) = TrialList.trialType(:); 
design_array(:,5) = TrialList.cond(:); 
design_array(:,6) = TrialList.animacy(:); 
design_array(:,7) = TrialList.Target(:);
design_array(:,8) = TrialList.Contrast(:); 
design_array(:,9) = TrialList.Distractor1(:); 
design_array(:,10) = TrialList.Distractor2(:); 

%% read in images/ create textures
[target_tex, target_h, target_w, target_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(:,7));
[contrast_tex, contrast_h, contrast_w, contrast_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(:,8));
[distract1_tex, distract1_h, distract1_w, distract1_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(:,9));
[distract2_tex, distract2_h, distract2_w, distract2_dim] = cellfun(@(x) img_to_tex(pics_dir,x,window), design_array(:,10));

listOfPorts = {'target','contrast','distract1','distract2'};
 
%% randomizing location of pictures on screen
orders = zeros(numTrials,4);
port1_tex = zeros(numTrials,3);
port2_tex = zeros(numTrials,3);
port3_tex = zeros(numTrials,3);
port4_tex = zeros(numTrials,3);

for q = 1:numTrials
    orders(q,:) = randperm(4);
    prt1 = listOfPorts(orders(q,:)== 1); % 1 = target, 2 = contrast, 3 = distract1, 4 = distract2 in listOfPorts/ order of columns
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
design_array(:,11:14) = num2cell(orders(:,1:4));%targport, contport,distract1port,distract2port

%pre-allocate matrices for click coordinates
click_coords = zeros(numTrials,2);
    
% Display green arrow so people can get ready
Screen('FillPoly',window,green,[xcenter-50 xcenter+50 xcenter-50; ycenter-50 ycenter ycenter+50]')
Screen('Flip',window, 0); 
GetClicks();

%% Begin TRIAL LOOP
for t=1:numTrials
    t
    %clears screen for new trial
    Screen('Flip', window,0);
    WaitSecs(1);
    
   % Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
    PsychPortAudio('GetAudioData', audiochannel, 120);
    
    Screen('DrawTexture', window,port1_tex(t,1),[],[p1x-port1_tex(t,2)/2 p1y-port1_tex(t,3)/2 p1x+port1_tex(t,2)/2 p1y+port1_tex(t,3)/2]);
    Screen('DrawTexture', window,port2_tex(t,1),[],[p2x-port2_tex(t,2)/2 p2y-port2_tex(t,3)/2 p2x+port2_tex(t,2)/2 p2y+port2_tex(t,3)/2]);
    Screen('DrawTexture', window,port3_tex(t,1),[],[p3x-port3_tex(t,2)/2 p3y-port3_tex(t,3)/2 p3x+port3_tex(t,2)/2 p3y+port3_tex(t,3)/2]);
    Screen('DrawTexture', window,port4_tex(t,1),[],[p4x-port4_tex(t,2)/2 p4y-port4_tex(t,3)/2 p4x+port4_tex(t,2)/2 p4y+port4_tex(t,3)/2]);
    TargetPort = eval(['big_port',char(string(design_array(t,11)))]);
    Screen('FrameRect',window,green,[TargetPort(1)+160 TargetPort(2)+10 TargetPort(3)-160 TargetPort(4)-10],10);
    Screen('DrawingFinished',window,clearmode);
    Screen('Flip', window,[],clearmode);
    
    %% START RECORDING AUDIO with fast latency
     PsychPortAudio('Start',audiochannel,[],[],1); 
%     audiostatus2=PsychPortAudio('GetStatus',audiochannel);%to check if working

 
    %% wait for mouse click to END TRIAL
     [clicks,x,y,whichButton] = GetClicks(window,0); 
     click_coords(t,1) = x;
     click_coords(t,2) = y;

     PsychPortAudio('Stop',audiochannel); % stop the audio channel
     % Perform a last fetch operation to get all remaining data from the capture engine:
     audiodata = PsychPortAudio('GetAudioData', audiochannel);
    
     wavfilename = [sounds_dir,'ContrastsProd_s' subject '_t' num2str(t) '_' srand '.wav'];

     psychwavwrite(transpose(audiodata), freq, 16, wavfilename);
     
     %% close the textures we just used
     Screen('Close',[port1_tex(t,1),port2_tex(t,1),port3_tex(t,1),port4_tex(t,1)]);
     
end%end trial loop  

design_array(:,15:16) = num2cell(click_coords(:,:)); 
output_table = cell2table(design_array,'VariableNames',...
    {'Subject','trialOrder','trialID','trialType','Condition','Animacy',...
    'Target','Contrast','Competitor','Distractor','TargetLoc',...
    'ContrastLoc','Distract1Loc','Distract2Loc','ResponseX','ResponseY'});
name_of_file=['output/ContrastsProd_s' subject '_' srand '.csv'];
writetable(output_table,name_of_file);


%% Close Audio
PsychPortAudio('Close', audiochannel);

%% display red square
 Screen('Flip', window,0);
Screen('FillRect',window,red,[xcenter-50 ycenter-50 xcenter+50 ycenter+50])
Screen('Flip',window, [],1); 
WaitSecs(1);

  
fclose all;
Screen('CloseAll');

    