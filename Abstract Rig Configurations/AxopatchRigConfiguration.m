classdef AxopatchRigConfiguration < RiekeRigConfiguration
    
    methods
        
        function mode = axopatchMode(obj, deviceName)
            device = obj.deviceWithName(deviceName);
            
            mode = '';
            while isempty(mode)
                try
                    mode = char(device.CurrentDeviceParameters.OperatingMode);
                catch
                    error(['Unable to get the ' deviceName ' mode.'], 's');
                end
            end
        end
        
        
        function addAxopatchDevice(obj, deviceName, outStreamName, inStreamName, gainStreamName, modeStreamName)
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            modes = NET.createArray('System.String', 5);
            modes(1) = 'Track';
            modes(2) = 'VClamp';
            modes(3) = 'I0';
            modes(4) = 'IClampNormal';
            modes(5) = 'IClampFast';
            
            backgroundMeasurements = NET.createArray('Symphony.Core.IMeasurement', 5);
            backgroundMeasurements(1) = Measurement(0, 'mV');
            backgroundMeasurements(2) = Measurement(0, 'mV');
            backgroundMeasurements(3) = Measurement(0, 'pA');
            backgroundMeasurements(4) = Measurement(0, 'pA');
            backgroundMeasurements(5) = Measurement(0, 'pA');
            
            patch = Axopatch200B();
            dev = AxopatchDevice(patch, obj.controller, modes, backgroundMeasurements);
            dev.Name = deviceName;
            dev.Clock = obj.controller.DAQController.Clock;
            
            dev.BindStream(obj.streamWithName(outStreamName, true));
            
            dev.BindStream(AxopatchDevice.SCALED_OUTPUT_STREAM_NAME, obj.streamWithName(inStreamName, false));
            dev.BindStream(AxopatchDevice.GAIN_TELEGRAPH_STREAM_NAME, obj.streamWithName(gainStreamName, false));
            dev.BindStream(AxopatchDevice.MODE_TELEGRAPH_STREAM_NAME, obj.streamWithName(modeStreamName, false));
            
            try
                obj.axopatchMode(deviceName);
            catch ME
                dev.Controller = [];
                if iscell(obj.controller.Devices)
                    for i = 1:length(obj.controller.Devices)
                        if obj.controller.Devices{i} == dev
                            obj.controller.Devices(i) = [];
                            break;
                        end
                    end
                else
                    obj.controller.Devices.Remove(dev);
                end
                throw(ME);
            end
        end
        
        
        function d = axopatchDevices(obj)
            d = {};
            devices = obj.devices();
            for i = 1:length(devices)
                if isa(devices{i}, 'Symphony.ExternalDevices.AxopatchDevice')
                    d{end + 1} = devices{i};
                end
            end
        end
        
        
        function n = numAxopatchDevices(obj)
            n = length(obj.multiClampDevices());
        end
        
        
        function names = axopatchDeviceNames(obj)            
            names = {};
            devices = obj.axopatchDevices();
            for i = 1:length(devices)
                names{end + 1} = char(devices{i}.Name);
            end
        end
        
        
        %% Redirects from multiclamp to axopatch methods to support multiclamp protocols.
        
        function addMultiClampDevice(obj, deviceName, channel, outStreamName, inStreamName) %#ok<INUSD>
            error('addMultiClampDevice is not supported in AxopatchRigConfiguration. Use addAxopatchDevice.');
        end
        
        
        function mode = multiClampMode(obj, deviceName)
            mode = obj.axopatchMode(deviceName);
        end
        
        
        function d = multiClampDevices(obj)
            d = obj.axopatchDevices();
        end
        
        
        function n = numMultiClampDevices(obj)
            n = obj.numAxopatchDevices();
        end
        
        
        function names = multiClampDeviceNames(obj)
            names = obj.axopatchDeviceNames();
        end
        
        
        function close(obj)
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.CloseHardware();
            end
        end
        
    end
    
end