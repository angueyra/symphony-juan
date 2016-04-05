classdef LiLabRigConfiguration < RigConfiguration
    
    properties (SetAccess = private)
        stage
        stageConfig
    end
    
    methods
        
        function addOledStage(obj, micronsPerPixel, highRamp, mediumRamp, lowRamp)            
            obj.stage = OledStageClient();
            
            obj.stage.connect();
            
            % Set config values.
            obj.stageConfig.micronsPerPixel = micronsPerPixel;
            obj.stageConfig.highGammaRamp = highRamp;
            obj.stageConfig.mediumGammaRamp = mediumRamp;
            obj.stageConfig.lowGammaRamp = lowRamp;
            obj.stageConfig.size = obj.stage.getCanvasSize().*[.5,1]; % split width for triple head
            obj.stageConfig.refreshRate = obj.stage.getMonitorRefreshRate();
            obj.stageConfig.isTripleHead = true;
        end
        
        
        function addLcrStage(obj, micronsPerPixel)
            obj.stage = LcrStageClient();
            
            obj.stage.connect();
            
            % Set config values.
            obj.stageConfig.micronsPerPixel = micronsPerPixel;
            obj.stageConfig.size = obj.stage.getCanvasSize();
            obj.stageConfig.refreshRate = obj.stage.getMonitorRefreshRate();
            obj.stageConfig.isTripleHead = false;
        end
        
        
        function addCalibratedDevice(obj, deviceName, outStreamName, inStreamName, xRamp, yRamp)            
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if strncmp(outStreamName, 'DIGITAL', 7)
                % No reason this couldn't work, it just doesn't make much sense at the moment.
                error('Digital output streams are not currently supported by calibrated devices');               
            end
            
            units = Measurement.NORMALIZED;
            
            lut = NET.createGeneric('System.Collections.Generic.SortedList', {'System.Decimal', 'System.Decimal'});
            for i = 1:length(xRamp)
                lut.Add(xRamp(i), yRamp(i));
            end
            
            dev = CalibratedDevice(deviceName, 'unknown', obj.controller, Measurement(0, units), lut);
            dev.MeasurementConversionTarget = units;
            dev.Clock = obj.controller.DAQController.Clock;
            
            obj.addStreams(dev, outStreamName, inStreamName);
            
            % Set default device background stream in the controller.
            if ~isempty(outStreamName)
                out = BackgroundOutputDataStream(Background(Measurement(0, units), dev.OutputSampleRate));
                obj.controller.BackgroundDataStreams.Item(dev, out);
            end
        end
        
    end
    
end