classdef ledPulseAll < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDPulse'
        version = 4
        displayName = 'LED Pulse (all)'
    end
    
    properties
        led1
        led2
        led3
        preTime = 10
        stimTime = 200
        tailTime = 490
        lightAmplitude1 = 4
        lightAmplitude2 = 4
        lightAmplitude3 = 4
        lightMean1 = 0
        lightMean2 = 0
        lightMean3 = 0
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
                case {'led1', 'led2','led3'}
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                    p.description = 'select corresponding LED from rig configuration';
                case {'lightAmplitude1', 'lightMean1'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led1).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case {'lightAmplitude2', 'lightMean2'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led2).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case {'lightAmplitude3', 'lightMean3'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led3).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
%             prepareRun@AutoRCProtocol(obj);
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
%                 obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
%                 obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Data', obj.amp);
%                 obj.openFigure('Response', 'LED_455');
                obj.openFigure('Mean Response', obj.amp);
%                 obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
%                 obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led1, obj.lightMean1);
            obj.setDeviceBackground(obj.led2, obj.lightMean2);
            obj.setDeviceBackground(obj.led3, obj.lightMean3);
            
        end
        
        function stim = ledStimulus(obj,LED,cnt)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            

            switch cnt
                case 1
                    p.mean = obj.lightMean1;
                    p.amplitude = obj.lightAmplitude1;
                    p.units = char(obj.rigConfig.deviceWithName(LED).Background.DisplayUnit);
                case 2
                    p.mean = obj.lightMean2;
                    p.amplitude = obj.lightAmplitude2;
                    p.units = char(obj.rigConfig.deviceWithName(LED).Background.DisplayUnit);
                case 3
                    p.mean = obj.lightMean3;
                    p.amplitude = obj.lightAmplitude3;
                    p.units = char(obj.rigConfig.deviceWithName(LED).Background.DisplayUnit);
            end
            
            p.sampleRate = obj.sampleRate;
            
            stim = p.generate();
            
        end
         
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli{1} = obj.ledStimulus(obj.led1,1);
            stimuli{2} = obj.ledStimulus(obj.led2,2);
            stimuli{3} = obj.ledStimulus(obj.led3,3);
        end
        
        
        function prepareEpoch(obj, epoch)
%             prepareEpoch@AutoRCProtocol(obj, epoch);
%             if obj.addedRCEpoch
%                 % Do nothing?
%             else
                prepareEpoch@PulsedProtocol(obj, epoch);
                % Add LED stimulus.
                epoch.addStimulus(obj.led1, obj.ledStimulus(obj.led1,1));
                epoch.addStimulus(obj.led2, obj.ledStimulus(obj.led2,2));
                epoch.addStimulus(obj.led3, obj.ledStimulus(obj.led3,3));
%             end
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

