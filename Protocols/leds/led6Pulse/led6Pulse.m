classdef led6Pulse < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDPulse'
        version = 4
        displayName = 'LED Pulse 6leds'
    end
    
    properties
        led
        preTime = 10
        stimTime = 200
        tailTime = 490
        lightAmplitude = 4
        lightMean = 0
        led_ctrl = 1
        amp
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numberOfAverages = uint8(2)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case {'lightAmplitude', 'lightMean'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
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
%                 obj.openFigure('Response', 'LED_455');
                obj.openFigure('Mean Response', obj.amp);
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, obj.lightMean);
            obj.setDeviceBackground('led_ctrl',obj.led_ctrl);
            
        end
        
        
        function stim = ledStimulus(obj)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = obj.lightMean;
            p.amplitude = obj.lightAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end   
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli{1} = obj.ledStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add LED stimulus.
            epoch.addStimulus(obj.led, obj.ledStimulus());
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

