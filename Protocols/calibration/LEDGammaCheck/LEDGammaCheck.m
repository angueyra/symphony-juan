classdef LEDGammaCheck < SymphonyProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.LEDGammaCheck'
        version = 3
        displayName = 'LED Gamma Check'
    end
    
    properties
        led
        preTime = 500
        stimTime = 750
        tailTime = 500
        calibrationIntensity = 0.1
        acceptableError = 0.05
    end
    
    properties (Constant)
        numSteps = 11
        firstStep = 0.001
    end
    
    properties (Hidden)
        currentStep
        outputs
        measurements
        predictions
        failures
        optometer
        plotData
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
                case 'calibrationIntensity'
                    p.units = 'norm. [0-1]';
                case 'acceptableError'
                    p.units = 'ratio';
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
            
            % Create output intensities that grow exponentially from the first step up to the max intensity (1).
            outs = 2.^(1:obj.numSteps)';
            outs = (outs - min(outs)) / (max(outs) - min(outs));
            outs = (outs * (1 - obj.firstStep)) + obj.firstStep;
            obj.outputs = outs;
            
            % Step 0 will be a baseline measurement.
            obj.currentStep = 0;
            
            obj.measurements = zeros(obj.numSteps, 1);
            obj.failures = [];
            
            dev = obj.rigConfig.deviceWithName(obj.led);
            if ~isprop(dev, 'LookupTable')
                error([obj.led ' must have an associated lookup table']);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led, 0);
            
            obj.optometer = OptometerUDT350(10^0);
        end
        
        
        function updateGammaTable(obj, epoch, axesHandle)
            
            if obj.numEpochsCompleted == 1
                % Initialize plot.
                title(axesHandle, ['Optometer Power Measurement vs. ' humanReadableParameterName(obj.led) ' Intensity']);
                xlabel(axesHandle, 'Intensity (normalized)');
                ylabel(axesHandle, 'Power (µW)');
                set(axesHandle, 'Box', 'off', 'TickDir', 'out');
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
            
            % No gain adjustments are required.
            intensity = (measurement - baseline) * obj.optometer.microwattPerMillivolt * obj.optometer.gain;
            
            if obj.currentStep == 0
                % Calculate a predicted intensity for each output value.
                obj.predictions = zeros(obj.numSteps, 1);
                for i = 1:obj.numSteps
                    obj.predictions(i) = intensity * obj.outputs(i) / obj.calibrationIntensity;
                end
                
                % Turn down the optometer gain to start verification.
                obj.optometer.gain = 10^-1;
                obj.currentStep = obj.currentStep + 1;
                return;
            end
            
            obj.measurements(obj.currentStep) = intensity;
            
            lower = obj.predictions(obj.currentStep) - (obj.predictions(obj.currentStep) * obj.acceptableError);
            upper = obj.predictions(obj.currentStep) + (obj.predictions(obj.currentStep) * obj.acceptableError);
            
            if obj.measurements(obj.currentStep) < lower || obj.measurements(obj.currentStep) > upper
                obj.failures(end + 1, 1) = obj.outputs(obj.currentStep);
                obj.failures(end, 2) = obj.measurements(obj.currentStep);
            end
            
            errors = obj.predictions(1:obj.currentStep) * obj.acceptableError;
            
            errorbar(obj.outputs(1:obj.currentStep), obj.predictions(1:obj.currentStep), errors, 'Parent', axesHandle, 'LineStyle', 'none', 'Marker', 's', 'Color', 'g');
            
            hold on;
            line(obj.outputs(1:obj.currentStep), obj.measurements(1:obj.currentStep), 'Parent', axesHandle, 'LineStyle', 'none', 'Marker', 'o', 'Color', 'b');
            
            if isempty(obj.failures)
                legend(axesHandle, 'Predicted', 'Measured');
            else
                line(obj.failures(:,1), obj.failures(:,2), 'Parent', axesHandle, 'LineStyle', 'none', 'LineWidth', 2, 'Marker', 'x', 'MarkerSize', 12,  'Color', 'r');                
                legend(axesHandle, 'Predicted', 'Measured', 'Failed');
            end
            hold off;

            xlim(axesHandle, [min(obj.outputs(1:obj.currentStep)) - 1e-4, max(obj.outputs(1:obj.currentStep)) + 1e-4]);
            ylim(axesHandle, [min(obj.measurements) - 0.01, max(obj.measurements) + 0.01]);
            
            obj.currentStep = obj.currentStep + 1;
        end
        
        
        function stim = ledStimulus(obj, step)
            if obj.currentStep == 0
                output = obj.calibrationIntensity;
            else
                output = obj.outputs(step);
            end
            
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = output;
            p.mean = 0;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base class method which sets up default backgrounds and records responses
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
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
        
    end
end
