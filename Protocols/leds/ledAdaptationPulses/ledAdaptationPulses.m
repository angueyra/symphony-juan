classdef ledAdaptationPulses < PulsedProtocol
    
    
    properties (Constant)
        identifier = 'edu.washington.rieke.jbaudin.AdaptationPulses'
        version = 1
        displayName = 'Adaptation Pulses'
    end
    
    properties
        
        
        
        LED
        
        flashBeforeStep = 20
        flashDuringStep = 20
        flashAfterStep = 20
        
        adaptAmp = 1
        flashPreTime = 10
        flashStimTime = 10
        flashTailTime = 200
        flashAmpOnMean = .5
        flashAmpOnAdapt = .75
        
        interpulseInterval = 0;
        
        amp
        
        numAverages = uint8(5)
        
        
        
        
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    
    properties (Dependent, Hidden)
        
        preTime
        stimTime
        tailTime
        
        flashDuration
        
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
                case 'flashPreTime'
                    p.units = 'ms';
                    p.description = 'time preceding each flash';
                case 'flashStimTime'
                    p.units = 'ms';
                    p.description = 'duration of flashes';
                case 'flashTailTime'
                    p.units = 'ms';
                    p.description = 'tail time following each flash';
                case 'flashBeforeStep'
                    p.description = 'number of flashes given before adapting step - determines time before step';
                case 'flashDuringStep'
                    p.description = 'number of flashes given during adapting step - determines step duration';
                case 'flashAfterStep'
                    p.description = 'number of flashes following return to mean after adapting step - determines time following step';
                case 'numAverages'
                    p.description = 'number of epochs to average';
                case 'adaptAmp'
                    p.description = 'amplitude of adapting step';
                    p.units = 'V';
                    
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                % obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                % obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                
            else
                
                obj.openFigure('Response', obj.amp);
                obj.openFigure('Mean Response', obj.amp);
                % obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                % obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.LED, obj.mean, 'V');
            
        end
        
        
        
        function stim = ledStimulus(obj)
            
            % create adaptation kinetics stimulus object
            p = AdaptationPulsesGenerator();
            
            
            
            
            p.mean = obj.mean; % mean light levels to have serve as background upon which to
            % deliver adapting step and additional flashes
            
            
            p.numFlashBeforeStep = obj.flashBeforeStep; % this along with flash duration determines length
            % before step
            p.numFlashDuringStep = obj.flashDuringStep; % this along with flash duration determines length
            % of step
            p.numFlashAfterStep = obj.flashAfterStep; % this along with flash duration determines length
            % following step
            
            p.adaptAmp = obj.adaptAmp;% amplitude of the adapting step
            
            p.flashPreTime = obj.flashPreTime;
            p.flashStimTime = obj.flashStimTime; % duration of the flash stimulus
            p.flashTailTime = obj.flashTailTime; % tail points to require after flash -- this also will
            % define where the constant flash on the adapting background will
            % fall relative to the removal of the adapting flash back to the
            % mean background -- this constant flash will occur such that it
            % precedes the return to mean by flashTailTime
            p.flashAmpOnMean = obj.flashAmpOnMean; % amp of flash when on mean background
            p.flashAmpOnAdapt = obj.flashAmpOnAdapt;% amp of flash when on adapting background (likely higher)
            
            
            p.sampleRate   = obj.sampleRate;
            p.units = 'V';
            p.mean = obj.mean;
            
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            
            stimuli{1} = obj.ledStimulus();
            
        end
        
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            
            % Add LED stimulus.
            epoch.addStimulus(obj.LED, obj.ledStimulus());
            
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
                keepQueuing = obj.numEpochsQueued < obj.numAverages;
            end
            
            fprintf('epoch number %d has queued \n', obj.numEpochsQueued);
            
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of epochs have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numAverages;
            end
            
            fprintf('epoch number %d has completed \n', obj.numEpochsCompleted);
           
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
        function value = get.mean(obj)
            % use user defined background for LED mean
            device = obj.rigConfig.deviceWithName(obj.LED);
            value = double(System.Convert.ToDouble(device.Background.Quantity));
        end
        
        function value = timeToPts(obj, time)
            value = round(time/1e3 * obj.sampleRate);
        end
        
        function value = get.preTime(obj)
            
            value = obj.flashBeforeStep * obj.flashDuration;
            value = 0;
            
        end
        
        function value = get.stimTime(obj)
            
            value = obj.flashDuringStep * obj.flashDuration;
            value = 0;
            
        end
        
        function value = get.tailTime(obj)
            
            value = obj.flashAfterStep * obj.flashDuration;
            value = 0;
            
        end
        
        function value = get.flashDuration(obj)
            
            value = (obj.flashDuringStep + obj.flashBeforeStep + obj.flashAfterStep) * ...
                (obj.flashPreTime + obj.flashStimTime + obj.flashTailTime);
            
            
        end
        
        
    end
    
end

