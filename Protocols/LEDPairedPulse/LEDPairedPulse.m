classdef LEDPairedPulse < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.frieke.LEDPairedPulse'
        version = 2
        displayName = 'LED Paired Pulse'
    end
    
    properties
        led1
        preTime = 100
        stimTime = 10
        tailTime = 1000
        lightAmplitude = 1
        lightMean = 0
        led2
        preTime2 = 300
        stimTime2 = 10
        lightAmplitude2 = 1
        lightMean2 = 0
        amp
        ampHoldSignal = -60
    end

    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        amp2HoldSignal = -60
        numberOfAverages = uint8(5)
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
                case {'lightAmplitude', 'lightMean','lightAmplitude2','lightMean2'}
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
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'PlotGroup'});
            end
            
            % Set LED mean.
            obj.setDeviceBackground(obj.led1, obj.lightMean, 'V');
            obj.setDeviceBackground(obj.led2, obj.lightMean2, 'V');
        end
        
        function [stim1,stim2] = ledStimulus(obj, pulseNum)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.lightAmplitude;
            p.mean = obj.lightMean;
            p.sampleRate = obj.sampleRate;
            p.units = 'V';

            if (rem(pulseNum, 3) == 2)
                p.amplitude = 0;
            end
            
            stim1 = p.generate();

            p.preTime = obj.preTime2;
            p.stimTime = obj.stimTime2;
            p.tailTime = (obj.preTime + obj.stimTime + obj.tailTime) - obj.preTime2 - obj.stimTime2;
            p.amplitude = obj.lightAmplitude2;
            p.mean = obj.lightMean2;                

            if (rem(pulseNum, 3) == 1)
                p.amplitude = 0;
            end
            
            stim2 = p.generate();

        end   
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli = cell(6, 1);
  
            for i = 1:3
                [stimuli{2*i-1}, stimuli{2*i}] = obj.ledStimulus(i);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);

            [stim1, stim2] = obj.ledStimulus(obj.numEpochsQueued);
            
            cnt = rem(obj.numEpochsQueued, 3) + 1;
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

