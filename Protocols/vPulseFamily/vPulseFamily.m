classdef vPulseFamily < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.PulseFamily'
        version = 4
        displayName = 'vDoublePulse Family'
    end
    
    properties
        amp
        preTime = 500
        stimTimeL = 2000
        stimTimeR = 2000
        tailTime = 500
        firstPulseSignalL = 100
        incrementPerPulseL = 0
        firstPulseSignalR = 100
        incrementPerPulseR = 10
        pulsesInFamily = uint16(11)
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        amp2PulseSignal = -60
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case {'firstPulseSignalL', 'incrementPerPulseR','firstPulseSignalL', 'incrementPerPulseR'}
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'amp2PulseSignal'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp2).Background.DisplayUnit);
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
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2, 'GroupByParams', {'pulseSignal'});
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
%                 obj.openFigure('Response', obj.amp);
                obj.openFigure('Data', obj.amp);
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'pulseSignal'});
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
        end
        
        
        function [stim, pulseSignal] = ampStimulus(obj, pulseNum)
            % Calculate a pulse signal for the pulse number.
            pulseSignal = obj.incrementPerPulse * (double(pulseNum) - 1) + obj.firstPulseSignal;
            
            % Main amp stimulus.
            pL = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            pL.preTime = obj.preTime;
            pL.stimTimeL = obj.stimTime;
            pL.tailTime = obj.tailTime;
            pL.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            pL.amplitude = pulseSignal - p.mean;
            pL.sampleRate = obj.sampleRate;
            pL.units = char(device.Background.DisplayUnit);
            
            stimL = pL.generate();
            
            % Main amp stimulus.
            pR = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            pR.preTime = obj.preTime;
            pR.stimTime = obj.stimTime;
            pR.tailTime = obj.tailTime;
            pR.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            pR.amplitude = pulseSignal - p.mean;
            pR.sampleRate = obj.sampleRate;
            pR.units = char(device.Background.DisplayUnit);
            
            stimR = pR.generate();
            
            stim = stimL + stimR;
        end
        
        
        function stim = amp2Stimulus(obj)
            % Secondary amp stimulus.
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp2);
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitude = obj.amp2PulseSignal - p.mean;
            p.sampleRate = obj.sampleRate;
            p.units = char(device.Background.DisplayUnit);
            
            stim = p.generate();          
        end        
        
        
        function stimuli = sampleStimuli(obj)
            % Return main amp stimulus for display in the edit parameters window.
            stimuli = cell(obj.pulsesInFamily, 1);
            for i = 1:obj.pulsesInFamily         
                stimuli{i} = obj.ampStimulus(i);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add main amp stimulus.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, pulseSignal] = obj.ampStimulus(pulseNum);
            
            epoch.addParameter('pulseSignal', pulseSignal);
            epoch.addStimulus(obj.amp, stim);
            
            % Add secondary amp stimulus if the rig config is two amp.
            if obj.rigConfig.numMultiClampDevices() > 1
                epoch.addStimulus(obj.amp2, obj.amp2Stimulus());
            end
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
            
            % Keep going until the requested number of epochs is reached.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end

