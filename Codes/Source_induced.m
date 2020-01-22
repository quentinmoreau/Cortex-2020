sub= ['S01';'S02';'S03';'S04';'S05';'S06';'S07';'S08';'S09';'S10';'S11';'S12';'S13';'S14';'S15';'S16';'S17';'S18';'S20';'S21';'S22';'S23']; %
mark=['corr';'noco'];
cond=['F';'G'];
subcond=['OP';'UG'];
grasp=['up';'do'];

for ii=1:size(sub,1);
    sub_ind=sub(ii,:);
    for kk=1:size(cond,1);
    cond_ind=cond(kk,:);
         for jj=1:size(mark,1);
         mark_ind=mark(jj,:);
            for uu=1:size(subcond,1);
            subcond_ind=subcond(uu,:);
                for ff=1:size(grasp,1);
                grasp_ind=grasp(ff,:);
                    
                      cfg =[];
                      filename=strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.eeg');
                      cfg.trigger = ft_read_event ('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.vmrk'); %('C:\Users\Matteo\Documents\My Work\Viviana\data_Viviana\S1_LH.cnt');
                      cfg.dataset=ft_read_header(strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.vhdr'));
                      savingname1 = strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Induced Source\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'_induced_source_thetalpha'); 

                      cfg.layout = 'EEG1010.lay';
                      
                                       % Markers 
                        cfg =[];
                        cfg.trialdef.prestim = 1;                   % in seconds
                        cfg.trialdef.poststim = 1.5;       
                        cfg.dataset = filename;
                        cfg.trialdef.eventtype = 'Stimulus';
                        cfg  = ft_definetrial(cfg);
                        data = ft_preprocessing(cfg);
                        
                         
                         % Compute Average

                        cfg = [];
                        cfg.trials = 'all';
                        cfg.keeptrials = 'no';
                        avg_evoked = ft_timelockanalysis(cfg, data);
                        
                        cfg = [];
                        cfg.trials = 'all';
                        cfg.keeptrials = 'yes';
                        avg_induced = ft_timelockanalysis(cfg, data);


                        a = size(avg_induced.trial, 1);
                        bigone=repmat(avg_evoked.avg,[1,1,a]);    
                        evoked = permute(bigone,[3 1 2]);

                        induced = avg_induced.trial - evoked;
                        
                        data_induced = avg_induced;
                        data_induced.trial = induced;
                        
                        cfg = [];                                           
                        cfg.toilim = [-.5 0];                       
                        dataPre = ft_redefinetrial(cfg, data_induced);

                        cfg.toilim = [0 .5];                       
                        dataPost = ft_redefinetrial(cfg, data_induced);
                        
                        cfg = [];
                        cfg.method    = 'mtmfft';
                        cfg.output    = 'powandcsd';
                        cfg.tapsmofrq = 2;
                        cfg.foilim    = [4 13];
                        freqPre = ft_freqanalysis(cfg, dataPre);
                        freqPost = ft_freqanalysis(cfg, dataPost);
                        freqAll = ft_freqanalysis(cfg, data_induced);
                        
                        
                        load standard_BEM.mat
                        elec = ft_read_sens('standard_1020.elc'); 
                        
                        
                        % Compute Grid
                        cfg                 = [];
                        cfg.elec            = elec;
                        cfg.headmodel       = vol;
                        cfg.grid.resolution = 10;
                        cfg.grid.unit       = 'mm';
                        cfg.inwardshift     = -1.5;
                        grid                = ft_prepare_sourcemodel(cfg);
                        
                         freqPre.elec = elec;
                        freqPost.elec = elec;
                        freqAll.elec = elec;

                        % Source computation
                        cfg              = [];
                        cfg.method       = 'dics'; % 
%                         cfg.frequency    = 5;
                        cfg.grid         = grid;
                        cfg.headmodel    = vol;
                        cfg.dics.projectnoise = 'yes';
                        cfg.dics.lambda       = '5%';
                        cfg.dics.keepfilter   = 'yes';
                        cfg.dics.realfilter   = 'yes';
                        sourceAll = ft_sourceanalysis(cfg, freqAll); % parameters from the tutorials

                        cfg.grid.filter = sourceAll.avg.filter;
                        sourcePre  = ft_sourceanalysis(cfg, freqPre);
                        sourcePost = ft_sourceanalysis(cfg, freqPost);

                        sourceDiff = sourcePre;
                        sourceDiff.avg.pow = (sourcePost.avg.pow - sourcePre.avg.pow) ./ sourcePre.avg.pow; 
                        
                        load standard_mri.mat
                        mri = ft_volumereslice([], mri); 
                        % Interpolate Pow on MRI
                        cfg            = [];
                        cfg.downsample = 2;
                        cfg.parameter  = 'avg.pow';
                        sourceDiffInt  = ft_sourceinterpolate(cfg, sourceDiff , mri); % you project the source power onto an fMRI

                        %Normalise
                        cfg = [];
                        cfg.nonlinear     = 'no';
                        sourceDiffIntNorm = ft_volumenormalise(cfg, sourceDiffInt);
                        
                        
%                         % plot on a brain template
%                         cfg = [];
%                         cfg.method         = 'surface';
%                         cfg.funparameter   = 'avg.pow';
%                         cfg.maskparameter  = cfg.funparameter;
%                         cfg.funcolorlim    = [0.3 1];
%                         cfg.funcolormap    = 'parula';
%                         cfg.opacitylim     = [0.3 1]; 
%                         cfg.opacitymap     = 'rampup';  
%                         cfg.projmethod     = 'nearest'; 
%                         cfg.surffile       = 'surface_white_both.mat';
%                         cfg.surfdownsample = 10; 
%                         cfg.vertexcolor = 'none';
%                         ft_sourceplot(cfg, sourceDiffIntNorm);
%                         view ([90 20])
%                         camlight('right')
%                         % light('Position',[1 0 1])
%                         ft_sourceplot(cfg, sourceDiffIntNorm);
%                         view ([-90 20]) 
%                         camlight('left')

save(savingname1, 'sourceDiffInt') 

                end
            end
         end
    end
end
 
