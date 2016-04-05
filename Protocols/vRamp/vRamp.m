classdef vRamp < AutoRCProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.Ramp'
        version = 4
        displayName = 'vRamp'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        rampAmplitude = 120
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'rampAmplitude'
                    p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@AutoRCProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                obj.openFigure('Data', obj.amp);
                obj.openFigure('Mean Response', obj.amp);
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
        end
        
        
        function stim = ampStimulus(obj)
            % Main amp stimulus.
            r = RampGenerator();
            
            device = obj.rigConfig.deviceWithName(obj.amp);
            r.preTime = obj.preTime;
            r.stimTime = obj.stimTime;
            r.tailTime = obj.tailTime;
            r.mean = double(System.Convert.ToDouble(device.Background.Quantity));
            r.amplitude = obj.rampAmplitude;
            r.sampleRate = obj.sampleRate;
            r.units = char(device.Background.DisplayUnit);
            
            stim = r.generate();
        end       
        
        
        function stimuli = sampleStimuli(obj)
            % Return main amp stimulus for display in the edit parameters window.
            stimuli{1} = obj.ampStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@AutoRCProtocol(obj, epoch);
            if obj.addedRCEpoch
                % Do nothing?
            else
                prepareEpoch@PulsedProtocol(obj, epoch);
                
                % Add main amp stimulus.
                epoch.addStimulus(obj.amp, obj.ampStimulus());
            end
        end
        
        
%         function queueEpoch(obj, epoch)            
%             % Call the base method to queue the actual epoch.
%             queueEpoch@PulsedProtocol(obj, epoch);
%             
%             % Queue the inter-pulse interval after queuing the epoch.
%             if obj.interpulseInterval > 0
%                 obj.queueInterval(obj.interpulseInterval);
%             end
%         end
%         
%         
%         function keepQueuing = continueQueuing(obj)
%             % Check the base class method to make sure the user hasn't paused or stopped the protocol.
%             keepQueuing = continueQueuing@PulsedProtocol(obj);
%             
%             % Keep queuing until the requested number of averages have been queued.
%             if keepQueuing
%                 keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
%             end
%         end
%         
%         
%         function keepGoing = continueRun(obj)
%             % Check the base class method to make sure the user hasn't paused or stopped the protocol.
%             keepGoing = continueRun@PulsedProtocol(obj);
%             
%             % Keep going until the requested number of averages have been completed.
%             if keepGoing
%                 keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
%             end
%         end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end

