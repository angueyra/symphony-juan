classdef InfiniteFlicker < PulsedProtocol
    
    properties (Constant)
        identifier = 'angueyra.InfiniteFlicker'
        version = 1
        displayName = 'InfiniteFlicker'
    end
    
    properties
        led
        amp
        preTime = 15
        stimTime = 30
        tailTime = 15
        ledAmp = 5
        ledMean = 0
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
        figureHandler
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case {'ledAmp', 'ledMean'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function init(obj, rigConfig)
            % Call the base method.
            init@PulsedProtocol(obj, rigConfig);
            
            % Epochs of indefinite duration, like those produced by this protocol, cannot be saved. 
            obj.allowSavingEpochs = false;
            obj.allowPausing = false;            
        end
        
        
        function stim = ledStimulus(obj)
            % Main led stimulus.
            p = RepeatingPulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.ledAmp;
            p.mean = obj.ledMean;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.amp).Background.DisplayUnit);
            
            stim = p.generate();
        end   
        
        
        function stimuli = sampleStimuli(obj)
            % We cannot display a stimulus with an infinite number of pulses. Instead we will display a single pulse 
            % generated with the same parameters used to generate the repeating pulse stimulus.
            stim = obj.ledStimulus();
            
            params = dictionaryToStruct(stim.Parameters);
            params = rmfield(params, {'version', 'generatorClassName'});
            
            p = PulseGenerator(params);
            stimuli{1} = p.generate();
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open mode indicating figure handler.
            obj.figureHandler = obj.openFigure('Custom', 'Name', 'Current Mode', 'ID', 'sealLeakMode', 'UpdateCallback', @null);
            axesHandle = obj.figureHandler.axesHandle();
            cla(axesHandle);
            set(axesHandle, 'XTick', [], 'YTick', []);
            text(0.5, 0.5, [obj.led ' running...'], 'FontSize', 48, 'HorizontalAlignment', 'center', 'Parent', axesHandle);
            
            % Set led mean.
            obj.setDeviceBackground(obj.led, obj.ledMean);
            
        end
        
        
        function prepareEpoch(obj, epoch)
            % With an indefinite epoch protocol we should not call the base class.
            %prepareEpoch@PulsedProtocol(obj, epoch);
                                    
            % Set the epoch default background values for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set the default epoch background to be the same as the device background.
                if ~isempty(device.OutputSampleRate)
                    epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                end
            end
            
            % Add a stimulus to trigger the oscilliscope at the start of each pulse.
            if ~isempty(obj.rigConfig.deviceWithName('Oscilloscope_Trigger'))
                p = RepeatingPulseGenerator();
                
                p.preTime = 0;
                p.stimTime = 1;
                p.tailTime = obj.preTime + obj.stimTime + obj.tailTime - 1;
                p.amplitude = 1;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = Symphony.Core.Measurement.UNITLESS;
                
                epoch.addStimulus('Oscilloscope_Trigger', p.generate());
            end
            
            % Add the led pulse stimulus to the epoch.         
            epoch.addStimulus(obj.led, obj.ledStimulus());         
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            % Queue only one indefinite epoch.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < 1;
            end            
        end
        
        
        function completeRun(obj)
            % Call the base method.
            completeRun@PulsedProtocol(obj);
            
            
            % Update figure handler.
            axesHandle = obj.figureHandler.axesHandle();
            if ~isempty(axesHandle)            
                cla(axesHandle);
                set(axesHandle, 'XTick', [], 'YTick', []);
                text(0.5, 0.5, [obj.led ' next'], 'FontSize', 48, 'HorizontalAlignment', 'center', 'Parent', axesHandle);
            end
        end

        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end

