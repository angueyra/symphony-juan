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
            fprintf('Made it to prepareRun AutoRC!\n')
            if obj.autoRC
				% Open RC figure
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
        
        
%         function stim = amp2Stimulus(obj)
%             % Secondary amp stimulus.
%             p = PulseGenerator();
%             
%             device = obj.rigConfig.deviceWithName(obj.amp2);
%             p.preTime = obj.RCpreTime;
%             p.stimTime = obj.RCstimTime;
%             p.tailTime = obj.RCtailTime;
%             p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
%             p.amplitude = obj.RCamp2PulseAmplitude;
%             p.sampleRate = obj.RCsampleRate;
%             p.units = char(device.Background.DisplayUnit);
%             
%             stim = p.generate();
%         end
        
        
%         function stimuli = sampleStimuli(obj)
%             % Return main amp stimulus for display in the edit parameters window.
%             stimuli{1} = obj.ampStimulus();
%         end
        
        
        function prepareEpoch(obj, epoch)            
            

            if obj.autoRC && obj.numEpochsQueued < obj.RCnumberOfAverages
                prepareEpoch@PulsedProtocol(obj, epoch);
				% Add RC epoch
				obj.addedRCEpoch = true;
                
                % Add main amp stimulus.
                epoch.addStimulus(obj.amp, obj.RCStimulus());
                fprintf('added RCstim\n')
                % Add secondary amp stimulus if the rig config is two amp.
                if obj.rigConfig.numMultiClampDevices() > 1
                    epoch.RCStimulus(obj.amp2, obj.amp2Stimulus());
                end
			else
				obj.addedRCEpoch = false;
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
        
        
    end
    
end

