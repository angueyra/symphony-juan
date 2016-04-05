classdef ledPairedIncDec < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.frieke.LEDPairedIncDec'
        version = 1
        displayName = 'LED Paired Inc/Dec'
    end
    
    properties
        led1
        lightMean = 0
        DecrementAmplitude = 1
        preTimeDec = 100
        stimTimeDec = 10
        IncrementAmplitude = 1
        preTime = 100
        stimTime = 10
        tailTime = 1000
        led2
        lightMean2 = 0
        DecrementAmplitude2 = 1
        preTimeDec2 = 100
        stimTimeDec2 = 10
        IncrementAmplitude2 = 1
        preTimeInc2 = 100
        stimTimeInc2 = 10
        amp
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end

    properties (Hidden)
        MeanResponse
    end

    properties
        amp2HoldSignal = -60
        numberOfAverages = uint8(30)
        interpulseInterval = 0
    end
    
    methods              
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case {'led1','led2'}
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                    p.description = 'select corresponding LED from rig configuration';
                case {'IncrementAmplitude', 'IncrementAmplitude2', 'lightMean', 'DecrementAmplitude', 'DecrementAmplitude2', 'lightMean2'}
                    p.units = 'V';
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
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2, 'GroupByParams', {'PlotGroup'});
            else
                obj.openFigure('Response', obj.amp);
                obj.openFigure('Custom', 'UpdateCallback', @IncDecAnalysis);
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led1, obj.lightMean, 'V');
            obj.setDeviceBackground(obj.led2, obj.lightMean2, 'V');
        end

        function IncDecAnalysis(obj,epoch,axesHandle)

            [response, sampleRate] = epoch.response(obj.amp);
            response = response-mean(response(1:sampleRate*obj.preTime/1000)); %baseline
            
            response = normrnd(0, 1, length(response), 1);
            
            if (obj.numEpochsCompleted == 1)
                cla(axesHandle);
                set(axesHandle, 'XTick', [], 'YTick', []);
                obj.MeanResponse = cell(6,1);
            end
            
            if (obj.numEpochsCompleted < 7)
                obj.MeanResponse{rem(obj.numEpochsCompleted-1,6)+1} = response;
            else
                obj.MeanResponse{rem(obj.numEpochsCompleted-1,6)+1} = obj.MeanResponse{rem(obj.numEpochsCompleted-1,6)+1} + response;
            end

            switch(rem(obj.numEpochsCompleted-1,6)+1)
                case 1
                    subplot(2, 2, 1); hold on;
                    plot(obj.MeanResponse{1}+5);
                    subplot(2, 2, 3); hold on;
                    plot(obj.MeanResponse{1}+5);
                case 2
                    subplot(2, 2, 2); hold on;
                    plot(obj.MeanResponse{2}+5);
                    subplot(2, 2, 4); hold on;
                    plot(obj.MeanResponse{2}+5);
                case 3
                    subplot(2, 2, 1); hold on;
                    plot(obj.MeanResponse{3}, 'k');
                case 4
                    subplot(2, 2, 3); hold on;
                    plot(obj.MeanResponse{4}, 'k');
                case 5
                    subplot(2, 2, 2); hold on;
                    plot(obj.MeanResponse{5}, 'k');
                case 6
                    subplot(2, 2, 4); hold on;
                    plot(obj.MeanResponse{6}, 'k');
            end
            hold off;
            
        end
        

        function [stim1, stim2] = ledStimulus(obj, pulseNum)
            % Main LED stimulus.
            s = SumGenerator();
            p = PulseGenerator();
            stim = cell(2, 1);
            Duration = obj.preTime + obj.stimTime + obj.tailTime;

            % LED1 increment
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.IncrementAmplitude;
            p.mean = obj.lightMean;
            p.sampleRate = obj.sampleRate;
            p.units = 'V';
            
            if (rem(pulseNum, 6) == 2 | rem(pulseNum, 6) == 5 | rem(pulseNum, 6) == 0)
                p.amplitude = 0;
            end
            stim{1} = p.generate();

            % LED1 decrement            
            p.preTime = obj.preTimeDec;
            p.stimTime = obj.stimTimeDec;
            p.tailTime = Duration - obj.preTimeDec - obj.stimTimeDec;
            p.amplitude = obj.DecrementAmplitude;
            p.mean = 0;

            if (rem(pulseNum, 6) == 1 | rem(pulseNum, 6) == 2 | rem(pulseNum, 6) == 4 | rem(pulseNum, 6) == 0)
                p.amplitude = 0;
            end
            stim{2} = p.generate();
            
            s.stimuli = stim;
            stim1 = s.generate();
            
            % LED2 increment
            p.preTime = obj.preTimeInc2;
            p.stimTime = obj.stimTimeInc2;
            p.tailTime = Duration - obj.preTimeInc2 - obj.stimTimeInc2;
            p.amplitude = obj.IncrementAmplitude2;
            p.mean = obj.lightMean2;
            
            if (rem(pulseNum, 6) == 1 | rem(pulseNum, 6) == 3 | rem(pulseNum, 6) == 4)
                p.amplitude = 0;
            end
            stim{1} = p.generate();
 
            % LED2 decrement
            p.preTime = obj.preTimeDec2;
            p.stimTime = obj.stimTimeDec2;
            p.tailTime = Duration - obj.preTimeDec2 - obj.stimTimeDec2;
            p.amplitude = obj.DecrementAmplitude2;
            p.mean = 0;

            if (rem(pulseNum, 6) == 1 | rem(pulseNum, 6) == 2 | rem(pulseNum, 6) == 3 | rem(pulseNum, 6) == 5)
                p.amplitude = 0;
            end
            stim{2} = p.generate();
            
            s.stimuli = stim;
            stim2 = s.generate();
           
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
  
            stimuli = cell(2, 1);
            [stimuli{1}, ~] = obj.ledStimulus(3);
            [~, stimuli{2}] = obj.ledStimulus(6);
            
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);

            [stim1, stim2] = obj.ledStimulus(obj.numEpochsQueued);
            
            cnt = rem(obj.numEpochsQueued-1, 6) + 1;
            epoch.addParameter('PlotGroup', cnt);

            epoch.addStimulus(obj.led1, stim1);
            epoch.addStimulus(obj.led2, stim2);
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

