classdef ledSine < PulsedProtocol
    
    properties (Constant)
        identifier = 'juan.LEDSine'
        version = 1
        displayName = 'LEDSine'
    end
    
    properties
        led
        preTime = 100
        stimTime = 500
        tailTime = 100
        
        freq = 5
        phase = 0           
        wcontrast = 25          
        mean = 4
        amp
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'freq'
                    p.units = 'Hz';
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case 'mean'
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'phase'
                    p.units = 'deg';
                case 'wcontrast'
                    p.units = '%%';
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
%                 obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
%                 obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Data', obj.amp);
%                 obj.openFigure('Stim', obj.amp);
                obj.openFigure('Mean Response', obj.amp);
%                 obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
%                 obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, obj.mean);
        end
        
        
        function stim = ledStimulus(obj)
            % led stimulus           
            p = SineGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.led);
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
%             p.mean = obj.mean;
            p.freq = obj.freq;
            p.phase = obj.phase;
            p.wcontrast = obj.wcontrast;
            p.freq = obj.freq;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return main amp stimulus for display in the edit parameters window.
            stimuli{1} = obj.ledStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)            
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add led stimulus.
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

