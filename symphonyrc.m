function config = symphonyrc(config)
    
    packagePath = mfilename('fullpath');
    parentDir = fileparts(packagePath);
    [~, packageName] = fileparts(parentDir);
    
% % %     git = ['git -C "' parentDir '"'];
% % %     
% % %     % Check the main package local vs. remote repository.
% % %     disp(['Synchronizing ' packageName ' with remote repository...']);
% % %     sync = true;
% % %     while sync
% % %         execute([git ' remote update origin']);
% % %         local = execute([git ' rev-parse @']);
% % %         remote = execute([git ' rev-parse @{u}']);
% % %         base = execute([git ' merge-base @ @{u}']);
% % %         if strcmp(local, remote)
% % %             sync = false;
% % %         else
% % %             if strcmp(local, base)
% % %                 disp([packageName ' updates need to be pulled. Pulling...']);
% % %                 execute([git ' pull']);
% % %             elseif strcmp(remote, base)
% % %                 error([packageName ' changes need to be pushed by the admin.']);
% % %             else
% % %                 error([packageName ' has diverged.']);
% % %             end
% % %         end
% % %     end
% % %     disp('Done.');
% % %     
% % %     % Update personal user directories (submodules).
% % %     disp(['Updating ' packageName ' submodules...']);
% % %     execute([git ' submodule update --init --remote']);
% % %     disp('Done.');
% % %     
% % %     % Check for uncommitted changes.
% % %     out = execute([git ' status --porcelain']);
% % %     if ~isempty(out)
% % %         disp(['symphony-package contains changes not tracked by the server: ' char(10) out]);
% % %         r = input('Are you sure you want to continue? [y/n]: ', 's');
% % %         if ~strcmp(r, 'y')
% % %             error('Terminated by user');
% % %         end
% % %     end
    
    % Add base directories to the path.
    addpath(parentDir);
    addpath(fullfile(parentDir, 'Abstract Protocols'));
    addpath(fullfile(parentDir, 'Abstract Rig Configurations'));
    addpath(fullfile(parentDir, 'Stimulus Generators'));
    addpath(fullfile(parentDir, 'Calibration'));
    addpath(fullfile(parentDir, 'Utilities'));
    
    % Directory containing rig configurations.
    % Rig configuration .m files must be at the top level of this directory.
    config.rigConfigsDir = fullfile(parentDir, 'Rig Configurations');
    
    % Directory containing protocols.
    % Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
    config.protocolsDir = fullfile(parentDir, 'Protocols');
    
    % Directory containing figure handlers (built-in figure handlers are always available).
    % Figure handler .m files must be at the top level of this directory.
    config.figureHandlersDir = fullfile(parentDir, 'Figure Handlers');
    
    % Directory containing modules (built-in modules are always available).
    % Module .m files must be at the top level of this directory.
    config.modulesDir = fullfile(parentDir, 'Modules');
    
    % Text file specifying the source hierarchy.
    config.sourcesFile = fullfile(parentDir, 'SourceHierarchy.txt');
    
    % Factories to define which DAQ controller and epoch persistor Symphony should use.
    % HekaDAQControllerFactory and EpochHDF5PersistorFactory are only supported on Windows.
    if ispc
        config.daqControllerFactory = HekaDAQControllerFactory();
        config.epochPersistorFactory = EpochHDF5PersistorFactory();
    else
        config.daqControllerFactory = SimulationDAQControllerFactory('LoopbackSimulation');
        config.epochPersistorFactory = EpochXMLPersistorFactory();
    end
    
end


function cmdout = execute(cmd)
    if nargout == 0
        status = system(cmd);
    else
        [status, cmdout] = system(cmd);
    end
    if status
        error(['Failed to execute ''' cmd '''']);
    end
end