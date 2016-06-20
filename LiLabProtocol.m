classdef LiLabProtocol < SymphonyProtocol
    
    properties (Abstract)
        amp
    end
    
    properties (Abstract, Dependent, SetAccess = private)
        % Defined as abstract to allow sub-classes control over the order of properties.
        amp2
        
        % The amp2 sub-class get method is usually:
        % function amp2 = get.amp2(obj)
        %    amp2 = obj.get_amp2();
        % end
    end
    
%     properties (Access = private)
%         gitHash
%     end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);
            
            switch parameterName
                case 'amp'
                    p.defaultValue = obj.rigConfig.multiClampDeviceNames();
            end
        end
        
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@SymphonyProtocol(obj);
            else
                pn = parameterNames@SymphonyProtocol(obj, includeConstant);
            end
            
            % Hide parameters with 'amp2' prefix if the current rig config only has one amp.
            if obj.rigConfig.numMultiClampDevices() <= 1
                pn = pn(~strncmp(pn, 'amp2', 4));
            end
        end
        
        
        function prepareRun(obj)
            prepareRun@SymphonyProtocol(obj);
            
%             % Get current package git commit hash.
%             [status, hash] = system(['git -C "' fileparts(mfilename('fullpath')) '" rev-parse @']);
%             if status ~= 0
%                 hash = 'unknown';
%             end
%             obj.gitHash = hash;
        end
        
        
        function completeEpoch(obj, epoch)
            completeEpoch@SymphonyProtocol(obj, epoch);
            
            % Replace the temperature response with a single reading.
            device = obj.rigConfig.deviceWithName('Temp');
            if ~isempty(device)
                [response, ~, units] = epoch.response(char(device.Name));
                
                if strcmp(units, 'V')
                    % Temperature readout from Bioptechs Delta T4/T5 Culture dish controller is
                    % 100 mV/degree C.
                    temp = mean(response) * 1000 * (1/100);
                    temp = round(temp * 10) / 10;
                    epoch.addParameter('bathTemperature', temp);
                    
                    epoch.getCoreEpoch().Responses.Remove(device);
                end
            end
            fprintf('Current T=%g\n',temp);
            
            trigger_device=obj.rigConfig.deviceWithName('Oscilloscope_Trigger');
            epoch.getCoreEpoch().Stimuli.Remove(trigger_device);
            
            % Add the current package hash.
%             epoch.addParameter('gitHash', obj.gitHash);
        end
        
    end
    
    methods
        
        % Convenience methods.
        
        function amp2 = get_amp2(obj)
            % The secondary amp is defined as the amp not selected as the main amp.            
            amps = obj.rigConfig.multiClampDeviceNames();
            
            if ~isempty(obj.amp)
                index = find(~ismember(amps, obj.amp), 1);
                amp2 = amps{index};
            else
                amp2 = '';
            end
        end
    
    end
    
end