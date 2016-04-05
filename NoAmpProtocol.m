classdef NoAmpProtocol < SymphonyProtocol
    
%     properties (Access = private)
%         gitHash
%     end

    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);           
        end
        
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@SymphonyProtocol(obj);
            else
                pn = parameterNames@SymphonyProtocol(obj, includeConstant);
            end
        end
        
        
        function prepareRun(obj)
            prepareRun@SymphonyProtocol(obj);
        end
        
        
        function completeEpoch(obj, epoch)
            completeEpoch@SymphonyProtocol(obj, epoch);
            
            % Replace the temperature response with a single reading.
            device = obj.rigConfig.deviceWithName('Temp');
            if ~isempty(device)
                [response, ~, units] = epoch.response(char(device.Name));
                
                if strcmp(units, 'V')
                    % Temperature readout from Bioptech Delta T4 Culture dish controller is
                    % 100 mV/degree C.
                    temp = mean(response) * 1000 * (1/100);
                    temp = round(temp * 10) / 10;
                    epoch.addParameter('bathTemperature', temp);
                    
                    epoch.getCoreEpoch().Responses.Remove(device);
                end
            end
            fprintf('Current T=%g\n',temp);
            try
                trigger_device=obj.rigConfig.deviceWithName('Oscilloscope_Trigger'); %#ok<NASGU>
            end
            trigger_device=obj.rigConfig.deviceWithName('Imaging_Trigger');
             
            epoch.getCoreEpoch().Stimuli.Remove(trigger_device);
        end
        
    end
    
    methods   
        % Convenience methods.

    end
    
end