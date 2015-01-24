classdef ResistanceAndCapacitance < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.ResistanceAndCapacitance'
        version = 4
        displayName = 'Resistance and Capacitance'
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
        numberOfAverages = uint16(10)
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
        
        
        function [tf , msg] = isCompatibleWithRigConfig(obj, rigConfig)
            % Call the base method.
            [tf, msg] = isCompatibleWithRigConfig@PulsedProtocol(obj, rigConfig);
            
            % Check if MATLAB has curve fitting toolbox.
            if tf
               v = ver;
               if ~any(strcmp('Curve Fitting Toolbox', {v.Name}))
                   tf = false;
                   msg = 'This protocol requires Curve Fitting Toolbox.';
               end
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
                        
            % Open figure handlers.
            obj.openFigure('Response', obj.amp);
            obj.openFigure('Mean Response', obj.amp);
            obj.openFigure('Custom', 'ID', 'rcResults', 'UpdateCallback', @updateFigure);
            
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
        
        
        function updateFigure(obj, epoch, axesHandle)
            cla(axesHandle);
            set(axesHandle, 'XTick', [], 'YTick', []);
            
            [response, sampleRate] = epoch.response(obj.amp);
            
            obj.cumulativeData = obj.cumulativeData + response;
            
            if obj.numEpochsCompleted < obj.numberOfAverages
                text(0.5, 0.5, 'Accumulating data...', 'FontSize', 20, 'HorizontalAlignment', 'center');
                return;
            end
            
            % Done accumulating data, calculate the results.
            
            % Mean data.
            data = obj.cumulativeData / obj.numEpochsCompleted;
            
            % Calculate baseline current before step.
            baseline = mean(data(1:obj.prePts));
            
            % Curve fit the transient with a single exponential.
            [~, peakPt] = max(data(obj.stimStart:obj.stimEnd));
            
            fitStartPt = obj.stimStart + peakPt - 1;
            fitEndPt = obj.stimEnd;
            
            sampleInterval = 1 / sampleRate * 1e3; % ms
            
            fitTime = (fitStartPt:fitEndPt) * sampleInterval;
            fitData = data(fitStartPt:fitEndPt);
            
            fitFunc = @(a,b,c,x) a*exp(-x/b)+c;
            
            % Initial guess for a, b, and c.
            p0 = [max(fitData) - min(fitData), (max(fitTime) - min(fitTime)) / 2, mean(fitData)];
            
            curve = fit(fitTime', fitData', fitFunc, 'StartPoint', p0);
            
            tauCharge = curve.b;
            currentSS = curve.c;
            
            % Extrapolate single exponential back to where the step started to calculate the series resistance.
            current0 = curve(obj.stimStart * sampleInterval) - baseline;
            rSeries = (0.005 / (current0 * 1e-12)) / 1e6;
            
            % Calculate charge, capacitance, and input resistance.
            subtractStartPt = obj.stimStart;
            subtractEndPt = obj.stimEnd;
            
            subtractStartTime = subtractStartPt * sampleInterval;
            subtractTime = (subtractStartPt:subtractEndPt) * sampleInterval;
            subtractData = baseline + (currentSS - baseline) * (1 - exp(-(subtractTime - subtractStartTime) / tauCharge));
            
            charge = trapz(subtractTime, data(subtractStartPt:subtractEndPt)) - trapz(subtractTime, subtractData);
            
            capacitance = charge / obj.pulseAmplitude;
            rInput = (obj.pulseAmplitude * 1e-3) / ((currentSS - baseline) * 1e-12) / 1e6;
            
            % Display results.
            text(0.5, 0.5, ...
                {['R_{in} = ' num2str(rInput) ' MOhm']; ...
                ['R_{s} = ' num2str(rSeries) ' MOhm']; ...
                ['R_{m} = ' num2str(rInput - rSeries) ' MOhm']; ...
                ['R_{\tau} = ' num2str(tauCharge / (capacitance * 1e-12) / 1e9) ' MOhm']; ...
                ['C_{m} = ' num2str(capacitance) ' pF']; ...
                ['\tau = ' num2str(tauCharge) ' ms']} ...
                , 'FontSize', 20, 'HorizontalAlignment', 'center');
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

