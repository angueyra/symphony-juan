classdef TemplateRigConfiguration < RiekeRigConfiguration
    
    properties (Constant)
        displayName = 'Template Rig Configuration'
    end
    
    methods
        
        function createDevices(obj)   
            % Amps.
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            
            % LEDs.
            %obj.addDevice('Green_LED', 'ANALOG_OUT.2', '');
            
            % Others.
            obj.addDevice('Warner_Temperature_Controller', '', 'ANALOG_IN.6');
            obj.addDevice('Oscilloscope_Trigger', 'DIGITAL_OUT.0', '');
        end
        
    end
end
