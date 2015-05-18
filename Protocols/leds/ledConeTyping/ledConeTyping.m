classdef ledConeTyping < PulsedProtocol
    
    %%%%%%% deal with the number of flashes to give
    
    properties (Constant)
        identifier = 'edu.washington.rieke.jbaudin.ConeTyping'
        version = 1
        displayName = 'Cone Typing'
    end
    
    properties
        red_LED
        green_LED
        blue_LED
        preTime = 10
        stimTime = 100
        tailTime = 400
        redLEDAmplitude = 0
        greenLEDAmplitude = 0
        blueLEDAmplitude = 0
        
        amp
        
        flashesPerLED = uint8(3)
        interpulseInterval = 0
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
        plotData = struct;
        
        LEDs = {'red_LED', 'green_LED', 'blue_LED'};
        flashCounter = 0;
        stimulusCounter = 0;
        
    end
    
    properties (Dependent, Hidden)
        
        numFlashes
        
    end
    
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                
                case {'red_LED', 'blue_LED', 'green_LED'}
                    % the deviceNames protocol for rig configuration
                    % searches for the argument (a string) in the names of
                    % the devices on the rig configuration
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                    p.description = 'select corresponding LED from rig configuration';
                    
                case {'redLEDAmplitude', 'greenLEDAmplitude', 'blueLEDAmplitude', 'lightMean'} % light mean may not be necessary
                    p.units = 'V';
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                % add custom figure and get its handle
                obj.plotData.onlineFigureHandle = obj.openFigure('Custom', 'UpdateCallback', @updateFigure);
                % get handle for axes on custom figure
                obj.plotData.AxesHandle = get(obj.plotData.onlineFigureHandle.figureHandle, 'children');
                hold(obj.plotData.AxesHandle, 'on');
                % plot simple lines to get handles for line on custom figure
                obj.plotData.lineHandles{1} = plot(obj.plotData.AxesHandle, [0 1], [0 0], 'Color', [1 0 0]);
                obj.plotData.lineHandles{2} = plot(obj.plotData.AxesHandle, [0 1], [1 1], 'Color', [0 1 0]);
                obj.plotData.lineHandles{3} = plot(obj.plotData.AxesHandle, [0 1], [2 2], 'Color', [0 0 1]);
                % make a field in the plotData structure that can store data
                % from one epoch to the next so that plots can be composed with
                % data from more than one epoch
                obj.plotData.data = cell(1,3);
                obj.plotData.flashCounter = 0;
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                % obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                % obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                % obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                
            else
                % add custom figure and get its handle
                obj.plotData.onlineFigureHandle = obj.openFigure('Custom', 'UpdateCallback', @updateFigure);
                % get handle for axes on custom figure
                obj.plotData.AxesHandle = get(obj.plotData.onlineFigureHandle.figureHandle, 'children');
                hold(obj.plotData.AxesHandle, 'on');
                % plot simple lines to get handles for line on custom figure
                obj.plotData.lineHandles{1} = plot(obj.plotData.AxesHandle, [0 1], [0 0], 'Color', [1 0 0]);
                obj.plotData.lineHandles{2} = plot(obj.plotData.AxesHandle, [0 1], [1 1], 'Color', [0 1 0]);
                obj.plotData.lineHandles{3} = plot(obj.plotData.AxesHandle, [0 1], [2 2], 'Color', [0 0 1]);
                % make a field in the plotData structure that can store data
                % from one epoch to the next so that plots can be composed with
                % data from more than one epoch
                obj.plotData.data = cell(1,3);
                obj.plotData.flashCounter = 0;
                obj.openFigure('Response', obj.amp);
                % obj.openFigure('Mean Response', obj.amp);
                % obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                % obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                
            end
            
            
        end
        
        
        function stim = ledStimulus(obj, LED)
            
            
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            
            
            p.sampleRate = obj.sampleRate;
            p.units = 'V';
            
            switch LED
                case 'red_LED'
                    device = obj.rigConfig.deviceWithName(obj.(obj.LEDs{1}));
                    p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
                    p.amplitude = obj.redLEDAmplitude;
                    disp('red')
                    
                case 'green_LED'
                    
                    device = obj.rigConfig.deviceWithName(obj.(obj.LEDs{2}));
                    p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
                    p.amplitude = obj.greenLEDAmplitude;
                    disp('green')
                case 'blue_LED'
                    device = obj.rigConfig.deviceWithName(obj.(obj.LEDs{3}));
                    p.mean = double(System.Convert.ToDouble(device.Background.Quantity));
                    p.amplitude = obj.blueLEDAmplitude;
                    disp('blue')
            end
            
            
            stim = p.generate();
        end
        
        %
        %         function stimuli = sampleStimuli(obj)
        %             % Return LED stimulus for display in the edit parameters window.
        %             stimuli{1} = obj.ledStimulus();
        %         end
        %
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            
            % Add LED stimulus.
            %epoch.addStimulus(obj.led, obj.ledStimulus());
            
            % add stimulus to different LEDs based on which stimulus number
            % it is -- mod(stimCounter, 3) + 1 should cycle from 1 to 2 to
            % 3 starting with one if the stimulus counter is started at 0
            % and 1 is added to it at the end of this method (after the
            % modulus calculation)
            
            switch mod(obj.numEpochsQueued, 3) + 1
                case 1
                    epoch.addStimulus(obj.(obj.LEDs{1}), obj.ledStimulus(obj.LEDs{1}));
                case 2
                    epoch.addStimulus(obj.(obj.LEDs{2}), obj.ledStimulus(obj.LEDs{2}));
                case 3
                    epoch.addStimulus(obj.(obj.LEDs{3}), obj.ledStimulus(obj.LEDs{3}));
            end
            
            
            
            
            
            
        end
        
        
        function queueEpoch(obj, epoch)
            % Call the base method to queue the actual epoch.
            queueEpoch@PulsedProtocol(obj, epoch);
            
            % Queue the inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            % Keep queuing until the requested number of epochs have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numFlashes;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of epochs have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numFlashes;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
        function updateFigure(obj, epoch, ~)
            
            % get response data and sample rate
            [response, sampleRate] = epoch.response(obj.amp);
            
            disp('epoch done')
            
            % perform some tasks the first time this is called -- plot a
            % zero vector on appropriate time scale, and make a vector to
            % store responses in to each of the LED types
            if obj.numEpochsCompleted == 1
                obj.plotData.time = (1:length(response))/sampleRate;
                for i = 1:3
                    if i == 1
                        obj.plotData.data{i} = response;
                        set(obj.plotData.lineHandles{i}, 'XData', obj.plotData.time, ...
                            'YData', obj.plotData.data{i});
                    else
                        obj.plotData.data{i} = ones(size(response)) * ...
                            mean(obj.plotData.data{1}(1:round((obj.preTime/1000)*sampleRate)));
                        set(obj.plotData.lineHandles{i}, 'XData', obj.plotData.time, ...
                            'YData', obj.plotData.data{i});
                    end
                end
               
            else
                numFlashes = ceil(obj.numEpochsCompleted/3);
                flashType = mod(obj.numEpochsCompleted-1, 3)+1;
               
                                
                obj.plotData.data{flashType} = ...
                    (1/numFlashes) * response + ...
                    ((numFlashes-1)/numFlashes) * obj.plotData.data{flashType};
                
                
                set(obj.plotData.lineHandles{flashType}, 'YData', obj.plotData.data{flashType});
            end
            
            
          
        end
        
        function value = get.numFlashes(obj)
            
            % user defines flashes per LED, this just converts to total
            % number of flashes
            value = 3 * obj.flashesPerLED;
            
        end
        
    end
    
end


