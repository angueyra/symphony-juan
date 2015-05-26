classdef ledNoiseFamily < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDNoiseFamily'
        version = 4
        displayName = 'LED Noise Family'
    end
    
    properties
        led
        preTime = 100
        stimTime = 600 %9800
        tailTime = 100
        frequencyCutoff = 60
        numberOfFilters = 4
        startStdv = 0.005
        stdvMultiplier = 3
        stdvMultiples = uint16(3)
        repeatsPerStdv = uint16(5)
        useRandomSeed = false
        lightMean = 0.1
        amp
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numberOfAverages = uint16(5)
        interpulseInterval = 0 %10.5
        previewAll = false
    end
    
    properties (Hidden, Dependent)
        pulsesInFamily
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case 'frequencyCutoff'
                    p.units = 'Hz';
                case {'startStdv', 'lightMean'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'interpulseInterval'
                    p.units = 's';
                case 'previewAll'
                    p.description = 'Show the complete sequence of sample stimuli in the edit parameters window (slow).';
            end
        end
        
        
        function n = get.pulsesInFamily(obj)
            n = obj.stdvMultiples * obj.repeatsPerStdv;
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2, 'GroupByParams', {'stdv'});
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Response', obj.amp);
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'stdv'});
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, obj.lightMean);
        end
        
        
        function [stim, stdv] = ledStimulus(obj, pulseNum, seed)
            % Calculate a standard deviation for the pulse number.
            sdNum = floor((double(pulseNum) - 1) / double(obj.repeatsPerStdv));
            stdv = obj.stdvMultiplier^sdNum * obj.startStdv;
            
            % Main LED stimulus.
            n = GaussianNoiseGenerator();
            
            n.preTime = obj.preTime;
            n.stimTime = obj.stimTime;
            n.tailTime = obj.tailTime;
            n.stDev = stdv;
            n.freqCutoff = obj.frequencyCutoff;
            n.numFilters = obj.numberOfFilters;
            n.mean = obj.lightMean;
            n.seed = seed;
            n.sampleRate = obj.sampleRate;
            n.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            if n.units == Symphony.Core.Measurement.NORMALIZED
                n.upperLimit = 1;
                n.lowerLimit = 0;
            else
                n.upperLimit = 10.239;
                n.lowerLimit = -10.24;
            end
            
            stim = n.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            if obj.previewAll
                numPulses = obj.pulsesInFamily;
            else
                numPulses = 1;
            end
                
            stimuli = cell(numPulses, 1);
            
            for i = 1:numPulses
                
                % Determine seed value.
                if ~obj.useRandomSeed
                    seed = 0;
                elseif mod(i - 1, obj.repeatsPerStdv) == 0
                    seed = RandStream.shuffleSeed;
                end
                    
                stimuli{i} = obj.ledStimulus(i, seed);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Determine seed value.
            persistent seed;
            if ~obj.useRandomSeed
                seed = 0;
            elseif mod(obj.numEpochsQueued, obj.repeatsPerStdv) == 0
                seed = RandStream.shuffleSeed;
            end
            
            % Add LED stimulus.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, stdv] = obj.ledStimulus(pulseNum, seed);
            
            epoch.addParameter('stdv', stdv);
            epoch.addParameter('seed', seed);
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
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end

