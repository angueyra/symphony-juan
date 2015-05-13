classdef MonitorGammaCheck < StageProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.MonitorGammaCheck'
        version = 3
        displayName = 'Monitor Gamma Check'
    end
    
    properties
        amp
        preTime = 500
        stimTime = 750
        tailTime = 500
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numSteps = uint16(16)
    end
    
    properties (Hidden)
        currentStep
        outputs
        measurements
        optometer
        plotData
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            switch parameterName
            end
        end
        
        
        function dn = requiredDeviceNames(obj)
            dn = requiredDeviceNames@StageProtocol(obj);
            dn = [dn, 'Optometer'];
        end
        
        
        function prepareRun(obj)
            % Call the base class method.
            prepareRun@StageProtocol(obj);
            
            % Open figure handlers.
            obj.openFigure('Response', 'Optometer');
            obj.openFigure('Custom', 'Name', 'Gamma Table', 'UpdateCallback', @updateGammaTable);
            
            % Create output intensities that grow from 0 to 1.
            obj.outputs = linspace(0, 1, obj.numSteps);
            
            obj.currentStep = 1;
            obj.measurements = zeros(1, obj.numSteps);
            
            % Set the remote canvas color.
            obj.rigConfig.stage.setCanvasClearColor(0);
            
            obj.optometer = OptometerUDT350(OptometerUDT350.gainMin);
        end
        
        
        function updateGammaTable(obj, epoch, axesHandle)
            
            if obj.numEpochsCompleted == 1
                % Initialize plot.
                title(axesHandle, 'Optometer Power Measurement vs. Intensity');
                xlabel(axesHandle, 'Output (inten.)');
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
        
        
        function preparePresentation(obj, presentation)
            rect = Rectangle();
            rect.position = obj.canvasSize / 2;
            rect.size = [300, 300];
            
            function c = getRectColor(obj)
                c = obj.outputs(obj.currentStep);
            end
            rectColorController = PropertyController(rect, 'color', @(state)getRectColor(obj));
            
            presentation.addStimulus(rect);
            presentation.addController(rectColorController);
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
            if keepGoing
                keepGoing = obj.currentStep <= obj.numSteps;
            end
        end
        
        
        function completeRun(obj)
            % Call the base class method.
            completeRun@StageProtocol(obj);
            
            if obj.currentStep > obj.numSteps
                
                % Normalize measurements with span from 0 to 1.
                mrange = range(obj.measurements);
                baseline = min(obj.measurements);
                
                outs = obj.outputs;
                values = (obj.measurements - baseline) / mrange;
                
                % Create ideal linear gamma vector.
                linear = linspace(0, 1, 256);
                
                figure('Name', 'Gamma', 'NumberTitle', 'off');
                plot(outs, values, '.', ((0:255)/255), linear, '-');
                legend('Measurements', 'Ideal');
            end
        end
        
        
        function sobj = saveobj(obj)
            sobj = saveobj@StageProtocol(obj);
            sobj.optometer = [];
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
end
