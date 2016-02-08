classdef LEDGammaMeasurement < SymphonyProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDGammaMeasurement'
        version = 3
        displayName = 'LED Gamma Measurement'
    end
    
    properties
        led
        preTime = 500
        stimTime = 750
        tailTime = 500
    end
    
    properties (Constant)
        numSteps = 100
        zeroOffset = -0.0005
    end
    
    properties (Hidden)
        currentStep
        outputs
        measurements
        optometer
        plotData
        lookupTable
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);
            
            switch parameterName
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
            end
        end
        
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            dn = {'Optometer'};
        end
        
        
        function prepareRun(obj)
            % Call the base class method.
            prepareRun@SymphonyProtocol(obj);
            
            % Open figure handlers.
            obj.openFigure('Response', 'Optometer');
            obj.openFigure('Custom', 'Name', 'Gamma Table', 'UpdateCallback', @updateGammaTable);
            
            % Create output intensities that grow exponentially from zero offset to 1.
            outs = 1.05.^(1:obj.numSteps)';
            outs = (outs - min(outs)) / (max(outs) - min(outs));
            outs = (outs * (1 - obj.zeroOffset)) + obj.zeroOffset;
            obj.outputs = outs;
            
            obj.currentStep = 1;
            obj.measurements = zeros(obj.numSteps, 1);
            
            % Store the current lookup table.
            dev = obj.rigConfig.deviceWithName(obj.led);
            if ~isprop(dev, 'LookupTable')
                error([obj.led ' must have an associated lookup table']);
            end
            obj.lookupTable = dev.LookupTable;
            
            % Set a linear lookup table.
            lut = NET.createGeneric('System.Collections.Generic.SortedList', {'System.Decimal', 'System.Decimal'});
            lut.Add(obj.zeroOffset, obj.zeroOffset);
            lut.Add(1, 1);
            dev.LookupTable = lut;
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, obj.zeroOffset);
            
            obj.optometer = OptometerUDT350(OptometerUDT350.gainMin);
        end
        
        
        function updateGammaTable(obj, epoch, axesHandle)
            
            if obj.numEpochsCompleted == 1
                % Initialize plot.
                title(axesHandle, ['Optometer Power Measurement vs. ' humanReadableParameterName(obj.led) ' Intensity']);
                xlabel(axesHandle, 'Intensity (normalized)');
                ylabel(axesHandle, 'Power (µW)');
                set(axesHandle, 'Box', 'off', 'TickDir', 'out');
                obj.plotData.gammaLineHandle = line(0, 0, 'Parent', axesHandle);
            end
            
            response = epoch.response('Optometer') * 1e3; % V to mV
            
            prePts = round(obj.preTime / 1e3 * obj.sampleRate);
            stimPts = round(obj.stimTime / 1e3 * obj.sampleRate);
            measurementStart = prePts + (stimPts / 2);
            measurementEnd = prePts + stimPts;
            
            baseline = mean(response(1:prePts));
            measurement = mean(response(measurementStart:measurementEnd));
            
            % Change gain, if necessary.
            outputMax = obj.optometer.outputMax;
            outputMin = obj.optometer.outputMax / obj.optometer.gainStepMultiplier;
            outputMin = outputMin * 0.8;
            
            if measurement > outputMax && obj.optometer.gain < obj.optometer.gainMax
                obj.optometer.increaseGain();
                return;
            elseif measurement < outputMin && obj.optometer.gain > obj.optometer.gainMin
                obj.optometer.decreaseGain();
                return;
            end
            
            % No gain adjustments were required, we can now record the measured intensity.
            obj.measurements(obj.currentStep) = (measurement - baseline) * obj.optometer.microwattPerMillivolt * obj.optometer.gain;
            
            set(obj.plotData.gammaLineHandle, 'Xdata', obj.outputs(1:obj.currentStep), 'Ydata', obj.measurements(1:obj.currentStep));
            xlim(axesHandle, [min(obj.outputs(1:obj.currentStep)) - 0.05, max(obj.outputs(1:obj.currentStep)) + 0.05]);
            ylim(axesHandle, [min(obj.measurements) - 0.05, max(obj.measurements) + 0.05]);
            
            obj.currentStep = obj.currentStep + 1;
        end
        
        
        function stim = ledStimulus(obj, step)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.outputs(step) - obj.zeroOffset;
            p.mean = obj.zeroOffset;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Add LED stimulus.
            epoch.addStimulus(obj.led, obj.ledStimulus(obj.currentStep));
        end
        
        
        function preloadQueue(obj)
            % Do not preload the epoch queue.
        end
        
        
        function waitToContinueQueuing(obj)
            % Call the base class method.
            waitToContinueQueuing@SymphonyProtocol(obj);
            
            % Wait for the previous epoch to complete before queuing another epoch.
            while obj.numEpochsQueued > obj.numEpochsCompleted && strcmp(obj.state, 'running')
                pause(0.01);
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.currentStep <= obj.numSteps;
            end
        end
        
        
        function completeRun(obj)
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
            
            % Restore the old lookup table.
            obj.rigConfig.deviceWithName(obj.led).LookupTable = obj.lookupTable;
            if obj.currentStep > obj.numSteps
                % Save the gamma table.
                
                % Normalize measurements with span from 0 to 1.
                mrange = range(obj.measurements);
                baseline = min(obj.measurements);
                xRamp = (obj.measurements - baseline) / mrange;
                yRamp = obj.outputs;
                
                measures = obj.measurements;
                dateVector = clock;
                dateString = datestr(dateVector);
                
                % Save the ramp and measurements to file.
                [filename, pathname] = uiputfile('*.mat', 'Save Gamma Table');
                if ~isequal(filename, 0) && ~isequal(pathname, 0)
                    save(fullfile(pathname, filename), 'xRamp', 'yRamp', 'measures', 'dateVector', 'dateString');
                end
            end
        end
        
    end
end
