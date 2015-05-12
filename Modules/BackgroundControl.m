% Controls for setting the background on all output devices in the current rig configuration.

classdef BackgroundControl < Module

    properties (Constant)
        displayName = 'Background Control!'
    end

    properties
        rigConfigChanged    % Rig config changed event listener.
        deviceBackgroundSet % Device background set event listener.
        controls            % Struct containing UI element handles.
    end

    methods

        function obj = BackgroundControl(symphonyUI)
            obj = obj@Module(symphonyUI);

            obj.rigConfigChanged = addlistener(symphonyUI, 'ChangedRigConfig', @(src,evt)obj.createUI());

            set(obj.figureHandle, 'Resize', 'off');
            set(obj.figureHandle, 'WindowKeyPressFcn', @obj.windowKeyPress);
            obj.createUI();
        end


        function delete(obj)
            delete(obj.rigConfigChanged);
            delete(obj.deviceBackgroundSet);
        end


        function createUI(obj)
            % Creates all UI elements on the main figure.

            clf(obj.figureHandle);

            % Size figure to fit all output devices.
            outDevices = obj.symphonyUI.rigConfig.outputDevices();

            labelWidth = 120;
            figureHeight = length(outDevices) * 30 + 40;
            figureWidth = labelWidth + 120;

            position = get(obj.figureHandle, 'Position');
            position(3) = labelWidth + 120;
            position(4) = figureHeight;
            set(obj.figureHandle, 'Position', position);

            % Create a control for each output device.
            for i = 1:length(outDevices)
                dev = outDevices{i};

                % Device name label.
                uicontrol(...
                    'Parent', obj.figureHandle,...
                    'Units', 'points', ...
                    'FontSize', 12,...
                    'HorizontalAlignment', 'right', ...
                    'Position', [10 figureHeight-i*30 labelWidth 18], ...
                    'String',  char(dev.Name),...
                    'Style', 'text');

                % Background input field.
                editTag = [char(dev.Name) 'Edit'];
                value = double(System.Convert.ToDouble(dev.Background.Quantity));
                outStreams = enumerableToCellArray(dev.OutputStreams, 'Symphony.Core.IDAQOutputStream');
                if strncmp(char(outStreams{1}.Name), 'DIGITAL', 7)
                    % Background checkbox.
                    obj.controls.(editTag) = uicontrol(...
                        'Parent', obj.figureHandle,...
                        'Units', 'points', ...
                        'FontSize', 12,...
                        'Position', [labelWidth+15 figureHeight-i*30-2 50 26], ...
                        'Value', value, ...
                        'Style', 'checkbox', ...
                        'Tag', editTag);
                else
                    % Background text field and unit label.
                    obj.controls.(editTag) = uicontrol(...
                        'Parent', obj.figureHandle,...
                        'Units', 'points', ...
                        'FontSize', 12,...
                        'HorizontalAlignment', 'left', ...
                        'Position', [labelWidth+15 figureHeight-i*30-2 50 26], ...
                        'String', num2str(value),...
                        'Style', 'edit', ...
                        'Tag', editTag);

                    unitTag = [char(dev.Name) 'Unit'];
                    unit = char(dev.Background.DisplayUnit);
                    if strcmpi(unit,'Symphony.Core.Measurement.NORMALIZED')
                        unit = 'norm.';
                    end
                    position = get(obj.controls.(editTag), 'Position');
                    unitLeft = position(1) + position(3) + 5;
                    obj.controls.(unitTag) = uicontrol(...
                        'Parent', obj.figureHandle,...
                        'Units', 'points', ...
                        'FontSize', 12, ...
                        'HorizontalAlignment', 'left', ...
                        'Position', [unitLeft figureHeight-i*30 40 18], ...
                        'String', unit, ...
                        'Style', 'text', ...
                        'Tag', unitTag);
                end
            end

            obj.controls.applyButton = uicontrol( ...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Callback', @(src,evt)obj.apply(), ...
                'Position',[figureWidth-66 10 56 20], ...
                'String', 'Apply', ...
                'Tag', 'applyButton');

            % add a button that will turn off background on all LEDs
            obj.controls.allOffButton = uicontrol(...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Callback', @(src,evt)obj.ledsOff(), ...
                'Position',[figureWidth-132 10 56 20], ...
                'String', 'LEDs Off', ...
                'Tag', 'ledsOffButton');

            setDefaultButton(obj.figureHandle, obj.controls.applyButton);

            obj.deviceBackgroundSet = addlistener(obj.symphonyUI.rigConfig, 'SetDeviceBackground', @(src,evt)obj.update());
        end


        function update(obj)
            % Updates all background fields with current background value.

            outDevices = obj.symphonyUI.rigConfig.outputDevices();
            for i = 1:length(outDevices)
                dev = outDevices{i};

                % Background input field.
                editTag = [char(dev.Name) 'Edit'];
                value = double(System.Convert.ToDouble(dev.Background.Quantity));
                outStreams = enumerableToCellArray(dev.OutputStreams, 'Symphony.Core.IDAQOutputStream');
                if strncmp(char(outStreams{1}.Name), 'DIGITAL', 7)
                    % Background checkbox.
                    set(obj.controls.(editTag), 'Value', value);
                else
                    % Background text field and unit label.
                    set(obj.controls.(editTag), 'String', value);

                    unitTag = [char(dev.Name) 'Unit'];
                    unit = char(dev.Background.DisplayUnit);
                    if unit == Symphony.Core.Measurement.NORMALIZED
                        unit = 'norm.';
                    end
                    set(obj.controls.(unitTag), 'String', unit);
                end
            end
        end


        function windowKeyPress(obj, ~, data)
            if strcmp(data.Key, 'return')
                % Move focus off of any edit text so the changes can be seen.
                uicontrol(obj.controls.applyButton);

                obj.apply();
            end
        end


        function apply(obj)
            % Applies all background values from fields to devices.

            outDevices = obj.symphonyUI.rigConfig.outputDevices();
            backgrounds = cell(1, length(outDevices));
            for i = 1:length(outDevices)
                dev = outDevices{i};
                devName = char(dev.Name);
                devUnit = char(dev.Background.DisplayUnit);

                tag = [devName 'Edit'];
                if strcmp(get(obj.controls.(tag), 'Style'), 'checkbox')
                    value = get(obj.controls.(tag), 'Value') == get(obj.controls.(tag), 'Max');
                else
                    value = str2double(get(obj.controls.(tag), 'String'));
                end

                backgrounds{i} = {devName, value, devUnit};
            end

            for i = 1:length(backgrounds)
                try
                    obj.symphonyUI.rigConfig.setDeviceBackground(backgrounds{i}{:});
                catch
                    errordlg(['Could not set background for ' backgrounds{i}{1}]);
                    continue;
                end
            end
        end

        function ledsOff(obj)
            % turns off background for all leds

            % get output devices names
            outDevices = obj.symphonyUI.rigConfig.outputDevices();

            for i = 1:length(outDevices)
                % check if it is an LED
                if sum(regexpi(char(outDevices{i}.Name),'LED'))
                    % if so, shut it off
                    tag = [char(outDevices{i}.Name) 'Edit'];
                    set(obj.controls.(tag), 'String', '0');
                end
            end

            % apply new backgrounds
            obj.apply();

        end

    end

end
