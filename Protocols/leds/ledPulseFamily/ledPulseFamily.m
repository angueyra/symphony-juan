classdef ledPulseFamily < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDPulseFamily'
        version = 4
        displayName = 'LED Pulse Family'
    end
    
    properties
        led
        preTime = 10
        stimTime = 100
        tailTime = 400
        firstLightAmplitude = 0.1
        pulsesInFamily = uint16(3)
        lightMean = 0
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
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case {'firstLightAmplitude', 'lightMean'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'interpulseInterval'
                    p.units = 's';
                case 'pulsesInFamily'
                    units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if units == Symphony.Core.Measurement.NORMALIZED
                        p.isValid = obj.amplitudeForPulseNum(obj.pulsesInFamily) <= 1;
                    else
                        p.isValid = obj.amplitudeForPulseNum(obj.pulsesInFamily) <= 10.239;
                    end
                    if ~p.isValid
                        p.description = 'The last pulse amplitude is too big';
                    end
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2, 'GroupByParams', {'lightAmplitude'});
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Response', obj.amp);
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'lightAmplitude'});
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, obj.lightMean);
        end
        
        
        function [stim, lightAmplitude] = ledStimulus(obj, pulseNum)
            % Calculate a light amplitude for the pulse number.
            lightAmplitude = obj.amplitudeForPulseNum(pulseNum);
            
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = obj.lightMean;
            p.amplitude = lightAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function amplitude = amplitudeForPulseNum(obj, pulseNum)
            amplitude = obj.firstLightAmplitude * 2^(double(pulseNum) - 1);
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli = cell(obj.pulsesInFamily, 1);
            for i = 1:obj.pulsesInFamily
                stimuli{i} = obj.ledStimulus(i);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add LED stimulus.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, lightAmplitude] = obj.ledStimulus(pulseNum);
            
            epoch.addParameter('lightAmplitude', lightAmplitude);
            epoch.addStimulus(obj.led, stim);
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
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the defined number of averages is reached.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end

