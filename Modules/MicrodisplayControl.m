% Controls for an eMagin microdisplay.

classdef MicrodisplayControl < Module
    
    properties (Constant)
        displayName = 'Microdisplay Control'
    end
    
    properties
        rigConfigChanged    % Rig config changed event listener.
        controls            % Struct containing UI element handles.
        stage
    end
    
    methods
        
        function obj = MicrodisplayControl(symphonyUI)
            obj = obj@Module(symphonyUI);
            
            obj.rigConfigChanged = addlistener(symphonyUI, 'ChangedRigConfig', @(src,evt)obj.setStage());
            
            set(obj.figureHandle, 'Resize', 'off');
            obj.setStage();
        end
        
        
        function delete(obj)
            delete(obj.rigConfigChanged);
        end
        
        
        function setStage(obj)
            rigConfig = obj.symphonyUI.rigConfig;
            if isprop(rigConfig, 'stage') && ~isempty(rigConfig.stage)
                obj.stage = OledStageClient(rigConfig.stage);
            else
                obj.stage = [];
            end
            
            obj.createUI();
        end
        
        
        function createUI(obj)
            % Creates all UI elements on the main figure.
            
            clf(obj.figureHandle);
            
            position = get(obj.figureHandle, 'Position');
            position(3) = 130;
            position(4) = 55;
            set(obj.figureHandle, 'Position', position);
            
            if isempty(obj.stage)
                uicontrol(...
                    'Parent', obj.figureHandle,...
                    'Units', 'points', ...
                    'FontSize', 12,...
                    'HorizontalAlignment', 'left', ...
                    'Position', [8 20 200 18], ...
                    'String',  'No stage in rig config.',...
                    'Style', 'text');
                
                return;
            end
            
            try
                brightness = obj.stage.getOledBrightness();
            catch
                uicontrol(...
                    'Parent', obj.figureHandle,...
                    'Units', 'points', ...
                    'FontSize', 12,...
                    'HorizontalAlignment', 'left', ...
                    'Position', [8 20 200 18], ...
                    'String',  'Not an OLED server.',...
                    'Style', 'text');
                
                return;
            end
            
            switch brightness
                case OledBrightness.HIGH
                    value = 1;
                case OledBrightness.MEDIUM
                    value = 2;
                case OledBrightness.LOW
                    value = 3;
                case OledBrightness.MIN
                    value = 4;
                otherwise
                    error('Unknown brightness');
            end
            
            % Brightness popup menu.
            obj.controls.brightnessPopup = uicontrol( ...
                'Parent', obj.figureHandle,...
                'Units', 'points', ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'Position', [10 10 110 20], ...
                'String', {'High', 'Medium', 'Low', 'Minimum'}, ...
                'Value', value, ...
                'Callback', @(src,evt)obj.chooseBrightness(), ...
                'Style', 'popupmenu');
            
            % Brightness label.
            uicontrol(...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'Position', [10 30 60 18], ...
                'String',  'Brightness:',...
                'Style', 'text');
        end
        
        
        function chooseBrightness(obj)
            % The user selected a brightness level from the popup menu.
            
            contents = get(obj.controls.brightnessPopup, 'String');
            index = get(obj.controls.brightnessPopup, 'Value');
            
            config = obj.symphonyUI.rigConfig.stageConfig;
            
            switch upper(contents{index})
                case 'HIGH'
                    obj.setGamma(config.highGammaRamp);                    
                    obj.stage.setOledBrightness(OledBrightness.HIGH);
                case 'MEDIUM'
                    obj.setGamma(config.mediumGammaRamp);
                    obj.stage.setOledBrightness(OledBrightness.MEDIUM);
                case 'LOW'
                    obj.setGamma(config.lowGammaRamp);
                    obj.stage.setOledBrightness(OledBrightness.LOW);
                case 'MINIMUM'
                    obj.stage.setOledBrightness(OledBrightness.MIN);
            end
        end
        
        
        function setGamma(obj, ramp)
            ramp = round(ramp * (2^16-1));
            obj.stage.setMonitorGammaRamp(ramp, ramp, ramp);

            % Verify the gamma was set.
            [r, g, b] = obj.stage.getMonitorGammaRamp();
            if ~isequal(r, ramp) || ~isequal(g, ramp) || ~isequal(b, ramp)
                errordlg('Could not set the gamma ramp');
            end
        end
        
    end
    
end