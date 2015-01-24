% Create a sub-class of this class to define a protocol that display visual stimuli via Stage.

classdef StageProtocol < PulsedProtocol
    
    properties (Hidden)
        stageConfig
    end
    
    properties (Dependent, SetAccess = private, Hidden)
        % Convienence properties.
        stage
        canvasSize
        
        preFrames
        stimFrames
        tailFrames
        totalFrames
    end
    
    methods
        
        function obj = init(obj, rigConfig)
            obj = init@PulsedProtocol(obj, rigConfig);
            
            % Copy the stage config to the protocol because the rig config is not sent over TCP.
            obj.stageConfig = obj.rigConfig.stageConfig;
            
            % If there are no stage settings, make a placeholder.
            if isempty(obj.stageConfig)
                obj.stageConfig.canvasSize = [0 0];
                obj.stageConfig.micronsPerPixel = 0;
                obj.stageConfig.monitorRefreshRate = 0;
            end
        end
        
        
        function dn = requiredDeviceNames(obj)
            dn = requiredDeviceNames@PulsedProtocol(obj);
            dn = [dn, 'Frame_Monitor'];
        end
        
        
        function [tf , msg] = isCompatibleWithRigConfig(obj, rigConfig)
            [tf, msg] = isCompatibleWithRigConfig@PulsedProtocol(obj, rigConfig);
            
            if tf && isempty(obj.rigConfig.stage)
                tf = false;
                msg = 'This protocol requires a stage in your rig configuration.';
            end
        end
        
        
        function prepareRun(obj)
            prepareRun@PulsedProtocol(obj);
            
            % Open a custom figure to display the duration between window flips.
            handler = obj.openFigure('Custom', 'Name', 'Flip Durations', 'ID', 'flip', 'UpdateCallback', @updateFlipDurations);
            subplot(2, 1, 1, 'Parent', handler.figureHandle);
            subplot(2, 1, 2, 'Parent', handler.figureHandle);
            
            % Ensure the GL constants are loaded in memory (this can take a while and we want to control when it occurs).
            GL;
        end
        
        
        function updateFlipDurations(obj, epoch, axesHandle)
            info = obj.stage.getPlayInfo;
            if isa(info, 'MException')
                obj.stop();
                waitfor(errordlg(['Stage encountered an error during the presentation.' char(10) char(10) getReport(info, 'extended', 'hyperlinks', 'off')]));
                return;
            end
            
            persistent plotData;
            
            [response, sampleRate, units] = epoch.response('Frame_Monitor');
            
            % Check frame timing.
            times = getFrameTiming(response);
            durations = diff(times(:));
            minDuration = min(durations) / obj.sampleRate;
            maxDuration = max(durations) / obj.sampleRate;
            ideal = 1/obj.stageConfig.refreshRate;
            if minDuration <= ideal/2 || maxDuration >= ideal*2
                lineColor = 'r';
                epoch.addKeyword('badFrameTiming');
            else
                lineColor = 'b';
            end
            
            if obj.numEpochsCompleted == 1
                fig = get(axesHandle, 'Parent');
                
                plotData.axes1 = subplot(2, 1, 1, 'Parent', fig);
                plotData.flipDurationsLine = line(1:numel(info.flipDurations), info.flipDurations, 'Parent', plotData.axes1);
                xlabel(plotData.axes1, 'flip');
                ylabel(plotData.axes1, 'sec');
                title(plotData.axes1, 'Software-based Timing');
                
                plotData.axes2 = subplot(2, 1, 2, 'Parent', fig);
                plotData.frameMonitorLine = line((1:numel(response))/sampleRate, response, 'Parent', plotData.axes2, 'Color', lineColor);
                xlabel(plotData.axes2, 'sec');
                ylabel(plotData.axes2, units);
                title(plotData.axes2, 'Frame Monitor Timing');
            else
                set(plotData.flipDurationsLine, 'Xdata', 1:numel(info.flipDurations), 'Ydata', info.flipDurations);
                set(plotData.frameMonitorLine, 'Xdata', (1:numel(response))/sampleRate, 'Ydata', response, 'Color', lineColor);
            end
        end
        
        
        function preloadQueue(obj) %#ok<MANU>
            % Do nothing to suppress preloading. 
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Enable wait for trigger so the epoch and presentation may be syncronized.
            epoch.waitForTrigger = true;
        end
        
        
        function preparePresentation(obj, presentation) %#ok<INUSD>
            % Override this method to add stimuli and controllers to the visual presentation.
        end
        
        
        function playPresentation(obj, presentation)
            % Override this method to change how to presentation is played (i.e. play or replay?).
            obj.stage.play(presentation);
        end
        
        
        function queueEpoch(obj, epoch)
            % Ensure the DAQ is "waiting for trigger" before playing the presentation.
            daqReady = false;
            hardwareStarted = addNetListener(obj.rigConfig.controller.DAQController, 'StartedHardware', 'Symphony.Core.TimeStampedEventArgs', @startedHardware);
            removeListener = onCleanup(@()removeNetListener(obj.rigConfig.controller.DAQController, 'StartedHardware', hardwareStarted));
            
            function startedHardware(src, data) %#ok<INUSD>
                daqReady = true;
            end
            
            % Queue the epoch.
            queueEpoch@PulsedProtocol(obj, epoch);
                        
            % Create the Stage presentation.
            duration = (obj.preTime + obj.stimTime + obj.tailTime) * 1e-3;
            presentation = Presentation(duration);
            obj.preparePresentation(presentation);
            
            % Hide all stimuli during the pre- and tail- time.
            stimuli = presentation.stimuli;
            for i = 1:length(stimuli)
                stim = stimuli{i};
                controller = PropertyController(stim, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
                presentation.addController(controller);
            end
            
            % Add frame tracker for light monitor.

            tracker = FrameTracker();
            if obj.stageConfig.isTripleHead
                tracker.size = obj.canvasSize;
                tracker.position = obj.canvasSize/2 + [obj.canvasSize(1),0];
            else
                tracker.size = [(1/6)*obj.canvasSize(1) obj.canvasSize(2)];
                tracker.position = [obj.canvasSize(1)-tracker.size(1)/2,obj.canvasSize(2)/2];
            end

            presentation.addStimulus(tracker);
            
            % Hide the epoch so it doesn't ship over with the property controller.
            epoch = [];
            
            % Set frame tracker to black on last frame.
            trackerColor = PropertyController(tracker, 'color', @(s)setTrackerColor(s, duration));
            function c = setTrackerColor(s, dur)
                if s.time + s.frameDuration >= dur
                    c = 0;
                else
                    c = 1;
                end
            end
            presentation.addController(trackerColor);
            
            % Wait until the DAQ is ready.
            if isa(obj.rigConfig.controller, 'System.Object')
                while ~daqReady && strcmp(obj.state, 'running')
                    pause(0.01);
                end
            end
            delete(removeListener);
            
            % Start playing the stage presentation on the remote server.
            obj.playPresentation(presentation);
        end
        
        
        function waitToContinueQueuing(obj)
            waitToContinueQueuing@PulsedProtocol(obj);
            
            % Wait until the previous epoch and interval are complete.
            while (obj.numEpochsQueued > obj.numEpochsCompleted || obj.numIntervalsQueued > obj.numIntervalsCompleted) && strcmp(obj.state, 'running')
                pause(0.01);
            end
        end
        
        
        function completeEpoch(obj, epoch)
            % Call the base class method.
            completeEpoch@PulsedProtocol(obj, epoch);
            
            epoch.addParameter('preFrames', obj.preFrames);
            epoch.addParameter('stimFrames', obj.stimFrames);
            epoch.addParameter('tailFrames', obj.tailFrames);
            
            % Add the current OLED brightness setting when possible.
            try %#ok<TRYNC>
                epoch.addParameter('oledBrightness', obj.stage.getOledBrightness());
            end
        end
        
        
        function completeRun(obj)
            % Call the base class method.
            completeRun@PulsedProtocol(obj);
            
            obj.stage.clearSessionData();
        end
        
        
        function sobj = saveobj(obj)
            % The entire protocol is serialized and sent to the remote Stage server. Some properties may be set to empty
            % to reduce the size of the serialized protocol.
            sobj = copy(obj);
            sobj.symphonyUI = [];
            sobj.rigConfig = [];
            sobj.persistor = [];
            sobj.figureHandlers = [];
            sobj.log = [];
        end
        
    end
    
    methods
        
        % Convenience methods.
        
        function p = um2pix(obj, um)
            p = round(um / obj.stageConfig.micronsPerPixel);
        end
        
        
        function s = get.stage(obj)
            s = obj.rigConfig.stage;
        end
        
        
        function s = get.canvasSize(obj)
            s = obj.stageConfig.size;
        end
        
        
        function frames = get.preFrames(obj)
            frames = ceil(obj.preTime / 1e3 * obj.stageConfig.refreshRate);
        end
        
        
        function frames = get.stimFrames(obj)
            frames = ceil((obj.preTime + obj.stimTime) / 1e3 * obj.stageConfig.refreshRate) - obj.preFrames;
        end
        
        
        function frames = get.tailFrames(obj)
            frames = obj.totalFrames - obj.preFrames - obj.stimFrames;
        end
        
        
        function frames = get.totalFrames(obj)
            frames = ceil((obj.preTime + obj.stimTime + obj.tailTime) / 1e3 * obj.stageConfig.refreshRate);
        end
        
    end
    
end