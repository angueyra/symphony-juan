% Controls for an TI LightCrafter.

classdef LightCrafterControl < Module
    
    properties (Constant)
        displayName = 'LightCrafter Control'
    end
    
    properties
        rigConfigChanged    % Rig config changed event listener.
        controls            % Struct containing UI element handles.
        stage
    end
    
    methods
        
        function obj = LightCrafterControl(symphonyUI)
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
                obj.stage = LcrStageClient(rigConfig.stage);
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
                [auto, red, green, blue] = obj.stage.getLcrLedEnables();
            catch
                uicontrol(...
                    'Parent', obj.figureHandle,...
                    'Units', 'points', ...
                    'FontSize', 12,...
                    'HorizontalAlignment', 'left', ...
                    'Position', [8 20 200 18], ...
                    'String',  'Not an LCR server.',...
                    'Style', 'text');
                
                return;
            end
            
            if auto
                value = 1;
            elseif red
                value = 2;
            elseif green
                value = 3;
            elseif blue
                value = 4;
            else
                value = 5;
            end
            
            % LEDs popup menu.
            obj.controls.ledsPopup = uicontrol( ...
                'Parent', obj.figureHandle,...
                'Units', 'points', ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'Position', [10 10 110 20], ...
                'String', {'Auto', 'Red', 'Green', 'Blue', 'None'}, ...
                'Value', value, ...
                'Callback', @(src,evt)obj.chooseLeds(), ...
                'Style', 'popupmenu');
            
            % LEDs label.
            uicontrol(...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'Position', [10 30 60 18], ...
                'String',  'LEDs:',...
                'Style', 'text');
        end
        
        
        function chooseLeds(obj)
            % The user selected an LED from the popup menu.
            
            contents = get(obj.controls.ledsPopup, 'String');
            index = get(obj.controls.ledsPopup, 'Value');
            
            switch upper(contents{index})
                case 'AUTO'
                    obj.stage.setLcrLedEnables(1, 0, 0, 0);
                case 'RED'
                    obj.stage.setLcrLedEnables(0, 1, 0, 0);
                case 'GREEN'
                    obj.stage.setLcrLedEnables(0, 0, 1, 0);
                case 'BLUE'
                    obj.stage.setLcrLedEnables(0, 0, 0, 1);
                case 'NONE'
                    obj.stage.setLcrLedEnables(0, 0, 0, 0);
            end
        end
        
    end
    
end