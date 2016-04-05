classdef TwoAmps < AxopatchRigConfiguration
% Created Nov_2014, Angueyra
% Configuration of Angueyra's Rig in Li Lab
% Double Amps (200B) and 2 LEDs
    properties (Constant)
        displayName = 'TwoAmps'
    end
    
    methods
        
        function createDevices(obj) 
            % Amps.
            obj.addAxopatchDevice('Amp1', 'ANALOG_OUT.0', 'ANALOG_IN.0', 'ANALOG_IN.1', 'ANALOG_IN.2');
            obj.addAxopatchDevice('Amp2', 'ANALOG_OUT.1', 'ANALOG_IN.3', 'ANALOG_IN.4', 'ANALOG_IN.5');

            % LEDs
            obj.addDevice('LED_530','ANALOG_OUT.2','');
            obj.addDevice('LED_455','ANALOG_OUT.3','');
            
            % Temp. Control
            obj.addDevice('Temp','','ANALOG_IN.6');
                      
            % Oscilloscope_Trigger
            obj.addDevice('Oscilloscope_Trigger','DIGITAL_OUT.0','');
            
            
%             % Switchbox
%             obj.addDevice('Run','','DIGITAL_IN.8');
%             obj.addDevice('Save','','DIGITAL_IN.9');
%             obj.addDevice('Update','','DIGITAL_IN.10');
%             obj.addDevice('CellParams','','DIGITAL_IN.11');
%             obj.addDevice('RandomSeed','','DIGITAL_IN.13');


% % %             % LEDs.
% % %             parentDir = fileparts(mfilename('fullpath'));
% % %             s = load([parentDir '/../Calibration/Suction/LED/suction_uv_led.mat']);
% % %             obj.addCalibratedDevice('UV_LED', 'ANALOG_OUT.1', '', s.xRamp, s.yRamp);
% % %             s = load([parentDir '/../Calibration/Suction/LED/suction_blue_led.mat']);
% % %             obj.addCalibratedDevice('Blue_LED', 'ANALOG_OUT.2', '', s.xRamp, s.yRamp);
% % %             s = load([parentDir '/../Calibration/Suction/LED/suction_green_led.mat']);
% % %             obj.addCalibratedDevice('Green_LED', 'ANALOG_OUT.3', '', s.xRamp, s.yRamp);
% % % 
        end
        
    end
end