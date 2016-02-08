classdef AutoRC < PulsedProtocol
    
    properties (Constant)
        identifier = 'angueyra.AutoRC'
        version = 1
        displayName = 'AutoRC'
    end
    
    properties
        amp
        preTime = 15
        stimTime = 30
        tailTime = 15
        pulseAmplitude = 5
        ampHoldSignal = 0
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        amp2HoldSignal = 0
        numberOfAverages = uint16(3)
    end
    
    properties (Hidden)
        cumulativeData
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case {'pulseAmplitude', 'ampHoldSignal'}
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'amp2HoldSignal'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp2).Background.DisplayUnit);
            end
        end
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
                        
            % Open figure handlers.
            obj.openFigure('Response', obj.amp);
            obj.openFigure('Mean Response', obj.amp);
                        
            obj.cumulativeData = zeros(1, obj.totalPts);
            
            % Allow the protocol to preload all epochs.
            obj.epochQueueSize = obj.numberOfAverages;
            
            % Set main amp hold signal.
            obj.setDeviceBackground(obj.amp, obj.ampHoldSignal);
            
            % Set secondary amp hold signal.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.setDeviceBackground(obj.amp2, obj.amp2HoldSignal);
            end
        end
        
   
        function stim = ampStimulus(obj)
            % Main amp stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = obj.ampHoldSignal;
            p.amplitude = obj.pulseAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return main amp stimulus for display in the edit parameters window.
            stimuli{1} = obj.ampStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add main amp stimulus.
            epoch.addStimulus(obj.amp, obj.ampStimulus());
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end