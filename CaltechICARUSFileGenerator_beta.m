%% READ BEFORE PROCEED

% Originally written by Stephanie Kong (wkong@caltech.edu) for Caltech
% atmospheric chamber data archiving 
% Feb 2020

% PI Contact: John H. Seinfeld <seinfeld@caltech.edu>

% Please change default directory (main directory) in the next section,
% the directory should be the main folder for experiment set,
% not date-specific folders

% If raw data are sorted into folders by date, please also refer to the
% experiment information session for directory changing 

% Avoid using comma in CSV files unless specified as csv stands for 
% "Comma-Separated Values" and comma will separate the input into different 
% cells in the spreadsheet 



% Matlab script to generate ICARUS website compatible data (.csv), including
%   Timeline- manually input (timestamp, procedure description)
%   SMPS- data structure saved in .mat named 'dma'
%           can be processed into either particle size distribution data
%           with time and dN/dlogDp for all the size bins OR
%           into total concentrations with time, N, S and V OR
%           into the two pieces information combined with time N, S, V and 
%           dN/dlogDp for all the size bins
%   GC - data file saved originally in excel spreadsheet .xlsx or .mat
%   CIMS - data file saved originally in .mat
%   RHT - data file saved originally in .txt
%   NOX/O3 - data file saved originally in .txt


clear all;
close all;
clc;

msgbox('DO NOT USE COMMA "," IN ANY FIELD THAT WILL BE RECORDED IN THE CSV FILES UNLESS SPECIFIED',...
    'WARNING');

pause(2);

%% Default directory for files - change accordingly before starts
% icarus_dir is the directory where all ICARUS-compatible data are stored, 
% the directory should be the main folder for experiment set, not 
% date-specific folders

% if want to use the current folder as default, simply uncomment  
% icarus_dir = pwd() and delete icarus_dir = '/Users/....', otherwise please 
% specify directory using icarus_dir = '/Users/....';

icarus_dir = pwd();
% icarus_dir = '';

% directory where the inverted DMA data in .mat are stored
smps_dir = '';

% directory where the GC data in .xlsx are stored
gc_dir = '';


% directory where the CIMS data in .mat are stored
cims_dir = '';




% directory where the RHT/NOX/O3 data in .txt are stored

rht_dir = '';
nox_dir =  '';
%% Experiment Information

% change default experiment date (yyyymmdd), experiment name and 
% main data directory here, the directory should be the main 
% folder for experiment set, not date-specific folders



df_info = {'','',icarus_dir};

% 
prompt_info = {'Experiment Date (yyyymmdd)',...
    'Experiment Name','Main Data Directory (no "/" in the end)'};
dlgtitle_info = 'Experiment Information and Data Directory';
dim_info = [1,40;1 40; 1 100];


Experiment_info =  inputdlg(prompt_info,dlgtitle_info,dim_info,df_info);
exp_date = convertCharsToStrings(cell2mat(Experiment_info(1)));
exp_name = convertCharsToStrings(cell2mat(Experiment_info(2)));
exp_dir = convertCharsToStrings(cell2mat(Experiment_info(3)));

% all the files created here will be saved to date-specific folders under
% the main directory 

exp_dir = exp_dir+'/'+exp_date;


% if organize data in this way: instrument/date(yymmdd)/data, uncomment the
% next seven lines 

exp_date_yymmdd = convertStringsToChars(exp_date);
exp_date_yymmdd = exp_date_yymmdd(3:end);

% smps_dir =strcat( smps_dir, '/', exp_date_yymmdd);
% gc_dir =strcat( gc_dir, '/', exp_date_yymmdd);
% cims_dir =strcat( cims_dir, '/', exp_date_yymmdd);
rht_dir = strcat(rht_dir, '/', exp_date_yymmdd);
nox_dir = strcat(nox_dir, '/', exp_date_yymmdd);



if ~exist(exp_dir, 'dir')
       mkdir(convertStringsToChars(exp_dir));
end



% get local timezone
dt = datetime('Now','TimeZone','local'); 
timestr =strcat('Time (', dt.TimeZone, ')' );


clear df_info prompt_info dlgtitle_info dim_info dt Experiment_info


%% Create or edit timeline 
% Matlab script to generate ICARUS website compatible timelinedata (.csv), 
% with timestamp (HH:MM) and experimental procedure description 

% Default experimental procedures - change accordingly before starts
% if create: there is no existing timeline file and user needs to input 
% time (HH:MM),and experimental procedure description at certain time 
% stamp. If this is filled before experiment (no timestamps available), 
% one can just put down the procedure description first and come back to 
% the accurate timestamps later (leaving timestamps blank)

% if edit: there should already be a timeline file in the time-specific 
% folder and one can either add a new step (will need to adjust step order),
% or edit cerntain step description and time.




% Default experimental procedures - change accordingly before starts
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





% warning message for timeline generation
str = {'Time should be recorded in 24-hour Clock, HH:MM, as is in local time',...
    'Avoid using comma "," in descriptions; do not use enter to start a new line',...
    'To Add a new step, just add to the empty row in the end or overwrite the unused default lines',...
    'No need to delete step as everthing without a timestamp will be deleted with the reordering function',...
    'Close this window when finished, everything will be saved automatically'};


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

% Reordering timeline in case there is a misalignment

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


% Saving Timeline File in .csv
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

clear k  timeline_arr max_step fid ans tf filename_timeline ...
    answer_overwrite answer_save str dt 

%% Convert SMPS Data into .csv
% Read inverted SMPS data in .mat into csv file in three different format:
% Particle size distribution only (Time vs. dNdlogDp), total
% number/surface/volume concentrations, and both. 
% Change default folder where DMA data was stored (assuming DMA data were 
% saved under same directory); 
% .mat file should have a saved strucutre named dma

answer_SMPSfile = questdlg('Do you want to convert an SMPS file (.mat)?', ...
	'SMPS Format Conversion', ...
	'Yes',...
    'No','No');
switch answer_SMPSfile
    case 'Yes'
        uiopen(smps_dir);

        answer_SMPSform = questdlg('What format is the SMPS output?', ...
            'SMPS Data Format',...
            'Particle Size Distribution', ...
            'Total Concentrations','Combined','No');
        
        switch answer_SMPSform
            case 'Particle Size Distribution'
                filename_smps = exp_dir +'/'+exp_date +'_' +exp_name'+...
                    '_SMPS_PSD';
                
                
                header_arr=   'Time (PST),';
                header_form = '%s\n';
                data_arr = dma.dNdlogDp_adj;
                data_form = '%s';
                
                if isfield(dma,'dp_adj')

                    for i = 1: length(dma.dp_adj(2,:))
                        header_arr= [header_arr,...
                            strcat(num2str(dma.dp_adj(2,i),'%.2f'),' nm,')];
                        data_form = [data_form,',%f'];
                    end 
                else
                    for i = 1: length(dma.dp(2,:))
                        header_arr= [header_arr,...
                            strcat(num2str(dma.dp(2,i),'%.2f'),' nm,')];
                        data_form = [data_form,',%f'];
                    end 
                end 
                data_form = [data_form, '\n'];
                

            case 'Total Concentrations'
                
                filename_smps = exp_dir +'/'+exp_date +'_' +exp_name'+...
                    '_SMPS_TotalConc';
                
                
                header_arr=   ['Time (PST),',...
                        'Total Number Concentrations (cm^-3),',...
                        'Total Surface Concentrations (um^2/cm^3),',...
                        'Total Volume Concentrations (um^3/cm^3),'];
                header_form = '%s\n';
                
                if isfield(dma,'n_tot_adj')
                    data_arr = [dma.n_tot_adj;dma.s_tot_adj;dma.v_tot_adj];
                else
                    data_arr = [dma.n_tot;dma.s_tot;dma.v_tot];
                end 
                
                data_form = '%s,%f,%f,%f\n';
               
                
           
            case 'Combined'
               
                
                filename_smps = exp_dir +'/'+exp_date +'_' +exp_name'+...
                    '_SMPS_Complete';
                
                
                header_arr=   ['Time (PST),',...
                        'Total Number Concentrations (cm^-3),',...
                        'Total Surface Concentrations (um^2/cm^3),',...
                        'Total Volume Concentrations (um^3/cm^3),'];
                header_form = '%s\n';
                
                
                data_form = '%s,%f,%f,%f';
                
                if isfield(dma,'n_tot_adj')
                    data_arr = [dma.n_tot_adj;dma.s_tot_adj;dma.v_tot_adj;...
                        dma.dNdlogDp_adj];
                    for i = 1: length(dma.dp_adj(2,:))
                        header_arr= [header_arr,...
                            strcat(num2str(dma.dp_adj(2,i),'%.2f'),' nm,')];
                        data_form = [data_form,',%f'];
                    end
                else
                    data_arr = [dma.n_tot;dma.s_tot;dma.v_tot;...
                        dma.dNdlogDp];
                    for i = 1: length(dma.dp(2,:))
                        header_arr= [header_arr,...
                            strcat(num2str(dma.dp(2,i),'%.2f'),' nm,')];
                        data_form = [data_form,',%f'];
                    end
                end
               
                
                 
                data_form = [data_form, '\n'];

        end 
        filename_smps_csv = strcat(filename_smps,'.csv');
        
        if exist(filename_smps_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        nooverwrite_msg = msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_smps_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(filename_smps,'_V1.csv'));
                        filename_smps_csv = convertCharsToStrings(filename_smps_csv);
                end 
        end 
        
        data_arr = data_arr';
        fid = fopen(filename_smps_csv ,'wt');
        if fid>0
            fprintf(fid,header_form,header_arr);
            for k=1:dma.scan
                fprintf(fid,data_form,dma.t_datetime(k),data_arr(k,:));
            end
            fclose(fid);
        end
           

    case 'No'
        
        
end 


clear data_arr data_form answer_SMPSfile answer_SMPSform dma fid...
    filename_smps filename_smps_csv header_arr header_form i k smps_dir...
    answer_overwrite ans

%% Convert GC Data into .csv
% Read GC data of number of scan N, time T (no date, HH:MM), and peak area
% (can be multiple peaks) T/P/P/P/... in .xlxs
% into a csv file with calibration factor multiplied (area/ppb)

% or it can read file that is processed with matlab with time and
% concentration, and convert in to a csv file



answer_gcfile = questdlg('Do you want to convert a GC file (.xlsx)?', ...
	'GC Format Conversion', ...
	'Yes, from .xlsx',...
    'Yes, from .mat',...
    'No','No');

switch answer_gcfile
    case 'Yes, from .xlsx'
        
        
        gc_dir_info =  inputdlg('GC File Directory',...
            'GC File Directory',[1 100],{gc_dir});

        gc_dir = gc_dir_info{1,1};


        d = dir(gc_dir);
        fn = {d.name};
        [indx,tf] = listdlg('PromptString','Select a GC file:',...
            'SelectionMode','single',...
            'Liststring',fn);
        filename_gc = strcat(gc_dir, '/',fn{indx});
        opts  = detectImportOptions(filename_gc);
        file_gc = readtable(filename_gc);
        
        f = figure('Name','Calibration factors for peak of interest',...
            'Position',[400 300 540 200]);
        
        str = {'The first column should be the existing headers from .xlsx file',...
            'Check the box on the second column only if it is peak of interest that will be recorded',...
            'Put down the calibration factor (area/ppb) in the third column for peaks that will be recorded',...
            'Put down compound peak name in the forth column for peak of interest',...
            'Close this window when finished, everything will be saved automatically'};

        annotation('textbox',[.02 .6 .2 .4],'String',str,'FitBoxToText','on');


        col_n = width(file_gc);
        table_logic ={false,false,true};
        if col_n >3
            for i = 4: col_n
                table_logic =[table_logic,false];
            end 
        end 

        gc_table = [opts.VariableNames;table_logic;cell([1, col_n]);cell([1, col_n])]';
        uit = uitable(f,'Data',gc_table,'Position',[20 20 486 100]);

        uit.ColumnEditable =logical([0 1 1 1]);
        uit.ColumnName={'Raw file header'; 'Peak area of interest';...
            'Calibration factor (area/ppb)';'Compound Name'};
        h = set(uit, 'CellEditCallback', 'get(uit,''Data'')');

        waitfor(gcf);
        
        gc_table = ans;
        
        % find total number of peaks 
      
        gc_conc = [];
        gc_header = strcat(timestr,',');
        gc_form = '%s';
        for i = 3:col_n
            if gc_table{i,2} == 1
                gc_conc = [gc_conc, file_gc{:,i}./str2double(gc_table{i,3})];
                gc_header = [gc_header, strcat(gc_table{i,4}, ' (ppb),')];
                gc_form = strcat(gc_form,',%f');
            end 
        end 
        
        gc_form = strcat(gc_form,'\n');
        gc_time = datenum(exp_date,'yyyymmdd') + table2array(file_gc(:,2));
        gc_time = datetime(gc_time,'ConvertFrom','datenum');
        filename_gc_csv = exp_dir +'/'+exp_date +'_' +exp_name'+'_GC.csv';
        
        if exist(filename_gc_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_gc_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(exp_dir +'/'+exp_date +'_' +exp_name'+'_GC_V1.csv'));
                        filename_gc_csv = convertCharsToStrings(filename_gc_csv);
                end 
        end 
        
        fid = fopen(filename_gc_csv ,'wt');
        if fid>0
            fprintf(fid,'%s\n',gc_header);
            for k=1:height(file_gc)
                    fprintf(fid,gc_form,gc_time(k),gc_conc(k,:));
            end
            fclose(fid);
        end
        
    case'Yes, from .mat'
        uiopen(gc_dir);
        
        gc_peak_info =  inputdlg({'How many peaks are there',...
            'Peak compound names (if more than one, separated by comma ",")'},...
            'GC Peak Number',[1 30; 1 100],{'1', ''});
        gc_peak_n = str2num(gc_peak_info{1,1});      
        gc_peak_name = strsplit(convertCharsToStrings(gc_peak_info{2}),',');
        
        
        gc_header = timestr;
        
        gc_form = '%s';
        
        
        for i  = 1 : gc_peak_n
            gc_header = strcat(gc_header,',',gc_peak_name(i), ' (ppb)');
            gc_form = strcat(gc_form,',%f');
        end 
        gc_form = strcat(gc_form,'\n');
  
        filename_gc_csv = exp_dir +'/'+exp_date +'_' +exp_name'+'_GC.csv';

        if exist(filename_gc_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_gc_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(exp_dir +'/'+exp_date +'_' +exp_name'+'_GC_V1.csv'));
                        filename_gc_csv = convertCharsToStrings(filename_gc_csv);
                end 
        end 
        
        fid = fopen(filename_gc_csv ,'wt');
        if fid>0
            fprintf(fid,'%s\n',gc_header);
            for k=1:length(sig)
                    fprintf(fid,gc_form, ...
                        datetime(sig(k).datenum,'ConvertFrom','datenum'),...
                        sig(k).ppb);
            end
            fclose(fid);
        end
        

    case 'No'
end 


clear d file_gc filename_gc fn gc_cal gc_dir indx tf gc_dir_info col_n...
    fid f uit opts tf table_logic k i h indx fn gc_conc ans answer_overwrite...
    answer_gcfile filename_gc_csv gc_form gc_header gc_table gc_time str...
    gc_peak_info gc_peak_n gc_peak_name calib b_fit calib_st exptSaveName...
    fold GCt i reg regComp regInt sig blank
%% Convert CIMS Data in .csv
% Read inverted CIMS data in .mat into csv file with single vector time,
% mass, counts and dig data
% .mat file should have a saved strucutre named ans
% The output will be a scan * m/z matrix with time series counts information

answer_CIMSfile = questdlg('Do you want to convert an CIMS file (.mat)?', ...
	'CIMS Format Conversion', ...
	'Yes',...
    'No','No');
switch answer_CIMSfile
    case 'Yes'
        uiopen(cims_dir);
        
        mz_min = min(ans.mass);

        min_ind = find(ans.mass==mz_min);
        cims_time = ans.time(min_ind);
        cims_time = datetime(cims_time,'ConvertFrom','datenum');

        total_scan = length(min_ind);
        total_mz = min_ind(2)-1;

        cims_counts = reshape(ans.cts,[total_scan total_mz ]);

        cims_header = timestr;
        cims_form = '%s';
        for i = 1: total_mz
            cims_header = [cims_header, strcat(',m/z = ',num2str(ans.mass(i)))];
            cims_form = strcat(cims_form,',%f');
        end 
        cims_form = strcat(cims_form,'\n');
        
        filename_cims_csv = exp_dir +'/'+exp_date +'_' +exp_name'+'_CIMS.csv';
        
        if exist(filename_cims_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_cims_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(exp_dir +'/'+exp_date +'_' +exp_name'+'_CIMS_V1.csv'));
                        filename_cims_csv = convertCharsToStrings(filename_cims_csv);
                end 
        end 
        


        
        
        fid = fopen(filename_cims_csv ,'wt');
        if fid>0
            fprintf(fid,'%s\n',cims_header);
            for k=1:total_scan
                fprintf(fid,cims_form,cims_time(k),cims_counts(k,:));
            end
            fclose(fid);
        end
        
    

    case 'No'
        
        
end 

clear answer_overwrite ans answer_CIMSfile cims_counts cims_dir cims_form ...
    cims_header cims_time filename_cims_csv i min_ind mz_min total_mz...
    fid k total_scan

%% Convert RHT Data in. csv
% RHT data is orignally given in .txt


answer_rhtfile = questdlg('Do you want to convert an RHT file (.txt)?', ...
	'RHT Format Conversion', ...
	'Yes',...
    'No','No');

switch answer_rhtfile
    case 'Yes'
        
        
        rht_dir_info =  inputdlg('RHT File Directory',...
            'RHT File Directory',[1 100],{rht_dir});

        rht_dir = rht_dir_info{1,1};


        d = dir(rht_dir);
        fn = {d.name};
        [indx,tf] = listdlg('PromptString','Select an RHT file:',...
            'SelectionMode','single',...
            'Liststring',fn);
        filename_rht = strcat(rht_dir, '/',fn{indx});
        data_rht = dlmread(filename_rht,'',2,0);

        filename_rht_csv = exp_dir +'/'+exp_date +'_' +exp_name'+'_RHT.csv';
        opts =detectImportOptions(filename_rht);
        rht_header = opts.VariableNames;
        rht_header{1} = 'Time';
        
        fid = fopen(filename_rht ,'r');
        start_time = fgetl(fid);
        fclose(fid);

        start_time_dt = datetime(start_time,'InputFormat','MM/dd/yyyy hh:mm a');
        rht_time = start_time_dt+ seconds(data_rht(:,1));



        
        if exist(filename_rht_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_rht_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(exp_dir +'/'+exp_date +'_' +exp_name'+'_RHT_V1.csv'));
                        filename_rht_csv = convertCharsToStrings(filename_rht_csv);
                end 
        end 
        
        header_form = '%s,%s,%s,%s,%s,%s,%s\n';
        rht_form = '%s,%f,%f,%f,%f,%f,%f\n';
        fid = fopen(filename_rht_csv ,'wt');
        if fid>0
            fprintf(fid,header_form,convertCharsToStrings(rht_header));
            for k=1:length(data_rht)
                    fprintf(fid,rht_form,rht_time(k),data_rht(k,2:end));
            end
            fclose(fid);
        end

    case 'No'
end 


clear answer_overwrite answer_rhtfile d data_rht fid filename_rht...
    filename_rht_csv fn header_form indx k opts rht_dir rht_dir_info...
    rht_form rht_header rht_time tf start_time start_time_dt ans
%% Convert NOX/O3 Data in. csv
% NOX/O3 data is orignally given in .txt


answer_noxfile = questdlg('Do you want to convert an NOx/O3 file (.txt)?', ...
	'NOx/O3 Format Conversion', ...
	'Yes',...
    'No','No');

switch answer_noxfile
    case 'Yes'
        
        
        nox_dir_info =  inputdlg('NOx/O3 File Directory',...
            'NOx/O3 File Directory',[1 100],{nox_dir});

        nox_dir = nox_dir_info{1,1};


        d = dir(nox_dir);
        fn = {d.name};
        [indx,tf] = listdlg('PromptString','Select an NOx/O3 file:',...
            'SelectionMode','single',...
            'Liststring',fn);
        filename_nox = strcat(nox_dir, '/',fn{indx});
        data_nox = dlmread(filename_nox,'',2,0);

        filename_nox_csv = exp_dir +'/'+exp_date +'_' +exp_name'+'_NOx_O3.csv';
        opts =detectImportOptions(filename_nox);
        nox_header = opts.VariableNames;
        nox_header{1} = 'Time';
        
        fid = fopen(filename_nox ,'r');
        start_time = fgetl(fid);
        fclose(fid);

        start_time_dt = datetime(start_time,'InputFormat','MM/dd/yyyy hh:mm a');
        nox_time = start_time_dt+ seconds(data_nox(:,1));



        
        if exist(filename_nox_csv, 'file')  
            answer_overwrite =questdlg('Do you want to overwrite existing file?',...
                    'Warning: Overwrite Existing File',...
                    'Yes','No','No');

                switch answer_overwrite
                    case 'Yes'
                    case 'No'
                        msgbox('Error: File Already Existed',...
                                    'WARNING');
                        pause(1)
                        filename_nox_csv =  inputdlg('Filename',...
                            'Choose a new filename',[1 100],...
                           strcat(exp_dir +'/'+exp_date +'_' +exp_name'+'_NOX_O3_V1.csv'));
                        filename_nox_csv = convertCharsToStrings(filename_nox_csv);
                end 
        end 
        
        header_form = '%s,%s,%s,%s,%s,%s,%s,%s\n';
        nox_form = '%s,%f,%f,%f,%f,%f,%f,%f\n';
        fid = fopen(filename_nox_csv ,'wt');
        if fid>0
            fprintf(fid,header_form,convertCharsToStrings(nox_header));
            for k=1:length(data_nox)
                    fprintf(fid,nox_form,nox_time(k),data_nox(k,2:end));
            end
            fclose(fid);
        end

    case 'No'
end 


clear answer_overwrite answer_noxfile d data_nox fid filename_nox...
    filename_nox_csv fn header_form indx k opts nox_dir nox_dir_info...
    nox_form nox_header nox_time tf start_time start_time_dt ans



%%
clear exp_name exp_dir exp_date timestr exp_date_yymmdd icarus_dir
