%% READ BEFORE PROCEED

% Matlab script to generate ICARUS website compatible timelinedata (.csv), 
% with timestamp (HH:MM) and experimental procedure description 

% Originally written by Stephanie Kong <wkong@caltech.edu> for Caltech
% atmospheric chamber experiment procedure timeline archiving 
% July 2019

% PI Contact: John H. Seinfeld <seinfeld@caltech.edu>

% Please change default directory (main directory) in the next section,
% the directory should be the main folder for experiment set,
% not date-specific folders

% Avoid using comma in CSV files as csv stands for "Comma-Separated Values" 
% and comma will separate the input into different cells in the spreadsheet 


clear all;
close all;
clc;

msgbox('DO NOT USE COMMA "," IN ANY FIELD THAT WILL BE RECORDED IN THE CSV FILES UNLESS SPECIFIED',...
    'WARNING');

pause(2);



%% Default directory for files - change accordingly before starts
% directory where all ICARUS-compatible data are stored, the directory 
% should be the main folder for experiment set, not date-specific folders
% if want to use the current folder as default, simply uncomment  
% icarus_dir = pwd() and delete icarus_dir = '/Users/....', otherwise please 
% specify directory using icarus_dir = '/Users/....';

icarus_dir = pwd();
% icarus_dir = '/Users/....';



%% Default experimental procedures - change accordingly before starts

default_desc= {'GC on','RHT/NOx/O3 on','AMS on filter','AMS on chamber',...
    'SMPS on ','CIMS on','PILS on','OH injection starts',...
    'OH injection ends (OH concentration is...)',...
    'VOC injection starts (VOC compound is... )',...
    'VOC injection ends (VOC concentration is ...)',...
    'Seed injection starts',...
    'Seed injection ends (seed concentration is... )',...
    'Time background starts','Lights on','Lights off',...
    'Refill bag starts','Refill bag ends','Mixing starts','Mixing ends',...
    'Wall loss starts','Wall loss ends','GC off','RHT/Nox/O3 off','AMS off',...
    'DMA off','CIMS off','Filter starts','Filter ends'}';

% initialize the timeline table, assuming the maximum steps is 100
max_step = 100;
%% Getting main directory and experiment date
% change default experiment date (yyyymmdd), experiment name and 
% main data directory here, the directory should be the main 
% folder for experiment set, not date-specific folders

df_info = {'','',icarus_dir};

% warning message for timeline generation
str = {'Time should be recorded in 24-hour Clock, HH:MM, as is in local time',...
    'Avoid using comma "," in descriptions; do not use enter to start a new line',...
    'To Add a new step, just add to the empty row in the end or overwrite the unused default lines',...
    'No need to delete step as everthing without a timestamp will be deleted with the reordering function',...
    'Close this window when finished, everything will be saved automatically'};

% 
prompt_info = {'Experiment Date (yyyymmdd)',...
    'Experiment Name','Main Data Directory (no "/" in the end)'};
dlgtitle_info = 'Experiment Information and Data Directory';
dim_info = [1,40;1 40; 1 100];


Experiment_info =  inputdlg(prompt_info,dlgtitle_info,dim_info,df_info);
exp_date = convertCharsToStrings(cell2mat(Experiment_info(1)));
exp_name = convertCharsToStrings(cell2mat(Experiment_info(2)));
exp_dir = convertCharsToStrings(cell2mat(Experiment_info(3)));

% all the files created here will be saved to date-specific folders
exp_dir = exp_dir+'/'+exp_date;


if ~exist(exp_dir, 'dir')
       mkdir(exp_dir);
end


dt = datetime('Now','TimeZone','local'); % get local timezones
timestr =strcat('Time (', dt.TimeZone, ')' );


clear icarus_dir df_info prompt_info dlgtitle_info dim_info dt Experiment_info
%% Create or edit timeline 
% if create: there is no existing timeline file and user needs to input 
% time (HH:MM),and experimental procedure description at certain time 
% stamp. If this is filled before experiment (no timestamps available), 
% one can just put down the procedure description first and come back to 
% the accurate timestamps later (leaving timestamps blank)

% if edit: there should already be a timeline file in the time-specific 
% folder and one can either add a new step (will need to adjust step order),
% or edit cerntain step description and time.


answer_timelinecreate = questdlg('Do you want to create a new timeline?', ...
	'Timeline Input', ...
	'Yes, I want to create a new timeline',...
    'No, I want to edit my existing timeline','No','No');





switch answer_timelinecreate
    case 'Yes, I want to create a new timeline'
        filename_timeline = exp_dir +'/'+exp_date +'_' +exp_name'+'_TimeLine.csv';
        f = figure('Name','Create a new timeline',...
            'Position',[300 100 900 600]);
        annotation('textbox',[.02 .6 .2 .4],'String',str,'FitBoxToText','on');

%   Make new timeline table...{}
        
    answer_defdesc= questdlg('Do you want to use default experiment procedures?', ...
        'Default Procedure', ...
        'Yes, I want to use the default',...
        'No, I want to start with blank','No');
    switch answer_defdesc
        case 'Yes, I want to use the default'
            timeline_arr = [cell([max_step,1]),...
                [default_desc;cell(max_step-length(default_desc),1)]];
        case 'No, I want to start with blank'
            timeline_arr = cell([max_step,2]);
    end 

        ans = timeline_arr;
        t = uitable(f,'Data',timeline_arr,...
            'Position',[20 20 850 500],...
            'ColumnName',{timestr; 'Action'},...
            'ColumnWidth',{200 640},...
            'ColumnEditable',logical([1 1]));

        h = set(t, 'CellEditCallback', 'get(t,''Data'')');


        waitfor(gcf);

        
        timeline_arr = ans;

        
    case 'No, I want to edit my existing timeline'
        d = dir(exp_dir);
        fn = {d.name};
        [indx,tf] = listdlg('PromptString','Select a file:',...
            'SelectionMode','single',...
            'Liststring',fn);
        filename_timeline = exp_dir + '/'+fn{indx};
        file_exist = readtable(filename_timeline);
        
        timeline_arr = table2cell(file_exist);
        answer_edittimeline = questdlg('How do you want to edit the existing timeline?', ...
            'Timeline Edit', ...
            'I want to edit the entire timeline',...
            'I want to make minor changes (edit one step at a time or add one step)','No');
        switch answer_edittimeline
            case  'I want to edit the entire timeline'
                f = figure('Name','Edit an existing timeline',...
                    'Position',[300 100 900 600]);
                annotation('textbox',[.02 .6 .2 .4],'String',str,'FitBoxToText','on');
                ans = timeline_arr;

                t = uitable(f,'Data',timeline_arr,...
                    'Position',[20 20 850 500],...
                    'ColumnName',{timestr; 'Action'},...
                    'ColumnWidth',{200 640},...
                    'ColumnEditable',logical([1 1]));

                set(t, 'CellEditCallback', 'get(t,''Data'')');


                waitfor(gcf);


                timeline_arr = ans;
            
            case 'I want to make minor changes (edit one step at a time or add one step)'
                timeline = strcat(timeline_arr(:,1),' : ',timeline_arr(:,2));
                prompt_timestamp = {'Time Stamps (24-hour Clock, HH:MM, can be left blank; for overnight experiment, use 24+Hr )',...
                                     'Descriptions (do not use comma "," in descriptions; do not use enter to start a new line)'};
               

                dim_timestamp = [1 60; 10 80];

                while true
                    answer_minoredit = questdlg('Edit one step or add one step?', ...
                            'Timeline Minor Edit', ...
                            'I want to edit one step',...
                            'I want to add one extra step',...
                            'I am done editing','No');
                        
                        switch answer_minoredit
                            case  'I want to edit one step'
                                [indx,tf] = listdlg('PromptString','Select a step to edit:',...
                                    'SelectionMode','single',...
                                    'Liststring',timeline);
                                
                                dlgtitle_timestamp_ed = 'Editing one experiment step';
                                df_timestep = timeline_arr(indx,:);
                                
                                answer_update = inputdlg(prompt_timestamp,dlgtitle_timestamp_ed,dim_timestamp,df_timestep);
                                timeline_arr(indx,:) = answer_update';
                                


                            case  'I want to add one extra step'
                                [indx,tf] = listdlg('PromptString','Add a new step after:',...
                                    'SelectionMode','single',...
                                    'Liststring',timeline);
                                
                                
                                dlgtitle_timestamp_ad = 'Adding one experiment step after... ';


                                answer_add = inputdlg(prompt_timestamp,...
                                            dlgtitle_timestamp_ad,dim_timestamp);
                                if indx == length(timeline_arr)
                                    timeline_arr =[timeline_arr;answer_add'];
                                    
                                else
                                    timeline_arr =[timeline_arr(1:indx,:);...
                                        answer_add';
                                        timeline_arr(indx+1:end,:)];
                                    
                                end 




                            case  'I am done editing'   
                                break
                        end 
                end 
        end 

    case 'No, do nothing'


end


clear prompt_timestamp ans answer_minoredit timeline dim_timestamp indx...
     d fn f t max_step answer_edittimeline answer_defdesc answer_timelinecreate...
     dlgtitle_timestamp_ad dlgtitle_timestamp_ed file_exist default_desc tf...
     df_timestep answer_update answer_add
%% Reordering timeline in case there is a misalignment

% Only proceed if the timeline is complete
% Any procedure without a timestamp will be deleted
% Timeline will be reordered by timestamp automatically 

answer_reorder = questdlg('Do you want to reorder your timeline based on timestamps and delete empty procedure entries? (Only proceed if the timeline is complete with HH:mm timestamp format)', ...
	'Timeline Reorder', ...
	'Yes, I want to autocorrect my timeline',...
    'No','No');
switch answer_reorder
    case 'Yes, I want to autocorrect my timeline'
        timeline_arr = timeline_arr(~cellfun('isempty',timeline_arr(:,1)),:);
        timenum = datenum(timeline_arr(:,1),'HH:MM');
        [~,p] = sort(timenum,'ascend');
        r = 1:length(timenum);
        r(p) = r;
        timeline_arr_new = timeline_arr ;

        if ~issorted(r)
            for i = 1:length(timeline_arr)
                timeline_arr_new(i,:) = timeline_arr(p(i),:);

            end
        end
       timeline_arr = timeline_arr_new;
       
    case 'No'
end

clear timeline_arr_new r p i timenum answer_reorder  

%% Saving Timeline File in .csv

% extra step in checking if the user want to overwrite the existing file 

answer_save = questdlg('Do you want to save your current timeline', ...
	'Saving Timeline', ...
	'Yes',...
    'No','No');

switch answer_save
    case 'Yes'
        % if filename already existed, check if user wants to overwrite
        if exist(filename_timeline, 'file')
            msgbox('Error: File Already Existed','WARNING');
            pause(1)
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                'Warning: Overwrite Existing File',...
                'Yes','No','No');
            switch answer_overwrite
                case 'Yes'
                    
                case 'No'
                    
                    filename_timeline =  inputdlg('Filename',...
                        'Choose a new filename',[1 100],...
                        exp_dir +'/'+exp_date +'_' +exp_name'+'_TimeLine_V1.csv');
                    filename_timeline = convertCharsToStrings(filename_timeline);
            end 
        end 
    fid = fopen(filename_timeline ,'wt');
    if fid>0
        fprintf(fid,'%s,%s\n',timestr,'Action');
        
        for k=1:length(timeline_arr)
            % replace all the "," with ";"
            timeline_arr{k,2}= strrep(timeline_arr{k,2},',',';'); 
            fprintf(fid,'%s,%s\n',timeline_arr{k,1},timeline_arr{k,2});
        end
        fclose(fid);
    end
    case 'No'
                         
end

clear k filename_timeline timestr timeline_arr exp_name exp_dir exp_date...
    filename_timeline answer_overwrite answer_save str max_step fid ans tf