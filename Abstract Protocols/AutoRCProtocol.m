classdef AutoRCProtocol < PulsedProtocol
    
    properties
        autoRC = true
    end
    
    properties (Hidden)
		addedRCEpoch
        RCpreTime = 15
        RCstimTime = 30
        RCtailTime = 15
        RCpulseAmplitude = 5
        RCnumberOfAverages = 1
        RCamp2PulseAmplitude = 0
        RCinterpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'RCpulseAmplitude'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'RCamp2PulseAmplitude'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp2).Background.DisplayUnit);
                case 'RCinterpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            prepareRun@PulsedProtocol(obj);
            if obj.autoRC
                obj.addedRCEpoch = true;
				% Open RC figure
                obj.openFigure('AutoRC', obj.amp);
            else
                obj.addedRCEpoch = false;
			end
        end
        
        
        function stim = RCStimulus(obj)
            % Main amp stimulus.           
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            p.preTime = obj.RCpreTime;
            p.stimTime = obj.RCstimTime;
            p.tailTime = obj.RCtailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitude = obj.RCpulseAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(device.Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stim = RC2Stimulus(obj)
            % Secondary amp stimulus.
            p = PulseGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp2);
            p.preTime = obj.RCpreTime;
            p.stimTime = obj.RCstimTime;
            p.tailTime = obj.RCtailTime;
            p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            p.amplitude = obj.RCamp2PulseAmplitude;
            p.sampleRate = obj.RCsampleRate;
            p.units = char(device.Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function prepareEpoch(obj, epoch)            
            if obj.addedRCEpoch && obj.numEpochsQueued < obj.RCnumberOfAverages
                prepareEpoch@PulsedProtocol(obj, epoch);
                % Add RC epoch
                epoch.addParameter('RCepoch', 1);
                epoch.addParameter('RCpreTime', obj.RCpreTime);
                epoch.addParameter('RCstimTime', obj.RCstimTime);
                epoch.addParameter('RCtailTime', obj.RCtailTime);
                epoch.addParameter('RCpulseAmplitude', obj.RCpulseAmplitude);
                epoch.addParameter('RCnumberOfAverages', obj.RCnumberOfAverages);
                epoch.addParameter('RCamp2PulseAmplitude', obj.RCamp2PulseAmplitude);
                epoch.addParameter('RCinterpulseInterval', obj.RCinterpulseInterval);
                
                epoch.addStimulus(obj.amp, obj.RCStimulus());
                % Add secondary amp stimulus if the rig config is two amp.
                if obj.rigConfig.numMultiClampDevices() > 1
                    epoch.RCStimulus(obj.amp2, obj.RC2Stimulus());
                end
			else
				obj.addedRCEpoch = false;
%                 epoch.addParameter('RCnumberOfAverages', obj.RCnumberOfAverages);
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
                if obj.autoRC
                    keepQueuing = obj.numEpochsQueued < obj.RCnumberOfAverages+obj.numberOfAverages;
                else
                    keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
                end
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                if obj.autoRC
                    keepGoing = obj.numEpochsCompleted < obj.RCnumberOfAverages+obj.numberOfAverages;
                else
                    keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
                end
            end
        end
        
        
    end
    
end

