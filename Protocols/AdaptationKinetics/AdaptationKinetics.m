classdef AdaptationKinetics < PulsedProtocol
    
    
    properties (Constant)
        identifier = 'edu.washington.rieke.jbaudin.AdaptationKinetics'
        version = 1
        displayName = 'Adaptation Kinetics'
    end
    
    properties
        
        %%%% do we want to add and LED option here?  should the flash and
        %%%% the step be from the same or different LEDs? Bye.
        
        LED
        preTime = 1000
        stimTime = 2000
        tailTime = 2000
        adaptAmp = 1
        flashStimTime = 10
        flashTailTime = 200
        flashAmpOnMean = .5
        flashAmpOnAdapt = .75
        delay = 100
        logScale = 2
        numDelays = uint64(4)
        interpulseInterval = 0;
        
        amp
        
        
        %         red_LED
        %         green_LED
        %         blue_LED
        %         preTime = 10
        %         stimTime = 100
        %         tailTime = 400
        %         redLEDAmplitude = 0
        %         greenLEDAmplitude = 0
        %         blueLEDAmplitude = 0
        
        
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
        % may not need
    end
    
    properties (Dependent, Hidden)
        
        mean
        
    end
    
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                
                case {'LED'}
                    % the deviceNames protocol for rig configuration
                    % searches for the argument (a string) in the names of
                    % the devices on the rig configuration
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                    p.description = 'select corresponding LED from rig configuration';
                    
                case 'flashAmpOnAdapt' % light mean may not be necessary
                    p.units = 'V';
                    p.description = 'amplitude of flash delivered during adapting step';
                case 'flashAmpOnMean'
                    p.units = 'V';
                    p.description = 'amplitude of flash delivered before or after adapting step';
                case 'interpulseInterval'
                    p.units = 's';
                    p.description = 'time interval between pulses';
                case 'adaptPreTime'
                    p.units = 'ms';
                    p.description = 'time preceding adapting step';
                case 'adaptStimTime'
                    p.units = 'ms';
                    p.description = 'duration of adapting step';
                case 'adaptTailTime'
                    p.units = 'ms';
                    p.description = 'time following adapting step';
                case 'flashStimTime'
                    p.units = 'ms';
                    p.description = 'duration of flashes superimposed on adapting step or mean';
                case 'flashTailTime'
                    p.units = 'ms';
                    p.description = ['require tail points to follow superimposed ' ...
                        'flashes - this will also determine the point at which ' ...
                        'the constant flashes will be delivered'];
                case 'delay'
                    p.units = 'ms';
                    p.description = ['delay before variable flashes that will '...
                        'be scaled by the log scale parameter on successive epochs'];
                case 'logScale'
                    p.description = 'scale factor by which delay is scaled on successive epochs';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                % obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                % obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                % obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                
            else
                
                obj.openFigure('Response', obj.amp);
                % obj.openFigure('Mean Response', obj.amp);
                % obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                % obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.LED, obj.mean, 'V');
            
        end
        
        
        
        function stim = ledStimulus(obj, epochNum)
            
            % create adaptation kinetics stimulus object
            p = AdaptationKineticsGenerator();
            
            p.adaptPreTime = obj.preTime; % time before the adapting step
            p.adaptStimTime = obj.stimTime; % duration of the adapting step
            p.adaptTailTime = obj.tailTime; % time following the adapting step
            p.adaptAmp = obj.adaptAmp; % amplitude of the adapting step
            
            p.flashStimTime = obj.flashStimTime; % duration of the flash stimulus
            p.flashTailTime = obj.flashTailTime; % tail points to require after flash -- this also will
            % define where the constant flash on the adapting background will
            % fall relative to the removal of the adapting flash back to the
            % mean background -- this constant flash will occur such that it
            % precedes the return to mean by flashTailTime
            p.flashAmpOnMean = obj.flashAmpOnMean; % amp of flash when on mean background
            p.flashAmpOnAdapt = obj.flashAmpOnAdapt; % amp of flash when on adapting background (likely higher)
            
            p.delay = obj.delay; % delay before variable timing flash -- will be
            % scaled by the log scale for successive trials
            p.logScale = obj.logScale; % scale by which to scale the delay
            % for successive trials
            
            %%%% figure this out
            p.epochNum = epochNum; % start from 0 -- this would the case where no additional
            % flashes would be delivered, 1 would be where the constant flashes
            % were delivered without any variable ones, and if epochNum > 1, it
            % would be the case where variable flashes were added with a delay
            % of delay*(logScale^(epochNum-1))
            
            p.sampleRate   = obj.sampleRate;
            p.units = 'V';
            p.mean = obj.mean;
            
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli = cell(1, obj.numDelays+2);
            % create all sample stimuli
            for stim = 1:obj.numDelays+2
                stimuli{stim} = obj.ledStimulus(stim);
            end
        end
        
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            
            % Add LED stimulus.
            epoch.addStimulus(obj.LED, obj.ledStimulus(obj.numEpochsQueued + 1));
            
        end
        
        
        function queueEpoch(obj, epoch)
            % Call the base method to queue the actual epoch.
            queueEpoch@PulsedProtocol(obj, epoch);
            
            % Queue the inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            % Keep queuing until the requested number of epochs have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numDelays + 2;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of epochs have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numDelays + 2;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
        function value = get.mean(obj)
            % use user defined background for LED mean
            device = obj.rigConfig.deviceWithName(obj.LED);
            value = double(System.Convert.ToDouble(device.Background.Quantity));
        end
        
        function value = pulseSpacingValid(obj)
            % this will return true or false aftering checking to see if the
            % current parameter set allows for appropriate spacing of the
            % flashes -- ie, the variable flashes (with their tail time included
            % should not extend to the static flashes -- if they do, either
            % numDelays, logScale, delay, stimTime, tailTime, or
            % flashTailTime need to change -- different combinations of
            % changes can also bring the parameter set back to a valid point
            
            value = 1;
            
            latestFlashPoint = obj.timeToPoints(obj.flashTailPoints) + ...
                obj.timeToPts(obj.delay)*((obj.logScale)^(obj.numDelays-2));
            
            if latestFlashPoint > obj.timeToPts(obj.stimTime - obj.flashStimTime - obj.flashTailTime)
                % checks if variable flashes will extend too far on
                % section where an adapting background is present
                value = 0;
            elseif latestFlashPoint > obj.timeToPts(obj.tailTime - obj.flashStimTime - obj.flashTailTime)
                % checks if variable flashes will extend too far on section
                % after pulse has ended and background has returned to mean
                value = 0;
            end
            
        end
        
        function value = timeToPts(obj, time)
            value = round(time/1e3 * obj.sampleRate);
        end
    end
    
end

