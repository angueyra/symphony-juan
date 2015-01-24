classdef TwoAmp < AxopatchRigConfiguration
    
    properties (Constant)
        displayName = 'TwoAmp'
    end
    
    methods
        
        function createDevices(obj) 
            % Amps.
            obj.addAxopatchDevice('Amp1', 'ANALOG_OUT.0', 'ANALOG_IN.0', 'ANALOG_IN.1', 'ANALOG_IN.2');
            obj.addAxopatchDevice('Amp2', 'ANALOG_OUT.1', 'ANALOG_IN.3', 'ANALOG_IN.4', 'ANALOG_IN.5');

            % LEDs.
            parentDir = fileparts(mfilename('fullpath'));
%             s = load([parentDir '/../Calibration/Suction/LED/suction_uv_led.mat']);
%             obj.addCalibratedDevice('UV_LED', 'ANALOG_OUT.1', '', s.xRamp, s.yRamp);
%             s = load([parentDir '/../Calibration/Suction/LED/suction_blue_led.mat']);
%             obj.addCalibratedDevice('Blue_LED', 'ANALOG_OUT.2', '', s.xRamp, s.yRamp);
%             s = load([parentDir '/../Calibration/Suction/LED/suction_green_led.mat']);
%             obj.addCalibratedDevice('Green_LED', 'ANALOG_OUT.3', '', s.xRamp, s.yRamp);

%             obj.addDevice('LED_590','ANALOG_OUT.1','');
            obj.addDevice('LED_530','ANALOG_OUT.2','');
            obj.addDevice('LED_455','ANALOG_OUT.3','');
            % Others.
            obj.addDevice('Warner_Temperature_Controller', '', 'ANALOG_IN.6');
        end
        
    end
end