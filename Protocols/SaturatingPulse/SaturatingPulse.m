classdef SaturatingPulse < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.SaturatingPulse'
        version = 4
        displayName = 'Saturating Pulse'
    end
    
    properties
        
        led
        preTime = 10
        stimTime = 100
        tailTime = 400
        lightAmplitude = 0.1
        amp
       
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        numberOfAverages = uint8(5)
        interpulseInterval = 0
    end
    
    properties (Hidden)
         
        % this will be a property that will contain all things relevant to
        % the custom figure
        plotData
        
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case 'led'
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                case {'lightAmplitude', 'lightMean'}
                    % Support both calibrated and non-calibrated LEDs.
                    p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
                    if p.units == Symphony.Core.Measurement.NORMALIZED
                        p.units = 'norm. [0-1]';
                    end
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                % this will retrieve the plot data from the last time this
                % protocol was run
                obj.plotData = obj.storedData();
                % this is the custom figure handler to monitor kinetics
                obj.plotData.figureHandle = obj.openFigure('Custom', 'UpdateCallback', @updateFigure);
            else
                % same as above -- consider removing this if statement,
                % because it may not matter
                obj.plotData = obj.storedData();
                obj.plotData.figureHandle = obj.openFigure('Custom', 'UpdateCallback', @updateFigure);
            end
            
            % restore the epoch data
            obj.plotData.data = SaturatingPulse.storedData();
            
            % restore the figure
            obj.restoreFigure;
                        
            % Set LED mean.
            obj.setDeviceBackground(obj.led, 0);
        end
        
        
        function stim = ledStimulus(obj)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.mean = 0;
            p.amplitude = obj.lightAmplitude;
            p.sampleRate = obj.sampleRate;
            p.units = char(obj.rigConfig.deviceWithName(obj.led).Background.DisplayUnit);
            
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return LED stimulus for display in the edit parameters window.
            stimuli{1} = obj.ledStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Add LED stimulus.
            epoch.addStimulus(obj.led, obj.ledStimulus());
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
        
        
        function updateFigure(obj, epoch, ~)
                        
            % this will be the function that updates the figure as each new
            % epoch arrives
            
            % get response data and sample rate
            [response, ~] = epoch.response(obj.amp);
            
            time = obj.getTimeString;
            
            
            
            % zero the epoch, filter it, store it in the appropriate
            % location
            response = obj.zeroEpoch(response);
            
            %%%%%%%%%%%%%% DEBUG STUFF %%%%%%%%%%%%%%%%
            response = rand(1,length(response));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            normalized = obj.normalizeEpoch(response);
            filtered = obj.filterEpoch(normalized);
            timePts = (1:length(response)) * obj.sampleRate / 1000;
            
            
            % store it - location in which it is stored will depend on if
            % there are already epochs stored
            if ~isempty(obj.plotData.data.upperL{1})
                % add it to the end
                obj.plotData.data.upperL{end+1,1} = response;
                % save the time vector
                obj.plotData.data.upperL{end,3} = timePts;
                % save the time
                obj.plotData.data.upperL{end,4} = time;
            else
                % add it as the first epoch to be stored
                obj.plotData.data.upperL{1,1} = response;
                % save the time vector
                obj.plotData.data.upperL{1,3} = timePts;
                obj.plotData.data.upperL{1,4} = time;
            end
            
            % save the necessary data for the other two plots - note that
            % these two plots will take normalized responese instead of the
            % raw traces
            
            % upper right
            if ~isempty(obj.plotData.upperR{1})
                obj.plotData.data.upperR{end+1,1} = normalized;
                obj.plotData.data.upperR{end,2} = filtered;
                obj.plotData.data.upperR{end,3} = timePts;
                obj.plotData.data.upperR{end,4} = time;
            else
                obj.plotData.data.upperR{1,1} = normalized;
                obj.plotData.data.upperR{1,2} = filtered;
                obj.plotData.data.upperR{1,3} = timePts;
                obj.plotData.data.upperR{1,4} = time;
            end
            
            % lower
            if ~isempty(obj.plotData.lower{1})
                obj.plotData.data.lower{end+1,1} = normalized;
                obj.plotData.data.lower{end,2} = filtered;
                obj.plotData.data.lower{end,3} = timePts;
                obj.plotData.data.lower{end,4} = time;
            else
                obj.plotData.data.lower{1,1} = normalized;
                obj.plotData.data.lower{1,2} = filtered;
                obj.plotData.data.lower{1,3} = timePts;
                obj.plotData.data.lower{1,4} = time;
            end
            
            
            % replot all data
            obj.plotEpochs;
            
            % update slider value and range
            obj.updateSliderValues;
            
            
            % store to the persistent variable
            SaturatingPulse.storedData(obj.plotData.data);
            
        end
        
        
        function restoreFigure(obj)
            
            % this function will restore the custom figure associated with
            % this protocol - the figure will be deleted each time the
            % protocol is changed, so this will return it to its former
            % state
            
            % call the figure desigining method
            obj.designFigure;
            
            % restore the slider position (and therefore the currently
            % selected epoch), the bounds, and the dates
            
            % replot the old stuff?
            obj.plotEpochs;
            
        end
        
        
        function plotEpochs(obj)
            % this function should just look for data and replot epochs on
            % each of the three figures
            
            % make a more convenient variable to deal with
            data = obj.plotData.data;
            
            % get the colors
            colors = obj.plotData.colors;
            
            % start by clearing all of the lines on the plots, if there are
            % lines on them
            obj.clearPlot('upperL');
            obj.clearPlot('upperR');
            obj.clearPlot('lower');
            
            % the upper left figure will plot the seed epoch as well as the
            % most recent epoch in their raw form
            
            % this will be the epochs stored for the upper right figure
            num = size(data.upperL, 1);
            
            % determine if there is 0, 1, or 2 epochs stored, and plot all
            % available epochs
            if num
                % this means there is at least one epoch - the first epoch
                % will be the "seed" - plot this in black
                
                % plot the epoch, and store the line handle
                data.upperL{1,5} = plot(obj.plotData.axesHandles{1}, ...
                    data.upperL{1,3}, data.upperL{1,1},...
                    'Color', colors.backgroundLine, ...
                    'LineWidth', obj.plotData.positions.lineWidthUpper);
                
                if num > 1
                    % plot the second line - it will have the "selected
                    % line" color because it will be the most recent epoch
                    data.upperL{2,5} = plot(obj.plotData.axesHandles{1}, ...
                        data.upperL{2,3}, data.upperL{2,1}, ...
                        'Color', colors.selectedLine, ...
                        'LineWidth', obj.plotData.positions.lineWidthUpper);
                else
                    % if there is not a second epoch to plot, change the
                    % color of the only line to the "selected line" color
                    set(data.upperL{1,5}, ...
                        'Color', colors.selectedLine);
                end
            end
            
            
            % do the same for the upper right figure
            
            num = size(data.upperR, 1);
            
            if num
                % this figure will plot normalized responses
                data.upperR{1,5} = plot(obj.plotData.axesHandles{2}, ...
                    data.upperR{1,3}, data.upperR{1,1}, ...
                    'Color', colors.backgroundLine, ...
                    'LineWidth', obj.plotData.positions.lineWidthUpper);
                
                if num > 1
                    data.upperR{2,5} = plot(obj.plotData.axesHandles{2}, ...
                        data.upperR{2,3}, data.upperR{2,1}, ...
                        'Color', colors.selectedLine, ...
                        'LineWidth', obj.plotData.positions.lineWidthUpper);
                else
                    set(data.upperR{1,5}, ...
                        'Color', colors.selectedLine);
                end
            end
            
            
            % for the lower left figure, deal with color too
            num = size(data.lower, 1);
            
            slider = obj.plotData.data.slider;
            
            if num
                % there is at least one epoch, plot it
                
                % if the first epoch is selected, give it the appropriate
                % color
                if slider == 1
                    col = colors.selectedLine;
                else
                    col = colors.backgroundLine;
                end
                
                data.lower{1,5} = plot(obj.plotData.axesHandles{3}, ...
                    data.lower{1,3}, data.lower{1,2}, ...
                    'Color', col, ...
                    'LineWidth', obj.plotData.positions.lineWidthLower);
                if num > 1
                    % plot all the remaining epochs
                    for ep = 2:num
                        
                        if slider == ep
                            col = colors.selectedLine;
                        else
                            col = colors.backgroundLine;
                        end
                        
                        data.lower{ep,5} = plot(obj.plotData.axesHandles{3}, ...
                            data.lower{ep,3}, data.lower{ep,2}, ...
                            'Color', col, ...
                            'LineWidth', obj.plotData.positions.lineWidthLower);
                        
                    end
                    
                end
                
                % make certain the selected figure is at the top of the
                % stack of lines
                uistack(data.lower{slider,5}, 'top')
                
                % update the displayed times on the figure
                obj.updateSelectedTime;
                set(obj.plotData.uiElements.timeSeedString, 'String', ...
                    obj.plotData.data.lower{1,4});
            end
            
            
            
            % return all changes to plot data structure
            obj.plotData.data = data;
                                   
        end
            
        
        function updateSliderValues(obj)
            
            % this function will update the range of values that the slider
            % can take - the min should always be 1, so it will just change
            % the max - it will also check to make sure that the slider is
            % in the appropriate position based on which epoch is currently
            % selected (problems could arise, for example, if epoch 4 is
            % selected when epoch 2 is removed - this will fix that)
            
            % get the max value
            maxVal = size(obj.plotData.data.lower,1);
            
            % if the max is supposed to be 1, matlab requires that the min
            % and the max are not the same, so set it to be something
            % barely larger than 1
            if maxVal == 1
                maxVal = 1.00001;
            end
            
            % set the slider max
            set(obj.plotData.uiElements.scrollbar, 'max', maxVal, ...
                'sliderstep', (1/maxVal)*ones(1,2));
            
            
            % determine which epoch is selected
            
            % there likely is a more efficient way to do this, but this
            % will do for now
            % looking for the epoch that is currently selected
       
            found = 0;
            current = 0;
            while found == 0
                current = current + 1;
                if get(obj.plotData.data.lower{current,5}, 'Color') == obj.plotData.colors.selectedLine
                  found = 1;
                end
            end
            
            % once the selected epoch has been found, make sure the slider
            % reflects that
            set(obj.plotData.uiElements.scrollbar, 'value', current);
            obj.plotData.slider = current;
         
            
        end
        
        
        function obj = sliderCallback(obj, hObject, ~)
       
            % make sure slider value is an integer
            value = round(get(hObject, 'value'));
            set(hObject, 'value', value);
            
            % this is the value the slider had previously
            oldValue = obj.plotData.data.slider;
            
            % store the new value to plotData
            obj.plotData.data.slider = value;
            % save this to the persistent variable
            SaturatingPulse.storedData(obj.plotData.data);
            
            % change the color of the previously selected line back to the
            % background line color, and change the color of the newly
            % selected line to the selected line color
            set(obj.plotData.data.lower{oldValue,5}, 'Color', obj.plotData.colors.backgroundLine);
            set(obj.plotData.data.lower{value,5}, 'Color', obj.plotData.colors.selectedLine);
            
            % place selected line on top of stack of lines on the figure
            uistack(obj.plotData.data.lower{value,5}, 'top');
        
            % update the time that is displayed for the selected epoch
            set(obj.plotData.uiElements.timeSelectedString , 'String', obj.plotData.data.lower{value,4});
            
            % update selected epoch time
            obj.updateSelectedTime;
            
        end
        
        
        function obj = removeButtonCallback(obj, ~, ~)
            
            % remove the hilighted epoch - get from slider
            
            if ~isempty(obj.plotData.data.upperL{1})
                              
                % find which epoch is selected, in order to remove it
                current = obj.plotData.data.slider;
                
                % remove selected and move all subsequent rows up
                
                % get number of epochs on lower plot
                num = size(obj.plotData.data.lower,1);
                
                % depending on which epoch is chosen, different things will
                % need to be done
                if current == 1
                    % this would be removing the reference trace (or
                    % "seed") - the user will be prompted to see if they
                    % indeed want to do this, and if so, it will just do
                    % the same thing as pressing the reset button
                    question = ['Are you sure you would like to remove the reference epoch?  ' ...
                        'Doing so will be equivalent to pressing reset.'];
                    title = 'Removing Reference';
                    button = questdlg(question, title,'Yes','No','No');
                    
                    if strcmp(button, 'Yes')
                       % if so, reset
                       obj.resetButtonCallback();
                    end
                else
                    
                    % clear the plots
                    obj.clearPlot('lower');
                    obj.clearPlot('upperR');
                    obj.clearPlot('upperL');
                    
                    if current == num
                        
                    % if the user has chosen to remove the most recent
                    % epoch, it must be removed from all of the axes
                    obj.plotData.data.upperL = obj.plotData.data.upperL(1:end-1,:); 
                    obj.plotData.data.upperR = obj.plotData.data.upperR(1:end-1,:);
                    obj.plotData.data.lower = obj.plotData.data.lower(1:end-1,:);
                   
                    
                    
                    else
                        
                        % this means that the user has chosen to remove some
                        % epoch in the middle - no the first and not the
                        % last -- remove that given row - also fix the
                        % slider value
                        
                        before = obj.plotData.data.lower(1:current-1,:);
                        after = obj.plotData.data.lower(current+1:end,:);
                        
                        obj.plotData.data.lower = [before; after];
                    end
                    
                    % give the slider a new value
                    obj.plotData.data.slider = current - 1;
                    
                    % save the results to the persistent variable
                    SaturatingPulse.storedData(obj.plotData.data);
                    
                    % plotEpochs function will make the plots reflect all of the
                    % changes
                    obj.plotEpochs;
                    
                    % update the slider
                    obj.updateSliderValues;
                end
                
                
            end
            
        end
        
        
        function obj = resetButtonCallback(obj, ~, ~)
            
            % remove all saved epochs except for the most recent and
            % change the seed time to reflect the time for that given epoch
            if ~isempty(obj.plotData.data.upperL{1})
                
                obj.clearPlot('lower');
                obj.clearPlot('upperR');
                obj.clearPlot('upperL');
                
                
                obj.plotData.data.upperL = obj.plotData.data.upperL(end,:);
                obj.plotData.data.upperR = obj.plotData.data.upperR(end,:);
                obj.plotData.data.lower = obj.plotData.data.lower(end,:);
            end
            
            % save the results to the persistent variable
            SaturatingPulse.storedData(obj.plotData.data);
            
            % plotEpochs function will make the plots reflect all of the
            % changes
            obj.plotEpochs;
        end
        
        
        function value = getTimeString(obj) %#ok<MANU>
            
            % get clock time
            time = clock;
            
            % throw away the date data as well as the seconds
            time = time(4:5);
            
            % convert it to 12 hour clock time
            if time(1) > 12
                time(1) = time(1) - 12;
            end
            
            hour = num2str(time(1));
            
            if time(2) > 9
                min = num2str(time(2));
            else
                min = ['0' num2str(time(2))];
            end                   
             
            % make the clock string
            value = [hour ':' min];
            
        end
        
        
        function obj = changeFilterBounds(obj, ~, ~)
            % this is the callback for a change in the filter bounds
            
            lower = get(obj.plotData.uiElements.lowerBoundBox, 'String');
            upper = get(obj.plotData.uiElements.upperBoundBox, 'String');
            
            % save the new filter values to the plotData structure
            obj.plotData.data.filter = {lower, upper};
            
            % filter all the epochs with new bounds
            obj.filterAllEpochs;
            
            % save the newly filtered data set to the persistent variable
            SaturatingPulse.storedData(obj.plotData.data);
            
            % replot the newly filtered epochs
            obj.plotEpochs;
                      
        end
        
        
        function updateSelectedTime(obj)
            
            % get the selected epoch
            ep = obj.plotData.data.slider;
            
            % get the time for that given epoch
            time = obj.plotData.data.lower{ep,4};
            
            % change the time on the display
            set(obj.plotData.uiElements.timeSelectedString, 'String', time);
            
        end
        
        
        function filterAllEpochs(obj)
            % the epochs on the top right and bottom plots should be
            % filtered - this method is called when the filter bounds have
            % been changed and should refilter all of the epochs with the
            % new bounds
            
            % deal with upper right plot first
            % check to see if there is data for the plot, if there is,
            % filter it
            if ~isempty(obj.plotData.data.upperR{1})
                % this number will be 1 or 2 for this given plot
                num = size(obj.plotData.data.upperR, 1);
                for ep = 1:num
                    % filter
                    obj.plotData.data.upperR{ep,2} = ...
                        obj.filterEpoch(obj.plotData.data.upperR{ep,1});
                end
            end
            
            % do the same for the bottom plot
            if ~isempty(obj.plotData.data.lower{1})
               % get the number of epochs that are currently stored
               num = size(obj.plotData.data.lower, 1);
               for ep = 1:num
                  % filter 
                   obj.plotData.data.lower{ep,2} = ...
                       obj.filterEpoch(obj.plotData.data.lower{ep,1});
               end               
                
            end
            
        end
        
        
        function designFigure(obj)
            % get the handle from the plotData structure
            handle = obj.plotData.figureHandle.figureHandle;
            
            % define some default properties if they haven't been defined
            % previously - there is a method that defines these so that
            % they are kept in a single place
            if ~isfield(obj.plotData, 'figureProp')
                obj.defaultFigProp;
            end
            
            % assign the properties to the figure
            set(handle, obj.plotData.figureProp);
            
            % remove any axes already on the plot
            set(get(handle, 'children'), 'Visible', 'off')
            
            % add axes to the plot
            % define the default axes positions if they have not been
            % defined already
            if ~isfield(obj.plotData, 'axesPositions')
                obj.defaultAxesPositions;
            end
            
            for axes = 1:length(obj.plotData.axesPositions)
                obj.plotData.axesHandles{axes} = ...
                    obj.createAxes(handle, obj.plotData.axesPositions{axes});
            end
            
            
            
            % add ui elements to the plot
            obj.addUIElements(handle);
            
        end
        
        
        function clearPlot(obj, fieldString)
            % for each plot, there is a field to the obj.plotData.data
            % structure that contains all of the information for each plot
            % on that specific axis - it will be in the fifth column of
            % that cell array - this will determine how many rows there
            % are, then clear the plot that whose handle is in the fifth
            % column of each row
            
            % num rows
            num = size(obj.plotData.data.(fieldString), 1);
            
            for ep = 1:num
                % if there is a handle in the fifth column, delete it
                if ~isempty(obj.plotData.data.(fieldString){ep,5})
                    if ishandle(obj.plotData.data.(fieldString){ep,5})
                        delete(obj.plotData.data.(fieldString){ep,5})
                    end
                end
            end
            
        end
        
        
        function axesHandle = createAxes(obj, figHandle, position)
            
            % this is the place where all the default axes stuff will be
            % stored - because all axes will have the same properties,
            % defining them once here will simplify things.
            if ~isfield(obj.plotData, 'colors')
                obj.definePlotColors;
            end
            colors = obj.plotData.colors;
            
            
            set(0, 'CurrentFigure', figHandle);
            axesHandle = axes('Visible', 'on', ...
                'Units', 'Normalize', ...
                'Position', position, ...
                'NextPlot', 'add', ...
                'Color', colors.figureBackground, ...
                'Box', 'off', ...
                'YColor', colors.axesColor, ...
                'XColor', colors.axesColor);
            
            
        end
        
        
        function value = filterEpoch(obj, data)
            % this will bandpass filter the epoch
            
            % get the upper and lower bounds based on the entries into the
            % bound boxes on the figure
            lower = str2double(obj.plotData.data.filter{1});
            upper = str2double(obj.plotData.data.filter{2});
            
            % number of data points per epoch
            inputPts = length(data);
            
            % make sure there are an even number of points, if not,
            % duplicate the final point
            if ~isinteger(size(data,2)/2)
                data = [data data(end)];
            end
            
            % vector with frequencies for each element in the output of FFT
            fftFrequencies = [(0:inputPts/2) fliplr(-(1:inputPts/2 -1))] * obj.sampleRate / inputPts;
            
            % do FFT
            dataFFT = fft(data);
            % delete data at all frequencies outside of ranges defined in inputs
            dataFFT(abs(fftFrequencies) < lower | abs(fftFrequencies) > upper) = 0;
            % inverse FFT to get back to time domain
            value = real(ifft(dataFFT));
            
            % confirm that the FFT has not changed the length of the vector
            outputPts = length(value);
            if outputPts ~= inputPts
                if outputPts > inputPts
                    % remove until lengths are same
                    value = value(1:inputPts);
                else
                    % add the final value to the end of the vector enough
                    % times to resolve the length difference
                    toAdd = inputPts - outputPts;
                    value = [value value(outputPts)*ones(1,toAdd)];
                end
            end
            
        end
        
        
        function value = prePts(obj)
            % get the number of pre points
            value = obj.preTime * obj.sampleRate / 1000;
        end
        
        
        function value = zeroEpoch(obj, data)
            
            % subtract the mean of all of the points before the stimulus
            % was delivered to zero the data
            value = data - mean(data(1:obj.prePts));
            
        end
        
        
        function value = normalizeEpoch(obj, data) %#ok<INUSL>
            
            % check to make sure that it isn't a vector of zeros
            maxVal = max(data);
            if maxVal
                % divide the entire epoch by the max value of the epoch
                value = data / max(data);
            else
                % if it is a vector of zeros, then return the vector
                % unchanged
                value = data;
            end
            
        end
        
        
        function obj = defaultFigProp(obj)
            
            % this will be the place where all of the default figure
            % properties are defined
            
            prop.Color = 'w';
            prop.Toolbar = 'none';
            prop.MenuBar = 'none';
            
            
            obj.plotData.figureProp = prop;
        end
        
        
        function obj = definePlotColors(obj)
            % this will be the place where all of the default plot colors
            % are defined
            
            colors.figureBackground = [1 1 1];
            colors.backgroundLine = [1 0.2 0.2];
            colors.selectedLine = [0.3 0.3 1];
            colors.newLine = [1 0.2 0.2];
            colors.axesColor = [0 0 0];
            
            
            obj.plotData.colors = colors;
            
        end
        
        
        function obj = defineFigureSizesAndPositions(obj)
            
            % define the positions of all of the plot components and save
            % them to a structure within the plotData structure
            
            positions.titleStringPosition = [0.2 0.945 0.6 0.045];
            positions.titleFont = 0.75;
            
            positions.slider = [0.1 0.00 0.65 0.05];
            positions.sliderTitle = [0.35 0.05 0.2 0.03];
            positions.sliderTitleFontSize = 10;
            positions.stepsize = 1;
            positions.timeSeed = [0.78 0.4 0.18 0.06];
            positions.timeFontSize = 0.45;
            positions.timeSelected = [0.78 0.35 0.18 0.06];
            positions.removeSelected = [0.8 0.29 0.14 0.06];
            positions.buttonFontsize = 0.45;
            positions.filterBounds = [0.78 0.22 0.18 0.06];
            positions.upperBoundTitle = [0.8 0.175 0.1 0.04];
            positions.upperBoundBox = [0.905 0.1725 0.05 0.05];
            positions.lowerBoundTitle = [0.8 0.125 0.1 0.04];
            positions.lowerBoundBox = [0.905 0.1225 0.05 0.05];
            positions.boundsFontSize = 0.65;
            positions.boxFontSize = 0.25;
            positions.reset = [0.8 0.055 0.14 0.06];
            positions.lineWidthUpper = 1;
            positions.lineWidthLower = 2;
            
            
            obj.plotData.positions = positions;
            
            
        end
        
        
        function obj = defaultAxesPositions(obj)
            
            % define the positions of the axes and save them to a cell that
            % is within the plotData structure
            
            topLeft = [0.1 0.6 0.35 0.33];
            topRight = [0.55 0.6 0.35 0.33];
            bottomWide = [0.1 0.19 0.65 0.33];
            
            obj.plotData.axesPositions = {topLeft, topRight, bottomWide};
            
            
            
        end
        
        
        function obj = addUIElements(obj, handle)
            % if the positions of all of the UI elements have not been
            % defined, do so
            if ~isfield(obj.plotData, 'positions')
                obj.defineFigureSizesAndPositions;
            end
            
            if ~isfield(obj.plotData, 'colors')
                obj.definePlotColors;
            end
            
            color = obj.plotData.colors;
            
            pos = obj.plotData.positions;
            
            ui = struct;
            
            % get the number of epochs present on the plot to determine
            % slider range - then get the value at which the slider should
            % start
            num = size(obj.plotData.data.lower,1);
            % matlab will not render the slider unless the lower and upper
            % limits are not the same - this overcomes that
            if num == 1
                num = num*1.0001;
            end
            
            lower = 1;
            upper = num;
            
            value = obj.plotData.slider;
                       
            ui.scrollbar = uicontrol(handle, ...
                'Style', 'slider', ...
                'Units', 'Normalize', ...
                'Position', pos.slider, ...
                'Callback', @obj.sliderCallback, ...
                'min', lower, ...
                'max', upper, ...
                'value', value, ...
                'sliderstep', (1/num)*ones(1,2));
            
            ui.scrollbarTitle = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'choose epoch', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.sliderTitleFontSize, ...
                'Position', pos.sliderTitle, ...
                'BackgroundColor', [1 1 1]);
            
            
            
            ui.timeSeedString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'seed time', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.timeFontSize, ...
                'Position', pos.timeSeed, ...
                'BackgroundColor', color.figureBackground);
            
            ui.timeSelectedString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'selected time', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.timeFontSize, ...
                'Position', pos.timeSelected, ...
                'BackgroundColor', color.figureBackground);
            
            
            ui.removeSelectedButton = uicontrol(handle, ...
                'Style', 'pushbutton', ...
                'Units', 'Normalize', ...
                'Position', pos.removeSelected, ...
                'String', 'remove sel.', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.buttonFontsize, ...
                'BackgroundColor', color.figureBackground, ...
                'Callback', @obj.removeButtonCallback);
            
            ui.filterBoundString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'filter bounds', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.timeFontSize, ...
                'Position', pos.filterBounds, ...
                'BackgroundColor', color.figureBackground);
            
            
            ui.upperBoundString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'upper (Hz)', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.boundsFontSize, ...
                'Position', pos.upperBoundTitle, ...
                'BackgroundColor', color.figureBackground);
            
            ui.lowerBoundString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'lower (Hz)', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.boundsFontSize, ...
                'Position', pos.lowerBoundTitle, ...
                'BackgroundColor', color.figureBackground);
            
            ui.upperBoundBox = uicontrol(handle, ...
                'Style', 'edit', ...
                'Units', 'Normalize', ...
                'String', obj.plotData.data.filter{2}, ...
                'Position', pos.upperBoundBox, ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.boxFontSize, ...
                'BackgroundColor', color.figureBackground, ...
                'Callback', @obj.changeFilterBounds);
            
            ui.lowerBoundBox = uicontrol(handle, ...
                'Style', 'edit', ...
                'Units', 'Normalize', ...
                'String', obj.plotData.data.filter{1}, ...
                'Position', pos.lowerBoundBox, ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.boxFontSize, ...
                'BackgroundColor', color.figureBackground, ...
                'Callback', @obj.changeFilterBounds);
            
            
            ui.titleString = uicontrol(handle, ...
                'Style', 'text', ...
                'Units', 'Normalize', ...
                'String', 'Sat Response Kinetics', ...
                'Position', pos.titleStringPosition, ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.titleFont, ...
                'BackgroundColor', color.figureBackground);
            
            
            ui.resetButton = uicontrol(handle, ...
                'Style', 'pushbutton', ...
                'Units', 'Normalize', ...
                'Position', pos.reset, ...
                'String', 'reset', ...
                'FontUnits', 'Normalize', ...
                'FontSize', pos.buttonFontsize, ...
                'BackgroundColor', color.figureBackground, ...
                'Callback', @obj.resetButtonCallback);
            
            
            obj.plotData.uiElements = ui;
            
        end
                
    end
    
    methods (Static)
        
        function data = storedData(data)
            
            % This method stores plot data to be used from one instance of
            % the figure handler to another
            
            persistent stored;
            if nargin > 0
                stored = data;
            end
            
            if isempty(stored)
                
                % the first time this function is run, there will be no data
                % stored - if that is the case, create all the necessary
                % structure
                
                % for each plot, there will be a cell with five columns -
                % the raw data, the filtered data, the time vector, the
                % epoch time, and the handle for the line object
                data = struct;
                data.upperR = cell(1,5);
                data.upperL = cell(1,5);
                data.lower = cell(1,5);
                
                
                % make a field in which the state of the different ui
                % elements can be stored
                data.filter = {'0', '20'};
                data.slider = 1;
               
                
                % save the new structure to the persistent variable
                stored = data;
                
            else
                data = stored;
            end
        end
        
    end
    
end

