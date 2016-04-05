classdef NoAmp_2P < AxopatchRigConfiguration
% Created Nov_2014, Angueyra
% Configuration of Angueyra's Rig in Li Lab
% Double Amps (200B) and 2 LEDs
    properties (Constant)
        displayName = 'NoAmp_2P'
    end
    
    methods
        
        function createDevices(obj) 
            % LEDs
            obj.addDevice('mxLED_Violet','ANALOG_OUT.2','');
            obj.addDevice('mxLED_Amber','ANALOG_OUT.3','');
            
            % Temp. Control
            obj.addDevice('Temp','','ANALOG_IN.4');
            
            % Imaging frame clocl
            obj.addDevice('Frames','','DIGITAL_IN.1');
                 
            % Imaging_Trigger
            obj.addDevice('Imaging_Trigger','DIGITAL_OUT.0','');
            
          

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