classdef vDoublePulseFamily < DoublePulsedProtocol
    
    properties (Constant)
        identifier = 'angueyra.DoublePulseFamily'
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
            p = parameterProperty@DoublePulsedProtocol(obj, parameterName);
            
            switch parameterName
                case {'firstPulseSignalL', 'incrementPerPulseL','firstPulseSignalR', 'incrementPerPulseR'}
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'amp2PulseSignal'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp2).Background.DisplayUnit);
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@DoublePulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2, 'GroupByParams', {'pulseSignal'});
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
%                 obj.openFigure('Response', obj.amp);
                obj.openFigure('Data', obj.amp);
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'pulseSignalL','pulseSignalR'});
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
        end
        
        
        function [stim, pulseSignalL, pulseSignalR] = ampStimulus(obj, pulseNum)
            % Calculate a pulse signal for the pulse number.
            pulseSignalL = obj.incrementPerPulseL * (double(pulseNum) - 1) + obj.firstPulseSignalL;
            pulseSignalR = obj.incrementPerPulseR * (double(pulseNum) - 1) + obj.firstPulseSignalR;
            
            % Main amp stimulus left.
            p = DoublePulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            p.preTime = obj.preTime;
            p.stimTimeL = obj.stimTimeL;
            p.stimTimeR = obj.stimTimeR;
            p.tailTime = obj.tailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitudeL = pulseSignalL - p.mean;
            p.amplitudeR = pulseSignalR - p.mean;
            p.sampleRate = obj.sampleRate;
            p.units = char(device.Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stim = amp2Stimulus(obj)
            % Secondary amp stimulus.
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp2);
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTimeL + obj.stimTimeR;
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
            prepareEpoch@DoublePulsedProtocol(obj, epoch);
            
            % Add main amp stimulus.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, pulseSignalL, pulseSignalR] = obj.ampStimulus(pulseNum);
            
            epoch.addParameter('pulseSignalL', pulseSignalL);
            epoch.addParameter('pulseSignalR', pulseSignalR);
            epoch.addStimulus(obj.amp, stim);
            
            % Add secondary amp stimulus if the rig config is two amp.
            if obj.rigConfig.numMultiClampDevices() > 1
                epoch.addStimulus(obj.amp2, obj.amp2Stimulus());
            end
        end
        
        
        function queueEpoch(obj, epoch)
            % Call the base method to queue the actual epoch.
            queueEpoch@DoublePulsedProtocol(obj, epoch);
            
            % Queue the inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@DoublePulsedProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@DoublePulsedProtocol(obj);
            
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

