% Create a sub-class of this class to define a pulsed protocol.
% A pulsed protocol is a protocol whose stimulus is best defined with pre, stim, and tail segments.

classdef PulsedProtocol < LiLabProtocol
    
    properties (Abstract)
        preTime
        stimTime
        tailTime
    end
    
    properties (Dependent, SetAccess = private, Hidden)        
        % Convenience properties calculated based on the current pre, stim, and tail time. 
        prePts
        stimPts
        tailPts
        totalPts
        stimStart
        stimEnd
    end
    
    methods        
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@LiLabProtocol(obj, parameterName);
            
            switch parameterName
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base class method.
            prepareRun@LiLabProtocol(obj);
            
            % Set the oscilloscope trigger background to zero.
            if ~isempty(obj.rigConfig.deviceWithName('Oscilloscope_Trigger'))
                obj.setDeviceBackground('Oscilloscope_Trigger', 0, Symphony.Core.Measurement.UNITLESS);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base class method.
            prepareEpoch@LiLabProtocol(obj, epoch);
            
            % Add a stimulus to trigger the oscilliscope at the start of the epoch.
            if ~isempty(obj.rigConfig.deviceWithName('Oscilloscope_Trigger'))
                p = PulseGenerator();
                
                p.preTime = 0;
                p.stimTime = 1;
                p.tailTime = obj.preTime + obj.stimTime + obj.tailTime - 1;
                p.amplitude = 1;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = Symphony.Core.Measurement.UNITLESS;
                
                epoch.addStimulus('Oscilloscope_Trigger', p.generate());
            end
        end
        
    end
        
    methods
        
        % Convenience methods.        
        
        function pts = get.prePts(obj)
            pts = round(obj.preTime / 1e3 * obj.sampleRate);
        end
        
        
        function pts = get.stimPts(obj)
            pts = round(obj.stimTime / 1e3 * obj.sampleRate);
        end
        
        
        function pts = get.tailPts(obj)
            pts = round(obj.tailTime / 1e3 * obj.sampleRate);  
        end
        
        
        function pts = get.totalPts(obj)
            pts = obj.prePts + obj.stimPts + obj.tailPts;
        end
        
        
        function pt = get.stimStart(obj)
            pt = obj.prePts + 1;
        end
        
        
        function pt = get.stimEnd(obj)
            pt = obj.prePts + obj.stimPts;
        end
        
    end
    
end

