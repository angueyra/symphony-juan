classdef Test < PulsedProtocol
    
    properties (Constant)
        identifier = 'angueyra.Test'
        version = 1
        displayName = 'Test'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        pulseAmplitude = 10
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        amp2PulseAmplitude = 0
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'pulseAmplitude'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'amp2PulseAmplitude'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp2).Background.DisplayUnit);
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
                       
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Data', obj.amp);
%                 obj.openFigure('Stim', obj.amp);
                obj.openFigure('Mean Response', obj.amp);
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
        end
        
        
        function stim = ampStimulus(obj)
            % Main amp stimulus.           
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitude = obj.pulseAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(device.Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stim = amp2Stimulus(obj)
            % Secondary amp stimulus.
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp2);
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitude = obj.amp2PulseAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(device.Background.DisplayUnit);
            
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
            
            % Add secondary amp stimulus if the rig config is two amp.
            if obj.rigConfig.numMultiClampDevices() > 1
                epoch.addStimulus(obj.amp2, obj.amp2Stimulus());
            end
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

