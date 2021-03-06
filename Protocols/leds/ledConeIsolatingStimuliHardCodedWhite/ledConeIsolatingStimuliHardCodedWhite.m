classdef ledConeIsolatingStimuliHardCodedWhite < PulsedProtocol
    %CONEISOLATINGSTIMULI Summary of this class goes here
    % note that the chosen rigConfig must have calibration values for each
    % of the LEDs, because cone sensitivities here are entered as
    % response/(voltage/calibration) - therefore the calibration values are
    % used to construct the cone sensitivity matrix
    
    properties (Constant)
        identifier = 'edu.washington.rieke.jbaudin.ConeIsolatingStimuliHardCodedWhite'
        version = 2
        displayName = 'Cone Isolating Stimuli Hard Coded White Pt'
    end
    
    properties
        
        red_LED
        green_LED
        blue_LED
        
        preTime = 10
        stimTime = 100
        tailTime = 400
        
        amp
        ampHoldSignal = -60
        preAndTailSignal = -60
        
        % this property will modulate LED output along a vector that
        % produces equal response in each of the cone types
        coneBaseline = 1
        
        % these properties will modulate LED contrast -- they will move the
        % point in cone space along directions specified by the
        % ConeIsolatingVectors (see dependent properties) -- this movement
        % of the stimulus in cone space will be defined by percentage away
        % from the current coneBaseline
        
        
        sConeContrast = 0
        mConeContrast = 0
        lConeContrast = 0
        
        
    end
    
    % necessary amp2 stuff
    properties (Dependent, SetAccess = private)
        amp2
    end
    properties
        amp2HoldSignal = -60
        numberOfAverages = uint8(5)
        interpulseInterval = 0
        
    end
    
    % this property list can be used to store variables that will be
    % necessary for numerous calcuations, but not viewed in the edit
    % parameters window
    properties (Dependent = true, Hidden = true)
        
        % define get methods below
        coneToLED
        LEDToCone
        
        % this will be a hidden property that will a sum of the
        % equalResponseVector and any creponontrast changes
        stimConeSpacePoint
        stimLEDSpacePoint
        
        % this dependent parameter will inform the user of the maximum
        % allowed change in contrast that can be done in each of the cone
        % directions
        maxContrastIncrease_S_M_L
        maxContrastDecrease_S_M_L
        
        % this dependent parameter will contain the RGB outputs
        % that will be used to create the user-defined coneBaseline
        RGBLEDmeans
    end
    
    properties (Hidden)
        
        % in cone space, the equal cone response vector should be [1; 1; 1]
        equalConeResponseVector = [3;.4;.5];
        
        % these are user-provided values that define the sensitivity of
        % each cone type to each of the different LEDs - they should be
        % normalized by calibration values in the form
        % (response/(voltage/calibration)) -- the current calibration
        % values of the rig will be used to construct the transition
        % matrices
        
        lRGBSensitivity = [1 2.6 .326]
        mRGBSensitivity = [1 11.1 1.207]
        sRGBSensitivity = [1 13.69 143.6]
       
        
        coneContrastRanges
        
        outOfLEDRange
        
        redLEDRange = [0 10];
        greenLEDRange = [0 10];
        blueLEDRange = [0 10];
        
        hardCodedWhitePointRGB = [3; .4; .5];
        
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
                case 'interpulseInterval'
                    p.units = 's';
                case 'preAndTailSignal'
                    p.units = 'mV or pA';
                case 'coneBaseline'
                    p.units = 'isom/s';
                    p.description = ['enter a value in terms of isomerizations/second, and the LED levels during background and '...
                        'pretime will be set to produce that level of isomerization in all 3 cone types'];
                case {'sConeContrast', 'mConeContrast', 'lConeContrast'}
                    p.units = '%';
                    if obj.outOfLEDRange
                        p.description = 'LEDs are not all in range';
                    else
                        switch parameterName
                            case 'sConeContrast'
                                p.description = ...
                                    ['max allowable contrast value is '...
                                    num2str(100*obj.coneContrastRanges.sCone.increase)...
                                    ', min allowable contrast value is -'...
                                    num2str(100*obj.coneContrastRanges.sCone.decrease) ...
                                    ' to remain within LED range'];
                                
                            case 'mConeContrast'
                                p.description = ...
                                    ['max allowable contrast value is '...
                                    num2str(100*obj.coneContrastRanges.mCone.increase)...
                                    ', min allowable contrast value is -'...
                                    num2str(100*obj.coneContrastRanges.mCone.decrease) ...
                                    ' to remain within LED range'];
                                
                            case 'lConeContrast'
                                p.description = ...
                                    ['max allowable contrast value is '...
                                    num2str(100*obj.coneContrastRanges.lCone.increase)...
                                    ', min allowable contrast value is -'...
                                    num2str(100*obj.coneContrastRanges.lCone.decrease) ...
                                    ' to remain within LED range'];
                                
                        end
                    end
                    
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
                obj.openFigure('Dual Variance vs. Epoch', obj.amp, obj.amp2, 'EndPt', obj.prePts);
            else
                % Change these to match real rig configuration
                obj.openFigure('Response', obj.amp);
                %                 obj.openFigure('Response', 'redIn');
                %                 obj.openFigure('Response', 'blueIn');
                %                 obj.openFigure('Response', 'greenIn');
                % change this when actually using a real rig
                obj.openFigure('Mean Response', obj.amp);
                obj.openFigure('Mean vs. Epoch', obj.amp, 'EndPt', obj.prePts);
                obj.openFigure('Variance vs. Epoch', obj.amp, 'EndPt', obj.prePts);
            end
            
            % Set LED means.
            obj.setDeviceBackground(obj.red_LED, obj.RGBLEDmeans(1), 'V');
            obj.setDeviceBackground(obj.green_LED, obj.RGBLEDmeans(2), 'V');
            obj.setDeviceBackground(obj.blue_LED, obj.RGBLEDmeans(3), 'V');
        end
        
        
        function stim = ledStimulus(obj,LED)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            
            switch LED
                case 'Red_LED'
                    p.mean = obj.RGBLEDmeans(1);
                    p.amplitude = obj.stimLEDSpacePoint(1);
                case 'Green_LED'
                    p.mean = obj.RGBLEDmeans(2);
                    p.amplitude = obj.stimLEDSpacePoint(2);
                case 'Blue_LED'
                    p.mean = obj.RGBLEDmeans(3);
                    p.amplitude = obj.stimLEDSpacePoint(3);
            end
            
            
            
            p.sampleRate = obj.sampleRate;
            p.units = 'V';
            
            stim = p.generate();
            
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            LEDs = {'red_LED', 'green_LED', 'blue_LED'};
            for LED = 1:length(LEDs)
                stimuli{LED} = obj.ledStimulus(obj.(LEDs{LED})); %#ok<AGROW>
            end
            
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            
            LEDs = {'red_LED', 'green_LED', 'blue_LED'};
            
            for LED = 1:length(LEDs)
                epoch.addStimulus(obj.(LEDs{LED}), obj.ledStimulus(obj.(LEDs{LED})));
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
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
        % get methods for dependent and hidden parameters that will be used
        % to move between cone space and LED space
        % UPDATE TO INCLUDE CALIBRATION VALUES
        function value = get.coneToLED(obj)
            
            if ~isempty(obj.LEDToCone)
                value = inv(obj.LEDToCone);
            else
                value = 0;
            end
        end
        
        function value = get.LEDToCone(obj)
            
            if ~(isempty(obj.sRGBSensitivity)||isempty(obj.mRGBSensitivity)||isempty(obj.lRGBSensitivity))
                
                % this matrix will depend on the calibration values for the
                % rig because they are used in the calculation below
                % sensitivity vectors are column vectors
                value = [obj.sRGBSensitivity; obj.mRGBSensitivity; obj.lRGBSensitivity].*...
                    [obj.rigConfig.redLEDCalibration obj.rigConfig.greenLEDCalibration obj.rigConfig.blueLEDCalibration;
                    obj.rigConfig.redLEDCalibration obj.rigConfig.greenLEDCalibration obj.rigConfig.blueLEDCalibration;
                    obj.rigConfig.redLEDCalibration obj.rigConfig.greenLEDCalibration obj.rigConfig.blueLEDCalibration];
            else
                value = 0;
            end
        end
        
        % calculates levels of LEDs necessary to
        % produce user defined cone response means
        function value = get.RGBLEDmeans(obj)
            %             if ~(isempty(obj.coneToLED)||isempty(obj.coneBaseline)||...
            %                     isempty(obj.equalConeResponseVector))
            %                 value =  obj.coneToLED*(obj.coneBaseline*obj.equalConeResponseVector);
            %             else
            %                 value = 0;
            %             end
            value = obj.hardCodedWhitePointRGB;
        end
        
        %         calculate the current point in cone space based on current mean
        %         value of the equal cone response vector as well as change in
        %         contrast due to any entered stimuli
        function value = get.stimConeSpacePoint(obj)
            
            if ~(isempty(obj.sConeContrast)||isempty(obj.mConeContrast)||...
                    isempty(obj.lConeContrast)||isempty(obj.coneBaseline))
                value = (obj.sConeContrast/100)*obj.coneBaseline*[1;0;0] + ...
                    (obj.mConeContrast/100)*obj.coneBaseline*[0;1;0] + ...
                    (obj.lConeContrast/100)*obj.coneBaseline*[0;0;1];
                
            else
                value = 0;
            end
            
        end
        
        function value = get.stimLEDSpacePoint(obj)
            if ~(isempty(obj.coneToLED)||isempty(obj.stimConeSpacePoint))
                value = obj.coneToLED*obj.stimConeSpacePoint;
            else
                value = 0;
            end
            
        end
        
        % this will find the contrast ranges that area allowable from the
        % current mean - the calculated values will be used in tool tips
        % for stimulus contrast for each cone to define the possible range
        function value = get.coneContrastRanges(obj)
            % create a structure to store possible increases/decreases for
            % each of the LEDs
            value = struct;
            
            % vectors with min and max values in volts for each LED
            
            
            % make a matrix of LED ranges, with the first column being
            % minimum values and second maximum values
            LEDRanges = [obj.redLEDRange; obj.greenLEDRange; obj.blueLEDRange];
            
            % subtract current point in LED space from vector with max
            % allowable voltage output to each LED
            allowableIncreases = LEDRanges(:,2) - (obj.RGBLEDmeans + ...
                obj.stimLEDSpacePoint);
            % subtract current point in LED space from minimum allowable
            % LED output voltages
            allowableDecreases = LEDRanges(:,1) - (obj.RGBLEDmeans + ...
                obj.stimLEDSpacePoint);
            
            
            % scalesToBoundaries = cell(3,2);
            
            % calculate range for each cone type
            for cone = 1:3
                
                
                possibleScalings = [(allowableIncreases./obj.coneToLED(:,cone))' ...
                    (allowableDecreases./obj.coneToLED(:,cone))'];
                
                possibleIncreases = possibleScalings(possibleScalings > 0);
                possibleDecreases = -possibleScalings(possibleScalings < 0);
                
                
                
                switch cone
                    case 1 % sCone
                        value.sCone.increase = min(possibleIncreases)/obj.coneBaseline;
                        value.sCone.decrease = min(possibleDecreases)/obj.coneBaseline;
                    case 2 % mCone
                        value.mCone.increase = min(possibleIncreases)/obj.coneBaseline;
                        value.mCone.decrease = min(possibleDecreases)/obj.coneBaseline;
                    case 3 % lCone
                        value.lCone.increase = min(possibleIncreases)/obj.coneBaseline;
                        value.lCone.decrease = min(possibleDecreases)/obj.coneBaseline;
                end
                
            end
            
        end
        
        % outOfLEDRange will return a three element vector corresponding to
        % the R, G, then B LEDs that will have a 1 if the LED is out of
        % range and a 0 if it is within range
        function value = get.outOfLEDRange(obj)
            
            LEDRanges = [obj.redLEDRange; obj.greenLEDRange; obj.blueLEDRange];
            stimPoint = obj.stimLEDSpacePoint + obj.RGBLEDmeans;
            value = sum((stimPoint<LEDRanges(:,1)) + (stimPoint>LEDRanges(:,2))) > 0;
        end
        
    end
    
end

