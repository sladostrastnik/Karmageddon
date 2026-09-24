
--[[

    modified by Sladostrastnik

        [18/04/2026]:
            built in SaveManager and ThemeManager
            added visibility management for dividers

        [20/04/2026]:
            improved configuration for dividers
            fixed initial visibility for buttons
            added text changing for dividers
            added text alignment for slider bars

        [24/04/2026]:
            fixed resizing for groupboxes

        [07/05/2026]:
            added single value adding and removing for multi dropdowns

        [15/07/2026]:
            added tooltips for dropdown values

        [18/07/2026]:
            added icons system for dropdown values
        
    
]]--

local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(clonefunction) == "function" then
    local isfolder_copy, isfile_copy, listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    },

    LoadingIcon = {
        RobloxId = 97544096941083,
        Path = "Obsidian/assets/LoadingIcon.png",
        URL = BaseURL .. "assets/LoadingIcon.png",

        Id = nil,
    },

    CheckIcon = {
        RobloxId = 97682394690683,
        Path = "Obsidian/assets/CheckIcon.png",
        URL = BaseURL .. "assets/CheckIcon.png",

        Id = nil,
    },
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},
    Dialogues = {},
    ActiveLoading = nil,
    ActiveDialog = nil,

    Corners = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,
    CornerRadiusDropdown = false, -- Temporary

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        RedColor = Color3.fromRGB(255, 50, 50),
        DestructiveColor = Color3.fromRGB(220, 38, 38),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),
    },

    Registry = {},
    Scales = {},

    ImageManager = CustomImageManager,
}

Library.SaveManager = (function()
    local SaveManager = {} do
        SaveManager.Folder = "ObsidianLibSettings"
        SaveManager.SubFolder = ""
        SaveManager.Ignore = {}
        SaveManager.Library = Library
        SaveManager.Parser = {
            Toggle = {
                Save = function(idx, object)
                    return { type = "Toggle", idx = idx, value = object.Value }
                end,
                Load = function(idx, data)
                    local object = SaveManager.Library.Toggles[idx]
                    if object and object.Value ~= data.value then
                        object:SetValue(data.value)
                    end
                end,
            },
            Slider = {
                Save = function(idx, object)
                    return { type = "Slider", idx = idx, value = tostring(object.Value) }
                end,
                Load = function(idx, data)
                    local object = SaveManager.Library.Options[idx]
                    if object and object.Value ~= data.value then
                        object:SetValue(data.value)
                    end
                end,
            },
            Dropdown = {
                Save = function(idx, object)
                    return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
                end,
                Load = function(idx, data)
                    local object = SaveManager.Library.Options[idx]
                    if object and object.Value ~= data.value then
                        object:SetValue(data.value)
                    end
                end,
            },
            ColorPicker = {
                Save = function(idx, object)
                    return { type = "ColorPicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
                end,
                Load = function(idx, data)
                    if SaveManager.Library.Options[idx] then
                        SaveManager.Library.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                    end
                end,
            },
            KeyPicker = {
                Save = function(idx, object)
                    return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value, modifiers = object.Modifiers }
                end,
                Load = function(idx, data)
                    if SaveManager.Library.Options[idx] then
                        SaveManager.Library.Options[idx]:SetValue({ data.key, data.mode, data.modifiers })
                    end
                end,
            },
            Input = {
                Save = function(idx, object)
                    return { type = "Input", idx = idx, text = object.Value }
                end,
                Load = function(idx, data)
                    local object = SaveManager.Library.Options[idx]
                    if object and object.Value ~= data.text and type(data.text) == "string" then
                        SaveManager.Library.Options[idx]:SetValue(data.text)
                    end
                end,
            },
        }

        function SaveManager:IgnoreThemeSettings()
            self:SetIgnoreIndexes({
                "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "FontFace", -- themes
                "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", -- themes
            })
        end

        --// Folders \\--
        function SaveManager:CheckSubFolder(createFolder)
            if typeof(self.SubFolder) ~= "string" or self.SubFolder == "" then return false end

            if createFolder == true then
                if not isfolder(self.Folder .. "/settings/" .. self.SubFolder) then
                    makefolder(self.Folder .. "/settings/" .. self.SubFolder)
                end
            end

            return true
        end

        function SaveManager:GetPaths()
            local paths = {}

            local parts = self.Folder:split("/")
            for idx = 1, #parts do
                local path = table.concat(parts, "/", 1, idx)
                if not table.find(paths, path) then paths[#paths + 1] = path end
            end

            paths[#paths + 1] = self.Folder .. "/themes"
            paths[#paths + 1] = self.Folder .. "/settings"

            if self:CheckSubFolder(false) then
                local subFolder = self.Folder .. "/settings/" .. self.SubFolder
                parts = subFolder:split("/")

                for idx = 1, #parts do
                    local path = table.concat(parts, "/", 1, idx)
                    if not table.find(paths, path) then paths[#paths + 1] = path end
                end
            end

            return paths
        end

        function SaveManager:BuildFolderTree()
            local paths = self:GetPaths()

            for i = 1, #paths do
                local str = paths[i]
                if isfolder(str) then continue end

                makefolder(str)
            end
        end

        function SaveManager:CheckFolderTree()
            if isfolder(self.Folder) then return end
            SaveManager:BuildFolderTree()

            task.wait(0.1)
        end

        function SaveManager:SetIgnoreIndexes(list)
            for _, key in pairs(list) do
                self.Ignore[key] = true
            end
        end

        function SaveManager:SetFolder(folder)
            self.Folder = folder
            self:BuildFolderTree()
        end

        function SaveManager:SetSubFolder(folder)
            self.SubFolder = folder
            self:BuildFolderTree()
        end

        --// Save, Load, Delete, Refresh \\--
        function SaveManager:Save(name)
            if (not name) then
                return false, "no config file is selected"
            end
            SaveManager:CheckFolderTree()

            local fullPath = self.Folder .. "/settings/" .. name .. ".json"
            if SaveManager:CheckSubFolder(true) then
                fullPath = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
            end

            local data = {
                objects = {}
            }

            for idx, toggle in pairs(self.Library.Toggles) do
                if not toggle.Type then continue end
                if not self.Parser[toggle.Type] then continue end
                if self.Ignore[idx] then continue end

                table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
            end

            for idx, option in pairs(self.Library.Options) do
                if not option.Type then continue end
                if not self.Parser[option.Type] then continue end
                if self.Ignore[idx] then continue end

                table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
            end

            local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
            if not success then
                return false, "failed to encode data"
            end

            writefile(fullPath, encoded)
            return true
        end

        function SaveManager:Load(name)
            if (not name) then
                return false, "no config file is selected"
            end
            SaveManager:CheckFolderTree()

            local file = self.Folder .. "/settings/" .. name .. ".json"
            if SaveManager:CheckSubFolder(true) then
                file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
            end

            if not isfile(file) then return false, "invalid file" end

            local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
            if not success then return false, "decode error" end

            for _, option in pairs(decoded.objects) do
                if not option.type then continue end
                if not self.Parser[option.type] then continue end
                if self.Ignore[option.idx] then continue end

                task.spawn(self.Parser[option.type].Load, option.idx, option) -- task.spawn() so the config loading wont get stuck.
            end

            return true
        end

        function SaveManager:Delete(name)
            if (not name) then
                return false, "no config file is selected"
            end

            local file = self.Folder .. "/settings/" .. name .. ".json"
            if SaveManager:CheckSubFolder(true) then
                file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
            end

            if not isfile(file) then return false, "invalid file" end

            local success = pcall(delfile, file)
            if not success then return false, "delete file error" end

            return true
        end

        function SaveManager:RefreshConfigList()
            local success, data = pcall(function()
                SaveManager:CheckFolderTree()

                local list = {}
                local out = {}

                if SaveManager:CheckSubFolder(true) then
                    list = listfiles(self.Folder .. "/settings/" .. self.SubFolder)
                else
                    list = listfiles(self.Folder .. "/settings")
                end
                if typeof(list) ~= "table" then list = {} end

                for i = 1, #list do
                    local file = list[i]
                    if file:sub(-5) == ".json" then
                        -- i hate this but it has to be done ...

                        local pos = file:find(".json", 1, true)
                        local start = pos

                        local char = file:sub(pos, pos)
                        while char ~= "/" and char ~= "\\" and char ~= "" do
                            pos = pos - 1
                            char = file:sub(pos, pos)
                        end

                        if char == "/" or char == "\\" then
                            table.insert(out, file:sub(pos + 1, start - 1))
                        end
                    end
                end

                return out
            end)

            if (not success) then
                if self.Library then
                    self.Library:Notify("Failed to load config list: " .. tostring(data))
                else
                    warn("Failed to load config list: " .. tostring(data))
                end

                return {}
            end

            return data
        end

        --// Auto Load \\--
        function SaveManager:GetAutoloadConfig()
            SaveManager:CheckFolderTree()

            local autoLoadPath = self.Folder .. "/settings/autoload.txt"
            if SaveManager:CheckSubFolder(true) then
                autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
            end

            if isfile(autoLoadPath) then
                local successRead, name = pcall(readfile, autoLoadPath)
                if not successRead then
                    return "none"
                end

                name = tostring(name)
                return if name == "" then "none" else name
            end

            return "none"
        end

        function SaveManager:LoadAutoloadConfig()
            SaveManager:CheckFolderTree()

            local autoLoadPath = self.Folder .. "/settings/autoload.txt"
            if SaveManager:CheckSubFolder(true) then
                autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
            end

            if isfile(autoLoadPath) then
                local successRead, name = pcall(readfile, autoLoadPath)
                if not successRead then
                    self.Library:Notify("Failed to load autoload config: write file error")
                    return
                end

                local success, err = self:Load(name)
                if not success then
                    self.Library:Notify("Failed to load autoload config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Auto loaded config %q", name))
            end
        end

        function SaveManager:SaveAutoloadConfig(name)
            SaveManager:CheckFolderTree()

            local autoLoadPath = self.Folder .. "/settings/autoload.txt"
            if SaveManager:CheckSubFolder(true) then
                autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
            end

            local success = pcall(writefile, autoLoadPath, name)
            if not success then return false, "write file error" end

            return true, ""
        end

        function SaveManager:DeleteAutoLoadConfig()
            SaveManager:CheckFolderTree()

            local autoLoadPath = self.Folder .. "/settings/autoload.txt"
            if SaveManager:CheckSubFolder(true) then
                autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
            end

            local success = pcall(delfile, autoLoadPath)
            if not success then return false, "delete file error" end

            return true, ""
        end

        --// GUI \\--
        function SaveManager:BuildConfigSection(tab)
            assert(self.Library, "Must set SaveManager.Library")

            local section = tab:AddRightGroupbox("Configuration", "folder-cog")

            section:AddInput("SaveManager_ConfigName",    { Text = "Config name" })
            section:AddButton("Create config", function()
                local name = self.Library.Options.SaveManager_ConfigName.Value

                if name:gsub(" ", "") == "" then
                    self.Library:Notify("Invalid config name (empty)", 2)
                    return
                end

                local success, err = self:Save(name)
                if not success then
                    self.Library:Notify("Failed to create config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Created config %q", name))
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                self.Library.Options.SaveManager_ConfigList:SetValue(nil)
            end)

            section:AddDivider()

            section:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })
            section:AddButton("Load config", function()
                local name = self.Library.Options.SaveManager_ConfigList.Value

                local success, err = self:Load(name)
                if not success then
                    self.Library:Notify("Failed to load config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Loaded config %q", name))
            end)
            section:AddButton("Overwrite config", function()
                local name = self.Library.Options.SaveManager_ConfigList.Value

                local success, err = self:Save(name)
                if not success then
                    self.Library:Notify("Failed to overwrite config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Overwrote config %q", name))
            end)

            section:AddButton("Delete config", function()
                local name = self.Library.Options.SaveManager_ConfigList.Value

                local success, err = self:Delete(name)
                if not success then
                    self.Library:Notify("Failed to delete config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Deleted config %q", name))
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                self.Library.Options.SaveManager_ConfigList:SetValue(nil)
            end)

            section:AddButton("Refresh list", function()
                self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                self.Library.Options.SaveManager_ConfigList:SetValue(nil)
            end)

            section:AddButton("Set as autoload", function()
                local name = self.Library.Options.SaveManager_ConfigList.Value

                local success, err = self:SaveAutoloadConfig(name)
                if not success then
                    self.Library:Notify("Failed to set autoload config: " .. err)
                    return
                end

                self.Library:Notify(string.format("Set %q to auto load", name))
                self.AutoloadConfigLabel:SetText("Current autoload config: " .. name)
            end)
            section:AddButton("Reset autoload", function()
                local success, err = self:DeleteAutoLoadConfig()
                if not success then
                    self.Library:Notify("Failed to set autoload config: " .. err)
                    return
                end

                self.Library:Notify("Set autoload to none")
                self.AutoloadConfigLabel:SetText("Current autoload config: none")
            end)

            self.AutoloadConfigLabel = section:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)

            -- self:LoadAutoloadConfig()
            self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
        end

        SaveManager:BuildFolderTree()
    end

    return SaveManager
end)()
Library.ThemeManager = (function()
    local ThemeManager = {}
    do
        local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        ThemeManager.Folder = "ObsidianLibSettings"
        -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

        ThemeManager.Library = Library
        ThemeManager.AppliedToTab = false
        ThemeManager.BuiltInThemes = {
            ["Default"] = {
                1,
                { FontColor = "ffffff", MainColor = "191919", AccentColor = "7d55ff", BackgroundColor = "0f0f0f", OutlineColor = "282828" },
            },
            ["BBot"] = {
                2,
                { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" },
            },
            ["Fatality"] = {
                3,
                { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" },
            },
            ["Jester"] = {
                4,
                { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
            },
            ["Mint"] = {
                5,
                { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
            },
            ["Tokyo Night"] = {
                6,
                { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" },
            },
            ["Ubuntu"] = {
                7,
                { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" },
            },
            ["Quartz"] = {
                8,
                { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" },
            },
            ["Nord"] = {
                9,
                { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" },
            },
            ["Dracula"] = {
                10,
                { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" },
            },
            ["Monokai"] = {
                11,
                { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" },
            },
            ["Gruvbox"] = {
                12,
                { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" },
            },
            ["Solarized"] = {
                13,
                { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" },
            },
            ["Catppuccin"] = {
                14,
                { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" },
            },
            ["One Dark"] = {
                15,
                { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" },
            },
            ["Cyberpunk"] = {
                16,
                { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" },
            },
            ["Oceanic Next"] = {
                17,
                { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" },
            },
            ["Material"] = {
                18,
                { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" },
            },
        }

        --// Folders \\--
        function ThemeManager:GetPaths()
            local paths = {}

            local parts = self.Folder:split("/")
            for idx = 1, #parts do
                paths[#paths + 1] = table.concat(parts, "/", 1, idx)
            end

            paths[#paths + 1] = self.Folder .. "/themes"

            return paths
        end

        function ThemeManager:BuildFolderTree()
            local paths = self:GetPaths()

            for i = 1, #paths do
                local str = paths[i]
                if isfolder(str) then
                    continue
                end
                makefolder(str)
            end
        end

        function ThemeManager:CheckFolderTree()
            if isfolder(self.Folder) then
                return
            end
            self:BuildFolderTree()

            task.wait(0.1)
        end

        function ThemeManager:SetFolder(folder)
            self.Folder = folder
            self:BuildFolderTree()
        end

        --// Apply, Update theme \\--
        function ThemeManager:ApplyTheme(theme)
            local customThemeData = self:GetCustomTheme(theme)
            local data = customThemeData or self.BuiltInThemes[theme]

            if not data then
                return
            end

            local scheme = data[2]
            for idx, val in pairs(customThemeData or scheme) do
                if idx == "VideoLink" then
                    continue
                elseif idx == "FontFace" then
                    self.Library:SetFont(Enum.Font[val])

                    if self.Library.Options[idx] then
                        self.Library.Options[idx]:SetValue(val)
                    end
                else
                    self.Library.Scheme[idx] = Color3.fromHex(val)

                    if self.Library.Options[idx] then
                        self.Library.Options[idx]:SetValueRGB(Color3.fromHex(val))
                    end
                end
            end

            self:ThemeUpdate()
        end

        function ThemeManager:ThemeUpdate()
            for i, field in ThemeFields do
                if self.Library.Options and self.Library.Options[field] then
                    self.Library.Scheme[field] = self.Library.Options[field].Value
                end
            end

            self.Library:UpdateColorsUsingRegistry()
        end

        --// Get, Load, Save, Delete, Refresh \\--
        function ThemeManager:GetCustomTheme(file)
            local path = self.Folder .. "/themes/" .. file .. ".json"
            if not isfile(path) then
                return nil
            end

            local data = readfile(path)
            local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)

            if not success then
                return nil
            end

            return decoded
        end

        function ThemeManager:LoadDefault()
            local theme = "Default"
            local content = isfile(self.Folder .. "/themes/default.txt") and readfile(self.Folder .. "/themes/default.txt")

            local isDefault = true
            if content then
                if self.BuiltInThemes[content] then
                    theme = content
                elseif self:GetCustomTheme(content) then
                    theme = content
                    isDefault = false
                end
            elseif self.BuiltInThemes[self.DefaultTheme] then
                theme = self.DefaultTheme
            end

            if isDefault then
                self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
            else
                self:ApplyTheme(theme)
            end
        end

        function ThemeManager:SaveDefault(theme)
            writefile(self.Folder .. "/themes/default.txt", theme)
        end

        function ThemeManager:SetDefaultTheme(theme)
            assert(self.Library, "Must set ThemeManager.Library first!")
            assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

            local FinalTheme = {}
            local LibraryScheme = {}
            for _, field in ThemeFields do
                if typeof(theme[field]) == "Color3" then
                    FinalTheme[field] = "#" .. theme[field]:ToHex()
                    LibraryScheme[field] = theme[field]

                elseif typeof(theme[field]) == "string" then
                    FinalTheme[field] = if theme[field]:sub(1, 1) == "#" then theme[field] else ("#" .. theme[field])
                    LibraryScheme[field] = Color3.fromHex(theme[field])

                else
                    FinalTheme[field] = ThemeManager.BuiltInThemes["Default"][2][field]
                    LibraryScheme[field] = Color3.fromHex(ThemeManager.BuiltInThemes["Default"][2][field])
                end
            end

            if typeof(theme["FontFace"]) == "EnumItem" then
                FinalTheme["FontFace"] = theme["FontFace"].Name
                LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])

            elseif typeof(theme["FontFace"]) == "string" then
                FinalTheme["FontFace"] = theme["FontFace"]
                LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])

            else
                FinalTheme["FontFace"] = "Code"
                LibraryScheme["Font"] = Font.fromEnum(Enum.Font.Code)
            end

            for _, field in { "RedColor", "DarkColor", "WhiteColor" } do
                LibraryScheme[field] = self.Library.Scheme[field]
            end

            self.Library.Scheme = LibraryScheme
            self.BuiltInThemes["Default"] = { 1, FinalTheme }

            self.Library:UpdateColorsUsingRegistry()
        end

        function ThemeManager:SaveCustomTheme(file)
            if file:gsub(" ", "") == "" then
                self.Library:Notify("Invalid file name for theme (empty)", 3)
                return
            end

            local theme = {}
            for _, field in ThemeFields do
                theme[field] = self.Library.Options[field].Value:ToHex()
            end
            theme["FontFace"] = self.Library.Options["FontFace"].Value

            writefile(self.Folder .. "/themes/" .. file .. ".json", HttpService:JSONEncode(theme))
        end

        function ThemeManager:Delete(name)
            if not name then
                return false, "no config file is selected"
            end

            local file = self.Folder .. "/themes/" .. name .. ".json"
            if not isfile(file) then
                return false, "invalid file"
            end

            local success = pcall(delfile, file)
            if not success then
                return false, "delete file error"
            end

            return true
        end

        function ThemeManager:ReloadCustomThemes()
            local list = listfiles(self.Folder .. "/themes")

            local out = {}
            for i = 1, #list do
                local file = list[i]
                if file:sub(-5) == ".json" then
                    -- i hate this but it has to be done ...

                    local pos = file:find(".json", 1, true)
                    local start = pos

                    local char = file:sub(pos, pos)
                    while char ~= "/" and char ~= "\\" and char ~= "" do
                        pos = pos - 1
                        char = file:sub(pos, pos)
                    end

                    if char == "/" or char == "\\" then
                        table.insert(out, file:sub(pos + 1, start - 1))
                    end
                end
            end

            return out
        end

        --// GUI \\--
        function ThemeManager:CreateThemeManager(groupbox)
            groupbox
                :AddLabel("Background color")
                :AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
            groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
            groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
            groupbox
                :AddLabel("Outline color")
                :AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
            groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
            groupbox:AddDropdown("FontFace", {
                Text = "Font Face",
                Default = "Code",
                Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans" },
            })

            local ThemesArray = {}
            for Name, Theme in pairs(self.BuiltInThemes) do
                table.insert(ThemesArray, Name)
            end

            table.sort(ThemesArray, function(a, b)
                return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
            end)

            groupbox:AddDivider()

            groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })
            groupbox:AddButton("Set as default", function()
                self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
                self.Library:Notify(
                    string.format("Set default theme to %q", self.Library.Options.ThemeManager_ThemeList.Value)
                )
            end)

            self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
                self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
            end)

            groupbox:AddDivider()

            groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
            groupbox:AddButton("Create theme", function()
                local name = self.Library.Options.ThemeManager_CustomThemeName.Value

                if name:gsub(" ", "") == "" then
                    self.Library:Notify("Invalid theme name (empty)", 2)
                    return
                end

                self:SaveCustomTheme(name)

                self.Library:Notify(string.format("Created theme %q", name))
                self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
            end)

            groupbox:AddDivider()

            groupbox:AddDropdown(
                "ThemeManager_CustomThemeList",
                { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
            )
            groupbox:AddButton("Load theme", function()
                local name = self.Library.Options.ThemeManager_CustomThemeList.Value

                self:ApplyTheme(name)
                self.Library:Notify(string.format("Loaded theme %q", name))
            end)
            groupbox:AddButton("Overwrite theme", function()
                local name = self.Library.Options.ThemeManager_CustomThemeList.Value

                self:SaveCustomTheme(name)
                self.Library:Notify(string.format("Overwrote config %q", name))
            end)
            groupbox:AddButton("Delete theme", function()
                local name = self.Library.Options.ThemeManager_CustomThemeList.Value

                local success, err = self:Delete(name)
                if not success then
                    self.Library:Notify("Failed to delete theme: " .. err)
                    return
                end

                self.Library:Notify(string.format("Deleted theme %q", name))
                self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
            end)
            groupbox:AddButton("Refresh list", function()
                self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
            end)
            groupbox:AddButton("Set as default", function()
                if
                    self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil
                    and self.Library.Options.ThemeManager_CustomThemeList.Value ~= ""
                then
                    self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                    self.Library:Notify(
                        string.format("Set default theme to %q", self.Library.Options.ThemeManager_CustomThemeList.Value)
                    )
                end
            end)
            groupbox:AddButton("Reset default", function()
                local success = pcall(delfile, self.Folder .. "/themes/default.txt")
                if not success then
                    self.Library:Notify("Failed to reset default: delete file error")
                    return
                end

                self.Library:Notify("Set default theme to nothing")
                self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
            end)

            self:LoadDefault()
            self.AppliedToTab = true

            local function UpdateTheme()
                self:ThemeUpdate()
            end

            self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
            self.Library.Options.MainColor:OnChanged(UpdateTheme)
            self.Library.Options.AccentColor:OnChanged(UpdateTheme)
            self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
            self.Library.Options.FontColor:OnChanged(UpdateTheme)
            self.Library.Options.FontFace:OnChanged(function(Value)
                self.Library:SetFont(Enum.Font[Value])
                self.Library:UpdateColorsUsingRegistry()
            end)
        end

        function ThemeManager:CreateGroupBox(tab)
            assert(self.Library, "Must set ThemeManager.Library first!")
            return tab:AddLeftGroupbox("Themes", "paintbrush")
        end

        function ThemeManager:ApplyToTab(tab)
            assert(self.Library, "Must set ThemeManager.Library first!")
            local groupbox = self:CreateGroupBox(tab)
            self:CreateThemeManager(groupbox)
        end

        function ThemeManager:ApplyToGroupbox(groupbox)
            assert(self.Library, "Must set ThemeManager.Library first!")
            self:CreateThemeManager(groupbox)
        end

        ThemeManager:BuildFolderTree()
    end

    getgenv().ObsidianThemeManager = ThemeManager
    return ThemeManager
end)()

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = true,
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        
        ShowMobileButtons = true,
        MobileButtonsSide = "Left",

        UnlockMouseWhileOpen = true,

        EnableSidebarResize = false,
        EnableCompacting = true,
        DisableCompactingSnap = false,
        SidebarCompacted = false,
        MinContainerWidth = 256,

        --// Snapping \\--
        MinSidebarWidth = 128,
        SidebarCompactWidth = 48,
        SidebarCollapseThreshold = 0.5,

        --// Dragging \\--
        CompactWidthActivation = 128,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Loading = {
        Title = "mspaint",
        Icon = 95816097006870,
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = CustomImageManager.GetAsset("LoadingIcon"),
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        Tooltips = {},
        DisabledValues = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Scheme Functions \\--
local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

--// Basic Functions \\--
local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Number, Factor)
    local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then Result = Result + Factor end
    return tonumber(string.format("%.12g", Result)) or Result
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in Library.DependencyBoxes do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    --// Loop through Groupboxes to get Elements Info
    for _, Groupbox in Tab.Groupboxes do
        local VisibleElements = 0

        for _, ElementInfo in Groupbox.Elements do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            Groupbox:Resize()
            HasVisible = true
        end
        Groupbox.BoxHolder.Visible = VisibleElements > 0
    end

    for _, Tabbox in Tab.Tabboxes do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, SubTab in Tabbox.Tabs do
            VisibleElements[SubTab] = 0

            for _, ElementInfo in SubTab.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[SubTab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[SubTab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
            end
        end

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                if Tabbox.ActiveTab == SubTab then
                    SubTab:Resize()
                elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                    SubTab:Show()
                end
            end
        end

        --// Update Tabbox Visibility if any visible
        Tabbox.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible
end
local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Groupbox in Tab.Groupboxes do
        for _, ElementInfo in Groupbox.Elements do
            ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

            if ElementInfo.SubButton then
                ElementInfo.Base.Visible = ElementInfo.Visible
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            RestoreDepbox(Depbox)
        end

        Groupbox:Resize()
        Groupbox.BoxHolder.Visible = true
    end

    for _, Tabbox in Tab.Tabboxes do
        for _, SubTab in Tabbox.Tabs do
            for _, ElementInfo in SubTab.Elements do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            SubTab.ButtonHolder.Visible = true
        end

        if Tabbox.ActiveTab then
            Tabbox.ActiveTab:Resize()
        end
        Tabbox.BoxHolder.Visible = true
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in Library.Tabs do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab, Search)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Instance[Property] = SchemeValue or Index()
            end
        end
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

    for _, UIScale in Library.Scales do
        UIScale.Scale = Library.DPIScale
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string" and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

local IconsModule = (function()
    local Icons = {["48px"]={rewind={16898613699,{48,48},{563,967}},fuel={16898613353,{48,48},{196,967}},["square-arrow-out-up-right"]={16898613777,{48,48},{967,514}},["table-cells-split"]={16898613777,{48,48},{771,955}},gavel={16898613353,{48,48},{967,808}},["dna-off"]={16898613044,{48,48},{453,967}},["refresh-ccw-dot"]={16898613699,{48,48},{869,404}},bean={16898612629,{48,48},{967,906}},["arrow-up-right-from-circle"]={16898612629,{48,48},{563,967}},["table-columns-split"]={16898613777,{48,48},{967,808}},bolt={16898612819,{48,48},{306,820}},["square-asterisk"]={16898613777,{48,48},{710,771}},feather={16898613353,{48,48},{771,98}},["align-horizontal-distribute-center"]={16898612629,{48,48},{771,355}},["align-center"]={16898612629,{48,48},{0,869}},["grip-vertical"]={16898613509,{48,48},{0,869}},["person-standing"]={16898613699,{48,48},{563,771}},["badge-swiss-franc"]={16898612629,{48,48},{771,857}},["between-horizontal-end"]={16898612819,{48,48},{771,306}},["rotate-cw"]={16898613699,{48,48},{869,453}},framer={16898613353,{48,48},{661,967}},["bus-front"]={16898612819,{48,48},{869,612}},["shield-ellipsis"]={16898613777,{48,48},{771,306}},["file-lock-2"]={16898613353,{48,48},{257,918}},["between-vertical-end"]={16898612819,{48,48},{257,820}},["globe-lock"]={16898613509,{48,48},{820,514}},["toggle-left"]={16898613869,{48,48},{869,49}},["concierge-bell"]={16898613044,{48,48},{869,147}},video={16898613869,{48,48},{355,967}},["arrow-left-square"]={16898612629,{48,48},{196,820}},["file-down"]={16898613353,{48,48},{98,820}},["picture-in-picture"]={16898613699,{48,48},{257,869}},["messages-square"]={16898613613,{48,48},{306,869}},grab={16898613509,{48,48},{514,820}},["phone-call"]={16898613699,{48,48},{514,820}},["chevron-up-circle"]={16898612819,{48,48},{820,808}},["server-crash"]={16898613699,{48,48},{918,955}},["heading-3"]={16898613509,{48,48},{869,306}},squircle={16898613777,{48,48},{820,759}},["wifi-off"]={16898613869,{48,48},{918,759}},["sun-medium"]={16898613777,{48,48},{661,967}},ungroup={16898613869,{48,48},{257,967}},["cloud-download"]={16898613044,{48,48},{612,820}},["sigma-square"]={16898613777,{48,48},{869,514}},["folder-plus"]={16898613353,{48,48},{661,918}},["hard-drive-download"]={16898613509,{48,48},{918,0}},["scatter-chart"]={16898613699,{48,48},{196,967}},pointer={16898613699,{48,48},{661,771}},ligature={16898613509,{48,48},{612,967}},["chevrons-up-down"]={16898612819,{48,48},{918,759}},["iteration-cw"]={16898613509,{48,48},{869,147}},["rail-symbol"]={16898613699,{48,48},{967,514}},["square-stack"]={16898613777,{48,48},{453,869}},parentheses={16898613613,{48,48},{869,906}},["book-up-2"]={16898612819,{48,48},{306,869}},flame={16898613353,{48,48},{967,306}},["chevrons-up"]={16898612819,{48,48},{869,808}},["chevron-right-square"]={16898612819,{48,48},{918,710}},["square-mouse-pointer"]={16898613777,{48,48},{869,661}},superscript={16898613777,{48,48},{918,759}},signal={16898613777,{48,48},{918,0}},["file-warning"]={16898613353,{48,48},{967,514}},hexagon={16898613509,{48,48},{967,0}},["navigation-2-off"]={16898613613,{48,48},{918,612}},unlock={16898613869,{48,48},{771,710}},["arrows-up-from-line"]={16898612629,{48,48},{918,404}},["square-gantt-chart"]={16898613777,{48,48},{453,820}},["square-chevron-left"]={16898613777,{48,48},{967,49}},scaling={16898613699,{48,48},{967,661}},["inspection-panel"]={16898613509,{48,48},{563,918}},["arrow-left-from-line"]={16898612629,{48,48},{869,147}},ship={16898613777,{48,48},{771,98}},["ticket-percent"]={16898613869,{48,48},{257,869}},["arrow-right-square"]={16898612629,{48,48},{869,404}},["calendar-clock"]={16898612819,{48,48},{918,98}},x={16898613869,{48,48},{869,906}},voicemail={16898613869,{48,48},{869,710}},presentation={16898613699,{48,48},{771,196}},["tree-palm"]={16898613869,{48,48},{820,612}},popsicle={16898613699,{48,48},{563,869}},["captions-off"]={16898612819,{48,48},{661,869}},["align-vertical-justify-center"]={16898612629,{48,48},{49,869}},theater={16898613869,{48,48},{98,771}},tent={16898613869,{48,48},{49,771}},["repeat-1"]={16898613699,{48,48},{918,612}},stethoscope={16898613777,{48,48},{147,967}},["screen-share-off"]={16898613699,{48,48},{771,906}},["arrow-big-up"]={16898612629,{48,48},{918,306}},["volume-x"]={16898613869,{48,48},{710,869}},["mouse-pointer-click"]={16898613613,{48,48},{771,710}},["square-m"]={16898613777,{48,48},{306,967}},["hard-drive"]={16898613509,{48,48},{820,98}},["package-minus"]={16898613613,{48,48},{771,808}},cloud={16898613044,{48,48},{918,306}},["mouse-pointer-square-dashed"]={16898613613,{48,48},{710,771}},["flip-horizontal"]={16898613353,{48,48},{306,967}},["alert-circle"]={16898612629,{48,48},{869,0}},unplug={16898613869,{48,48},{710,771}},["badge-cent"]={16898612629,{48,48},{612,967}},["check-square-2"]={16898612819,{48,48},{820,759}},["monitor-check"]={16898613613,{48,48},{196,771}},trello={16898613869,{48,48},{612,820}},["paintbrush-2"]={16898613613,{48,48},{967,404}},["bar-chart-horizontal"]={16898612629,{48,48},{710,967}},["book-plus"]={16898612819,{48,48},{771,404}},torus={16898613869,{48,48},{147,771}},["panel-right-close"]={16898613613,{48,48},{453,967}},["heart-handshake"]={16898613509,{48,48},{869,563}},trees={16898613869,{48,48},{661,771}},ham={16898613509,{48,48},{355,771}},text={16898613869,{48,48},{771,98}},["nut-off"]={16898613613,{48,48},{98,967}},["bean-off"]={16898612629,{48,48},{869,955}},rat={16898613699,{48,48},{869,612}},["separator-horizontal"]={16898613699,{48,48},{918,906}},["square-arrow-up-right"]={16898613777,{48,48},{820,661}},["signal-zero"]={16898613777,{48,48},{514,869}},citrus={16898613044,{48,48},{306,820}},["phone-missed"]={16898613699,{48,48},{771,98}},["user-round-check"]={16898613869,{48,48},{869,404}},["battery-medium"]={16898612629,{48,48},{869,906}},["square-minus"]={16898613777,{48,48},{918,612}},hotel={16898613509,{48,48},{98,869}},["folder-output"]={16898613353,{48,48},{771,808}},["ice-cream"]={16898613509,{48,48},{869,355}},menu={16898613613,{48,48},{49,820}},["arrow-up-left-square"]={16898612629,{48,48},{710,820}},lightbulb={16898613509,{48,48},{918,196}},["badge-help"]={16898612629,{48,48},{147,967}},angry={16898612629,{48,48},{257,918}},outdent={16898613613,{48,48},{918,661}},["circle-dot-dashed"]={16898613044,{48,48},{771,514}},speech={16898613777,{48,48},{820,147}},["cake-slice"]={16898612819,{48,48},{661,820}},["git-graph"]={16898613509,{48,48},{0,771}},armchair={16898612629,{48,48},{820,147}},["qr-code"]={16898613699,{48,48},{967,257}},copy={16898613044,{48,48},{918,612}},goal={16898613509,{48,48},{563,771}},["trending-down"]={16898613869,{48,48},{563,869}},haze={16898613509,{48,48},{98,820}},nfc={16898613613,{48,48},{612,918}},["receipt-russian-ruble"]={16898613699,{48,48},{514,967}},disc={16898613044,{48,48},{661,967}},["notebook-tabs"]={16898613613,{48,48},{967,98}},["panels-left-bottom"]={16898613613,{48,48},{820,906}},videotape={16898613869,{48,48},{967,612}},["sun-moon"]={16898613777,{48,48},{967,196}},calendar={16898612819,{48,48},{355,918}},["minus-circle"]={16898613613,{48,48},{869,98}},sunset={16898613777,{48,48},{967,710}},["navigation-2"]={16898613613,{48,48},{869,661}},["message-square-heart"]={16898613613,{48,48},{771,147}},["rectangle-ellipsis"]={16898613699,{48,48},{820,196}},["badge-plus"]={16898612629,{48,48},{918,710}},["indian-rupee"]={16898613509,{48,48},{710,771}},["monitor-dot"]={16898613613,{48,48},{147,820}},delete={16898613044,{48,48},{661,918}},["clipboard-pen-line"]={16898613044,{48,48},{918,0}},["folder-search"]={16898613353,{48,48},{918,196}},["utensils-crossed"]={16898613869,{48,48},{918,147}},dices={16898613044,{48,48},{918,710}},reply={16898613699,{48,48},{612,918}},["flask-round"]={16898613353,{48,48},{404,869}},pause={16898613699,{48,48},{0,771}},shrub={16898613777,{48,48},{306,820}},flag={16898613353,{48,48},{98,918}},underline={16898613869,{48,48},{820,404}},["align-horizontal-distribute-end"]={16898612629,{48,48},{355,771}},newspaper={16898613613,{48,48},{661,869}},table={16898613777,{48,48},{820,955}},["move-vertical"]={16898613613,{48,48},{820,453}},["file-pen-line"]={16898613353,{48,48},{612,820}},["badge-russian-ruble"]={16898612629,{48,48},{820,808}},radius={16898613699,{48,48},{257,967}},["loader-2"]={16898613509,{48,48},{820,857}},pilcrow={16898613699,{48,48},{612,771}},["scan-face"]={16898613699,{48,48},{820,808}},spade={16898613777,{48,48},{514,918}},["book-user"]={16898612819,{48,48},{918,514}},["flip-vertical"]={16898613353,{48,48},{918,612}},["square-arrow-down"]={16898613777,{48,48},{453,771}},["circle-plus"]={16898613044,{48,48},{869,0}},view={16898613869,{48,48},{918,661}},cctv={16898612819,{48,48},{355,967}},["more-horizontal"]={16898613613,{48,48},{257,967}},["file-key-2"]={16898613353,{48,48},{404,771}},["pause-octagon"]={16898613699,{48,48},{771,0}},["circle-arrow-out-down-left"]={16898612819,{48,48},{771,955}},volume={16898613869,{48,48},{661,918}},facebook={16898613353,{48,48},{563,771}},["octagon-alert"]={16898613613,{48,48},{918,404}},["panel-bottom-dashed"]={16898613613,{48,48},{918,710}},["book-a"]={16898612819,{48,48},{820,563}},["align-end-vertical"]={16898612629,{48,48},{820,306}},["user-x-2"]={16898613869,{48,48},{771,759}},chrome={16898612819,{48,48},{820,857}},["receipt-japanese-yen"]={16898613699,{48,48},{612,869}},rabbit={16898613699,{48,48},{869,355}},["scissors-square"]={16898613699,{48,48},{869,808}},["check-square"]={16898612819,{48,48},{771,808}},["train-front-tunnel"]={16898613869,{48,48},{771,404}},["panel-left-dashed"]={16898613613,{48,48},{661,967}},fish={16898613353,{48,48},{869,147}},slack={16898613777,{48,48},{0,918}},sliders={16898613777,{48,48},{404,771}},["message-circle-warning"]={16898613613,{48,48},{771,612}},map={16898613613,{48,48},{306,771}},route={16898613699,{48,48},{404,918}},["arrow-up-left"]={16898612629,{48,48},{661,869}},award={16898612629,{48,48},{918,661}},["message-square-plus"]={16898613613,{48,48},{49,869}},["unfold-horizontal"]={16898613869,{48,48},{355,869}},["area-chart"]={16898612629,{48,48},{869,98}},["music-4"]={16898613613,{48,48},{306,967}},["shield-x"]={16898613777,{48,48},{514,820}},["plane-landing"]={16898613699,{48,48},{771,147}},["disc-3"]={16898613044,{48,48},{771,857}},["columns-4"]={16898613044,{48,48},{710,771}},["archive-x"]={16898612629,{48,48},{967,0}},["square-dashed-kanban"]={16898613777,{48,48},{98,918}},["users-2"]={16898613869,{48,48},{612,918}},["shield-off"]={16898613777,{48,48},{820,514}},compass={16898613044,{48,48},{514,967}},vegan={16898613869,{48,48},{967,355}},["message-circle-plus"]={16898613613,{48,48},{257,869}},["stop-circle"]={16898613777,{48,48},{453,918}},nut={16898613613,{48,48},{967,355}},search={16898613699,{48,48},{918,857}},files={16898613353,{48,48},{771,710}},["send-to-back"]={16898613699,{48,48},{820,955}},["alarm-clock"]={16898612629,{48,48},{257,820}},["shopping-basket"]={16898613777,{48,48},{0,869}},send={16898613699,{48,48},{967,857}},["chevron-left-square"]={16898612819,{48,48},{453,918}},["terminal-square"]={16898613869,{48,48},{0,820}},wifi={16898613869,{48,48},{869,808}},["skip-back"]={16898613777,{48,48},{147,771}},["wrap-text"]={16898613869,{48,48},{869,857}},["file-scan"]={16898613353,{48,48},{820,147}},["message-square-dashed"]={16898613613,{48,48},{918,0}},trophy={16898613869,{48,48},{820,147}},umbrella={16898613869,{48,48},{869,355}},touchpad={16898613869,{48,48},{49,869}},["clipboard-copy"]={16898613044,{48,48},{820,563}},pentagon={16898613699,{48,48},{771,306}},["arrow-up-from-line"]={16898612629,{48,48},{820,710}},["circle-chevron-up"]={16898613044,{48,48},{771,0}},worm={16898613869,{48,48},{918,808}},["lamp-desk"]={16898613509,{48,48},{355,918}},["circle-arrow-up"]={16898612819,{48,48},{967,857}},zap={16898613869,{48,48},{918,906}},boxes={16898612819,{48,48},{196,771}},["swiss-franc"]={16898613777,{48,48},{820,857}},["move-left"]={16898613613,{48,48},{98,918}},["chevron-up"]={16898612819,{48,48},{710,918}},instagram={16898613509,{48,48},{514,967}},["pen-tool"]={16898613699,{48,48},{820,0}},["pencil-ruler"]={16898613699,{48,48},{0,820}},["grid-2x2"]={16898613509,{48,48},{771,98}},["arrow-big-down-dash"]={16898612629,{48,48},{771,196}},["clipboard-edit"]={16898613044,{48,48},{771,612}},mic={16898613613,{48,48},{820,612}},["file-minus-2"]={16898613353,{48,48},{869,563}},gitlab={16898613509,{48,48},{820,257}},["rotate-3d"]={16898613699,{48,48},{147,918}},["spell-check"]={16898613777,{48,48},{196,771}},popcorn={16898613699,{48,48},{612,820}},blocks={16898612819,{48,48},{49,820}},["washing-machine"]={16898613869,{48,48},{918,710}},siren={16898613777,{48,48},{771,147}},["cloud-sun"]={16898613044,{48,48},{0,967}},circle={16898613044,{48,48},{771,355}},["shield-alert"]={16898613777,{48,48},{49,771}},rainbow={16898613699,{48,48},{918,563}},["separator-vertical"]={16898613699,{48,48},{869,955}},ampersands={16898612629,{48,48},{355,820}},["user-search"]={16898613869,{48,48},{918,612}},fence={16898613353,{48,48},{98,771}},["square-user-round"]={16898613777,{48,48},{355,967}},sunrise={16898613777,{48,48},{453,967}},strikethrough={16898613777,{48,48},{869,759}},["calendar-days"]={16898612819,{48,48},{869,147}},["dollar-sign"]={16898613044,{48,48},{820,857}},["message-square-quote"]={16898613613,{48,48},{0,918}},["list-minus"]={16898613509,{48,48},{820,808}},["cloud-hail"]={16898613044,{48,48},{967,0}},upload={16898613869,{48,48},{612,869}},["app-window-mac"]={16898612629,{48,48},{661,771}},ellipsis={16898613353,{48,48},{771,49}},["copy-check"]={16898613044,{48,48},{453,820}},history={16898613509,{48,48},{869,98}},satellite={16898613699,{48,48},{147,967}},["bookmark-plus"]={16898612819,{48,48},{612,820}},["folder-key"]={16898613353,{48,48},{355,967}},["lamp-ceiling"]={16898613509,{48,48},{404,869}},["circle-power"]={16898613044,{48,48},{820,49}},hourglass={16898613509,{48,48},{49,918}},keyboard={16898613509,{48,48},{453,820}},triangle={16898613869,{48,48},{869,98}},["layers-2"]={16898613509,{48,48},{196,869}},["battery-full"]={16898612629,{48,48},{967,808}},["user-minus"]={16898613869,{48,48},{49,967}},["x-octagon"]={16898613869,{48,48},{967,808}},["folder-tree"]={16898613353,{48,48},{967,404}},command={16898613044,{48,48},{563,918}},["badge-dollar-sign"]={16898612629,{48,48},{918,196}},["align-start-vertical"]={16898612629,{48,48},{820,98}},["chevrons-down"]={16898612819,{48,48},{967,196}},["bluetooth-off"]={16898612819,{48,48},{869,257}},cannabis={16898612819,{48,48},{710,820}},book={16898612819,{48,48},{820,612}},hammer={16898613509,{48,48},{306,820}},["circle-minus"]={16898613044,{48,48},{771,306}},["audio-waveform"]={16898612629,{48,48},{967,612}},["moon-star"]={16898613613,{48,48},{355,869}},["arrow-right"]={16898612629,{48,48},{453,820}},sparkle={16898613777,{48,48},{967,0}},wand={16898613869,{48,48},{404,967}},["calendar-minus-2"]={16898612819,{48,48},{147,869}},["copy-minus"]={16898613044,{48,48},{404,869}},["folder-input"]={16898613353,{48,48},{453,869}},["book-image"]={16898612819,{48,48},{771,147}},shirt={16898613777,{48,48},{98,771}},["server-off"]={16898613699,{48,48},{967,955}},["move-up"]={16898613613,{48,48},{869,404}},["plug-2"]={16898613699,{48,48},{869,306}},radio={16898613699,{48,48},{306,918}},brackets={16898612819,{48,48},{98,869}},["calendar-heart"]={16898612819,{48,48},{196,820}},["list-ordered"]={16898613509,{48,48},{710,918}},["mic-off"]={16898613613,{48,48},{918,514}},["arrow-big-left"]={16898612629,{48,48},{98,869}},["square-split-horizontal"]={16898613777,{48,48},{918,404}},["tree-deciduous"]={16898613869,{48,48},{869,563}},["sun-snow"]={16898613777,{48,48},{196,967}},["user-2"]={16898613869,{48,48},{514,967}},["help-circle"]={16898613509,{48,48},{563,869}},["clock-2"]={16898613044,{48,48},{771,404}},["calendar-fold"]={16898612819,{48,48},{820,196}},["fish-off"]={16898613353,{48,48},{967,49}},baby={16898612629,{48,48},{771,808}},leaf={16898613509,{48,48},{918,661}},["fold-vertical"]={16898613353,{48,48},{661,869}},hop={16898613509,{48,48},{196,771}},paperclip={16898613613,{48,48},{918,857}},cigarette={16898612819,{48,48},{967,759}},minus={16898613613,{48,48},{771,196}},["smile-plus"]={16898613777,{48,48},{918,514}},["chevron-right-circle"]={16898612819,{48,48},{967,661}},["star-off"]={16898613777,{48,48},{612,967}},["git-pull-request-closed"]={16898613509,{48,48},{771,514}},["badge-check"]={16898612629,{48,48},{967,147}},["test-tube-2"]={16898613869,{48,48},{771,306}},["kanban-square"]={16898613509,{48,48},{98,918}},["plug-zap"]={16898613699,{48,48},{771,404}},["heading-4"]={16898613509,{48,48},{820,355}},["git-pull-request-create"]={16898613509,{48,48},{820,0}},["replace-all"]={16898613699,{48,48},{771,759}},["receipt-swiss-franc"]={16898613699,{48,48},{967,49}},["square-dashed-bottom-code"]={16898613777,{48,48},{196,820}},["clock-7"]={16898613044,{48,48},{918,514}},["scan-text"]={16898613699,{48,48},{661,967}},["shower-head"]={16898613777,{48,48},{771,355}},["equal-not"]={16898613353,{48,48},{49,771}},["move-down"]={16898613613,{48,48},{196,820}},["ticket-slash"]={16898613869,{48,48},{820,563}},ruler={16898613699,{48,48},{710,869}},["circle-user-round"]={16898613044,{48,48},{0,869}},subscript={16898613777,{48,48},{820,808}},["alarm-minus"]={16898612629,{48,48},{820,514}},["layout-grid"]={16898613509,{48,48},{918,404}},cog={16898613044,{48,48},{918,563}},dog={16898613044,{48,48},{869,808}},swords={16898613777,{48,48},{967,759}},["panel-right-dashed"]={16898613613,{48,48},{967,710}},["ship-wheel"]={16898613777,{48,48},{820,49}},bot={16898612819,{48,48},{869,98}},["trash-2"]={16898613869,{48,48},{257,918}},["chevron-down-square"]={16898612819,{48,48},{918,196}},dot={16898613044,{48,48},{918,808}},["file-symlink"]={16898613353,{48,48},{967,257}},["clipboard-paste"]={16898613044,{48,48},{514,869}},plug={16898613699,{48,48},{404,771}},["book-heart"]={16898612819,{48,48},{820,98}},["circle-parking"]={16898613044,{48,48},{820,514}},["volume-1"]={16898613869,{48,48},{820,759}},["circle-chevron-right"]={16898612819,{48,48},{967,955}},speaker={16898613777,{48,48},{869,98}},timer={16898613869,{48,48},{918,0}},forward={16898613353,{48,48},{771,857}},["file-up"]={16898613353,{48,48},{453,771}},["between-vertical-start"]={16898612819,{48,48},{820,514}},database={16898613044,{48,48},{710,869}},["panel-right"]={16898613613,{48,48},{820,857}},["log-out"]={16898613509,{48,48},{820,955}},["git-branch-plus"]={16898613353,{48,48},{967,857}},["clipboard-minus"]={16898613044,{48,48},{563,820}},["file-text"]={16898613353,{48,48},{869,355}},["arrow-right-circle"]={16898612629,{48,48},{49,967}},["table-rows-split"]={16898613777,{48,48},{869,906}},watch={16898613869,{48,48},{869,759}},["cloud-upload"]={16898613044,{48,48},{967,257}},banknote={16898612629,{48,48},{453,967}},["folder-up"]={16898613353,{48,48},{918,453}},["list-checks"]={16898613509,{48,48},{404,967}},bug={16898612819,{48,48},{257,967}},["circle-chevron-left"]={16898612819,{48,48},{918,955}},["arrow-down"]={16898612629,{48,48},{967,49}},["arrow-up-down"]={16898612629,{48,48},{918,612}},["file-audio"]={16898613353,{48,48},{771,355}},["whole-word"]={16898613869,{48,48},{967,710}},monitor={16898613613,{48,48},{404,820}},["flag-off"]={16898613353,{48,48},{820,196}},["align-right"]={16898612629,{48,48},{918,0}},["circle-stop"]={16898613044,{48,48},{49,820}},infinity={16898613509,{48,48},{661,820}},["arrow-big-down"]={16898612629,{48,48},{196,771}},["circle-parking-off"]={16898613044,{48,48},{257,820}},["calendar-x-2"]={16898612819,{48,48},{453,820}},["user-plus"]={16898613869,{48,48},{918,355}},["move-diagonal-2"]={16898613613,{48,48},{967,49}},["gallery-horizontal-end"]={16898613353,{48,48},{967,710}},["panel-top-dashed"]={16898613613,{48,48},{710,967}},["tram-front"]={16898613869,{48,48},{306,869}},podcast={16898613699,{48,48},{820,612}},["image-minus"]={16898613509,{48,48},{771,453}},["flip-vertical-2"]={16898613353,{48,48},{967,563}},github={16898613509,{48,48},{0,820}},pocket={16898613699,{48,48},{869,563}},printer={16898613699,{48,48},{196,771}},["megaphone-off"]={16898613613,{48,48},{514,820}},["file-bar-chart-2"]={16898613353,{48,48},{869,514}},["arrow-big-right"]={16898612629,{48,48},{0,967}},replace={16898613699,{48,48},{710,820}},["toy-brick"]={16898613869,{48,48},{918,257}},["square-chevron-down"]={16898613777,{48,48},{514,967}},["dice-1"]={16898613044,{48,48},{147,967}},["scan-search"]={16898613699,{48,48},{710,918}},["sticky-note"]={16898613777,{48,48},{918,453}},["shield-check"]={16898613777,{48,48},{820,257}},["hand-metal"]={16898613509,{48,48},{771,612}},["x-circle"]={16898613869,{48,48},{771,955}},["spell-check-2"]={16898613777,{48,48},{771,196}},["minus-square"]={16898613613,{48,48},{820,147}},["box-select"]={16898612819,{48,48},{820,147}},sprout={16898613777,{48,48},{918,306}},waypoints={16898613869,{48,48},{771,857}},["ice-cream-cone"]={16898613509,{48,48},{918,306}},["text-quote"]={16898613869,{48,48},{514,820}},wind={16898613869,{48,48},{820,857}},["layout-panel-left"]={16898613509,{48,48},{453,869}},["circle-percent"]={16898613044,{48,48},{563,771}},["circle-arrow-out-down-right"]={16898612819,{48,48},{967,808}},["square-x"]={16898613777,{48,48},{918,661}},italic={16898613509,{48,48},{967,49}},["step-forward"]={16898613777,{48,48},{196,918}},["a-arrow-down"]={16898612629,{48,48},{771,0}},container={16898613044,{48,48},{967,306}},sticker={16898613777,{48,48},{967,404}},["parking-circle-off"]={16898613613,{48,48},{820,955}},import={16898613509,{48,48},{967,514}},vault={16898613869,{48,48},{98,967}},["square-terminal"]={16898613777,{48,48},{404,918}},["file-music"]={16898613353,{48,48},{771,661}},beef={16898612819,{48,48},{0,771}},["route-off"]={16898613699,{48,48},{453,869}},["timer-reset"]={16898613869,{48,48},{514,869}},["monitor-stop"]={16898613613,{48,48},{820,404}},smile={16898613777,{48,48},{869,563}},["signpost-big"]={16898613777,{48,48},{869,49}},["folder-lock"]={16898613353,{48,48},{967,612}},["square-percent"]={16898613777,{48,48},{661,869}},["navigation-off"]={16898613613,{48,48},{820,710}},["arrow-left"]={16898612629,{48,48},{98,918}},["car-taxi-front"]={16898612819,{48,48},{967,98}},laugh={16898613509,{48,48},{869,196}},["x-square"]={16898613869,{48,48},{918,857}},["step-back"]={16898613777,{48,48},{918,196}},equal={16898613353,{48,48},{0,820}},megaphone={16898613613,{48,48},{869,0}},["calendar-x"]={16898612819,{48,48},{404,869}},egg={16898613353,{48,48},{514,771}},["video-off"]={16898613869,{48,48},{404,918}},["japanese-yen"]={16898613509,{48,48},{820,196}},library={16898613509,{48,48},{710,869}},["file-terminal"]={16898613353,{48,48},{918,306}},quote={16898613699,{48,48},{918,306}},accessibility={16898612629,{48,48},{257,771}},["square-library"]={16898613777,{48,48},{355,918}},salad={16898613699,{48,48},{967,147}},["tally-2"]={16898613869,{48,48},{771,0}},sheet={16898613777,{48,48},{820,0}},["circle-check-big"]={16898612819,{48,48},{918,906}},["map-pinned"]={16898613613,{48,48},{771,306}},["corner-down-left"]={16898613044,{48,48},{771,759}},dribbble={16898613044,{48,48},{918,857}},["pilcrow-square"]={16898613699,{48,48},{771,612}},["lamp-wall-up"]={16898613509,{48,48},{918,612}},["book-dashed"]={16898612819,{48,48},{514,869}},["unfold-vertical"]={16898613869,{48,48},{306,918}},["tree-pine"]={16898613869,{48,48},{771,661}},["receipt-indian-rupee"]={16898613699,{48,48},{661,820}},["check-circle-2"]={16898612819,{48,48},{918,661}},["flask-conical"]={16898613353,{48,48},{453,820}},["package-search"]={16898613613,{48,48},{612,967}},columns={16898613044,{48,48},{661,820}},["folder-sync"]={16898613353,{48,48},{147,967}},fingerprint={16898613353,{48,48},{563,918}},["arrow-up-narrow-wide"]={16898612629,{48,48},{612,918}},frame={16898613353,{48,48},{710,918}},["clock-12"]={16898613044,{48,48},{820,355}},images={16898613509,{48,48},{257,967}},lollipop={16898613509,{48,48},{967,857}},["folder-root"]={16898613353,{48,48},{612,967}},["arrow-left-circle"]={16898612629,{48,48},{918,98}},["lamp-floor"]={16898613509,{48,48},{306,967}},image={16898613509,{48,48},{306,918}},["baggage-claim"]={16898612629,{48,48},{967,196}},bike={16898612819,{48,48},{771,563}},option={16898613613,{48,48},{355,967}},["scroll-text"]={16898613699,{48,48},{967,759}},["toggle-right"]={16898613869,{48,48},{820,98}},["ferris-wheel"]={16898613353,{48,48},{49,820}},["camera-off"]={16898612819,{48,48},{306,967}},["function-square"]={16898613353,{48,48},{453,967}},group={16898613509,{48,48},{820,306}},codesandbox={16898613044,{48,48},{257,967}},["message-circle-question"]={16898613613,{48,48},{869,514}},["tent-tree"]={16898613869,{48,48},{771,49}},["rectangle-horizontal"]={16898613699,{48,48},{196,820}},subtitles={16898613777,{48,48},{771,857}},mail={16898613613,{48,48},{820,0}},["brain-cog"]={16898612819,{48,48},{0,967}},["hand-platter"]={16898613509,{48,48},{612,771}},club={16898613044,{48,48},{771,453}},twitch={16898613869,{48,48},{49,918}},pipette={16898613699,{48,48},{869,49}},user={16898613869,{48,48},{661,869}},["align-vertical-space-around"]={16898612629,{48,48},{869,306}},["test-tubes"]={16898613869,{48,48},{820,514}},wheat={16898613869,{48,48},{453,967}},["axis-3d"]={16898612629,{48,48},{820,759}},folders={16898613353,{48,48},{967,661}},diff={16898613044,{48,48},{869,759}},puzzle={16898613699,{48,48},{49,918}},["package-2"]={16898613613,{48,48},{869,710}},indent={16898613509,{48,48},{771,710}},tangent={16898613869,{48,48},{771,514}},["power-circle"]={16898613699,{48,48},{967,0}},["badge-pound-sterling"]={16898612629,{48,48},{869,759}},["mail-minus"]={16898613509,{48,48},{967,955}},["circle-slash"]={16898613044,{48,48},{98,771}},["app-window"]={16898612629,{48,48},{612,820}},["move-down-right"]={16898613613,{48,48},{820,196}},["parking-square-off"]={16898613613,{48,48},{869,955}},["clipboard-pen"]={16898613044,{48,48},{869,49}},["notepad-text"]={16898613613,{48,48},{147,918}},["signal-low"]={16898613777,{48,48},{612,771}},home={16898613509,{48,48},{820,147}},list={16898613509,{48,48},{869,808}},plus={16898613699,{48,48},{257,918}},["square-arrow-right"]={16898613777,{48,48},{918,563}},["scissors-square-dashed-bottom"]={16898613699,{48,48},{918,759}},["remove-formatting"]={16898613699,{48,48},{967,563}},["bookmark-check"]={16898612819,{48,48},{771,661}},["send-horizontal"]={16898613699,{48,48},{869,906}},["chevrons-left-right"]={16898612819,{48,48},{196,967}},["folder-kanban"]={16898613353,{48,48},{404,918}},["a-arrow-up"]={16898612629,{48,48},{0,771}},["list-restart"]={16898613509,{48,48},{967,196}},["cloud-moon"]={16898613044,{48,48},{820,147}},["book-audio"]={16898612819,{48,48},{771,612}},["vibrate-off"]={16898613869,{48,48},{869,453}},["mail-check"]={16898613509,{48,48},{918,955}},["panel-top-inactive"]={16898613613,{48,48},{967,759}},["file-type-2"]={16898613353,{48,48},{820,404}},["file-code"]={16898613353,{48,48},{869,49}},donut={16898613044,{48,48},{771,906}},["list-todo"]={16898613509,{48,48},{967,453}},dna={16898613044,{48,48},{967,710}},["monitor-down"]={16898613613,{48,48},{98,869}},["cassette-tape"]={16898612819,{48,48},{918,404}},["battery-low"]={16898612629,{48,48},{918,857}},flashlight={16898613353,{48,48},{869,404}},wine={16898613869,{48,48},{710,967}},signpost={16898613777,{48,48},{820,98}},["creative-commons"]={16898613044,{48,48},{147,918}},["globe-2"]={16898613509,{48,48},{257,820}},landmark={16898613509,{48,48},{771,759}},["map-pin"]={16898613613,{48,48},{820,257}},["clipboard-x"]={16898613044,{48,48},{98,820}},loader={16898613509,{48,48},{710,967}},bold={16898612819,{48,48},{355,771}},["dice-2"]={16898613044,{48,48},{967,404}},["file-type"]={16898613353,{48,48},{771,453}},utensils={16898613869,{48,48},{869,196}},beer={16898612819,{48,48},{257,771}},["file-video-2"]={16898613353,{48,48},{404,820}},["chef-hat"]={16898612819,{48,48},{661,918}},rocket={16898613699,{48,48},{918,147}},bird={16898612819,{48,48},{869,0}},["file-x"]={16898613353,{48,48},{869,612}},["move-diagonal"]={16898613613,{48,48},{918,98}},["folder-minus"]={16898613353,{48,48},{918,661}},["door-closed"]={16898613044,{48,48},{710,967}},["bluetooth-connected"]={16898612819,{48,48},{0,869}},["layout-template"]={16898613509,{48,48},{355,967}},["air-vent"]={16898612629,{48,48},{820,0}},["rows-2"]={16898613699,{48,48},{967,612}},["pen-square"]={16898613699,{48,48},{514,771}},["panel-bottom-close"]={16898613613,{48,48},{967,661}},["hand-heart"]={16898613509,{48,48},{869,514}},["file-code-2"]={16898613353,{48,48},{918,0}},["arrow-down-wide-narrow"]={16898612629,{48,48},{563,918}},["clock-10"]={16898613044,{48,48},{918,257}},drumstick={16898613044,{48,48},{869,955}},["disc-2"]={16898613044,{48,48},{820,808}},["skip-forward"]={16898613777,{48,48},{98,820}},skull={16898613777,{48,48},{49,869}},["chevron-left"]={16898612819,{48,48},{404,967}},["split-square-vertical"]={16898613777,{48,48},{49,918}},snowflake={16898613777,{48,48},{771,661}},key={16898613509,{48,48},{869,404}},["clock-11"]={16898613044,{48,48},{869,306}},["sliders-horizontal"]={16898613777,{48,48},{820,355}},["ticket-plus"]={16898613869,{48,48},{869,514}},["square-dashed-bottom"]={16898613777,{48,48},{147,869}},["mic-vocal"]={16898613613,{48,48},{869,563}},["activity-square"]={16898612629,{48,48},{771,514}},["monitor-pause"]={16898613613,{48,48},{0,967}},["book-open-check"]={16898612819,{48,48},{918,257}},projector={16898613699,{48,48},{147,820}},["lasso-select"]={16898613509,{48,48},{967,98}},["folder-open-dot"]={16898613353,{48,48},{869,710}},["align-justify"]={16898612629,{48,48},{563,820}},["log-in"]={16898613509,{48,48},{869,906}},tag={16898613777,{48,48},{967,906}},bus={16898612819,{48,48},{820,661}},["locate-fixed"]={16898613509,{48,48},{967,759}},["bed-single"]={16898612629,{48,48},{967,955}},["dice-4"]={16898613044,{48,48},{453,918}},["file-spreadsheet"]={16898613353,{48,48},{49,918}},["sun-dim"]={16898613777,{48,48},{710,918}},["clipboard-list"]={16898613044,{48,48},{612,771}},gamepad={16898613353,{48,48},{967,759}},["contact-round"]={16898613044,{48,48},{98,918}},["align-horizontal-space-around"]={16898612629,{48,48},{771,612}},["music-2"]={16898613613,{48,48},{404,869}},["hard-hat"]={16898613509,{48,48},{771,147}},["file-badge"]={16898613353,{48,48},{257,869}},["battery-warning"]={16898612629,{48,48},{820,955}},rows={16898613699,{48,48},{820,759}},["arrow-down-from-line"]={16898612629,{48,48},{404,820}},["rows-4"]={16898613699,{48,48},{869,710}},biohazard={16898612819,{48,48},{514,820}},["book-up"]={16898612819,{48,48},{257,918}},["heading-6"]={16898613509,{48,48},{404,771}},["scale-3d"]={16898613699,{48,48},{453,918}},["chevron-down-circle"]={16898612819,{48,48},{967,147}},["mail-x"]={16898613613,{48,48},{514,771}},["square-dashed-mouse-pointer"]={16898613777,{48,48},{49,967}},["user-cog"]={16898613869,{48,48},{147,869}},["satellite-dish"]={16898613699,{48,48},{196,918}},["alarm-clock-minus"]={16898612629,{48,48},{820,257}},pizza={16898613699,{48,48},{820,98}},["pc-case"]={16898613699,{48,48},{257,771}},["move-down-left"]={16898613613,{48,48},{869,147}},school={16898613699,{48,48},{453,967}},orbit={16898613613,{48,48},{967,612}},["file-minus"]={16898613353,{48,48},{820,612}},["rotate-ccw"]={16898613699,{48,48},{967,355}},["align-horizontal-justify-center"]={16898612629,{48,48},{257,869}},["phone-incoming"]={16898613699,{48,48},{820,49}},antenna={16898612629,{48,48},{869,563}},["memory-stick"]={16898613613,{48,48},{771,98}},["scan-eye"]={16898613699,{48,48},{869,759}},["align-center-vertical"]={16898612629,{48,48},{49,820}},["square-check"]={16898613777,{48,48},{563,918}},["align-end-horizontal"]={16898612629,{48,48},{869,257}},["message-square-off"]={16898613613,{48,48},{98,820}},["folder-open"]={16898613353,{48,48},{820,759}},["contact-2"]={16898613044,{48,48},{147,869}},["parking-circle"]={16898613613,{48,48},{967,857}},["menu-square"]={16898613613,{48,48},{98,771}},["hand-coins"]={16898613509,{48,48},{257,869}},["message-circle-code"]={16898613613,{48,48},{869,257}},["arrow-up-wide-narrow"]={16898612629,{48,48},{147,918}},["copy-x"]={16898613044,{48,48},{967,563}},clock={16898613044,{48,48},{771,661}},["file-pen"]={16898613353,{48,48},{563,869}},["git-compare-arrows"]={16898613353,{48,48},{918,955}},["square-arrow-down-right"]={16898613777,{48,48},{771,453}},joystick={16898613509,{48,48},{196,820}},["align-vertical-space-between"]={16898612629,{48,48},{820,355}},["file-pie-chart"]={16898613353,{48,48},{514,918}},gem={16898613353,{48,48},{918,857}},["calendar-plus"]={16898612819,{48,48},{918,355}},["bell-electric"]={16898612819,{48,48},{514,771}},["arrow-down-z-a"]={16898612629,{48,48},{514,967}},bath={16898612629,{48,48},{820,906}},anvil={16898612629,{48,48},{820,612}},["unlink-2"]={16898613869,{48,48},{918,563}},["archive-restore"]={16898612629,{48,48},{514,918}},archive={16898612629,{48,48},{918,49}},["folder-check"]={16898613353,{48,48},{563,967}},["arrow-big-left-dash"]={16898612629,{48,48},{147,820}},["book-key"]={16898612819,{48,48},{147,771}},ribbon={16898613699,{48,48},{967,98}},["package-open"]={16898613613,{48,48},{710,869}},["arrow-down-0-1"]={16898612629,{48,48},{869,355}},["library-big"]={16898613509,{48,48},{820,759}},["file-json"]={16898613353,{48,48},{771,404}},["arrow-down-a-z"]={16898612629,{48,48},{771,453}},["arrow-down-left"]={16898612629,{48,48},{257,967}},["square-scissors"]={16898613777,{48,48},{147,918}},["move-up-left"]={16898613613,{48,48},{967,306}},["arrow-down-up"]={16898612629,{48,48},{612,869}},["folder-heart"]={16898613353,{48,48},{869,453}},["gauge-circle"]={16898613353,{48,48},{820,906}},percent={16898613699,{48,48},{771,563}},["arrow-up-1-0"]={16898612629,{48,48},{355,918}},["arrow-up-a-z"]={16898612629,{48,48},{306,967}},["circle-arrow-right"]={16898612819,{48,48},{820,955}},["panel-bottom-inactive"]={16898613613,{48,48},{869,759}},["arrow-up"]={16898612629,{48,48},{967,355}},asterisk={16898612629,{48,48},{869,453}},["gallery-vertical"]={16898613353,{48,48},{771,906}},["swatch-book"]={16898613777,{48,48},{869,808}},["receipt-cent"]={16898613699,{48,48},{771,710}},["audio-lines"]={16898612629,{48,48},{355,967}},["folder-archive"]={16898613353,{48,48},{612,918}},["folder-symlink"]={16898613353,{48,48},{196,918}},["columns-3"]={16898613044,{48,48},{771,710}},ban={16898612629,{48,48},{196,967}},["message-square-x"]={16898613613,{48,48},{404,771}},["paint-roller"]={16898613613,{48,48},{147,967}},["folder-search-2"]={16898613353,{48,48},{967,147}},fan={16898613353,{48,48},{869,0}},["badge-euro"]={16898612629,{48,48},{196,918}},["badge-info"]={16898612629,{48,48},{918,453}},["building-2"]={16898612819,{48,48},{967,514}},square={16898613777,{48,48},{869,710}},medal={16898613613,{48,48},{563,771}},cake={16898612819,{48,48},{612,869}},["cloud-rain"]={16898613044,{48,48},{147,820}},["maximize-2"]={16898613613,{48,48},{820,514}},shell={16898613777,{48,48},{771,49}},wrench={16898613869,{48,48},{820,906}},badge={16898612629,{48,48},{661,967}},codepen={16898613044,{48,48},{306,918}},["corner-right-down"]={16898613044,{48,48},{563,967}},["flag-triangle-right"]={16898613353,{48,48},{147,869}},network={16898613613,{48,48},{710,820}},["bar-chart-3"]={16898612629,{48,48},{918,759}},bell={16898612819,{48,48},{820,257}},["bar-chart"]={16898612629,{48,48},{967,759}},ratio={16898613699,{48,48},{820,661}},["square-chevron-up"]={16898613777,{48,48},{869,147}},["brick-wall"]={16898612819,{48,48},{918,306}},["user-check"]={16898613869,{48,48},{918,98}},proportions={16898613699,{48,48},{98,869}},["alert-octagon"]={16898612629,{48,48},{820,49}},plane={16898613699,{48,48},{98,820}},["webhook-off"]={16898613869,{48,48},{661,967}},["thermometer-sun"]={16898613869,{48,48},{0,869}},["square-arrow-left"]={16898613777,{48,48},{404,820}},["mouse-pointer"]={16898613613,{48,48},{612,869}},heart={16898613509,{48,48},{661,771}},["test-tube-diagonal"]={16898613869,{48,48},{306,771}},["briefcase-medical"]={16898612819,{48,48},{820,404}},["align-vertical-distribute-start"]={16898612629,{48,48},{98,820}},mailbox={16898613613,{48,48},{771,49}},["bell-off"]={16898612819,{48,48},{771,49}},binary={16898612819,{48,48},{563,771}},["book-open-text"]={16898612819,{48,48},{869,306}},split={16898613777,{48,48},{0,967}},twitter={16898613869,{48,48},{0,967}},calculator={16898612819,{48,48},{563,918}},forklift={16898613353,{48,48},{869,759}},bluetooth={16898612819,{48,48},{771,355}},folder={16898613353,{48,48},{404,967}},["square-kanban"]={16898613777,{48,48},{404,869}},["message-square-diff"]={16898613613,{48,48},{869,49}},["square-sigma"]={16898613777,{48,48},{98,967}},["alarm-plus"]={16898612629,{48,48},{771,563}},star={16898613777,{48,48},{967,147}},["rotate-ccw-square"]={16898613699,{48,48},{98,967}},castle={16898612819,{48,48},{453,869}},["book-down"]={16898612819,{48,48},{918,0}},["file-volume-2"]={16898613353,{48,48},{306,918}},["book-headphones"]={16898612819,{48,48},{869,49}},power={16898613699,{48,48},{820,147}},album={16898612629,{48,48},{514,820}},["book-marked"]={16898612819,{48,48},{49,869}},["book-open"]={16898612819,{48,48},{820,355}},["file-box"]={16898613353,{48,48},{771,612}},["book-text"]={16898612819,{48,48},{404,771}},telescope={16898613869,{48,48},{820,0}},["glass-water"]={16898613509,{48,48},{771,306}},filter={16898613353,{48,48},{612,869}},glasses={16898613509,{48,48},{306,771}},["piggy-bank"]={16898613699,{48,48},{820,563}},["book-type"]={16898612819,{48,48},{355,820}},cuboid={16898613044,{48,48},{355,967}},["cloud-off"]={16898613044,{48,48},{771,196}},["check-check"]={16898612819,{48,48},{967,612}},activity={16898612629,{48,48},{514,771}},axe={16898612629,{48,48},{869,710}},["plane-takeoff"]={16898613699,{48,48},{147,771}},["book-x"]={16898612819,{48,48},{869,563}},["cloud-rain-wind"]={16898613044,{48,48},{196,771}},bookmark={16898612819,{48,48},{514,918}},["zoom-in"]={16898613869,{48,48},{869,955}},["square-pilcrow"]={16898613777,{48,48},{563,967}},["file-axis-3d"]={16898613353,{48,48},{355,771}},["receipt-euro"]={16898613699,{48,48},{710,771}},["brain-circuit"]={16898612819,{48,48},{49,918}},["briefcase-business"]={16898612819,{48,48},{869,355}},["bug-play"]={16898612819,{48,48},{306,918}},["tally-3"]={16898613869,{48,48},{0,771}},["clipboard-type"]={16898613044,{48,48},{147,771}},brush={16898612819,{48,48},{404,820}},["tally-5"]={16898613869,{48,48},{257,771}},["cable-car"]={16898612819,{48,48},{771,710}},cable={16898612819,{48,48},{710,771}},["calendar-check"]={16898612819,{48,48},{967,49}},["user-square-2"]={16898613869,{48,48},{869,661}},["calendar-minus"]={16898612819,{48,48},{98,918}},["calendar-plus-2"]={16898612819,{48,48},{967,306}},linkedin={16898613509,{48,48},{453,918}},["life-buoy"]={16898613509,{48,48},{661,918}},["calendar-search"]={16898612819,{48,48},{820,453}},["circle-chevron-down"]={16898612819,{48,48},{967,906}},["volume-2"]={16898613869,{48,48},{771,808}},["battery-charging"]={16898612629,{48,48},{771,955}},["russian-ruble"]={16898613699,{48,48},{661,918}},["square-arrow-up-left"]={16898613777,{48,48},{869,612}},["earth-lock"]={16898613353,{48,48},{771,0}},footprints={16898613353,{48,48},{918,710}},hash={16898613509,{48,48},{147,771}},building={16898612819,{48,48},{918,563}},ear={16898613044,{48,48},{967,955}},caravan={16898612819,{48,48},{869,196}},carrot={16898612819,{48,48},{196,869}},cherry={16898612819,{48,48},{612,967}},["user-check-2"]={16898613869,{48,48},{967,49}},["shield-plus"]={16898613777,{48,48},{771,563}},moon={16898613613,{48,48},{306,918}},["bell-minus"]={16898612819,{48,48},{820,0}},["image-up"]={16898613509,{48,48},{355,869}},["case-sensitive"]={16898612819,{48,48},{98,967}},drum={16898613044,{48,48},{918,906}},["arrow-up-z-a"]={16898612629,{48,48},{98,967}},sun={16898613777,{48,48},{967,453}},["gantt-chart-square"]={16898613353,{48,48},{918,808}},["align-horizontal-justify-start"]={16898612629,{48,48},{820,563}},["file-key"]={16898613353,{48,48},{355,820}},["monitor-smartphone"]={16898613613,{48,48},{918,306}},["move-3d"]={16898613613,{48,48},{514,967}},["scissors-line-dashed"]={16898613699,{48,48},{967,710}},["text-select"]={16898613869,{48,48},{820,49}},["case-lower"]={16898612819,{48,48},{147,918}},["plus-circle"]={16898613699,{48,48},{355,820}},["ticket-check"]={16898613869,{48,48},{355,771}},pyramid={16898613699,{48,48},{0,967}},["chevron-last"]={16898612819,{48,48},{967,404}},["user-cog-2"]={16898613869,{48,48},{196,820}},["refresh-cw-off"]={16898613699,{48,48},{453,820}},piano={16898613699,{48,48},{771,355}},["picture-in-picture-2"]={16898613699,{48,48},{306,820}},["user-round"]={16898613869,{48,48},{967,563}},["flower-2"]={16898613353,{48,48},{869,661}},["chevron-up-square"]={16898612819,{48,48},{771,857}},["chevrons-left"]={16898612819,{48,48},{967,453}},["chevrons-right-left"]={16898612819,{48,48},{453,967}},car={16898612819,{48,48},{918,147}},["keyboard-music"]={16898613509,{48,48},{820,453}},["star-half"]={16898613777,{48,48},{661,918}},mouse={16898613613,{48,48},{563,918}},lock={16898613509,{48,48},{918,857}},["pencil-line"]={16898613699,{48,48},{49,771}},mails={16898613613,{48,48},{49,771}},film={16898613353,{48,48},{710,771}},tablet={16898613777,{48,48},{918,906}},["circle-arrow-left"]={16898612819,{48,48},{820,906}},pi={16898613699,{48,48},{820,306}},trash={16898613869,{48,48},{918,514}},dock={16898613044,{48,48},{918,759}},["hdmi-port"]={16898613509,{48,48},{49,869}},["circle-arrow-out-up-left"]={16898612819,{48,48},{918,857}},["case-upper"]={16898612819,{48,48},{967,355}},["circle-arrow-out-up-right"]={16898612819,{48,48},{869,906}},tags={16898613777,{48,48},{918,955}},croissant={16898613044,{48,48},{967,355}},["circle-check"]={16898612819,{48,48},{869,955}},bomb={16898612819,{48,48},{257,869}},diameter={16898613044,{48,48},{967,147}},["circle-dashed"]={16898613044,{48,48},{0,771}},["bar-chart-big"]={16898612629,{48,48},{820,857}},["upload-cloud"]={16898613869,{48,48},{661,820}},["code-xml"]={16898613044,{48,48},{404,820}},divide={16898613044,{48,48},{967,453}},grape={16898613509,{48,48},{820,49}},["play-square"]={16898613699,{48,48},{0,918}},["party-popper"]={16898613613,{48,48},{918,955}},["circle-ellipsis"]={16898613044,{48,48},{820,0}},file={16898613353,{48,48},{820,661}},["user-circle-2"]={16898613869,{48,48},{869,147}},truck={16898613869,{48,48},{771,196}},["cloud-sun-rain"]={16898613044,{48,48},{49,918}},["calendar-range"]={16898612819,{48,48},{869,404}},contact={16898613044,{48,48},{49,967}},["zap-off"]={16898613869,{48,48},{967,857}},["square-check-big"]={16898613777,{48,48},{612,869}},["circle-user"]={16898613044,{48,48},{869,257}},["layout-panel-top"]={16898613509,{48,48},{404,918}},["roller-coaster"]={16898613699,{48,48},{196,869}},["laptop-minimal"]={16898613509,{48,48},{612,918}},["table-properties"]={16898613777,{48,48},{918,857}},["clipboard-check"]={16898613044,{48,48},{869,514}},layout={16898613509,{48,48},{967,612}},["indent-decrease"]={16898613509,{48,48},{869,612}},cookie={16898613044,{48,48},{869,404}},["message-square-more"]={16898613613,{48,48},{147,771}},clipboard={16898613044,{48,48},{49,869}},euro={16898613353,{48,48},{771,306}},sparkles={16898613777,{48,48},{918,49}},["heart-off"]={16898613509,{48,48},{820,612}},vibrate={16898613869,{48,48},{453,869}},["clock-3"]={16898613044,{48,48},{404,771}},["move-horizontal"]={16898613613,{48,48},{147,869}},["file-sliders"]={16898613353,{48,48},{98,869}},frown={16898613353,{48,48},{967,196}},["move-up-right"]={16898613613,{48,48},{918,355}},["cup-soda"]={16898613044,{48,48},{967,612}},["stretch-vertical"]={16898613777,{48,48},{918,710}},["refresh-cw"]={16898613699,{48,48},{404,869}},sword={16898613777,{48,48},{710,967}},["cloud-drizzle"]={16898613044,{48,48},{563,869}},["laptop-2"]={16898613509,{48,48},{661,869}},earth={16898613353,{48,48},{0,771}},slice={16898613777,{48,48},{869,306}},["land-plot"]={16898613509,{48,48},{820,710}},milk={16898613613,{48,48},{514,918}},["git-pull-request-draft"]={16898613509,{48,48},{771,49}},crown={16898613044,{48,48},{404,918}},["wallet-2"]={16898613869,{48,48},{967,147}},settings={16898613777,{48,48},{771,257}},["rotate-cw-square"]={16898613699,{48,48},{918,404}},atom={16898612629,{48,48},{404,918}},["package-x"]={16898613613,{48,48},{967,147}},["bed-double"]={16898612629,{48,48},{918,955}},["ice-cream-bowl"]={16898613509,{48,48},{967,257}},["circle-dot"]={16898613044,{48,48},{514,771}},["grip-horizontal"]={16898613509,{48,48},{49,820}},cloudy={16898613044,{48,48},{869,355}},["text-cursor-input"]={16898613869,{48,48},{771,563}},["folder-git-2"]={16898613353,{48,48},{967,355}},["message-square-code"]={16898613613,{48,48},{514,869}},clover={16898613044,{48,48},{820,404}},["arrow-down-narrow-wide"]={16898612629,{48,48},{967,514}},code={16898613044,{48,48},{355,869}},["user-x"]={16898613869,{48,48},{710,820}},coins={16898613044,{48,48},{869,612}},dumbbell={16898613044,{48,48},{967,906}},weight={16898613869,{48,48},{196,967}},["alert-triangle"]={16898612629,{48,48},{771,98}},expand={16898613353,{48,48},{306,771}},scale={16898613699,{48,48},{404,967}},component={16898613044,{48,48},{967,49}},["flashlight-off"]={16898613353,{48,48},{918,355}},["panel-top-open"]={16898613613,{48,48},{918,808}},computer={16898613044,{48,48},{918,98}},construction={16898613044,{48,48},{196,820}},notebook={16898613613,{48,48},{869,196}},["power-square"]={16898613699,{48,48},{869,98}},["copy-slash"]={16898613044,{48,48},{306,967}},["square-menu"]={16898613777,{48,48},{967,563}},["circle-play"]={16898613044,{48,48},{514,820}},wallet={16898613869,{48,48},{147,967}},laptop={16898613509,{48,48},{563,967}},["scan-line"]={16898613699,{48,48},{771,857}},["clock-4"]={16898613044,{48,48},{355,820}},["square-arrow-up"]={16898613777,{48,48},{771,710}},copyright={16898613044,{48,48},{820,710}},["chevron-down"]={16898612819,{48,48},{196,918}},["unlock-keyhole"]={16898613869,{48,48},{820,661}},["clock-1"]={16898613044,{48,48},{0,918}},["align-horizontal-distribute-start"]={16898612629,{48,48},{306,820}},["arrow-down-to-line"]={16898612629,{48,48},{661,820}},["mouse-pointer-2"]={16898613613,{48,48},{820,661}},["refresh-ccw"]={16898613699,{48,48},{820,453}},["venetian-mask"]={16898613869,{48,48},{918,404}},["calendar-check-2"]={16898612819,{48,48},{514,967}},["arrow-down-square"]={16898612629,{48,48},{771,710}},spline={16898613777,{48,48},{147,820}},banana={16898612629,{48,48},{967,453}},["git-pull-request-create-arrow"]={16898613509,{48,48},{514,771}},crosshair={16898613044,{48,48},{453,869}},["list-video"]={16898613509,{48,48},{967,710}},["arrow-right-left"]={16898612629,{48,48},{918,355}},["bar-chart-4"]={16898612629,{48,48},{869,808}},["dice-3"]={16898613044,{48,48},{918,453}},["dice-5"]={16898613044,{48,48},{404,967}},["dice-6"]={16898613044,{48,48},{967,661}},["square-plus"]={16898613777,{48,48},{918,147}},["timer-off"]={16898613869,{48,48},{563,820}},["arrow-big-right-dash"]={16898612629,{48,48},{49,918}},["radio-receiver"]={16898613699,{48,48},{404,820}},shield={16898613777,{48,48},{869,0}},["square-equal"]={16898613777,{48,48},{869,404}},backpack={16898612629,{48,48},{710,869}},download={16898613044,{48,48},{820,906}},["drafting-compass"]={16898613044,{48,48},{771,955}},youtube={16898613869,{48,48},{820,955}},["file-plus-2"]={16898613353,{48,48},{967,0}},["message-circle-more"]={16898613613,{48,48},{355,771}},["arrow-down-right"]={16898612629,{48,48},{820,661}},["loader-circle"]={16898613509,{48,48},{771,906}},receipt={16898613699,{48,48},{869,147}},["egg-off"]={16898613353,{48,48},{771,514}},bitcoin={16898612819,{48,48},{820,49}},["eye-off"]={16898613353,{48,48},{820,514}},factory={16898613353,{48,48},{514,820}},["fast-forward"]={16898613353,{48,48},{820,49}},["image-off"]={16898613509,{48,48},{453,771}},["file-audio-2"]={16898613353,{48,48},{820,306}},braces={16898612819,{48,48},{147,820}},cone={16898613044,{48,48},{820,196}},["wand-sparkles"]={16898613869,{48,48},{453,918}},["square-chevron-right"]={16898613777,{48,48},{918,98}},navigation={16898613613,{48,48},{771,759}},["file-check"]={16898613353,{48,48},{563,820}},["file-cog"]={16898613353,{48,48},{820,98}},["file-diff"]={16898613353,{48,48},{771,147}},["file-digit"]={16898613353,{48,48},{147,771}},["power-off"]={16898613699,{48,48},{918,49}},["align-vertical-distribute-center"]={16898612629,{48,48},{771,147}},["tally-1"]={16898613777,{48,48},{967,955}},ampersand={16898612629,{48,48},{404,771}},["line-chart"]={16898613509,{48,48},{196,918}},["shopping-cart"]={16898613777,{48,48},{869,257}},["align-vertical-justify-end"]={16898612629,{48,48},{0,918}},eraser={16898613353,{48,48},{820,257}},["alarm-smoke"]={16898612629,{48,48},{563,771}},["file-line-chart"]={16898613353,{48,48},{306,869}},["file-input"]={16898613353,{48,48},{869,306}},["clock-8"]={16898613044,{48,48},{869,563}},["server-cog"]={16898613699,{48,48},{967,906}},["cloud-cog"]={16898613044,{48,48},{661,771}},blend={16898612819,{48,48},{771,98}},["search-x"]={16898613699,{48,48},{967,808}},["radio-tower"]={16898613699,{48,48},{355,869}},["list-tree"]={16898613509,{48,48},{453,967}},droplet={16898613044,{48,48},{820,955}},heater={16898613509,{48,48},{612,820}},eye={16898613353,{48,48},{771,563}},battery={16898612629,{48,48},{967,857}},lamp={16898613509,{48,48},{869,661}},["link-2-off"]={16898613509,{48,48},{147,967}},["panel-top"]={16898613613,{48,48},{869,857}},["file-volume"]={16898613353,{48,48},{257,967}},["file-x-2"]={16898613353,{48,48},{918,563}},["circle-equal"]={16898613044,{48,48},{771,49}},["flag-triangle-left"]={16898613353,{48,48},{196,820}},flower={16898613353,{48,48},{820,710}},["fold-horizontal"]={16898613353,{48,48},{710,820}},["folder-closed"]={16898613353,{48,48},{918,147}},["folder-dot"]={16898613353,{48,48},{196,869}},["arrow-up-right"]={16898612629,{48,48},{918,147}},router={16898613699,{48,48},{355,967}},["leafy-green"]={16898613509,{48,48},{869,710}},["message-square-dot"]={16898613613,{48,48},{820,98}},focus={16898613353,{48,48},{771,759}},copyleft={16898613044,{48,48},{869,661}},["folder-x"]={16898613353,{48,48},{453,918}},["form-input"]={16898613353,{48,48},{820,808}},["minimize-2"]={16898613613,{48,48},{967,0}},regex={16898613699,{48,48},{306,967}},["gallery-horizontal"]={16898613353,{48,48},{918,759}},university={16898613869,{48,48},{967,514}},["gallery-vertical-end"]={16898613353,{48,48},{820,857}},["file-image"]={16898613353,{48,48},{918,257}},["at-sign"]={16898612629,{48,48},{453,869}},palette={16898613613,{48,48},{453,918}},["user-plus-2"]={16898613869,{48,48},{967,306}},["gallery-thumbnails"]={16898613353,{48,48},{869,808}},["arrow-down-right-from-circle"]={16898612629,{48,48},{918,563}},cpu={16898613044,{48,48},{196,869}},["split-square-horizontal"]={16898613777,{48,48},{98,869}},["thumbs-down"]={16898613869,{48,48},{820,306}},merge={16898613613,{48,48},{0,869}},ghost={16898613353,{48,48},{869,906}},["git-compare"]={16898613353,{48,48},{967,955}},["git-fork"]={16898613509,{48,48},{771,0}},hospital={16898613509,{48,48},{147,820}},["git-merge"]={16898613509,{48,48},{771,257}},["folder-edit"]={16898613353,{48,48},{98,967}},["thumbs-up"]={16898613869,{48,48},{771,355}},globe={16898613509,{48,48},{771,563}},palmtree={16898613613,{48,48},{404,967}},["bug-off"]={16898612819,{48,48},{355,869}},kanban={16898613509,{48,48},{49,967}},["thermometer-snowflake"]={16898613869,{48,48},{49,820}},apple={16898612629,{48,48},{563,869}},["wine-off"]={16898613869,{48,48},{771,906}},["graduation-cap"]={16898613509,{48,48},{869,0}},["hand-helping"]={16898613509,{48,48},{820,563}},hand={16898613509,{48,48},{563,820}},["square-bottom-dashed-scissors"]={16898613777,{48,48},{661,820}},stamp={16898613777,{48,48},{710,869}},["candy-off"]={16898612819,{48,48},{820,710}},["plug-zap-2"]={16898613699,{48,48},{820,355}},["heading-2"]={16898613509,{48,48},{918,257}},["square-activity"]={16898613777,{48,48},{869,355}},["circle-gauge"]={16898613044,{48,48},{0,820}},["cigarette-off"]={16898612819,{48,48},{710,967}},["arrow-up-0-1"]={16898612629,{48,48},{404,869}},["message-circle"]={16898613613,{48,48},{563,820}},["undo-2"]={16898613869,{48,48},{771,453}},headset={16898613509,{48,48},{257,918}},["heart-crack"]={16898613509,{48,48},{918,514}},["git-branch"]={16898613353,{48,48},{918,906}},shovel={16898613777,{48,48},{820,306}},share={16898613777,{48,48},{514,771}},["wallet-cards"]={16898613869,{48,48},{918,196}},["square-arrow-out-down-right"]={16898613777,{48,48},{306,918}},grip={16898613509,{48,48},{869,257}},["monitor-speaker"]={16898613613,{48,48},{869,355}},save={16898613699,{48,48},{918,453}},["cloud-snow"]={16898613044,{48,48},{98,869}},["file-question"]={16898613353,{48,48},{869,98}},["arrow-big-up-dash"]={16898612629,{48,48},{967,257}},coffee={16898613044,{48,48},{967,514}},["image-down"]={16898613509,{48,48},{820,404}},["beer-off"]={16898612819,{48,48},{771,257}},["file-bar-chart"]={16898613353,{48,48},{820,563}},["bar-chart-2"]={16898612629,{48,48},{967,710}},["lock-keyhole-open"]={16898613509,{48,48},{820,906}},["chevrons-down-up"]={16898612819,{48,48},{661,967}},["clipboard-plus"]={16898613044,{48,48},{820,98}},["monitor-up"]={16898613613,{48,48},{771,453}},["list-end"]={16898613509,{48,48},{918,710}},["square-radical"]={16898613777,{48,48},{196,869}},play={16898613699,{48,48},{918,257}},["chevrons-right"]={16898612819,{48,48},{967,710}},["file-badge-2"]={16898613353,{48,48},{306,820}},["message-square-reply"]={16898613613,{48,48},{918,257}},["corner-down-right"]={16898613044,{48,48},{710,820}},phone={16898613699,{48,48},{0,869}},["arrow-left-to-line"]={16898612629,{48,48},{147,869}},["lamp-wall-down"]={16898613509,{48,48},{967,563}},["link-2"]={16898613509,{48,48},{967,404}},["repeat"]={16898613699,{48,48},{820,710}},["ellipsis-vertical"]={16898613353,{48,48},{820,0}},snail={16898613777,{48,48},{820,612}},["paint-bucket"]={16898613613,{48,48},{196,918}},["square-parking"]={16898613777,{48,48},{771,759}},["align-horizontal-justify-end"]={16898612629,{48,48},{869,514}},lasso={16898613509,{48,48},{918,147}},["align-vertical-distribute-end"]={16898612629,{48,48},{147,771}},soup={16898613777,{48,48},{612,820}},airplay={16898612629,{48,48},{771,49}},["layout-dashboard"]={16898613509,{48,48},{967,355}},["heading-1"]={16898613509,{48,48},{0,918}},["circle-x"]={16898613044,{48,48},{820,306}},["monitor-x"]={16898613613,{48,48},{453,771}},["octagon-pause"]={16898613613,{48,48},{869,453}},["library-square"]={16898613509,{48,48},{771,808}},["square-pen"]={16898613777,{48,48},{710,820}},["heart-pulse"]={16898613509,{48,48},{771,661}},["database-backup"]={16898613044,{48,48},{820,759}},["gantt-chart"]={16898613353,{48,48},{869,857}},octagon={16898613613,{48,48},{404,918}},ticket={16898613869,{48,48},{612,771}},["message-square"]={16898613613,{48,48},{355,820}},["list-filter"]={16898613509,{48,48},{869,759}},["train-front"]={16898613869,{48,48},{404,771}},["spray-can"]={16898613777,{48,48},{967,257}},["list-music"]={16898613509,{48,48},{771,857}},["utility-pole"]={16898613869,{48,48},{196,869}},["list-plus"]={16898613509,{48,48},{661,967}},["screen-share"]={16898613699,{48,48},{710,967}},["file-clock"]={16898613353,{48,48},{514,869}},["list-collapse"]={16898613509,{48,48},{967,661}},gauge={16898613353,{48,48},{771,955}},store={16898613777,{48,48},{404,967}},["circle-arrow-down"]={16898612819,{48,48},{869,857}},["notebook-pen"]={16898613613,{48,48},{563,967}},["egg-fried"]={16898613353,{48,48},{257,771}},["calendar-off"]={16898612819,{48,48},{49,967}},["locate-off"]={16898613509,{48,48},{918,808}},["corner-right-up"]={16898613044,{48,48},{967,98}},locate={16898613509,{48,48},{869,857}},["ticket-x"]={16898613869,{48,48},{771,612}},["user-round-plus"]={16898613869,{48,48},{404,869}},["panel-left-close"]={16898613613,{48,48},{710,918}},["lock-keyhole"]={16898613509,{48,48},{771,955}},["lock-open"]={16898613509,{48,48},{967,808}},["user-round-minus"]={16898613869,{48,48},{453,820}},["m-square"]={16898613509,{48,48},{869,955}},magnet={16898613509,{48,48},{967,906}},["message-square-text"]={16898613613,{48,48},{820,355}},["mail-plus"]={16898613613,{48,48},{0,771}},["mail-search"]={16898613613,{48,48},{257,771}},move={16898613613,{48,48},{453,820}},["play-circle"]={16898613699,{48,48},{49,869}},["git-commit-vertical"]={16898613353,{48,48},{967,906}},slash={16898613777,{48,48},{918,257}},["map-pin-off"]={16898613613,{48,48},{0,820}},aperture={16898612629,{48,48},{771,661}},["image-plus"]={16898613509,{48,48},{404,820}},["message-circle-heart"]={16898613613,{48,48},{771,355}},syringe={16898613777,{48,48},{918,808}},info={16898613509,{48,48},{612,869}},["rows-3"]={16898613699,{48,48},{918,661}},check={16898612819,{48,48},{710,869}},["text-search"]={16898613869,{48,48},{869,0}},["square-slash"]={16898613777,{48,48},{967,355}},sandwich={16898613699,{48,48},{918,196}},["settings-2"]={16898613777,{48,48},{0,771}},["file-stack"]={16898613353,{48,48},{0,967}},["external-link"]={16898613353,{48,48},{257,820}},["ice-cream-2"]={16898613509,{48,48},{0,967}},["file-archive"]={16898613353,{48,48},{869,257}},["signal-high"]={16898613777,{48,48},{771,612}},inbox={16898613509,{48,48},{918,563}},["flip-horizontal-2"]={16898613353,{48,48},{355,918}},["traffic-cone"]={16898613869,{48,48},{820,355}},["file-signature"]={16898613353,{48,48},{147,820}},["align-horizontal-space-between"]={16898612629,{48,48},{612,771}},["message-circle-dashed"]={16898613613,{48,48},{820,306}},maximize={16898613613,{48,48},{771,563}},["database-zap"]={16898613044,{48,48},{771,808}},droplets={16898613044,{48,48},{967,857}},["fish-symbol"]={16898613353,{48,48},{918,98}},["message-circle-off"]={16898613613,{48,48},{306,820}},["wheat-off"]={16898613869,{48,48},{967,453}},["layout-list"]={16898613509,{48,48},{869,453}},["file-search"]={16898613353,{48,48},{196,771}},["download-cloud"]={16898613044,{48,48},{869,857}},["alarm-clock-plus"]={16898612629,{48,48},{306,771}},["circle-dollar-sign"]={16898613044,{48,48},{257,771}},usb={16898613869,{48,48},{563,918}},["arrow-up-square"]={16898612629,{48,48},{869,196}},["receipt-pound-sterling"]={16898613699,{48,48},{563,918}},scan={16898613699,{48,48},{967,196}},["heading-5"]={16898613509,{48,48},{771,404}},undo={16898613869,{48,48},{404,820}},["file-search-2"]={16898613353,{48,48},{771,196}},minimize={16898613613,{48,48},{918,49}},["redo-2"]={16898613699,{48,48},{49,967}},thermometer={16898613869,{48,48},{869,257}},["filter-x"]={16898613353,{48,48},{661,820}},["sliders-vertical"]={16898613777,{48,48},{771,404}},["boom-box"]={16898612819,{48,48},{967,0}},["table-2"]={16898613777,{48,48},{869,857}},["touchpad-off"]={16898613869,{48,48},{98,820}},["diamond-percent"]={16898613044,{48,48},{918,196}},brain={16898612819,{48,48},{967,257}},microwave={16898613613,{48,48},{661,771}},["arrow-down-left-square"]={16898612629,{48,48},{306,918}},["user-round-cog"]={16898613869,{48,48},{820,453}},["octagon-x"]={16898613613,{48,48},{453,869}},languages={16898613509,{48,48},{710,820}},["file-json-2"]={16898613353,{48,48},{820,355}},["alarm-clock-check"]={16898612629,{48,48},{0,820}},guitar={16898613509,{48,48},{771,355}},anchor={16898612629,{48,48},{306,869}},["text-cursor"]={16898613869,{48,48},{563,771}},["search-code"]={16898613699,{48,48},{820,906}},["square-parking-off"]={16898613777,{48,48},{820,710}},["notebook-text"]={16898613613,{48,48},{918,147}},["arrow-right-to-line"]={16898612629,{48,48},{820,453}},["ticket-minus"]={16898613869,{48,48},{306,820}},["tally-4"]={16898613869,{48,48},{771,257}},heading={16898613509,{48,48},{355,820}},wallpaper={16898613869,{48,48},{967,404}},["door-open"]={16898613044,{48,48},{967,759}},["arrow-down-circle"]={16898612629,{48,48},{453,771}},["monitor-play"]={16898613613,{48,48},{967,257}},["key-square"]={16898613509,{48,48},{918,355}},["monitor-off"]={16898613613,{48,48},{49,918}},["pocket-knife"]={16898613699,{48,48},{918,514}},["book-copy"]={16898612819,{48,48},{563,820}},["panel-left-inactive"]={16898613613,{48,48},{967,196}},["car-front"]={16898612819,{48,48},{563,967}},["file-video"]={16898613353,{48,48},{355,869}},["reply-all"]={16898613699,{48,48},{661,869}},["cloud-moon-rain"]={16898613044,{48,48},{869,98}},["zoom-out"]={16898613869,{48,48},{967,906}},["search-slash"]={16898613699,{48,48},{771,955}},["notepad-text-dashed"]={16898613613,{48,48},{196,869}},["circle-alert"]={16898612819,{48,48},{918,808}},briefcase={16898612819,{48,48},{771,453}},["list-start"]={16898613509,{48,48},{196,967}},["more-vertical"]={16898613613,{48,48},{967,514}},["a-large-small"]={16898612629,{48,48},{771,257}},tractor={16898613869,{48,48},{869,306}},waves={16898613869,{48,48},{820,808}},["folder-cog"]={16898613353,{48,48},{869,196}},["code-2"]={16898613044,{48,48},{453,771}},["clock-5"]={16898613044,{48,48},{306,869}},vote={16898613869,{48,48},{612,967}},["shield-question"]={16898613777,{48,48},{563,771}},["arrow-right-from-line"]={16898612629,{48,48},{967,306}},["flame-kindling"]={16898613353,{48,48},{49,967}},["square-power"]={16898613777,{48,48},{869,196}},["circle-help"]={16898613044,{48,48},{820,257}},["bring-to-front"]={16898612819,{48,48},{453,771}},["move-right"]={16898613613,{48,48},{49,967}},figma={16898613353,{48,48},{0,869}},["bell-plus"]={16898612819,{48,48},{49,771}},sailboat={16898613699,{48,48},{612,967}},["hard-drive-upload"]={16898613509,{48,48},{869,49}},["pie-chart"]={16898613699,{48,48},{869,514}},meh={16898613613,{48,48},{820,49}},["mail-warning"]={16898613613,{48,48},{771,514}},["music-3"]={16898613613,{48,48},{355,918}},["pause-circle"]={16898613613,{48,48},{967,955}},["panels-right-bottom"]={16898613613,{48,48},{771,955}},["file-edit"]={16898613353,{48,48},{49,869}},redo={16898613699,{48,48},{918,355}},["file-lock"]={16898613353,{48,48},{918,514}},["square-user"]={16898613777,{48,48},{967,612}},["circle-fading-plus"]={16898613044,{48,48},{49,771}},workflow={16898613869,{48,48},{967,759}},["undo-dot"]={16898613869,{48,48},{453,771}},target={16898613869,{48,48},{514,771}},tablets={16898613777,{48,48},{869,955}},radar={16898613699,{48,48},{820,404}},drama={16898613044,{48,48},{967,808}},["signal-medium"]={16898613777,{48,48},{563,820}},baseline={16898612629,{48,48},{869,857}},martini={16898613613,{48,48},{257,820}},contrast={16898613044,{48,48},{918,355}},pickaxe={16898613699,{48,48},{355,771}},["square-divide"]={16898613777,{48,48},{967,306}},["chevron-left-circle"]={16898612819,{48,48},{918,453}},["book-check"]={16898612819,{48,48},{612,771}},["scan-barcode"]={16898613699,{48,48},{918,710}},["book-lock"]={16898612819,{48,48},{98,820}},["panel-right-inactive"]={16898613613,{48,48},{918,759}},refrigerator={16898613699,{48,48},{355,918}},["divide-circle"]={16898613044,{48,48},{967,196}},["package-plus"]={16898613613,{48,48},{661,918}},["mic-2"]={16898613613,{48,48},{257,918}},["hop-off"]={16898613509,{48,48},{771,196}},warehouse={16898613869,{48,48},{967,661}},["plus-square"]={16898613699,{48,48},{306,869}},["square-arrow-out-up-left"]={16898613777,{48,48},{257,967}},["save-all"]={16898613699,{48,48},{967,404}},candy={16898612819,{48,48},{771,759}},["iteration-ccw"]={16898613509,{48,48},{918,98}},["corner-left-down"]={16898613044,{48,48},{661,869}},paintbrush={16898613613,{48,48},{918,453}},["cloud-lightning"]={16898613044,{48,48},{918,49}},["circle-slash-2"]={16898613044,{48,48},{771,98}},["layers-3"]={16898613509,{48,48},{147,918}},["credit-card"]={16898613044,{48,48},{98,967}},["ear-off"]={16898613044,{48,48},{918,955}},["git-commit-horizontal"]={16898613353,{48,48},{869,955}},["panel-bottom"]={16898613613,{48,48},{771,857}},["square-code"]={16898613777,{48,48},{820,196}},["panel-bottom-open"]={16898613613,{48,48},{820,808}},["kanban-square-dashed"]={16898613509,{48,48},{147,869}},["circle-pause"]={16898613044,{48,48},{771,563}},["panel-top-close"]={16898613613,{48,48},{771,906}},ambulance={16898612629,{48,48},{771,404}},["trending-up"]={16898613869,{48,48},{514,918}},["bookmark-x"]={16898612819,{48,48},{563,869}},["clock-9"]={16898613044,{48,48},{820,612}},pen={16898613699,{48,48},{771,49}},["smartphone-nfc"]={16898613777,{48,48},{306,869}},["candy-cane"]={16898612819,{48,48},{869,661}},unlink={16898613869,{48,48},{869,612}},["parking-meter"]={16898613613,{48,48},{918,906}},["gamepad-2"]={16898613353,{48,48},{710,967}},["user-round-search"]={16898613869,{48,48},{355,918}},["parking-square"]={16898613613,{48,48},{967,906}},["paw-print"]={16898613699,{48,48},{771,257}},["arrow-down-right-square"]={16898612629,{48,48},{869,612}},["square-split-vertical"]={16898613777,{48,48},{869,453}},["circle-off"]={16898613044,{48,48},{306,771}},dessert={16898613044,{48,48},{612,967}},eclipse={16898613353,{48,48},{771,257}},squirrel={16898613777,{48,48},{771,808}},["percent-circle"]={16898613699,{48,48},{306,771}},cylinder={16898613044,{48,48},{869,710}},["badge-japanese-yen"]={16898612629,{48,48},{453,918}},["circle-divide"]={16898613044,{48,48},{771,257}},["receipt-text"]={16898613699,{48,48},{918,98}},["square-pi"]={16898613777,{48,48},{612,918}},["align-center-horizontal"]={16898612629,{48,48},{98,771}},["phone-off"]={16898613699,{48,48},{98,771}},["pi-square"]={16898613699,{48,48},{869,257}},["file-output"]={16898613353,{48,48},{661,771}},["disc-album"]={16898613044,{48,48},{710,918}},["percent-square"]={16898613699,{48,48},{820,514}},clapperboard={16898613044,{48,48},{257,869}},captions={16898612819,{48,48},{612,918}},["wallet-minimal"]={16898613869,{48,48},{196,918}},layers={16898613509,{48,48},{98,967}},["umbrella-off"]={16898613869,{48,48},{918,306}},["badge-alert"]={16898612629,{48,48},{661,918}},["arrow-down-left-from-circle"]={16898612629,{48,48},{355,869}},["folder-pen"]={16898613353,{48,48},{710,869}},cross={16898613044,{48,48},{869,453}},["alarm-check"]={16898612629,{48,48},{49,771}},["chevron-right"]={16898612819,{48,48},{869,759}},pill={16898613699,{48,48},{563,820}},["square-arrow-down-left"]={16898613777,{48,48},{820,404}},["share-2"]={16898613777,{48,48},{771,514}},["arrow-up-from-dot"]={16898612629,{48,48},{869,661}},["pin-off"]={16898613699,{48,48},{514,869}},["align-vertical-justify-start"]={16898612629,{48,48},{918,257}},combine={16898613044,{48,48},{612,869}},["tv-2"]={16898613869,{48,48},{147,820}},mountain={16898613613,{48,48},{869,612}},cast={16898612819,{48,48},{869,453}},["indent-increase"]={16898613509,{48,48},{820,661}},currency={16898613044,{48,48},{918,661}},["shield-ban"]={16898613777,{48,48},{0,820}},["message-circle-reply"]={16898613613,{48,48},{820,563}},["corner-left-up"]={16898613044,{48,48},{612,918}},["triangle-right"]={16898613869,{48,48},{918,49}},["folder-clock"]={16898613353,{48,48},{967,98}},link={16898613509,{48,48},{918,453}},["pound-sterling"]={16898613699,{48,48},{514,918}},type={16898613869,{48,48},{967,257}},webhook={16898613869,{48,48},{967,196}},barcode={16898612629,{48,48},{918,808}},["shopping-bag"]={16898613777,{48,48},{49,820}},bed={16898612819,{48,48},{771,0}},["panel-right-open"]={16898613613,{48,48},{869,808}},["pointer-off"]={16898613699,{48,48},{771,661}},turtle={16898613869,{48,48},{196,771}},camera={16898612819,{48,48},{967,563}},scissors={16898613699,{48,48},{820,857}},["user-minus-2"]={16898613869,{48,48},{98,918}},["git-pull-request"]={16898613509,{48,48},{49,771}},["bluetooth-searching"]={16898612819,{48,48},{820,306}},["arrow-up-to-line"]={16898612629,{48,48},{196,869}},drill={16898613044,{48,48},{869,906}},["file-check-2"]={16898613353,{48,48},{612,771}},["badge-percent"]={16898612629,{48,48},{967,661}},shuffle={16898613777,{48,48},{257,869}},radiation={16898613699,{48,48},{771,453}},radical={16898613699,{48,48},{453,771}},microscope={16898613613,{48,48},{771,661}},["message-circle-x"]={16898613613,{48,48},{612,771}},box={16898612819,{48,48},{771,196}},["align-left"]={16898612629,{48,48},{514,869}},["switch-camera"]={16898613777,{48,48},{771,906}},["file-heart"]={16898613353,{48,48},{0,918}},cat={16898612819,{48,48},{404,918}},space={16898613777,{48,48},{563,869}},["rectangle-vertical"]={16898613699,{48,48},{147,869}},["clipboard-signature"]={16898613044,{48,48},{771,147}},["arrow-up-circle"]={16898612629,{48,48},{967,563}},["corner-up-left"]={16898613044,{48,48},{918,147}},["clock-6"]={16898613044,{48,48},{257,918}},["candlestick-chart"]={16898612819,{48,48},{918,612}},["key-round"]={16898613509,{48,48},{967,306}},headphones={16898613509,{48,48},{306,869}},tv={16898613869,{48,48},{98,869}},["book-minus"]={16898612819,{48,48},{0,918}},["bar-chart-horizontal-big"]={16898612629,{48,48},{771,906}},rss={16898613699,{48,48},{771,808}},["user-round-x"]={16898613869,{48,48},{306,967}},highlighter={16898613509,{48,48},{918,49}},["rocking-chair"]={16898613699,{48,48},{869,196}},["square-arrow-out-down-left"]={16898613777,{48,48},{355,869}},music={16898613613,{48,48},{967,563}},handshake={16898613509,{48,48},{514,869}},["check-circle"]={16898612819,{48,48},{869,710}},tornado={16898613869,{48,48},{771,147}},["copy-plus"]={16898613044,{48,48},{355,918}},["folder-git"]={16898613353,{48,48},{918,404}},["triangle-alert"]={16898613869,{48,48},{967,0}},shrink={16898613777,{48,48},{355,771}},sofa={16898613777,{48,48},{661,771}},["school-2"]={16898613699,{48,48},{967,453}},["search-check"]={16898613699,{48,48},{869,857}},crop={16898613044,{48,48},{918,404}},["columns-2"]={16898613044,{48,48},{820,661}},["mouse-pointer-square"]={16898613613,{48,48},{661,820}},["flask-conical-off"]={16898613353,{48,48},{820,453}},milestone={16898613613,{48,48},{612,820}},["wand-2"]={16898613869,{48,48},{918,453}},["square-dot"]={16898613777,{48,48},{918,355}},["badge-minus"]={16898612629,{48,48},{404,967}},["cloud-fog"]={16898613044,{48,48},{514,918}},["milk-off"]={16898613613,{48,48},{563,869}},bone={16898612819,{48,48},{869,514}},["percent-diamond"]={16898613699,{48,48},{257,820}},["package-check"]={16898613613,{48,48},{820,759}},["chevron-first"]={16898612819,{48,48},{147,967}},pencil={16898613699,{48,48},{820,257}},["shield-minus"]={16898613777,{48,48},{257,820}},["list-x"]={16898613509,{48,48},{918,759}},["stretch-horizontal"]={16898613777,{48,48},{967,661}},["panel-left-open"]={16898613613,{48,48},{196,967}},["corner-up-right"]={16898613044,{48,48},{869,196}},["repeat-2"]={16898613699,{48,48},{869,661}},pin={16898613699,{48,48},{918,0}},["mail-question"]={16898613613,{48,48},{771,257}},gift={16898613353,{48,48},{820,955}},["badge-indian-rupee"]={16898612629,{48,48},{967,404}},smartphone={16898613777,{48,48},{257,918}},["redo-dot"]={16898613699,{48,48},{967,306}},["users-round"]={16898613869,{48,48},{563,967}},["align-start-horizontal"]={16898612629,{48,48},{869,49}},["message-square-warning"]={16898613613,{48,48},{771,404}},["file-plus"]={16898613353,{48,48},{918,49}},["git-pull-request-arrow"]={16898613509,{48,48},{257,771}},webcam={16898613869,{48,48},{710,918}},["arrow-down-to-dot"]={16898612629,{48,48},{710,771}},["bell-dot"]={16898612819,{48,48},{771,514}},["folder-down"]={16898613353,{48,48},{147,918}},church={16898612819,{48,48},{771,906}},["square-play"]={16898613777,{48,48},{967,98}},["badge-x"]={16898612629,{48,48},{710,918}},server={16898613777,{48,48},{771,0}},["phone-forwarded"]={16898613699,{48,48},{869,0}},diamond={16898613044,{48,48},{196,918}},blinds={16898612819,{48,48},{98,771}},["user-square"]={16898613869,{48,48},{820,710}},package={16898613613,{48,48},{918,196}},["alarm-clock-off"]={16898612629,{48,48},{771,306}},["table-cells-merge"]={16898613777,{48,48},{820,906}},["helping-hand"]={16898613509,{48,48},{514,918}},recycle={16898613699,{48,48},{98,918}},["mountain-snow"]={16898613613,{48,48},{918,563}},luggage={16898613509,{48,48},{918,906}},["divide-square"]={16898613044,{48,48},{196,967}},["bot-message-square"]={16898612819,{48,48},{918,49}},["phone-outgoing"]={16898613699,{48,48},{49,820}},["smartphone-charging"]={16898613777,{48,48},{355,820}},["panel-left"]={16898613613,{48,48},{967,453}},["train-track"]={16898613869,{48,48},{355,820}},["bookmark-minus"]={16898612819,{48,48},{661,771}},["tablet-smartphone"]={16898613777,{48,48},{967,857}},["fire-extinguisher"]={16898613353,{48,48},{514,967}},sigma={16898613777,{48,48},{820,563}},["shield-half"]={16898613777,{48,48},{306,771}},terminal={16898613869,{48,48},{820,257}},shapes={16898613777,{48,48},{257,771}},["bell-ring"]={16898612819,{48,48},{0,820}},["tower-control"]={16898613869,{48,48},{0,918}},["arrow-down-1-0"]={16898612629,{48,48},{820,404}},users={16898613869,{48,48},{967,98}},scroll={16898613699,{48,48},{918,808}},["arrow-left-right"]={16898612629,{48,48},{820,196}},["lightbulb-off"]={16898613509,{48,48},{967,147}},["panels-top-left"]={16898613613,{48,48},{967,808}},beaker={16898612629,{48,48},{918,906}},["message-square-share"]={16898613613,{48,48},{869,306}},annoyed={16898612629,{48,48},{918,514}},["test-tube"]={16898613869,{48,48},{257,820}},["user-circle"]={16898613869,{48,48},{820,196}},["cooking-pot"]={16898613044,{48,48},{820,453}},["between-horizontal-start"]={16898612819,{48,48},{306,771}},fullscreen={16898613353,{48,48},{967,453}},["circuit-board"]={16898613044,{48,48},{355,771}},["grid-3x3"]={16898613509,{48,48},{98,771}},["mail-open"]={16898613613,{48,48},{771,0}},["square-function"]={16898613777,{48,48},{820,453}},["arrow-up-left-from-circle"]={16898612629,{48,48},{771,759}},variable={16898613869,{48,48},{147,918}},["arrow-up-right-square"]={16898612629,{48,48},{967,98}},["pen-line"]={16898613699,{48,48},{771,514}}},["256px"]={["align-vertical-distribute-center"]={16898613509,{256,256},{514,0}},["chevron-down"]={16898617411,{256,256},{514,257}},["list-restart"]={16898674572,{256,256},{257,257}},["table-cells-split"]={16898787819,{256,256},{514,0}},gavel={16898672166,{256,256},{514,257}},["dna-off"]={16898669271,{256,256},{514,514}},["refresh-ccw-dot"]={16898733036,{256,256},{257,514}},bean={16898615374,{256,256},{257,0}},["arrow-up-right-from-circle"]={16898614410,{256,256},{514,257}},["table-columns-split"]={16898787819,{256,256},{257,257}},bolt={16898615799,{256,256},{0,514}},heater={16898673271,{256,256},{257,0}},feather={16898669897,{256,256},{0,514}},["align-horizontal-distribute-center"]={16898613044,{256,256},{514,514}},["align-center"]={16898613044,{256,256},{0,514}},["grip-vertical"]={16898672700,{256,256},{514,0}},["person-standing"]={16898731539,{256,256},{257,257}},["badge-swiss-franc"]={16898615022,{256,256},{514,0}},["between-horizontal-end"]={16898615428,{256,256},{514,257}},["rotate-cw"]={16898733415,{256,256},{514,0}},framer={16898671684,{256,256},{514,514}},["bus-front"]={16898616879,{256,256},{0,514}},["shield-ellipsis"]={16898734564,{256,256},{514,0}},["file-lock-2"]={16898670241,{256,256},{0,0}},["between-vertical-end"]={16898615428,{256,256},{514,514}},["globe-lock"]={16898672599,{256,256},{514,0}},tags={16898788033,{256,256},{514,0}},["concierge-bell"]={16898619347,{256,256},{257,0}},["user-square"]={16898790047,{256,256},{514,257}},["arrow-left-square"]={16898614166,{256,256},{257,257}},["file-down"]={16898670072,{256,256},{514,514}},["picture-in-picture"]={16898731683,{256,256},{514,514}},["messages-square"]={16898728402,{256,256},{257,514}},["touchpad-off"]={16898788908,{256,256},{257,0}},["user-round-cog"]={16898789825,{256,256},{257,514}},["chevron-up-circle"]={16898617509,{256,256},{514,257}},["server-crash"]={16898734242,{256,256},{514,514}},["heading-3"]={16898672954,{256,256},{257,514}},squircle={16898736597,{256,256},{0,514}},["wifi-off"]={16898790996,{256,256},{257,514}},["sun-medium"]={16898736967,{256,256},{514,257}},["message-square"]={16898728402,{256,256},{514,257}},["cloud-download"]={16898618763,{256,256},{0,257}},["sigma-square"]={16898734792,{256,256},{257,257}},["folder-plus"]={16898671463,{256,256},{257,0}},["hard-drive-download"]={16898672829,{256,256},{257,514}},["scatter-chart"]={16898733817,{256,256},{257,257}},pointer={16898732061,{256,256},{514,514}},["circle-alert"]={16898617705,{256,256},{514,0}},["chevrons-up-down"]={16898617626,{256,256},{514,257}},["iteration-cw"]={16898673616,{256,256},{0,0}},["rail-symbol"]={16898732665,{256,256},{0,514}},["message-circle-more"]={16898675752,{256,256},{0,257}},parentheses={16898731166,{256,256},{257,514}},["book-up-2"]={16898616524,{256,256},{0,0}},flame={16898670919,{256,256},{0,257}},["chevrons-up"]={16898617626,{256,256},{257,514}},["chevron-right-square"]={16898617509,{256,256},{257,257}},["square-mouse-pointer"]={16898736237,{256,256},{257,0}},superscript={16898787671,{256,256},{514,0}},tag={16898788033,{256,256},{0,257}},["file-warning"]={16898670620,{256,256},{0,257}},hexagon={16898673271,{256,256},{257,257}},["navigation-2-off"]={16898730065,{256,256},{257,0}},["eye-off"]={16898669772,{256,256},{514,514}},["arrows-up-from-line"]={16898614574,{256,256},{0,514}},["square-gantt-chart"]={16898736072,{256,256},{257,257}},["square-chevron-left"]={16898735845,{256,256},{257,0}},scaling={16898733674,{256,256},{0,514}},["inspection-panel"]={16898673523,{256,256},{0,514}},["arrow-left-from-line"]={16898614166,{256,256},{0,257}},["signal-medium"]={16898734792,{256,256},{514,514}},["ticket-percent"]={16898788660,{256,256},{257,514}},["arrow-right-square"]={16898614275,{256,256},{257,0}},["calendar-clock"]={16898616953,{256,256},{0,514}},x={16898791349,{256,256},{257,0}},voicemail={16898790439,{256,256},{514,514}},presentation={16898732262,{256,256},{257,514}},["tree-palm"]={16898789012,{256,256},{0,514}},badge={16898615022,{256,256},{0,514}},["captions-off"]={16898617146,{256,256},{514,514}},["align-vertical-justify-center"]={16898613509,{256,256},{514,257}},theater={16898788479,{256,256},{514,514}},tent={16898788248,{256,256},{257,257}},["repeat-1"]={16898733146,{256,256},{0,514}},stethoscope={16898736776,{256,256},{257,257}},["screen-share-off"]={16898734065,{256,256},{0,257}},["arrow-big-up"]={16898613777,{256,256},{514,514}},["volume-x"]={16898790615,{256,256},{0,257}},["mouse-pointer-click"]={16898729337,{256,256},{0,514}},["square-m"]={16898736072,{256,256},{257,514}},["hard-hat"]={16898672954,{256,256},{257,0}},["package-minus"]={16898730417,{256,256},{257,514}},["iteration-ccw"]={16898673523,{256,256},{514,514}},pipette={16898731819,{256,256},{257,514}},["flip-horizontal"]={16898671019,{256,256},{0,0}},["alert-circle"]={16898613044,{256,256},{0,0}},unplug={16898789644,{256,256},{0,0}},["badge-cent"]={16898614755,{256,256},{514,514}},["check-square-2"]={16898617325,{256,256},{514,514}},["monitor-check"]={16898728878,{256,256},{257,257}},trello={16898789012,{256,256},{514,514}},["paintbrush-2"]={16898730641,{256,256},{514,257}},["bar-chart-horizontal"]={16898615143,{256,256},{514,257}},["book-open-text"]={16898616322,{256,256},{257,257}},["parking-meter"]={16898731301,{256,256},{257,0}},cat={16898617325,{256,256},{514,0}},["heart-handshake"]={16898673115,{256,256},{514,257}},trees={16898789012,{256,256},{257,514}},ham={16898672700,{256,256},{257,514}},text={16898788479,{256,256},{257,514}},["circle-pause"]={16898617944,{256,256},{0,514}},["chevron-up-square"]={16898617509,{256,256},{257,514}},rat={16898732665,{256,256},{257,514}},["separator-horizontal"]={16898734242,{256,256},{0,514}},ambulance={16898613613,{256,256},{0,257}},["signal-zero"]={16898734905,{256,256},{0,0}},citrus={16898618228,{256,256},{0,0}},["phone-missed"]={16898731539,{256,256},{514,514}},["calendar-off"]={16898617053,{256,256},{0,257}},["battery-medium"]={16898615240,{256,256},{0,514}},["square-minus"]={16898736237,{256,256},{0,0}},hotel={16898673358,{256,256},{0,257}},["folder-output"]={16898671263,{256,256},{514,514}},["ice-cream"]={16898673358,{256,256},{257,514}},menu={16898675673,{256,256},{514,257}},["arrow-up-left-square"]={16898614410,{256,256},{514,0}},["image-down"]={16898673358,{256,256},{514,514}},terminal={16898788248,{256,256},{514,257}},angry={16898613613,{256,256},{514,257}},outdent={16898730417,{256,256},{257,257}},["circle-dot-dashed"]={16898617884,{256,256},{514,0}},speech={16898735455,{256,256},{257,0}},["cake-slice"]={16898616953,{256,256},{0,0}},["git-graph"]={16898672316,{256,256},{514,514}},armchair={16898613777,{256,256},{0,0}},["qr-code"]={16898732504,{256,256},{257,257}},copy={16898619423,{256,256},{257,514}},goal={16898672599,{256,256},{0,514}},["trending-down"]={16898789153,{256,256},{0,0}},["creative-commons"]={16898668482,{256,256},{257,0}},nfc={16898730065,{256,256},{257,514}},pickaxe={16898731683,{256,256},{514,257}},car={16898617249,{256,256},{514,0}},["notebook-tabs"]={16898730298,{256,256},{0,0}},ear={16898669689,{256,256},{0,257}},videotape={16898790439,{256,256},{514,257}},["sun-moon"]={16898736967,{256,256},{257,514}},calendar={16898617146,{256,256},{0,0}},["minus-circle"]={16898728878,{256,256},{257,0}},["arrow-down-left-from-circle"]={16898613869,{256,256},{0,514}},gift={16898672316,{256,256},{0,0}},["message-square-heart"]={16898675863,{256,256},{0,514}},["rectangle-ellipsis"]={16898733036,{256,256},{0,0}},["badge-plus"]={16898615022,{256,256},{0,0}},["indian-rupee"]={16898673523,{256,256},{0,257}},["monitor-dot"]={16898728878,{256,256},{0,514}},delete={16898668755,{256,256},{514,257}},["clipboard-pen-line"]={16898618228,{256,256},{514,514}},["folder-search"]={16898671463,{256,256},{257,257}},["utensils-crossed"]={16898790259,{256,256},{257,257}},["arrow-up"]={16898614574,{256,256},{257,257}},["arrow-up-from-dot"]={16898614410,{256,256},{0,0}},["flask-round"]={16898670919,{256,256},{257,514}},pause={16898731301,{256,256},{257,514}},shrub={16898734792,{256,256},{0,257}},flag={16898670919,{256,256},{0,0}},underline={16898789303,{256,256},{514,257}},["align-horizontal-distribute-end"]={16898613353,{256,256},{0,0}},newspaper={16898730065,{256,256},{514,257}},table={16898787819,{256,256},{257,514}},["move-vertical"]={16898729752,{256,256},{257,257}},["file-pen-line"]={16898670241,{256,256},{514,257}},["badge-russian-ruble"]={16898615022,{256,256},{0,257}},radius={16898732665,{256,256},{257,257}},["loader-2"]={16898674684,{256,256},{0,257}},pilcrow={16898731819,{256,256},{514,0}},["corner-left-up"]={16898668288,{256,256},{257,257}},spade={16898735175,{256,256},{514,257}},["folder-cog"]={16898671139,{256,256},{514,0}},["flip-vertical"]={16898671019,{256,256},{0,257}},["square-arrow-down"]={16898735593,{256,256},{257,257}},["circle-plus"]={16898617944,{256,256},{514,514}},view={16898790439,{256,256},{257,514}},cctv={16898617325,{256,256},{257,257}},["more-horizontal"]={16898729337,{256,256},{0,0}},rows={16898733534,{256,256},{257,0}},["pause-octagon"]={16898731301,{256,256},{514,257}},["circle-arrow-left"]={16898617705,{256,256},{0,514}},volume={16898790615,{256,256},{514,0}},facebook={16898669897,{256,256},{257,0}},["octagon-alert"]={16898730298,{256,256},{257,514}},["panel-bottom-dashed"]={16898730821,{256,256},{0,257}},["book-a"]={16898615799,{256,256},{514,514}},["align-end-vertical"]={16898613044,{256,256},{257,514}},["user-x-2"]={16898790047,{256,256},{257,514}},chrome={16898617626,{256,256},{514,514}},["receipt-japanese-yen"]={16898732855,{256,256},{514,0}},rabbit={16898732504,{256,256},{514,257}},["scissors-square"]={16898734065,{256,256},{0,0}},["check-square"]={16898617411,{256,256},{0,0}},["train-front-tunnel"]={16898788908,{256,256},{257,514}},["panel-left-dashed"]={16898730821,{256,256},{257,514}},["dice-4"]={16898669042,{256,256},{0,514}},["message-circle-x"]={16898675752,{256,256},{514,514}},["folder-x"]={16898671684,{256,256},{0,0}},["message-circle-warning"]={16898675752,{256,256},{257,514}},map={16898675359,{256,256},{0,514}},move={16898729752,{256,256},{0,514}},["arrow-up-left"]={16898614410,{256,256},{257,257}},award={16898614755,{256,256},{0,257}},["arrow-down-wide-narrow"]={16898614020,{256,256},{257,514}},["unfold-horizontal"]={16898789451,{256,256},{257,0}},["area-chart"]={16898613699,{256,256},{514,514}},["music-4"]={16898729752,{256,256},{514,514}},["shield-x"]={16898734664,{256,256},{0,0}},["plane-landing"]={16898731919,{256,256},{0,0}},["disc-3"]={16898669271,{256,256},{0,257}},["columns-4"]={16898619182,{256,256},{514,0}},["archive-x"]={16898613699,{256,256},{514,257}},["square-dashed-kanban"]={16898735845,{256,256},{257,514}},["mouse-pointer-2"]={16898729337,{256,256},{257,257}},["shield-off"]={16898734564,{256,256},{514,257}},compass={16898619182,{256,256},{257,514}},vegan={16898790439,{256,256},{0,0}},["message-circle-plus"]={16898675752,{256,256},{257,257}},["stop-circle"]={16898736776,{256,256},{257,514}},nut={16898730298,{256,256},{514,257}},search={16898734242,{256,256},{257,0}},files={16898670620,{256,256},{514,257}},["send-to-back"]={16898734242,{256,256},{514,0}},["alarm-clock"]={16898612819,{256,256},{257,257}},["shopping-basket"]={16898734664,{256,256},{514,257}},send={16898734242,{256,256},{257,257}},["chevron-left-square"]={16898617509,{256,256},{257,0}},["terminal-square"]={16898788248,{256,256},{0,514}},["square-arrow-out-down-left"]={16898735593,{256,256},{514,257}},["skip-back"]={16898734905,{256,256},{0,514}},["zoom-in"]={16898791349,{256,256},{0,514}},["file-scan"]={16898670367,{256,256},{514,0}},["message-square-dashed"]={16898675863,{256,256},{0,257}},trophy={16898789153,{256,256},{0,514}},umbrella={16898789303,{256,256},{0,514}},touchpad={16898788908,{256,256},{0,257}},["clipboard-copy"]={16898618228,{256,256},{514,0}},["map-pin-off"]={16898675359,{256,256},{0,257}},headset={16898673115,{256,256},{257,257}},["circle-chevron-up"]={16898617803,{256,256},{514,514}},["align-vertical-space-between"]={16898613613,{256,256},{257,0}},["lamp-desk"]={16898673794,{256,256},{514,0}},["circle-arrow-up"]={16898617803,{256,256},{0,257}},zap={16898791349,{256,256},{257,257}},["triangle-alert"]={16898789153,{256,256},{0,257}},["swiss-franc"]={16898787671,{256,256},{0,514}},["move-left"]={16898729572,{256,256},{514,514}},["chevron-up"]={16898617509,{256,256},{514,514}},instagram={16898673523,{256,256},{514,257}},["pen-tool"]={16898731419,{256,256},{514,0}},["pencil-ruler"]={16898731419,{256,256},{514,257}},dna={16898669433,{256,256},{0,0}},["arrow-big-down-dash"]={16898613777,{256,256},{257,0}},["clipboard-edit"]={16898618228,{256,256},{257,257}},mic={16898728659,{256,256},{0,257}},["folder-search-2"]={16898671463,{256,256},{514,0}},gitlab={16898672450,{256,256},{514,514}},["rotate-3d"]={16898733317,{256,256},{514,514}},["spell-check"]={16898735455,{256,256},{514,0}},popcorn={16898732262,{256,256},{0,0}},blocks={16898615570,{256,256},{514,514}},["washing-machine"]={16898790791,{256,256},{0,514}},["badge-minus"]={16898614945,{256,256},{257,514}},["cloud-sun"]={16898618899,{256,256},{0,514}},circle={16898618049,{256,256},{257,514}},["shield-alert"]={16898734564,{256,256},{0,0}},rainbow={16898732665,{256,256},{514,257}},["separator-vertical"]={16898734242,{256,256},{514,257}},ampersands={16898613613,{256,256},{257,257}},["user-search"]={16898790047,{256,256},{257,257}},fence={16898669897,{256,256},{514,257}},["square-user-round"]={16898736597,{256,256},{257,0}},sunrise={16898787671,{256,256},{257,0}},strikethrough={16898736967,{256,256},{0,257}},["calendar-days"]={16898616953,{256,256},{514,257}},["dollar-sign"]={16898669433,{256,256},{514,0}},puzzle={16898732504,{256,256},{0,257}},["list-minus"]={16898674572,{256,256},{0,0}},["sun-dim"]={16898736967,{256,256},{0,514}},upload={16898789644,{256,256},{0,257}},["app-window-mac"]={16898613699,{256,256},{0,257}},ellipsis={16898669772,{256,256},{257,0}},["copy-check"]={16898619423,{256,256},{0,257}},history={16898673271,{256,256},{514,257}},satellite={16898733674,{256,256},{0,0}},["bookmark-plus"]={16898616524,{256,256},{257,514}},["folder-key"]={16898671263,{256,256},{514,0}},["lamp-ceiling"]={16898673794,{256,256},{0,257}},["circle-power"]={16898618049,{256,256},{0,0}},hourglass={16898673358,{256,256},{514,0}},["folder-git"]={16898671139,{256,256},{514,514}},bomb={16898615799,{256,256},{514,257}},["layers-2"]={16898673999,{256,256},{514,514}},["battery-full"]={16898615240,{256,256},{514,0}},["user-minus"]={16898789825,{256,256},{514,0}},["x-octagon"]={16898791187,{256,256},{514,514}},["folder-tree"]={16898671463,{256,256},{257,514}},command={16898619182,{256,256},{514,257}},regex={16898733146,{256,256},{514,0}},hand={16898672829,{256,256},{0,514}},["chevrons-down"]={16898617626,{256,256},{257,0}},["bluetooth-off"]={16898615799,{256,256},{257,0}},["music-2"]={16898729752,{256,256},{514,257}},book={16898616524,{256,256},{257,257}},hammer={16898672700,{256,256},{514,514}},["circle-minus"]={16898617944,{256,256},{257,0}},["audio-waveform"]={16898614755,{256,256},{257,0}},["moon-star"]={16898729141,{256,256},{257,514}},["arrow-down-narrow-wide"]={16898613869,{256,256},{514,514}},sparkle={16898735175,{256,256},{257,514}},wand={16898790791,{256,256},{514,0}},["calendar-minus-2"]={16898617053,{256,256},{0,0}},["copy-minus"]={16898619423,{256,256},{514,0}},["folder-input"]={16898671263,{256,256},{257,0}},["book-image"]={16898616080,{256,256},{257,514}},shirt={16898734664,{256,256},{257,257}},["server-off"]={16898734421,{256,256},{0,0}},["move-up"]={16898729752,{256,256},{514,0}},["plug-2"]={16898731919,{256,256},{514,257}},radio={16898732665,{256,256},{514,0}},brackets={16898616650,{256,256},{514,514}},["calendar-heart"]={16898616953,{256,256},{514,514}},["list-ordered"]={16898674572,{256,256},{0,257}},["mic-off"]={16898728659,{256,256},{0,0}},["arrow-big-left"]={16898613777,{256,256},{257,257}},["square-split-horizontal"]={16898736398,{256,256},{514,257}},clover={16898619015,{256,256},{0,0}},["sun-snow"]={16898736967,{256,256},{514,514}},["user-2"]={16898789644,{256,256},{257,257}},["help-circle"]={16898673271,{256,256},{0,257}},["clock-2"]={16898618583,{256,256},{257,0}},["calendar-fold"]={16898616953,{256,256},{257,514}},["fish-off"]={16898670775,{256,256},{514,0}},baby={16898614755,{256,256},{0,514}},leaf={16898674337,{256,256},{0,0}},["fold-vertical"]={16898671019,{256,256},{257,514}},hop={16898673358,{256,256},{0,0}},["phone-incoming"]={16898731539,{256,256},{257,514}},cigarette={16898617705,{256,256},{0,257}},minus={16898728878,{256,256},{514,0}},["smile-plus"]={16898735040,{256,256},{514,514}},["folder-edit"]={16898671139,{256,256},{514,257}},["star-off"]={16898736776,{256,256},{0,0}},["git-pull-request-closed"]={16898672450,{256,256},{0,257}},["badge-check"]={16898614945,{256,256},{0,0}},["test-tube-2"]={16898788248,{256,256},{257,514}},["kanban-square"]={16898673616,{256,256},{257,257}},["plug-zap"]={16898731919,{256,256},{514,514}},["heading-4"]={16898672954,{256,256},{514,514}},["git-pull-request-create"]={16898672450,{256,256},{257,257}},["replace-all"]={16898733146,{256,256},{514,514}},["receipt-swiss-franc"]={16898732855,{256,256},{514,257}},["square-dashed-bottom-code"]={16898735845,{256,256},{0,514}},["clock-7"]={16898618583,{256,256},{514,257}},["scan-text"]={16898733817,{256,256},{0,257}},["shower-head"]={16898734792,{256,256},{0,0}},["equal-not"]={16898669772,{256,256},{0,257}},["sliders-horizontal"]={16898735040,{256,256},{0,257}},["ticket-slash"]={16898788789,{256,256},{0,0}},ruler={16898733534,{256,256},{514,0}},["circle-user-round"]={16898618049,{256,256},{257,257}},["list-filter"]={16898674482,{256,256},{514,514}},["alarm-minus"]={16898612819,{256,256},{0,514}},["egg-off"]={16898669689,{256,256},{257,514}},cog={16898619015,{256,256},{514,514}},dog={16898669433,{256,256},{0,257}},swords={16898787671,{256,256},{514,514}},["panel-right-dashed"]={16898731024,{256,256},{514,0}},["ship-wheel"]={16898734664,{256,256},{0,257}},bot={16898616650,{256,256},{514,0}},["trash-2"]={16898789012,{256,256},{0,257}},["chevron-down-square"]={16898617411,{256,256},{0,514}},["panel-left-open"]={16898731024,{256,256},{0,0}},["file-symlink"]={16898670469,{256,256},{257,0}},["clipboard-paste"]={16898618228,{256,256},{257,514}},["chevron-last"]={16898617411,{256,256},{514,514}},["book-heart"]={16898616080,{256,256},{514,257}},["circle-parking"]={16898617944,{256,256},{257,257}},["panel-left"]={16898731024,{256,256},{257,0}},["message-circle-off"]={16898675752,{256,256},{514,0}},speaker={16898735455,{256,256},{0,0}},timer={16898788789,{256,256},{0,514}},forward={16898671684,{256,256},{514,257}},["file-up"]={16898670469,{256,256},{514,257}},["between-vertical-start"]={16898615570,{256,256},{0,0}},database={16898668755,{256,256},{0,514}},["panel-right"]={16898731024,{256,256},{514,257}},["log-out"]={16898674825,{256,256},{257,257}},["git-branch-plus"]={16898672316,{256,256},{257,0}},["shield-half"]={16898734564,{256,256},{257,257}},["square-dot"]={16898736072,{256,256},{257,0}},["arrow-right-circle"]={16898614166,{256,256},{257,514}},["table-rows-split"]={16898787819,{256,256},{514,257}},watch={16898790791,{256,256},{514,257}},["cloud-upload"]={16898618899,{256,256},{514,257}},["screen-share"]={16898734065,{256,256},{514,0}},drumstick={16898669562,{256,256},{514,514}},["list-checks"]={16898674482,{256,256},{0,514}},bug={16898616879,{256,256},{0,257}},["circle-chevron-left"]={16898617803,{256,256},{514,257}},["arrow-down"]={16898614166,{256,256},{0,0}},["arrow-up-down"]={16898614275,{256,256},{514,514}},["folder-dot"]={16898671139,{256,256},{257,257}},["whole-word"]={16898790996,{256,256},{514,257}},monitor={16898729141,{256,256},{514,257}},["flag-off"]={16898670775,{256,256},{514,257}},["align-right"]={16898613509,{256,256},{0,0}},["circle-stop"]={16898618049,{256,256},{514,0}},infinity={16898673523,{256,256},{514,0}},["arrow-big-down"]={16898613777,{256,256},{0,257}},["circle-parking-off"]={16898617944,{256,256},{514,0}},["calendar-x-2"]={16898617053,{256,256},{257,514}},["user-plus"]={16898789825,{256,256},{0,514}},["move-diagonal-2"]={16898729572,{256,256},{0,257}},["gallery-horizontal-end"]={16898672004,{256,256},{257,257}},["panel-top-dashed"]={16898731024,{256,256},{514,514}},["tram-front"]={16898789012,{256,256},{257,0}},podcast={16898732061,{256,256},{514,257}},["audio-lines"]={16898614755,{256,256},{0,0}},["flip-vertical-2"]={16898671019,{256,256},{257,0}},github={16898672450,{256,256},{257,514}},["rows-2"]={16898733415,{256,256},{257,514}},printer={16898732262,{256,256},{514,514}},["megaphone-off"]={16898675673,{256,256},{257,0}},["file-bar-chart-2"]={16898669984,{256,256},{514,257}},["arrow-big-right"]={16898613777,{256,256},{514,257}},["file-clock"]={16898670072,{256,256},{0,257}},["toy-brick"]={16898788908,{256,256},{257,257}},["square-chevron-down"]={16898735845,{256,256},{0,0}},smartphone={16898735040,{256,256},{257,514}},drill={16898669562,{256,256},{257,257}},["app-window"]={16898613699,{256,256},{514,0}},["shield-check"]={16898734564,{256,256},{0,257}},["hand-metal"]={16898672829,{256,256},{514,0}},["x-circle"]={16898791187,{256,256},{257,514}},["spell-check-2"]={16898735455,{256,256},{0,257}},["minus-square"]={16898728878,{256,256},{0,257}},["box-select"]={16898616650,{256,256},{257,257}},["list-plus"]={16898674572,{256,256},{514,0}},waypoints={16898790791,{256,256},{514,514}},["ice-cream-cone"]={16898673358,{256,256},{514,257}},["copy-slash"]={16898619423,{256,256},{0,514}},wind={16898791187,{256,256},{0,0}},["layout-panel-left"]={16898674182,{256,256},{0,514}},pill={16898731819,{256,256},{257,257}},grip={16898672700,{256,256},{257,257}},["square-x"]={16898736597,{256,256},{514,0}},italic={16898673523,{256,256},{257,514}},["step-forward"]={16898736776,{256,256},{514,0}},["a-arrow-down"]={16898612629,{256,256},{0,0}},container={16898619347,{256,256},{257,514}},sticker={16898736776,{256,256},{0,514}},["parking-circle-off"]={16898731166,{256,256},{514,514}},import={16898673447,{256,256},{514,257}},bird={16898615570,{256,256},{257,257}},["square-terminal"]={16898736597,{256,256},{0,0}},gem={16898672166,{256,256},{257,514}},beef={16898615374,{256,256},{0,514}},["ticket-x"]={16898788789,{256,256},{257,0}},["timer-reset"]={16898788789,{256,256},{257,257}},["monitor-stop"]={16898729141,{256,256},{514,0}},smile={16898735175,{256,256},{0,0}},["signpost-big"]={16898734905,{256,256},{0,257}},cloudy={16898618899,{256,256},{514,514}},["square-percent"]={16898736237,{256,256},{0,514}},["navigation-off"]={16898730065,{256,256},{514,0}},["arrow-left"]={16898614166,{256,256},{514,257}},["car-taxi-front"]={16898617249,{256,256},{0,257}},laugh={16898673999,{256,256},{257,514}},["x-square"]={16898791349,{256,256},{0,0}},["step-back"]={16898736776,{256,256},{0,257}},equal={16898669772,{256,256},{514,0}},megaphone={16898675673,{256,256},{0,257}},["chevron-left"]={16898617509,{256,256},{0,257}},egg={16898669689,{256,256},{514,514}},["video-off"]={16898790439,{256,256},{257,257}},["japanese-yen"]={16898673616,{256,256},{257,0}},library={16898674337,{256,256},{257,257}},["file-terminal"]={16898670469,{256,256},{0,257}},["circle-chevron-down"]={16898617803,{256,256},{0,514}},["bell-off"]={16898615428,{256,256},{0,257}},["square-library"]={16898736072,{256,256},{514,257}},salad={16898733534,{256,256},{514,257}},["tally-2"]={16898788033,{256,256},{0,514}},sheet={16898734421,{256,256},{257,514}},["circle-check-big"]={16898617803,{256,256},{514,0}},["map-pinned"]={16898675359,{256,256},{257,257}},["corner-down-left"]={16898668288,{256,256},{257,0}},dribbble={16898669562,{256,256},{514,0}},["pilcrow-square"]={16898731819,{256,256},{0,257}},["lamp-wall-up"]={16898673794,{256,256},{514,257}},["book-dashed"]={16898616080,{256,256},{514,0}},bluetooth={16898615799,{256,256},{514,0}},["tree-pine"]={16898789012,{256,256},{514,257}},["receipt-indian-rupee"]={16898732855,{256,256},{0,257}},["check-circle-2"]={16898617325,{256,256},{514,257}},["flask-conical"]={16898670919,{256,256},{514,257}},["package-search"]={16898730641,{256,256},{257,0}},columns={16898619182,{256,256},{257,257}},["folder-sync"]={16898671463,{256,256},{514,257}},fingerprint={16898670775,{256,256},{257,0}},["arrow-up-narrow-wide"]={16898614410,{256,256},{0,514}},frame={16898671684,{256,256},{257,514}},["clock-12"]={16898618583,{256,256},{0,0}},images={16898673447,{256,256},{0,514}},lollipop={16898674825,{256,256},{0,514}},["folder-root"]={16898671463,{256,256},{0,257}},["arrow-left-circle"]={16898614166,{256,256},{257,0}},["lamp-floor"]={16898673794,{256,256},{257,257}},image={16898673447,{256,256},{257,257}},["badge-euro"]={16898614945,{256,256},{0,257}},bike={16898615570,{256,256},{257,0}},option={16898730417,{256,256},{0,257}},["scroll-text"]={16898734065,{256,256},{257,257}},["toggle-right"]={16898788789,{256,256},{257,514}},["ferris-wheel"]={16898669897,{256,256},{257,514}},["camera-off"]={16898617146,{256,256},{257,0}},["function-square"]={16898672004,{256,256},{514,0}},group={16898672700,{256,256},{0,514}},codesandbox={16898619015,{256,256},{514,257}},expand={16898669772,{256,256},{514,257}},["tent-tree"]={16898788248,{256,256},{514,0}},settings={16898734421,{256,256},{514,0}},bitcoin={16898615570,{256,256},{0,514}},["thumbs-up"]={16898788660,{256,256},{257,257}},["calendar-search"]={16898617053,{256,256},{514,257}},["hand-platter"]={16898672829,{256,256},{257,257}},["circle-x"]={16898618049,{256,256},{514,257}},["file-diff"]={16898670072,{256,256},{514,257}},["archive-restore"]={16898613699,{256,256},{0,514}},["clock-10"]={16898618392,{256,256},{257,514}},["dice-1"]={16898669042,{256,256},{0,257}},["copy-x"]={16898619423,{256,256},{514,257}},["folder-open-dot"]={16898671263,{256,256},{514,257}},["axis-3d"]={16898614755,{256,256},{257,257}},["arrow-down-1-0"]={16898613869,{256,256},{257,0}},["clipboard-check"]={16898618228,{256,256},{0,257}},["file-x"]={16898670620,{256,256},{257,257}},diff={16898669271,{256,256},{0,0}},dot={16898669433,{256,256},{257,514}},castle={16898617325,{256,256},{0,257}},["power-circle"]={16898732262,{256,256},{514,0}},["fast-forward"]={16898669897,{256,256},{257,257}},["mail-minus"]={16898675156,{256,256},{257,0}},["file-minus-2"]={16898670241,{256,256},{0,257}},paintbrush={16898730641,{256,256},{257,514}},cast={16898617325,{256,256},{257,0}},["parking-square-off"]={16898731301,{256,256},{0,257}},["clipboard-pen"]={16898618392,{256,256},{0,0}},["settings-2"]={16898734421,{256,256},{0,257}},["alarm-clock-off"]={16898612819,{256,256},{0,257}},["ice-cream-2"]={16898673358,{256,256},{257,257}},list={16898674684,{256,256},{257,0}},["file-pie-chart"]={16898670241,{256,256},{514,514}},["square-arrow-right"]={16898735664,{256,256},{257,0}},["scissors-square-dashed-bottom"]={16898733817,{256,256},{514,514}},["remove-formatting"]={16898733146,{256,256},{257,257}},["bookmark-check"]={16898616524,{256,256},{0,514}},cannabis={16898617146,{256,256},{257,514}},["file-plus-2"]={16898670367,{256,256},{0,0}},["bookmark-x"]={16898616524,{256,256},{514,514}},["a-arrow-up"]={16898612629,{256,256},{257,0}},["chevron-right-circle"]={16898617509,{256,256},{514,0}},caravan={16898617249,{256,256},{257,257}},["file-text"]={16898670469,{256,256},{514,0}},["vibrate-off"]={16898790439,{256,256},{0,257}},["mail-check"]={16898675156,{256,256},{0,0}},["square-split-vertical"]={16898736398,{256,256},{257,514}},["file-type-2"]={16898670469,{256,256},{257,257}},["file-code"]={16898670072,{256,256},{257,257}},["file-volume"]={16898670620,{256,256},{257,0}},["flag-triangle-left"]={16898670775,{256,256},{257,514}},["square-equal"]={16898736072,{256,256},{0,257}},["scan-barcode"]={16898733674,{256,256},{514,257}},["cassette-tape"]={16898617325,{256,256},{0,0}},["battery-low"]={16898615240,{256,256},{257,257}},["utility-pole"]={16898790259,{256,256},{514,257}},folder={16898671684,{256,256},{257,0}},signpost={16898734905,{256,256},{514,0}},["file-edit"]={16898670171,{256,256},{0,0}},["globe-2"]={16898672599,{256,256},{0,257}},landmark={16898673999,{256,256},{0,0}},["fish-symbol"]={16898670775,{256,256},{257,257}},["form-input"]={16898671684,{256,256},{0,514}},loader={16898674684,{256,256},{257,257}},bold={16898615799,{256,256},{257,257}},["dice-2"]={16898669042,{256,256},{514,0}},["file-type"]={16898670469,{256,256},{0,514}},["book-user"]={16898616524,{256,256},{0,257}},beer={16898615374,{256,256},{257,514}},["gantt-chart-square"]={16898672166,{256,256},{0,257}},ghost={16898672166,{256,256},{514,514}},globe={16898672599,{256,256},{257,257}},["satellite-dish"]={16898733534,{256,256},{514,514}},binary={16898615570,{256,256},{0,257}},["move-diagonal"]={16898729572,{256,256},{514,0}},["table-cells-merge"]={16898787819,{256,256},{0,257}},["door-closed"]={16898669433,{256,256},{0,514}},["image-minus"]={16898673447,{256,256},{0,0}},utensils={16898790259,{256,256},{0,514}},["paw-print"]={16898731301,{256,256},{514,514}},["bar-chart-4"]={16898615143,{256,256},{514,0}},["book-x"]={16898616524,{256,256},{514,0}},["panel-bottom-close"]={16898730821,{256,256},{257,0}},["hand-heart"]={16898672829,{256,256},{257,0}},["file-code-2"]={16898670072,{256,256},{514,0}},["move-down-left"]={16898729572,{256,256},{257,257}},indent={16898673523,{256,256},{257,0}},joystick={16898673616,{256,256},{0,257}},keyboard={16898673794,{256,256},{257,0}},["toggle-left"]={16898788789,{256,256},{514,257}},skull={16898734905,{256,256},{257,514}},["route-off"]={16898733415,{256,256},{257,257}},["dice-6"]={16898669042,{256,256},{257,514}},lightbulb={16898674337,{256,256},{514,514}},key={16898673616,{256,256},{514,514}},["clock-11"]={16898618392,{256,256},{514,514}},["list-video"]={16898674572,{256,256},{514,514}},["ticket-plus"]={16898788660,{256,256},{514,514}},["square-dashed-bottom"]={16898735845,{256,256},{514,257}},["layout-panel-top"]={16898674182,{256,256},{514,257}},["more-vertical"]={16898729337,{256,256},{257,0}},["monitor-pause"]={16898728878,{256,256},{514,514}},["book-open-check"]={16898616322,{256,256},{514,0}},projector={16898732504,{256,256},{0,0}},["lasso-select"]={16898673999,{256,256},{0,514}},maximize={16898675359,{256,256},{514,514}},["text-quote"]={16898788479,{256,256},{257,257}},["image-up"]={16898673447,{256,256},{514,0}},["message-square-quote"]={16898728402,{256,256},{0,0}},bus={16898616879,{256,256},{514,257}},["square-arrow-down-right"]={16898735593,{256,256},{514,0}},["bed-single"]={16898615374,{256,256},{514,0}},["list-music"]={16898674572,{256,256},{257,0}},["file-spreadsheet"]={16898670367,{256,256},{514,514}},["heart-pulse"]={16898673115,{256,256},{514,514}},["clipboard-list"]={16898618228,{256,256},{0,514}},video={16898790439,{256,256},{0,514}},["contact-round"]={16898619347,{256,256},{0,514}},battery={16898615240,{256,256},{257,514}},microscope={16898728659,{256,256},{514,0}},["message-circle-question"]={16898675752,{256,256},{0,514}},["file-badge"]={16898669984,{256,256},{0,514}},["battery-warning"]={16898615240,{256,256},{514,257}},["git-pull-request"]={16898672450,{256,256},{514,257}},["arrow-down-from-line"]={16898613869,{256,256},{257,257}},briefcase={16898616757,{256,256},{514,257}},biohazard={16898615570,{256,256},{514,0}},moon={16898729141,{256,256},{514,514}},["heading-6"]={16898673115,{256,256},{257,0}},["scale-3d"]={16898733674,{256,256},{514,0}},["chevron-down-circle"]={16898617411,{256,256},{257,257}},["mail-x"]={16898675156,{256,256},{257,514}},["square-dashed-mouse-pointer"]={16898735845,{256,256},{514,514}},["user-cog"]={16898789825,{256,256},{257,0}},["lock-open"]={16898674825,{256,256},{257,0}},["mouse-pointer-square-dashed"]={16898729337,{256,256},{514,257}},pizza={16898731819,{256,256},{514,514}},["pc-case"]={16898731419,{256,256},{0,0}},["arrow-up-wide-narrow"]={16898614574,{256,256},{0,257}},["mouse-pointer"]={16898729337,{256,256},{514,514}},["clock-5"]={16898618583,{256,256},{257,257}},dices={16898669042,{256,256},{514,514}},["rotate-ccw"]={16898733415,{256,256},{257,0}},["align-horizontal-justify-center"]={16898613353,{256,256},{0,257}},mouse={16898729572,{256,256},{0,0}},antenna={16898613613,{256,256},{514,514}},["memory-stick"]={16898675673,{256,256},{257,257}},["scan-eye"]={16898733674,{256,256},{257,514}},["bean-off"]={16898615374,{256,256},{0,0}},["square-check"]={16898735664,{256,256},{514,514}},unlock={16898789451,{256,256},{514,514}},highlighter={16898673271,{256,256},{0,514}},["loader-circle"]={16898674684,{256,256},{514,0}},["hard-drive-upload"]={16898672829,{256,256},{514,514}},["gallery-vertical-end"]={16898672004,{256,256},{257,514}},["menu-square"]={16898675673,{256,256},{0,514}},["hand-coins"]={16898672829,{256,256},{0,0}},["notepad-text"]={16898730298,{256,256},{257,257}},orbit={16898730417,{256,256},{514,0}},["package-open"]={16898730417,{256,256},{514,514}},clock={16898618763,{256,256},{0,0}},["file-pen"]={16898670241,{256,256},{257,514}},["git-compare-arrows"]={16898672316,{256,256},{0,514}},["cloud-sun-rain"]={16898618899,{256,256},{257,257}},["align-horizontal-justify-start"]={16898613353,{256,256},{257,257}},["grid-2x2"]={16898672700,{256,256},{0,0}},percent={16898731539,{256,256},{514,0}},vibrate={16898790439,{256,256},{514,0}},["calendar-plus"]={16898617053,{256,256},{257,257}},brain={16898616757,{256,256},{0,257}},["arrow-down-z-a"]={16898614020,{256,256},{514,514}},bath={16898615240,{256,256},{257,0}},["panel-right-close"]={16898731024,{256,256},{0,257}},["unlink-2"]={16898789451,{256,256},{0,514}},paperclip={16898731166,{256,256},{514,257}},["parking-circle"]={16898731301,{256,256},{0,0}},["folder-check"]={16898671139,{256,256},{0,0}},["parking-square"]={16898731301,{256,256},{514,0}},["book-key"]={16898616080,{256,256},{514,514}},ribbon={16898733317,{256,256},{257,257}},microwave={16898728659,{256,256},{257,257}},["air-vent"]={16898612629,{256,256},{514,257}},["library-big"]={16898674337,{256,256},{0,257}},["file-json"]={16898670171,{256,256},{0,514}},["folder-open"]={16898671263,{256,256},{257,514}},["monitor-off"]={16898728878,{256,256},{257,514}},["square-scissors"]={16898736398,{256,256},{514,0}},["move-up-left"]={16898729752,{256,256},{257,0}},brush={16898616757,{256,256},{514,514}},["folder-heart"]={16898671263,{256,256},{0,0}},hash={16898672954,{256,256},{0,257}},["arrow-up-1-0"]={16898614275,{256,256},{0,514}},["arrow-right"]={16898614275,{256,256},{514,0}},["arrow-up-a-z"]={16898614275,{256,256},{514,257}},["badge-x"]={16898615022,{256,256},{257,257}},["panel-bottom-inactive"]={16898730821,{256,256},{514,0}},["file-video-2"]={16898670469,{256,256},{257,514}},["phone-call"]={16898731539,{256,256},{0,514}},construction={16898619347,{256,256},{514,0}},["swatch-book"]={16898787671,{256,256},{257,257}},["receipt-cent"]={16898732855,{256,256},{0,0}},["badge-pound-sterling"]={16898615022,{256,256},{257,0}},["folder-archive"]={16898671019,{256,256},{514,514}},["folder-symlink"]={16898671463,{256,256},{0,514}},["columns-3"]={16898619182,{256,256},{0,257}},ban={16898615022,{256,256},{257,514}},["message-square-x"]={16898728402,{256,256},{0,514}},["paint-roller"]={16898730641,{256,256},{0,514}},plug={16898732061,{256,256},{0,0}},gamepad={16898672166,{256,256},{257,0}},["book-minus"]={16898616322,{256,256},{0,257}},popsicle={16898732262,{256,256},{257,0}},["building-2"]={16898616879,{256,256},{514,0}},["circle-slash-2"]={16898618049,{256,256},{257,0}},["rectangle-horizontal"]={16898733036,{256,256},{257,0}},cake={16898616953,{256,256},{257,0}},["cloud-rain"]={16898618899,{256,256},{0,257}},["maximize-2"]={16898675359,{256,256},{257,514}},["redo-2"]={16898733036,{256,256},{257,257}},wrench={16898791187,{256,256},{514,257}},["repeat-2"]={16898733146,{256,256},{514,257}},codepen={16898619015,{256,256},{0,514}},reply={16898733317,{256,256},{0,257}},["flag-triangle-right"]={16898670775,{256,256},{514,514}},["rotate-ccw-square"]={16898733415,{256,256},{0,0}},["scan-search"]={16898733817,{256,256},{257,0}},bell={16898615428,{256,256},{0,514}},["grid-3x3"]={16898672700,{256,256},{257,0}},save={16898733674,{256,256},{0,257}},["music-3"]={16898729752,{256,256},{257,514}},focus={16898671019,{256,256},{0,514}},["user-check"]={16898789644,{256,256},{514,257}},proportions={16898732504,{256,256},{257,0}},["alert-octagon"]={16898613044,{256,256},{257,0}},plane={16898731919,{256,256},{0,257}},["webhook-off"]={16898790996,{256,256},{257,0}},carrot={16898617249,{256,256},{0,514}},["square-arrow-left"]={16898735593,{256,256},{0,514}},["file-cog"]={16898670072,{256,256},{0,514}},heart={16898673271,{256,256},{0,0}},["scan-face"]={16898733674,{256,256},{514,514}},["folder-down"]={16898671139,{256,256},{0,514}},["layout-template"]={16898674182,{256,256},{257,514}},mailbox={16898675359,{256,256},{0,0}},home={16898673271,{256,256},{257,514}},["traffic-cone"]={16898788908,{256,256},{514,257}},scissors={16898734065,{256,256},{257,0}},split={16898735455,{256,256},{257,514}},twitter={16898789303,{256,256},{0,257}},["locate-off"]={16898674684,{256,256},{514,257}},forklift={16898671684,{256,256},{257,257}},["square-arrow-out-up-left"]={16898735593,{256,256},{514,514}},component={16898619182,{256,256},{514,514}},["panels-left-bottom"]={16898731166,{256,256},{514,0}},["message-square-diff"]={16898675863,{256,256},{514,0}},["book-marked"]={16898616322,{256,256},{257,0}},["alarm-plus"]={16898612819,{256,256},{514,257}},["bluetooth-connected"]={16898615799,{256,256},{0,0}},unlink={16898789451,{256,256},{514,257}},signal={16898734905,{256,256},{257,0}},slack={16898734905,{256,256},{514,514}},["file-volume-2"]={16898670620,{256,256},{0,0}},["pound-sterling"]={16898732262,{256,256},{0,257}},power={16898732262,{256,256},{514,257}},["skip-forward"]={16898734905,{256,256},{514,257}},["m-square"]={16898674825,{256,256},{257,514}},["git-merge"]={16898672450,{256,256},{0,0}},["file-box"]={16898669984,{256,256},{514,514}},["align-justify"]={16898613353,{256,256},{257,514}},["paint-bucket"]={16898730641,{256,256},{257,257}},wallpaper={16898790791,{256,256},{0,0}},filter={16898670775,{256,256},{0,0}},glasses={16898672599,{256,256},{257,0}},["piggy-bank"]={16898731819,{256,256},{257,0}},["square-play"]={16898736237,{256,256},{514,514}},shell={16898734421,{256,256},{514,514}},["cloud-off"]={16898618899,{256,256},{0,0}},["check-check"]={16898617325,{256,256},{0,514}},activity={16898612629,{256,256},{0,514}},axe={16898614755,{256,256},{514,0}},["plane-takeoff"]={16898731919,{256,256},{257,0}},snowflake={16898735175,{256,256},{0,257}},["cloud-rain-wind"]={16898618899,{256,256},{257,0}},["square-plus"]={16898736398,{256,256},{0,0}},["dice-5"]={16898669042,{256,256},{514,257}},["search-slash"]={16898734065,{256,256},{514,514}},["file-axis-3d"]={16898669984,{256,256},{514,0}},["receipt-euro"]={16898732855,{256,256},{257,0}},["square-radical"]={16898736398,{256,256},{0,257}},["cloud-drizzle"]={16898618763,{256,256},{514,0}},["bug-play"]={16898616879,{256,256},{257,0}},["align-vertical-distribute-start"]={16898613509,{256,256},{0,514}},layout={16898674182,{256,256},{514,514}},["square-stack"]={16898736398,{256,256},{514,514}},["tally-5"]={16898788033,{256,256},{514,514}},squirrel={16898736597,{256,256},{514,257}},["pen-square"]={16898731419,{256,256},{0,257}},["folder-lock"]={16898671263,{256,256},{257,257}},["circle-divide"]={16898617884,{256,256},{257,0}},["case-sensitive"]={16898617249,{256,256},{257,514}},sunset={16898787671,{256,256},{0,257}},linkedin={16898674482,{256,256},{257,257}},["life-buoy"]={16898674337,{256,256},{0,514}},["circle-play"]={16898617944,{256,256},{257,514}},["tally-4"]={16898788033,{256,256},{257,514}},["volume-2"]={16898790615,{256,256},{257,0}},["battery-charging"]={16898615240,{256,256},{0,257}},["russian-ruble"]={16898733534,{256,256},{257,257}},["wallet-minimal"]={16898790615,{256,256},{257,514}},["earth-lock"]={16898669689,{256,256},{514,0}},footprints={16898671684,{256,256},{514,0}},["text-cursor-input"]={16898788479,{256,256},{0,257}},building={16898616879,{256,256},{257,257}},["lock-keyhole-open"]={16898674684,{256,256},{514,514}},twitch={16898789303,{256,256},{257,0}},["thermometer-sun"]={16898788660,{256,256},{257,0}},["switch-camera"]={16898787671,{256,256},{514,257}},club={16898619015,{256,256},{257,0}},["shield-plus"]={16898734564,{256,256},{257,514}},["alarm-check"]={16898612629,{256,256},{514,514}},["bell-minus"]={16898615428,{256,256},{257,0}},["log-in"]={16898674825,{256,256},{514,0}},["bot-message-square"]={16898616650,{256,256},{0,257}},drum={16898669562,{256,256},{257,514}},["arrow-up-z-a"]={16898614574,{256,256},{514,0}},sun={16898787671,{256,256},{0,0}},["layers-3"]={16898674182,{256,256},{0,0}},["zoom-out"]={16898791349,{256,256},{514,257}},["file-key"]={16898670171,{256,256},{257,514}},tractor={16898788908,{256,256},{0,514}},["school-2"]={16898733817,{256,256},{0,514}},["scissors-line-dashed"]={16898733817,{256,256},{257,514}},["text-select"]={16898788479,{256,256},{514,257}},["file-search"]={16898670367,{256,256},{0,514}},["unfold-vertical"]={16898789451,{256,256},{0,257}},["ticket-check"]={16898788660,{256,256},{0,514}},pyramid={16898732504,{256,256},{514,0}},["hard-drive"]={16898672954,{256,256},{0,0}},["user-cog-2"]={16898789825,{256,256},{0,0}},["refresh-cw-off"]={16898733146,{256,256},{0,0}},["external-link"]={16898669772,{256,256},{257,514}},["picture-in-picture-2"]={16898731683,{256,256},{257,514}},["file-x-2"]={16898670620,{256,256},{514,0}},["flower-2"]={16898671019,{256,256},{514,0}},["calendar-x"]={16898617053,{256,256},{514,514}},["user-round-check"]={16898789825,{256,256},{514,257}},["user-round"]={16898790047,{256,256},{514,0}},["link-2-off"]={16898674482,{256,256},{257,0}},["keyboard-music"]={16898673794,{256,256},{0,0}},["star-half"]={16898736597,{256,256},{514,514}},["user-x"]={16898790047,{256,256},{514,514}},["code-xml"]={16898619015,{256,256},{514,0}},["trending-up"]={16898789153,{256,256},{257,0}},mails={16898675359,{256,256},{257,0}},["brain-cog"]={16898616757,{256,256},{257,0}},tablet={16898788033,{256,256},{0,0}},["users-round"]={16898790259,{256,256},{0,257}},pi={16898731683,{256,256},{257,257}},trash={16898789012,{256,256},{514,0}},dock={16898669433,{256,256},{257,0}},["hdmi-port"]={16898672954,{256,256},{257,257}},braces={16898616650,{256,256},{257,514}},["case-upper"]={16898617249,{256,256},{514,514}},["move-3d"]={16898729572,{256,256},{257,0}},wallet={16898790615,{256,256},{514,514}},croissant={16898668482,{256,256},{514,0}},["monitor-speaker"]={16898729141,{256,256},{0,257}},waves={16898790791,{256,256},{257,514}},barcode={16898615143,{256,256},{514,514}},lock={16898674825,{256,256},{0,257}},["wheat-off"]={16898790996,{256,256},{257,257}},bed={16898615374,{256,256},{257,257}},quote={16898732504,{256,256},{0,514}},divide={16898669271,{256,256},{257,514}},grape={16898672599,{256,256},{514,514}},["play-square"]={16898731919,{256,256},{257,257}},["party-popper"]={16898731301,{256,256},{257,257}},["file-video"]={16898670469,{256,256},{514,514}},university={16898789451,{256,256},{257,257}},["user-circle-2"]={16898789644,{256,256},{257,514}},truck={16898789153,{256,256},{514,257}},box={16898616650,{256,256},{0,514}},["calendar-range"]={16898617053,{256,256},{0,514}},subscript={16898736967,{256,256},{514,0}},["zap-off"]={16898791349,{256,256},{514,0}},["square-check-big"]={16898735664,{256,256},{257,514}},["wand-sparkles"]={16898790791,{256,256},{0,257}},["square-chevron-up"]={16898735845,{256,256},{514,0}},["circle-ellipsis"]={16898617884,{256,256},{0,514}},["laptop-minimal"]={16898673999,{256,256},{514,0}},["radio-receiver"]={16898732665,{256,256},{257,0}},sofa={16898735175,{256,256},{514,0}},["square-asterisk"]={16898735664,{256,256},{0,514}},wine={16898791187,{256,256},{0,257}},cookie={16898619423,{256,256},{0,0}},["message-square-more"]={16898675863,{256,256},{514,257}},clapperboard={16898618228,{256,256},{257,0}},euro={16898669772,{256,256},{0,514}},["dice-3"]={16898669042,{256,256},{257,257}},["heart-off"]={16898673115,{256,256},{257,514}},["clipboard-minus"]={16898618228,{256,256},{514,257}},info={16898673523,{256,256},{257,257}},["move-horizontal"]={16898729572,{256,256},{257,514}},["file-sliders"]={16898670367,{256,256},{257,514}},frown={16898672004,{256,256},{0,0}},["cloud-hail"]={16898618763,{256,256},{0,514}},["cup-soda"]={16898668755,{256,256},{0,0}},["cable-car"]={16898616879,{256,256},{257,514}},["lock-keyhole"]={16898674825,{256,256},{0,0}},sword={16898787671,{256,256},{257,514}},play={16898731919,{256,256},{0,514}},["laptop-2"]={16898673999,{256,256},{0,257}},earth={16898669689,{256,256},{257,257}},slice={16898735040,{256,256},{257,0}},["land-plot"]={16898673794,{256,256},{514,514}},milk={16898728659,{256,256},{257,514}},["circle-user"]={16898618049,{256,256},{0,514}},["align-left"]={16898613353,{256,256},{514,514}},["circle-slash"]={16898618049,{256,256},{0,257}},contact={16898619347,{256,256},{514,257}},["rotate-cw-square"]={16898733415,{256,256},{0,257}},atom={16898614574,{256,256},{514,514}},["package-x"]={16898730641,{256,256},{0,257}},["bed-double"]={16898615374,{256,256},{0,257}},anchor={16898613613,{256,256},{0,514}},["circle-dot"]={16898617884,{256,256},{257,257}},["git-commit-horizontal"]={16898672316,{256,256},{514,0}},["git-commit-vertical"]={16898672316,{256,256},{257,257}},["message-circle-code"]={16898675673,{256,256},{514,514}},["folder-git-2"]={16898671139,{256,256},{257,514}},["message-square-code"]={16898675863,{256,256},{257,0}},["mail-plus"]={16898675156,{256,256},{514,0}},["diamond-percent"]={16898669042,{256,256},{0,0}},["message-circle-heart"]={16898675752,{256,256},{257,0}},["arrow-big-left-dash"]={16898613777,{256,256},{514,0}},["circle-arrow-out-down-left"]={16898617705,{256,256},{514,257}},dumbbell={16898669689,{256,256},{0,0}},["file-music"]={16898670241,{256,256},{257,257}},["alert-triangle"]={16898613044,{256,256},{0,257}},["chevrons-right-left"]={16898617626,{256,256},{257,257}},scale={16898733674,{256,256},{257,257}},eraser={16898669772,{256,256},{257,257}},["flashlight-off"]={16898670919,{256,256},{514,0}},["panel-top-open"]={16898731166,{256,256},{257,0}},["cloud-lightning"]={16898618763,{256,256},{514,257}},ungroup={16898789451,{256,256},{514,0}},notebook={16898730298,{256,256},{0,257}},["power-square"]={16898732262,{256,256},{0,514}},sprout={16898735593,{256,256},{0,0}},["square-menu"]={16898736072,{256,256},{514,514}},["mic-vocal"]={16898728659,{256,256},{257,0}},["monitor-smartphone"]={16898729141,{256,256},{257,0}},laptop={16898673999,{256,256},{257,257}},["scan-line"]={16898733817,{256,256},{0,0}},["clock-4"]={16898618583,{256,256},{514,0}},["square-arrow-up"]={16898735664,{256,256},{257,257}},copyright={16898668288,{256,256},{0,0}},["monitor-up"]={16898729141,{256,256},{257,257}},["unlock-keyhole"]={16898789451,{256,256},{257,514}},usb={16898789644,{256,256},{514,0}},rocket={16898733317,{256,256},{0,514}},["arrow-down-to-line"]={16898614020,{256,256},{0,514}},["book-plus"]={16898616322,{256,256},{514,257}},["refresh-ccw"]={16898733036,{256,256},{514,514}},["venetian-mask"]={16898790439,{256,256},{257,0}},["calendar-check-2"]={16898616953,{256,256},{514,0}},["arrow-down-square"]={16898614020,{256,256},{514,0}},spline={16898735455,{256,256},{257,257}},mail={16898675156,{256,256},{514,514}},["git-pull-request-create-arrow"]={16898672450,{256,256},{514,0}},["library-square"]={16898674337,{256,256},{514,0}},["circle-check"]={16898617803,{256,256},{257,257}},["square-arrow-up-right"]={16898735664,{256,256},{514,0}},["book-text"]={16898616322,{256,256},{257,514}},user={16898790259,{256,256},{0,0}},["file-key-2"]={16898670171,{256,256},{514,257}},["gallery-horizontal"]={16898672004,{256,256},{0,514}},["circle-chevron-right"]={16898617803,{256,256},{257,514}},["timer-off"]={16898788789,{256,256},{514,0}},["arrow-big-right-dash"]={16898613777,{256,256},{0,514}},["wallet-2"]={16898790615,{256,256},{0,514}},cloud={16898618899,{256,256},{257,514}},triangle={16898789153,{256,256},{257,257}},backpack={16898614755,{256,256},{514,257}},lamp={16898673794,{256,256},{257,514}},flower={16898671019,{256,256},{257,257}},youtube={16898791349,{256,256},{0,257}},["upload-cloud"]={16898789644,{256,256},{257,0}},lasso={16898673999,{256,256},{514,257}},["arrow-down-right"]={16898614020,{256,256},{0,257}},sailboat={16898733534,{256,256},{0,514}},receipt={16898732855,{256,256},{514,514}},["bell-ring"]={16898615428,{256,256},{257,257}},["heart-crack"]={16898673115,{256,256},{0,514}},["tree-deciduous"]={16898789012,{256,256},{257,257}},["fire-extinguisher"]={16898670775,{256,256},{0,257}},["baggage-claim"]={16898615022,{256,256},{514,257}},["image-off"]={16898673447,{256,256},{257,0}},["arrow-left-to-line"]={16898614166,{256,256},{0,514}},["layout-grid"]={16898674182,{256,256},{514,0}},["pi-square"]={16898731683,{256,256},{514,0}},["clock-3"]={16898618583,{256,256},{0,257}},["square-chevron-right"]={16898735845,{256,256},{0,257}},navigation={16898730065,{256,256},{257,257}},["filter-x"]={16898670620,{256,256},{514,514}},["bar-chart-3"]={16898615143,{256,256},{0,257}},["map-pin"]={16898675359,{256,256},{514,0}},["arrow-down-right-from-circle"]={16898614020,{256,256},{0,0}},["shopping-bag"]={16898734664,{256,256},{0,514}},["chevron-right"]={16898617509,{256,256},{0,514}},["tally-1"]={16898788033,{256,256},{257,257}},ampersand={16898613613,{256,256},{514,0}},["arrow-up-from-line"]={16898614410,{256,256},{257,0}},["shopping-cart"]={16898734664,{256,256},{257,514}},["user-minus-2"]={16898789825,{256,256},{0,257}},vote={16898790615,{256,256},{257,257}},["alarm-smoke"]={16898612819,{256,256},{257,514}},["file-line-chart"]={16898670171,{256,256},{514,514}},["file-input"]={16898670171,{256,256},{514,0}},["clock-8"]={16898618583,{256,256},{257,514}},["server-cog"]={16898734242,{256,256},{257,514}},["cloud-cog"]={16898618763,{256,256},{257,0}},blend={16898615570,{256,256},{514,257}},["search-x"]={16898734242,{256,256},{0,0}},["radio-tower"]={16898732665,{256,256},{0,257}},["list-tree"]={16898674572,{256,256},{257,514}},droplet={16898669562,{256,256},{0,514}},["panel-right-open"]={16898731024,{256,256},{0,514}},eye={16898669897,{256,256},{0,0}},siren={16898734905,{256,256},{257,257}},star={16898736776,{256,256},{257,0}},banana={16898615022,{256,256},{514,514}},["panel-top"]={16898731166,{256,256},{0,257}},donut={16898669433,{256,256},{257,257}},telescope={16898788248,{256,256},{0,257}},["circle-equal"]={16898617884,{256,256},{514,257}},["arrow-up-right"]={16898614410,{256,256},{514,514}},calculator={16898616953,{256,256},{0,257}},magnet={16898674825,{256,256},{514,514}},crown={16898668482,{256,256},{257,514}},subtitles={16898736967,{256,256},{257,257}},["brick-wall"]={16898616757,{256,256},{514,0}},["message-circle-dashed"]={16898675752,{256,256},{0,0}},["leafy-green"]={16898674337,{256,256},{257,0}},["message-square-dot"]={16898675863,{256,256},{257,257}},["arrow-down-a-z"]={16898613869,{256,256},{0,257}},copyleft={16898619423,{256,256},{514,514}},["monitor-play"]={16898729141,{256,256},{0,0}},["text-cursor"]={16898788479,{256,256},{514,0}},["minimize-2"]={16898728659,{256,256},{514,514}},disc={16898669271,{256,256},{257,257}},locate={16898674684,{256,256},{257,514}},cone={16898619347,{256,256},{0,257}},["heading-1"]={16898672954,{256,256},{0,514}},["file-image"]={16898670171,{256,256},{0,257}},sparkles={16898735175,{256,256},{514,514}},palette={16898730641,{256,256},{514,514}},["user-plus-2"]={16898789825,{256,256},{257,257}},["gallery-thumbnails"]={16898672004,{256,256},{514,257}},["book-up"]={16898616524,{256,256},{257,0}},cpu={16898668482,{256,256},{0,0}},["split-square-horizontal"]={16898735455,{256,256},{0,514}},["thumbs-down"]={16898788660,{256,256},{514,0}},merge={16898675673,{256,256},{257,514}},["circle-dashed"]={16898617884,{256,256},{0,0}},["bar-chart-big"]={16898615143,{256,256},{257,257}},["test-tubes"]={16898788479,{256,256},{257,0}},hospital={16898673358,{256,256},{257,0}},haze={16898672954,{256,256},{514,0}},plus={16898732061,{256,256},{514,0}},["align-vertical-space-around"]={16898613613,{256,256},{0,0}},["key-square"]={16898673616,{256,256},{257,514}},palmtree={16898730821,{256,256},{0,0}},["file-audio"]={16898669984,{256,256},{0,257}},kanban={16898673616,{256,256},{0,514}},["sliders-vertical"]={16898735040,{256,256},{514,0}},apple={16898613699,{256,256},{257,257}},["wine-off"]={16898791187,{256,256},{257,0}},["check-circle"]={16898617325,{256,256},{257,514}},cuboid={16898668482,{256,256},{514,514}},["square-code"]={16898735845,{256,256},{257,257}},["bug-off"]={16898616879,{256,256},{0,0}},["circle-arrow-out-up-left"]={16898617705,{256,256},{514,514}},["corner-right-down"]={16898668288,{256,256},{0,514}},["plug-zap-2"]={16898731919,{256,256},{257,514}},["heading-2"]={16898672954,{256,256},{514,257}},["square-activity"]={16898735593,{256,256},{257,0}},["package-plus"]={16898730641,{256,256},{0,0}},["cigarette-off"]={16898617705,{256,256},{257,0}},["align-vertical-justify-start"]={16898613509,{256,256},{514,514}},["power-off"]={16898732262,{256,256},{257,257}},["undo-2"]={16898789303,{256,256},{257,514}},router={16898733415,{256,256},{514,257}},["tower-control"]={16898788908,{256,256},{514,0}},["git-branch"]={16898672316,{256,256},{0,257}},shovel={16898734664,{256,256},{514,514}},share={16898734421,{256,256},{514,257}},["wallet-cards"]={16898790615,{256,256},{514,257}},["square-arrow-out-down-right"]={16898735593,{256,256},{257,514}},["circuit-board"]={16898618049,{256,256},{514,514}},shield={16898734664,{256,256},{257,0}},["bar-chart-2"]={16898615143,{256,256},{257,0}},["cloud-snow"]={16898618899,{256,256},{514,0}},["file-question"]={16898670367,{256,256},{0,257}},["arrow-big-up-dash"]={16898613777,{256,256},{257,514}},["folder-closed"]={16898671139,{256,256},{0,257}},["smartphone-nfc"]={16898735040,{256,256},{514,257}},network={16898730065,{256,256},{0,514}},["file-bar-chart"]={16898669984,{256,256},{257,514}},["user-round-x"]={16898790047,{256,256},{0,257}},["signal-low"]={16898734792,{256,256},{257,514}},["mail-question"]={16898675156,{256,256},{257,257}},["clipboard-plus"]={16898618392,{256,256},{257,0}},["file-minus"]={16898670241,{256,256},{514,0}},["list-end"]={16898674482,{256,256},{257,514}},torus={16898788908,{256,256},{0,0}},["arrow-down-left"]={16898613869,{256,256},{257,514}},["chevrons-right"]={16898617626,{256,256},{0,514}},["file-badge-2"]={16898669984,{256,256},{257,257}},["message-square-reply"]={16898728402,{256,256},{257,0}},["corner-down-right"]={16898668288,{256,256},{0,257}},["gauge-circle"]={16898672166,{256,256},{257,257}},["users-2"]={16898790259,{256,256},{257,0}},["lamp-wall-down"]={16898673794,{256,256},{0,514}},["square-bottom-dashed-scissors"]={16898735664,{256,256},{514,257}},["repeat"]={16898733146,{256,256},{257,514}},["ellipsis-vertical"]={16898669772,{256,256},{0,0}},snail={16898735175,{256,256},{257,0}},check={16898617411,{256,256},{257,0}},["square-parking"]={16898736237,{256,256},{514,0}},["align-horizontal-justify-end"]={16898613353,{256,256},{514,0}},["mail-search"]={16898675156,{256,256},{0,514}},["align-vertical-distribute-end"]={16898613509,{256,256},{257,257}},soup={16898735175,{256,256},{257,257}},airplay={16898612629,{256,256},{257,514}},pentagon={16898731419,{256,256},{514,514}},["rocking-chair"]={16898733317,{256,256},{514,257}},["between-horizontal-start"]={16898615428,{256,256},{257,514}},["monitor-x"]={16898729141,{256,256},{0,514}},["octagon-pause"]={16898730298,{256,256},{514,514}},["square-kanban"]={16898736072,{256,256},{0,514}},["square-pen"]={16898736237,{256,256},{257,257}},["rectangle-vertical"]={16898733036,{256,256},{0,257}},["panels-right-bottom"]={16898731166,{256,256},{257,257}},["gantt-chart"]={16898672166,{256,256},{514,0}},octagon={16898730417,{256,256},{257,0}},ticket={16898788789,{256,256},{0,257}},pocket={16898732061,{256,256},{0,514}},["link-2"]={16898674482,{256,256},{0,257}},["train-front"]={16898788908,{256,256},{514,514}},["spray-can"]={16898735455,{256,256},{514,514}},["arrow-up-0-1"]={16898614275,{256,256},{257,257}},album={16898612819,{256,256},{514,514}},replace={16898733317,{256,256},{0,0}},["move-right"]={16898729752,{256,256},{0,0}},["hand-helping"]={16898672829,{256,256},{0,257}},["list-collapse"]={16898674482,{256,256},{514,257}},gauge={16898672166,{256,256},{0,514}},store={16898736776,{256,256},{514,514}},["circle-arrow-down"]={16898617705,{256,256},{257,257}},["notebook-pen"]={16898730065,{256,256},{514,514}},["egg-fried"]={16898669689,{256,256},{514,257}},ligature={16898674337,{256,256},{514,257}},["sticky-note"]={16898736776,{256,256},{514,257}},["corner-right-up"]={16898668288,{256,256},{514,257}},["badge-help"]={16898614945,{256,256},{514,0}},["panel-top-inactive"]={16898731166,{256,256},{0,0}},["user-round-plus"]={16898790047,{256,256},{0,0}},["panel-left-close"]={16898730821,{256,256},{514,257}},rewind={16898733317,{256,256},{514,0}},fuel={16898672004,{256,256},{257,0}},["divide-circle"]={16898669271,{256,256},{0,514}},["square-arrow-out-up-right"]={16898735664,{256,256},{0,0}},["chevrons-down-up"]={16898617626,{256,256},{0,0}},["message-square-text"]={16898728402,{256,256},{514,0}},["user-round-search"]={16898790047,{256,256},{257,0}},scan={16898733817,{256,256},{514,0}},["monitor-down"]={16898728878,{256,256},{514,257}},["play-circle"]={16898731919,{256,256},{514,0}},["file-digit"]={16898670072,{256,256},{257,514}},slash={16898735040,{256,256},{0,0}},["split-square-vertical"]={16898735455,{256,256},{514,257}},aperture={16898613699,{256,256},{257,0}},["arrow-right-left"]={16898614275,{256,256},{0,0}},["helping-hand"]={16898673271,{256,256},{514,0}},["flask-conical-off"]={16898670919,{256,256},{0,514}},["circle-gauge"]={16898617884,{256,256},{514,514}},crosshair={16898668482,{256,256},{514,257}},["move-down-right"]={16898729572,{256,256},{0,514}},["text-search"]={16898788479,{256,256},{0,514}},["square-slash"]={16898736398,{256,256},{0,514}},sandwich={16898733534,{256,256},{257,514}},factory={16898669897,{256,256},{0,257}},["chef-hat"]={16898617411,{256,256},{0,257}},["arrow-down-to-dot"]={16898614020,{256,256},{257,257}},["image-plus"]={16898673447,{256,256},{0,257}},["file-archive"]={16898669984,{256,256},{0,0}},["signal-high"]={16898734792,{256,256},{514,257}},inbox={16898673447,{256,256},{257,514}},["flip-horizontal-2"]={16898670919,{256,256},{514,514}},["book-type"]={16898616322,{256,256},{514,514}},["file-signature"]={16898670367,{256,256},{514,257}},["align-horizontal-space-between"]={16898613353,{256,256},{514,257}},["bookmark-minus"]={16898616524,{256,256},{514,257}},["calendar-check"]={16898616953,{256,256},{257,257}},["database-zap"]={16898668755,{256,256},{257,257}},droplets={16898669562,{256,256},{514,257}},boxes={16898616650,{256,256},{514,257}},["bell-electric"]={16898615428,{256,256},{0,0}},["bar-chart"]={16898615143,{256,256},{257,514}},["layout-list"]={16898674182,{256,256},{257,257}},link={16898674482,{256,256},{514,0}},["download-cloud"]={16898669433,{256,256},{514,514}},["alarm-clock-plus"]={16898612819,{256,256},{514,0}},["circle-dollar-sign"]={16898617884,{256,256},{0,257}},["activity-square"]={16898612629,{256,256},{257,257}},["arrow-up-square"]={16898614574,{256,256},{0,0}},["receipt-pound-sterling"]={16898732855,{256,256},{257,257}},grab={16898672599,{256,256},{514,257}},["align-center-horizontal"]={16898613044,{256,256},{514,0}},undo={16898789451,{256,256},{0,0}},ratio={16898732665,{256,256},{514,514}},minimize={16898728878,{256,256},{0,0}},["user-square-2"]={16898790047,{256,256},{0,514}},heading={16898673115,{256,256},{0,257}},["panel-top-close"]={16898731024,{256,256},{257,514}},["grip-horizontal"]={16898672700,{256,256},{0,257}},["boom-box"]={16898616650,{256,256},{257,0}},package={16898730641,{256,256},{514,0}},["user-round-minus"]={16898789825,{256,256},{514,514}},["file-audio-2"]={16898669984,{256,256},{257,0}},["align-end-horizontal"]={16898613044,{256,256},{514,257}},mountain={16898729337,{256,256},{514,0}},["arrow-down-left-square"]={16898613869,{256,256},{514,257}},["folder-kanban"]={16898671263,{256,256},{0,257}},["octagon-x"]={16898730417,{256,256},{0,0}},languages={16898673999,{256,256},{257,0}},["file-json-2"]={16898670171,{256,256},{257,257}},["alarm-clock-check"]={16898612819,{256,256},{0,0}},["refresh-cw"]={16898733146,{256,256},{257,0}},medal={16898675673,{256,256},{0,0}},["beer-off"]={16898615374,{256,256},{514,257}},["search-code"]={16898734065,{256,256},{257,514}},["square-parking-off"]={16898736237,{256,256},{0,257}},["notebook-text"]={16898730298,{256,256},{257,0}},["arrow-right-to-line"]={16898614275,{256,256},{0,257}},["ticket-minus"]={16898788660,{256,256},{514,257}},["test-tube-diagonal"]={16898788248,{256,256},{514,514}},["rows-4"]={16898733534,{256,256},{0,0}},["pencil-line"]={16898731419,{256,256},{0,514}},["door-open"]={16898669433,{256,256},{514,257}},["arrow-down-circle"]={16898613869,{256,256},{514,0}},["pen-line"]={16898731419,{256,256},{257,0}},file={16898670620,{256,256},{0,514}},["git-compare"]={16898672316,{256,256},{514,257}},["pocket-knife"]={16898732061,{256,256},{257,257}},["book-copy"]={16898616080,{256,256},{0,257}},["panel-left-inactive"]={16898730821,{256,256},{514,514}},["car-front"]={16898617249,{256,256},{257,0}},["align-start-horizontal"]={16898613509,{256,256},{257,0}},["reply-all"]={16898733317,{256,256},{257,0}},["cloud-moon-rain"]={16898618763,{256,256},{257,514}},["clipboard-type"]={16898618392,{256,256},{514,0}},["contact-2"]={16898619347,{256,256},{257,257}},["list-todo"]={16898674572,{256,256},{514,257}},tablets={16898788033,{256,256},{257,0}},["pie-chart"]={16898731819,{256,256},{0,0}},["list-start"]={16898674572,{256,256},{0,514}},milestone={16898728659,{256,256},{0,514}},["a-large-small"]={16898612629,{256,256},{0,257}},ship={16898734664,{256,256},{514,0}},["percent-circle"]={16898731539,{256,256},{0,0}},radiation={16898732504,{256,256},{514,514}},["code-2"]={16898619015,{256,256},{0,257}},["tablet-smartphone"]={16898787819,{256,256},{514,514}},["phone-forwarded"]={16898731539,{256,256},{514,257}},["gallery-vertical"]={16898672004,{256,256},{514,514}},["arrow-right-from-line"]={16898614166,{256,256},{514,514}},webcam={16898790996,{256,256},{0,0}},["square-power"]={16898736398,{256,256},{257,0}},["circle-help"]={16898617944,{256,256},{0,0}},["bring-to-front"]={16898616757,{256,256},{257,514}},archive={16898613699,{256,256},{257,514}},figma={16898669897,{256,256},{514,514}},school={16898733817,{256,256},{514,257}},download={16898669562,{256,256},{0,0}},piano={16898731683,{256,256},{0,514}},["line-chart"]={16898674482,{256,256},{0,0}},folders={16898671684,{256,256},{0,257}},["mail-warning"]={16898675156,{256,256},{514,257}},vault={16898790259,{256,256},{514,514}},["pause-circle"]={16898731301,{256,256},{0,514}},["mic-2"]={16898728402,{256,256},{514,514}},["chevrons-left-right"]={16898617626,{256,256},{0,257}},redo={16898733036,{256,256},{514,257}},["file-lock"]={16898670241,{256,256},{257,0}},radar={16898732504,{256,256},{257,514}},["circle-fading-plus"]={16898617884,{256,256},{257,514}},workflow={16898791187,{256,256},{514,0}},["undo-dot"]={16898789303,{256,256},{514,514}},target={16898788248,{256,256},{257,0}},["corner-left-down"]={16898668288,{256,256},{514,0}},["indent-increase"]={16898673523,{256,256},{0,0}},drama={16898669562,{256,256},{0,257}},["arrow-down-up"]={16898614020,{256,256},{514,257}},baseline={16898615240,{256,256},{0,0}},martini={16898675359,{256,256},{514,257}},contrast={16898619347,{256,256},{514,514}},["shield-ban"]={16898734564,{256,256},{257,0}},syringe={16898787819,{256,256},{0,0}},["chevron-left-circle"]={16898617509,{256,256},{0,0}},["book-check"]={16898616080,{256,256},{257,0}},["nut-off"]={16898730298,{256,256},{0,514}},["book-lock"]={16898616322,{256,256},{0,0}},["panel-right-inactive"]={16898731024,{256,256},{257,257}},["briefcase-medical"]={16898616757,{256,256},{0,514}},bookmark={16898616650,{256,256},{0,0}},["heading-5"]={16898673115,{256,256},{0,0}},["align-vertical-justify-end"]={16898613509,{256,256},{257,514}},["hop-off"]={16898673271,{256,256},{514,514}},warehouse={16898790791,{256,256},{257,257}},["plus-square"]={16898732061,{256,256},{0,257}},["drafting-compass"]={16898669562,{256,256},{257,0}},["save-all"]={16898733674,{256,256},{257,0}},["plus-circle"]={16898732061,{256,256},{257,0}},["square-sigma"]={16898736398,{256,256},{257,257}},["clipboard-signature"]={16898618392,{256,256},{0,257}},["fold-horizontal"]={16898671019,{256,256},{514,257}},["notepad-text-dashed"]={16898730298,{256,256},{514,0}},["glass-water"]={16898672599,{256,256},{0,0}},["book-headphones"]={16898616080,{256,256},{0,514}},["credit-card"]={16898668482,{256,256},{0,257}},["message-circle"]={16898675863,{256,256},{0,0}},["square-pilcrow"]={16898736237,{256,256},{257,514}},radical={16898732665,{256,256},{0,0}},["tally-3"]={16898788033,{256,256},{514,257}},["panel-bottom-open"]={16898730821,{256,256},{257,257}},["kanban-square-dashed"]={16898673616,{256,256},{514,0}},["book-audio"]={16898616080,{256,256},{0,0}},["file-search-2"]={16898670367,{256,256},{257,257}},["receipt-russian-ruble"]={16898732855,{256,256},{0,514}},["square-arrow-up-left"]={16898735664,{256,256},{0,257}},["locate-fixed"]={16898674684,{256,256},{0,514}},["clock-9"]={16898618583,{256,256},{514,514}},pen={16898731419,{256,256},{257,257}},["navigation-2"]={16898730065,{256,256},{0,257}},["candy-cane"]={16898617146,{256,256},{257,257}},["book-open"]={16898616322,{256,256},{0,514}},["user-check-2"]={16898789644,{256,256},{0,514}},["gamepad-2"]={16898672166,{256,256},{0,0}},["badge-info"]={16898614945,{256,256},{0,514}},wheat={16898790996,{256,256},{0,514}},["roller-coaster"]={16898733317,{256,256},{257,514}},["arrow-down-right-square"]={16898614020,{256,256},{257,0}},["shield-minus"]={16898734564,{256,256},{0,514}},thermometer={16898788660,{256,256},{0,257}},dessert={16898668755,{256,256},{257,514}},eclipse={16898669689,{256,256},{0,514}},church={16898617705,{256,256},{0,0}},combine={16898619182,{256,256},{0,514}},cylinder={16898668755,{256,256},{0,257}},["badge-japanese-yen"]={16898614945,{256,256},{514,257}},["calendar-plus-2"]={16898617053,{256,256},{514,0}},["receipt-text"]={16898732855,{256,256},{257,514}},film={16898670620,{256,256},{257,514}},["book-down"]={16898616080,{256,256},{257,257}},asterisk={16898614574,{256,256},{514,257}},cable={16898616879,{256,256},{514,514}},["file-output"]={16898670241,{256,256},{0,514}},["disc-album"]={16898669271,{256,256},{514,0}},["percent-square"]={16898731539,{256,256},{0,257}},["arrow-down-0-1"]={16898613869,{256,256},{0,0}},captions={16898617249,{256,256},{0,0}},diameter={16898668755,{256,256},{514,514}},bone={16898615799,{256,256},{257,514}},["umbrella-off"]={16898789303,{256,256},{257,257}},["badge-alert"]={16898614755,{256,256},{257,514}},flashlight={16898670919,{256,256},{257,257}},["folder-pen"]={16898671463,{256,256},{0,0}},cross={16898668482,{256,256},{0,514}},["badge-dollar-sign"]={16898614945,{256,256},{257,0}},["ice-cream-bowl"]={16898673358,{256,256},{0,514}},worm={16898791187,{256,256},{257,257}},["square-arrow-down-left"]={16898735593,{256,256},{0,257}},["share-2"]={16898734421,{256,256},{0,514}},["circle-arrow-out-down-right"]={16898617705,{256,256},{257,514}},["ear-off"]={16898669689,{256,256},{257,0}},wifi={16898790996,{256,256},{514,514}},["message-square-off"]={16898675863,{256,256},{257,514}},["tv-2"]={16898789153,{256,256},{514,514}},fish={16898670775,{256,256},{0,514}},sliders={16898735040,{256,256},{257,257}},["stretch-horizontal"]={16898736967,{256,256},{0,0}},currency={16898668755,{256,256},{257,0}},coffee={16898619015,{256,256},{257,514}},["message-circle-reply"]={16898675752,{256,256},{514,257}},route={16898733415,{256,256},{0,514}},["triangle-right"]={16898789153,{256,256},{514,0}},["folder-clock"]={16898671139,{256,256},{257,0}},["circle-off"]={16898617944,{256,256},{0,257}},["message-square-plus"]={16898675863,{256,256},{514,514}},type={16898789303,{256,256},{514,0}},webhook={16898790996,{256,256},{0,257}},["candlestick-chart"]={16898617146,{256,256},{514,0}},phone={16898731683,{256,256},{0,257}},["package-2"]={16898730417,{256,256},{0,514}},["chevrons-left"]={16898617626,{256,256},{514,0}},["pointer-off"]={16898732061,{256,256},{257,514}},turtle={16898789153,{256,256},{257,514}},camera={16898617146,{256,256},{0,257}},["thermometer-snowflake"]={16898788660,{256,256},{0,0}},clipboard={16898618392,{256,256},{0,514}},["send-horizontal"]={16898734242,{256,256},{0,257}},["bluetooth-searching"]={16898615799,{256,256},{0,257}},["arrow-up-to-line"]={16898614574,{256,256},{257,0}},["wrap-text"]={16898791187,{256,256},{0,514}},["file-check-2"]={16898670072,{256,256},{0,0}},["badge-percent"]={16898614945,{256,256},{514,514}},shuffle={16898734792,{256,256},{514,0}},refrigerator={16898733146,{256,256},{0,257}},["rows-3"]={16898733415,{256,256},{514,514}},sigma={16898734792,{256,256},{0,514}},["milk-off"]={16898728659,{256,256},{514,257}},["file-check"]={16898670072,{256,256},{257,0}},["pin-off"]={16898731819,{256,256},{0,514}},["clock-1"]={16898618392,{256,256},{514,257}},["file-heart"]={16898670171,{256,256},{257,0}},beaker={16898615240,{256,256},{514,514}},space={16898735175,{256,256},{0,514}},users={16898790259,{256,256},{514,0}},["shield-question"]={16898734564,{256,256},{514,514}},["arrow-up-circle"]={16898614275,{256,256},{257,514}},["corner-up-left"]={16898668288,{256,256},{257,514}},["clock-6"]={16898618583,{256,256},{0,514}},["layout-dashboard"]={16898674182,{256,256},{0,257}},["key-round"]={16898673616,{256,256},{514,257}},headphones={16898673115,{256,256},{514,0}},tv={16898789303,{256,256},{0,0}},["brain-circuit"]={16898616757,{256,256},{0,0}},["bar-chart-horizontal-big"]={16898615143,{256,256},{0,514}},rss={16898733534,{256,256},{0,257}},["file-stack"]={16898670469,{256,256},{0,0}},["at-sign"]={16898614574,{256,256},{257,514}},code={16898619015,{256,256},{257,257}},["calendar-minus"]={16898617053,{256,256},{257,0}},music={16898730065,{256,256},{0,0}},handshake={16898672829,{256,256},{514,257}},["graduation-cap"]={16898672599,{256,256},{257,514}},tornado={16898788789,{256,256},{514,514}},["copy-plus"]={16898619423,{256,256},{257,257}},stamp={16898736597,{256,256},{257,514}},cherry={16898617411,{256,256},{514,0}},shrink={16898734792,{256,256},{257,0}},["circle-arrow-out-up-right"]={16898617803,{256,256},{0,0}},meh={16898675673,{256,256},{514,0}},["search-check"]={16898734065,{256,256},{514,257}},crop={16898668482,{256,256},{257,257}},["columns-2"]={16898619182,{256,256},{257,0}},["mouse-pointer-square"]={16898729337,{256,256},{257,514}},["indent-decrease"]={16898673447,{256,256},{514,514}},["align-center-vertical"]={16898613044,{256,256},{257,257}},["wand-2"]={16898790791,{256,256},{257,0}},anvil={16898613699,{256,256},{0,0}},["align-start-vertical"]={16898613509,{256,256},{0,257}},["cloud-fog"]={16898618763,{256,256},{257,257}},accessibility={16898612629,{256,256},{514,0}},layers={16898674182,{256,256},{257,0}},["percent-diamond"]={16898731539,{256,256},{257,0}},["package-check"]={16898730417,{256,256},{514,257}},["chevron-first"]={16898617411,{256,256},{257,514}},pencil={16898731419,{256,256},{257,514}},["database-backup"]={16898668755,{256,256},{514,0}},["list-x"]={16898674684,{256,256},{0,0}},shapes={16898734421,{256,256},{257,257}},["move-down"]={16898729572,{256,256},{514,257}},["corner-up-right"]={16898668288,{256,256},{514,514}},computer={16898619347,{256,256},{0,0}},pin={16898731819,{256,256},{514,257}},["phone-off"]={16898731683,{256,256},{0,0}},["clipboard-x"]={16898618392,{256,256},{257,257}},fullscreen={16898672004,{256,256},{0,257}},["align-horizontal-distribute-start"]={16898613353,{256,256},{257,0}},["redo-dot"]={16898733036,{256,256},{0,514}},["cloud-moon"]={16898618763,{256,256},{514,514}},["stretch-vertical"]={16898736967,{256,256},{257,0}},["message-square-warning"]={16898728402,{256,256},{257,257}},["file-plus"]={16898670367,{256,256},{257,0}},["git-pull-request-arrow"]={16898672450,{256,256},{257,0}},guitar={16898672700,{256,256},{514,257}},tangent={16898788248,{256,256},{0,0}},["bell-dot"]={16898615374,{256,256},{514,514}},["panel-bottom"]={16898730821,{256,256},{0,514}},["flame-kindling"]={16898670919,{256,256},{257,0}},["table-2"]={16898787819,{256,256},{257,0}},["align-horizontal-space-around"]={16898613353,{256,256},{0,514}},server={16898734421,{256,256},{257,0}},["briefcase-business"]={16898616757,{256,256},{257,257}},diamond={16898669042,{256,256},{257,0}},blinds={16898615570,{256,256},{257,514}},weight={16898790996,{256,256},{514,0}},candy={16898617146,{256,256},{514,257}},["volume-1"]={16898790615,{256,256},{0,0}},["table-properties"]={16898787819,{256,256},{0,514}},["git-fork"]={16898672316,{256,256},{257,514}},recycle={16898733036,{256,256},{514,0}},["mountain-snow"]={16898729337,{256,256},{0,257}},luggage={16898674825,{256,256},{514,257}},["divide-square"]={16898669271,{256,256},{514,257}},["folder-minus"]={16898671263,{256,256},{0,514}},["phone-outgoing"]={16898731683,{256,256},{257,0}},["smartphone-charging"]={16898735040,{256,256},{0,514}},banknote={16898615143,{256,256},{0,0}},["train-track"]={16898789012,{256,256},{0,0}},["folder-up"]={16898671463,{256,256},{514,514}},["circle-percent"]={16898617944,{256,256},{514,257}},["bell-plus"]={16898615428,{256,256},{514,0}},fan={16898669897,{256,256},{514,0}},["disc-2"]={16898669271,{256,256},{257,0}},["git-pull-request-draft"]={16898672450,{256,256},{0,514}},coins={16898619182,{256,256},{0,0}},["square-divide"]={16898736072,{256,256},{0,0}},scroll={16898734065,{256,256},{0,514}},["circle-arrow-right"]={16898617803,{256,256},{257,0}},["candy-off"]={16898617146,{256,256},{0,514}},["square-pi"]={16898736237,{256,256},{514,257}},["arrow-left-right"]={16898614166,{256,256},{514,0}},["lightbulb-off"]={16898674337,{256,256},{257,514}},["panels-top-left"]={16898731166,{256,256},{0,514}},["move-up-right"]={16898729752,{256,256},{0,257}},["message-square-share"]={16898728402,{256,256},{0,257}},annoyed={16898613613,{256,256},{257,514}},["test-tube"]={16898788479,{256,256},{0,0}},["user-circle"]={16898789644,{256,256},{514,514}},["cooking-pot"]={16898619423,{256,256},{257,0}},["case-lower"]={16898617249,{256,256},{514,257}},["alarm-clock-minus"]={16898612819,{256,256},{257,0}},["square-user"]={16898736597,{256,256},{0,257}},square={16898736597,{256,256},{257,257}},["mail-open"]={16898675156,{256,256},{0,257}},["square-function"]={16898736072,{256,256},{514,0}},["arrow-up-left-from-circle"]={16898614410,{256,256},{0,257}},variable={16898790259,{256,256},{257,514}},["arrow-up-right-square"]={16898614410,{256,256},{257,514}},["badge-indian-rupee"]={16898614945,{256,256},{257,257}}}}
    local Type = typeof or type
    local function CheckArgTypes(funcName: string, inputArgs: {any}, typeEntries: {[number]: {string}})
        for ArgIndex, TypeEntryArray in typeEntries do
            local ArgName = TypeEntryArray[1]
            local ExpectedType = TypeEntryArray[2]
            
            local InputArg = inputArgs[ArgIndex]
            local InputArgType = Type(InputArg)

            if InputArgType ~= ExpectedType then
                error(funcName .. ": Argument " .. ArgIndex .. " (" .. ArgName .. "): expected type `" .. ExpectedType .. "`, got `" .. InputArgType .. "`", 3)
            end
        end
    end

    local function TrimIconIdentifier(inputIconIdentifier: string): string
        return string.match(string.lower(inputIconIdentifier), "^%s*(.*)%s*$") :: string
    end

    local function ApplyToInstance(object: Instance, properties: {[string]: any}): Instance
        if properties then
            for Property, Value in properties do
                if Property ~= "Parent" then
                    object[Property] = Value
                end
            end

            if properties.Parent then
                object.Parent = properties.Parent
            end
        end

        return object
    end

    local Lucide = {}

    do
        local IconNames: {string} = {}
        local _, FirstIconIndex = next(Icons)
        FirstIconIndex = FirstIconIndex or {}

        for IconName in FirstIconIndex do
            table.insert(IconNames, IconName)
        end

        table.sort(IconNames)
        table.freeze(IconNames)
        Lucide.IconNames = IconNames
    end

    function Lucide.GetAsset(iconName: string, iconSize: number?)
        local IconSize = if iconSize == nil then 256 else iconSize

        CheckArgTypes("Lucide.GetAsset", {iconName, IconSize}, {
            [1] = {"iconName", "string"},
            [2] = {"iconSize", "number"},
        })

        local IconName = TrimIconIdentifier(iconName)

        if IconSize < 0 then
            IconSize = -IconSize
        end

        local RealSizeIndex = if IconSize <= 48 then "48px" else "256px"
        local IconIndexDict = Icons[RealSizeIndex]

        if not IconIndexDict then
            error("Lucide.GetAsset: Internal error: Failed to find icon index for specified size")
        end

        local RawAsset = IconIndexDict[IconName]
        if not RawAsset then
            error("Lucide.GetAsset: Failed to find icon by the name of \"" .. IconName .. "\" (@" .. RealSizeIndex .. "), perhaps a spelling mistake?", 2)
        end

        local Id = RawAsset[1]
        local RawImageRectSize = RawAsset[2]
        local RawImageRectOffset = RawAsset[3]

        if type(Id) ~= "number" or type(RawImageRectSize) ~= "table" or type(RawImageRectOffset) ~= "table" then
            error("Lucide.GetAsset: Internal error: Invalid auto-generated asset entry")
        end

        local Url = "rbxassetid://" .. Id
        local ImageRectSize = Vector2.new(RawImageRectSize[1], RawImageRectSize[2])
        local ImageRectOffset = Vector2.new(RawImageRectOffset[1], RawImageRectOffset[2])

        local Asset = {
            IconName = IconName,
            Id = Id,
            Url = Url,
            ImageRectSize = ImageRectSize,
            ImageRectOffset = ImageRectOffset,
        }

        return Asset
    end

    function Lucide.GetAllAssets(inputSize: number?): {Asset}
        local InputSize = if inputSize == nil then 256 else inputSize

        CheckArgTypes("Lucide.GetAllAssets", {InputSize}, {
            [1] = {"inputSize", "number"},
        })

        local Assets = {}

        for _, IconName in Lucide.IconNames do
            local Asset = Lucide.GetAsset(IconName, InputSize)
            if Asset then
                table.insert(Assets, Asset)
            end
        end

        return Assets
    end

    function Lucide.ImageLabel(iconName: string, imageSize: number?, propertyOverrides: {[string]: any}?): ImageLabel
        local ImageSize = if imageSize == nil then 256 else imageSize
        local PropertyOverrides = if propertyOverrides == nil then {} else propertyOverrides

        CheckArgTypes("Lucide.ImageLabel", {iconName, imageSize, propertyOverrides}, {
            [1] = {"iconName", "string"},
            [2] = {"imageSize", "number"},
            [3] = {"propertyOverrides", "table"}
        })

        local Asset = Lucide.GetAsset(iconName, ImageSize)

        local ImageLabel = ApplyToInstance(Instance.new("ImageLabel"), {
            Name = Asset.IconName,

            Size = UDim2.fromOffset(ImageSize, ImageSize),

            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = Asset.Url,
            ImageRectSize = Asset.ImageRectSize,
            ImageRectOffset = Asset.ImageRectOffset,
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit,
        })

        ApplyToInstance(ImageLabel, PropertyOverrides)

        return ImageLabel
    end

    table.freeze(Lucide)
    return Lucide
end)()

function Library:GetIcon(IconName: string)
    local Success, Icon = pcall(IconsModule.GetAsset, IconName)
    if not Success then
        return
    end
    return Icon
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
    end

    local CustomIcon = IsValidCustomIcon(IconName)
    if CustomIcon then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end

    local LucideIcon = Library:GetIcon(IconName)
    if LucideIcon then
        return LucideIcon
    end

    return nil
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        Instance[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 998,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Cursor
local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = CursorV,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor
    })
end

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )

    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:ResetCursorIcon()
    CursorCustomImage.Visible = false
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library:ChangeCursorIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library:ResetCursorIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    CursorCustomImage.Visible = true
    CursorCustomImage.Image = Icon.Url
    CursorCustomImage.ImageRectOffset = Icon.ImageRectOffset
    CursorCustomImage.ImageRectSize = Icon.ImageRectSize
end

function Library:ChangeCursorIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            if Callback then
                Library:SafeCallback(Callback)
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, 10000),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, 10000)
            )
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        ZIndex = 2,
        Parent = Frame,
    })
    local ShadowStroke = New("UIStroke", {
        Color = "DarkColor",
        Thickness = 1.5,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end

--// Deprecated \\--
function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    warn("Obsidian:MakeOutline is deprecated, please use Obsidian:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableLabel(Text: string)
    local Table = {}

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners, 
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Label,
        })
    )
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Label,
        })
    )
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        Label.Text = Text
    end

    function Table:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    return Table
end

function Library:AddDraggableButton(Text: string, Func, ExcludeScaling: boolean?)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners, 
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X * 2, Y * 2)
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    Library:AddOutline(Holder)

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)
    return Holder, Container
end

--// Watermark - Deprecated \\--
do
    local WatermarkLabel = Library:AddDraggableLabel("")
    WatermarkLabel:SetVisible(false)

    function Library:SetWatermark(Text: string)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetText(Text)
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetVisible(Visible)
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?,
    IgnoreCornerRadius: boolean?
)
    local Menu
    local ParentGui = Holder:FindFirstAncestorOfClass("ScreenGui")
    if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
        ParentGui = ScreenGui
    end

    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ParentGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ParentGui,
        })
    end
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Menu,
        })
    )

    New("UIStroke", {
        Color = "OutlineColor",
        Parent = Menu,
    })

    if IgnoreCornerRadius ~= true then
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            })
        )
    end

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end
        Menu.Visible = false

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})
table.insert(
    Library.Scales,
    New("UIScale", {
        Parent = TooltipLabel,
    })
)
New("UIStroke", {
    Color = "OutlineColor",
    Parent = TooltipLabel,
})
table.insert(
    Library.Corners,
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8)
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            -- or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        local ParentGui = HoverInstance:FindFirstAncestorOfClass("ScreenGui")
        if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
            ParentGui = ScreenGui
        end
        TooltipLabel.Parent = ParentGui

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            (Library.Toggled or Library.ActiveLoading)
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            -- and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true

    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")

function Library:SetIconModule(module)
    IconsModule = module

    -- Top ten fixes 🚀
    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Picker,
            })
        )

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,
            })

            local Checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })
            )
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, nil, true)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, Button in ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset((X + 9), (Y + 4))
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, KeyCode = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, KeyCode, NewModifiers)

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29, 18)

            -- Wait for an non modifier key --
            local Input
            local ActiveModifiers = {}

            local GetInput = nil; GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() ~= nil then
                    return true
                end

                if Input.KeyCode == Enum.KeyCode.Escape then
                    return false
                end

                local IsMod = IsModifierInput(Input)
                local KeyName
                if SpecialKeysInput[Input.UserInputType] ~= nil then
                    KeyName = SpecialKeysInput[Input.UserInputType]
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    if IsMod then
                        KeyName = ModifiersInput[Input.KeyCode]
                    else
                        KeyName = Input.KeyCode.Name
                    end
                end

                if KeyName then
                    if IsMod then
                        if KeyPicker.WhitelistedModifiers and #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.BlacklistedModifiers and table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                            return GetInput()
                        end
                    else
                        if KeyPicker.Whitelisted and #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.Blacklisted and table.find(KeyPicker.Blacklisted, KeyName) then
                            return GetInput()
                        end
                    end
                end

                return false
            end

            repeat
                task.wait()

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29, 18)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                -- Escape --
                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Handle modifier keys --
                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then
                                -- Add modifier to the key list --
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                -- Wait for another input --
                                if GetInput() then
                                    StopLoop = true
                                    break -- Invalid Input
                                end

                                -- Escape --
                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                -- Stop loop if its a normal key --
                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break -- Modifier is meant to be used as a normal key --
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end
                end

                break -- Input found, end loop
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType]
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            -- RunService.RenderStepped:Wait()
            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Holder,
            })
        )

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Position = UDim2.new(0, -1, 0, -1),
            Size = UDim2.new(1, 2, 1, 2),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HolderTransparency,
            })
        )

        --// Color Menu \\--
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1
        )
        ColorMenu.List.Padding = UDim.new(0, 8)
        ColorPicker.ColorMenu = ColorMenu

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ColorMenu.Menu,
        })

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorMenu.Menu,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = HueBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HueBox,
            })
        )

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = RgbBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = RgbBox,
            })
        )

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        ContextMenu.List.Padding = UDim.new(0, 6)
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)

                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// End \\--
        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            HolderStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider(Params)
        Params = Params or {}

        local Info = {}
        if typeof(Params) == "table" then
            Info.Visible = Params.Visible ~= false
            Info.Text = Params.Text
            Info.MarginTop = Params.MarginTop or Params.Margin or 0
            Info.MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Info.Visible = true
            Info.Text = Params
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            Visible = Info.Visible,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 6 + Info.MarginTop + Info.MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            Visible = Info.Visible,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, Info.MarginTop),
            PaddingBottom = UDim.new(0, Info.MarginBottom),
            Parent = Holder,
        })

        local Divider = {
            Holder = Holder,
            Text = Info.Text,
            MarginTop = Info.MarginTop,
            MarginBottom = Info.MarginBottom,
            Type = "Divider",
        }

        if Info.Text and typeof(Info.Text) == "string" then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Text = Info.Text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })

            local Left = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Parent = InnerHolder,
            })
            local Right = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0.5),
                Parent = InnerHolder,
            })

            function Divider:SetText(Text: string)
                Divider.Text = Text

                local Size = UDim2.new(0.5, -(Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X) // 2 + 10), 0, 2)

                TextLabel.Text = Text
                Left.Size = Size
                Right.Size = Size
            end

            Divider:SetText(Info.Text)
        else
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = InnerHolder,
            })
        end

        function Divider:SetVisible(Visible: boolean)
            Holder.Visible = Visible
            InnerHolder.Visible = Visible
            Groupbox:Resize()
        end

        Divider:SetVisible(Info.Visible)

        table.insert(Groupbox.Elements, Divider)
        return Divider
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible ~= false
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local _, Y =
                Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

            local Last = TextLabel.AbsoluteSize
            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible ~= false
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                Visible = true,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Base,
                })
            )

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.RedColor
                Library.Registry[SubButton.Base].TextColor3 = "RedColor"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible
            Holder.Visible = Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Button.Base].TextColor3 = "RedColor"
        end

        Button:UpdateColors()
        Button:SetVisible(Info.Visible)

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Variant = "Checkbox",
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
        )

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Variant = "Switch",
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        if typeof(Info) == "table" and (typeof(Info.VerifyValue) == "function" and Info.Finished ~= true) then
            Info.Finished = true
        end

        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Box,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Box,
            })
        )

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            if typeof(Info.VerifyValue) == "function" and (Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true) then
                Text = Input.EmptyReset
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    if Input.ClearTextOnBlur then
                        Box.Text = Input.Value
                    end

                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end
                
                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value
        if typeof(Info.VerifyValue) == "function" and (Input.Default ~= Input.EmptyReset and Info.VerifyValue(Input.Default) ~= true) then
            Input:SetValue(Input.EmptyReset)
            Input.Default = Input.EmptyReset
        end
        
        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)
        if (Info.Rounding == 0 or Info.Rounding ~= Info.Rounding) then
            Info.Rounding = 1
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Alignment = Info.Alignment,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or 33),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = Slider.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 15),
            Text = "",
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            TextXAlignment = Enum.TextXAlignment[Slider.Alignment or "Center"],
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = 2,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "DarkColor",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Bar,
            })
        )

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Fill,
            })
        )

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = false
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                local NewValue = Slider.Min + ((Slider.Max - Slider.Min) * Scale)
                Slider.Value = math.clamp(Round(NewValue, Slider.Rounding), Slider.Min, Slider.Max)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            Library:SafeCallback(Slider.Changed, Slider.Value)

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = true
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end
        end)

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            Multi = Info.Multi,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

            Tooltip = Info.Tooltip,
            Tooltips = Info.Tooltips,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 39 or 21),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            ZIndex = 3,
            Parent = Holder,
        })

        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = Display,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Display,
        })

        if Library.CornerRadiusDropdown == true then
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Display,
                })
            )
        end

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = Display,
        })

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = Display,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })
        end

        local MenuTable = Library:AddContextMenu(
            Display,
            function()
                return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, 0)
            end,
            function()
                return { 0.5, Display.AbsoluteSize.Y + 1.5 }
            end,
            2,
            function(Active: boolean)
                Display.TextTransparency = (Active and SearchBox) and 1 or 0
                ArrowImage.ImageTransparency = Active and 0 or 0.5
                ArrowImage.Rotation = Active and 180 or 0
                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end
            end,
            true
        )
        Dropdown.Menu = MenuTable

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp((Count or GetTableSize(Dropdown.Values)) * 21, 0, Info.MaxVisibleDropdownItems * 21)

            MenuTable:SetSize(function()
                return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, Y)
            end)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""

            if Info.Multi then
                for _, Value in Dropdown.Values do
                    if Dropdown.Value[Value] then
                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            if #Str > 25 then
                Str = Str:sub(1, 22) .. "..."
            end

            Display.Text = (Str == "" and "---" or Str)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}

                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        local Buttons = {}
        local Icons = {}

        local function CreateIconLabel(Button, IconId: string)
            return New("ImageLabel", {
                BackgroundTransparency = 1;
                Size = UDim2.fromOffset(17, 17);
                AnchorPoint = Vector2.new(0, 0.5);
                Position = UDim2.new(0, 0, 0.5, 0);
                Image = IconId;
                Parent = Button;
            })
        end
        function Dropdown:AddIcon(Value: string, IconId: string)
            Icons[Value] = IconId
            local btn = Buttons[Value]
            if btn then CreateIconLabel(btn.Button, IconId) end
        end
        function Dropdown:RemoveIcon(Value: any)
            if Value == nil then return end
            Icons[Value] = nil
        end
        function Dropdown:UnloadIcons()
            Icons = {}
        end

        function Dropdown:BuildDropdownList()
            local Menu = MenuTable.Menu

            local ExistingButtons = {}
            for Value, Btn in Buttons do
                ExistingButtons[Value] = Btn
            end
            
            local NewButtons = {}
            local Count = 0
            local ButtonIndex = 0
            
            for _, Value in Dropdown.Values do
                local FormattedValue = tostring(Value)
                if SearchBox and not FormattedValue:lower():match(SearchBox.Text:lower()) then
                    continue
                end
                
                Count = Count + 1
                ButtonIndex = ButtonIndex + 1
                local IsDisabled = Dropdown.DisabledValues[Value]
                
                local Table = ExistingButtons[Value]
                local Button
                local TextLabel
                
                if Table then
                    Button = Table.Button
                    TextLabel = Button:FindFirstChildOfClass("TextLabel")
                    ExistingButtons[Value] = nil
                    Button.Visible = true
                    Button.LayoutOrder = IsDisabled and 1 or 0
                    TextLabel.Text = FormattedValue
                else
                    Button = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        LayoutOrder = IsDisabled and 1 or 0,
                        Size = UDim2.new(1, 0, 0, 21),
                        Text = "",
                        Parent = Menu,
                    })
                    
                    TextLabel = New("TextLabel", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        TextTransparency = 0.5,
                        Text = FormattedValue,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 2,
                        Parent = Button,
                    })
                    
                    New("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 3),
                        Parent = Button,
                    })
                    
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 3),
                        PaddingRight = UDim.new(0, 3),
                        PaddingTop = UDim.new(0, 3),
                        PaddingBottom = UDim.new(0, 3),
                        Parent = Button,
                    })
                    
                    Table = {Button = Button, Value = Value}
                    
                    local IconUrl = Icons[Value]
                    if IconUrl then
                        CreateIconLabel(Button, IconUrl)
                    end
                    
                    local Tooltip = Info.Tooltips[Value]
                    if Tooltip then
                        Library:AddTooltip(Tooltip, nil, Button)
                    end
                    
                    if not IsDisabled then
                        Button.MouseButton1Click:Connect(function()
                            local Selected
                            if Info.Multi then
                                Selected = Dropdown.Value[Value]
                            else
                                Selected = Dropdown.Value == Value
                            end
                            
                            local Try = not Selected
                            
                            if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                                Selected = Try
                                if Info.Multi then
                                    Dropdown.Value[Value] = Selected and true or nil
                                else
                                    Dropdown.Value = Selected and Value or nil
                                end
                                
                                for _, OtherButton in NewButtons do
                                    OtherButton:UpdateButton()
                                end
                            end
                            
                            Table:UpdateButton()
                            Dropdown:Display()
                            
                            Library:UpdateDependencyBoxes()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        end)
                    end
                end
                
                function Table:UpdateButton()
                    local Selected
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end
                    
                    Button.BackgroundTransparency = Selected and 0 or 1
                    TextLabel.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5
                end
                
                Table:UpdateButton()
                Dropdown:Display()
                
                NewButtons[Value] = Table
            end
            
            for _, Btn in ExistingButtons do
                if Btn then
                    Btn.Button.Visible = false
                end
            end
            
            Buttons = NewButtons
            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        if Info.Multi then
            function Dropdown:AddValue(Value)
                if Dropdown.Value[Value] then return end
                Dropdown.Value[Value] = true

                Dropdown:Display()
                for _, Button in Buttons do
                    Button:UpdateButton()
                end

                if not Dropdown.Disabled then
                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end
            end

            function Dropdown:RemoveValue(Value)
                if not Dropdown.Value[Value] then return end
                Dropdown.Value[Value] = nil

                Dropdown:Display()
                for _, Button in Buttons do
                    Button:UpdateButton()
                end

                if not Dropdown.Disabled then
                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in Values do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            local NewDisabledValues = {}
            if #DisabledValues > 0 then
                for _, v in DisabledValues do
                    NewDisabledValues[v] = true
                end
            else
                for v, _ in DisabledValues do
                    NewDisabledValues[v] = true
                end
            end
            Dropdown.DisabledValues = NewDisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(v)
            if typeof(v) == "table" then
                for _, v in v do
                    Dropdown.DisabledValues[v] = true
                end
            elseif typeof(v) == "string" then
                Dropdown.DisabledValues[v] = true
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            Display.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, Text and 39 or 21)

            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddDependencyBox()
        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {},
        }

        function Depbox:Resize()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in Depbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = DepGroupboxContainer,
                })
            )
            Library:AddOutline(DepGroupboxContainer)

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = DepGroupboxContainer,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in DepGroupbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepGroupboxContainer.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                DepGroupboxContainer.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = FakeBackground,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })
    Library:AddOutline(Holder)

    local ContentContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = Holder,
    })
    
    if Data.BigIcon then
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = ContentContainer,
        })
    end

    local BigIconLabel
    if Data.BigIcon then
        local ParsedIcon = Library:GetCustomIcon(Data.BigIcon)
        if ParsedIcon then
            BigIconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "AccentColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = ContentContainer,
            })
        end
    end

    local TextContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = ContentContainer,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })
    
    local TitleContainer
    if Data.Title then
        TitleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Parent = TextContainer,
        })
    end

    local IconLabel
    if Data.Icon and TitleContainer then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            IconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(15, 15),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "FontColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = TitleContainer,
            })
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (Data.Icon and 21 or 0), 0.5, 0),
            Size = UDim2.fromScale(0, 0),
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = TitleContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    function Data:Resize()
        local ExtraWidth = BigIconLabel and 32 or 0
        local IconWidth = IconLabel and 21 or 0

        if Title then
            local X, Y =
                Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth - IconWidth)
            Title.Size = UDim2.fromOffset(X, Y)
            TitleX = X + IconWidth
            TitleContainer.Size = UDim2.fromOffset(TitleX, math.max(Y, IconLabel and 16 or 0))
        end

        if Desc then
            local X, Y =
                Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth)
            Desc.Size = UDim2.fromOffset(X, Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24 + ExtraWidth, 0)
    end

    function Data:ChangeTitle(Text)
        if Title then
            Data.Title = tostring(Text)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(Text)
        if Desc then
            Data.Description = tostring(Text)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end

        if DeleteConnection then
            DeleteConnection:Disconnect()
        end

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()

        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        New("Sound", {
            SoundId = SoundId,
            Volume = 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Library.OriginalMinSize

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)
    
    --// Old Naming \\--
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end
    if WindowInfo.SidebarMinWidth ~= nil then
        WindowInfo.MinSidebarWidth = WindowInfo.SidebarMinWidth
    end
    WindowInfo.MinSidebarWidth = math.max(64, WindowInfo.MinSidebarWidth)
    WindowInfo.SidebarCompactWidth = math.max(48, WindowInfo.SidebarCompactWidth)
    WindowInfo.SidebarCollapseThreshold = math.clamp(WindowInfo.SidebarCollapseThreshold, 0.1, 0.9)
    WindowInfo.CompactWidthActivation = math.max(48, WindowInfo.CompactWidthActivation)

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local DividerLine
    local TitleHolder
    local WindowTitle
    local WindowIcon
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local BackgroundImage
    local BottomBackground
    local FooterLabel

    local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.3)
    local IsCompact = WindowInfo.SidebarCompacted
    local LastExpandedWidth = InitialLeftWidth

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = MainFrame,
            })
        )
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = MainFrame,
            })
        )
        Library:AddOutline(MainFrame)
        Library:MakeLine(MainFrame, {
            Position = UDim2.fromOffset(0, 48),
            Size = UDim2.new(1, 0, 0, 1),
        })

        DividerLine = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromOffset(InitialLeftWidth, 0),
            Size = UDim2.new(0, 1, 1, -21),
            Parent = MainFrame,
        })

        if WindowInfo.BackgroundImage then
            BackgroundImage = New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = BackgroundImage,
                })
            )
        end

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        --// Title
        TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, InitialLeftWidth, 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })

        if WindowInfo.Icon then
            local Icon = Library:GetCustomIcon(WindowInfo.Icon)
            WindowIcon = New("ImageLabel", {
                Image = Icon.Url,
                ImageRectOffset = Icon.ImageRectOffset,
                ImageRectSize = Icon.ImageRectSize,
                Size = WindowInfo.IconSize,
                Parent = TitleHolder,
            })
        else
            WindowIcon = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = WindowInfo.IconSize,
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Visible = false,
                Parent = TitleHolder,
            })
        end

        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            20,
            TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
        )
        WindowTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, X, 1, 0),
            Text = WindowInfo.Title,
            TextSize = 20,
            Parent = TitleHolder,
        })

        --// Top Right Bar
        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -49, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - 57 - 1, 1, -16),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search",
            Size = WindowInfo.SearchbarSize,
            TextScaled = true,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = SearchBox,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = SearchBox,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = SearchBox,
            })
        end

        if MoveIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Image = MoveIcon.Url,
                ImageColor3 = "OutlineColor",
                ImageRectOffset = MoveIcon.ImageRectOffset,
                ImageRectSize = MoveIcon.ImageRectSize,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TopBar,
            })
        end

        --// Bottom Bar \\--
        BottomBackground = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20 + WindowInfo.CornerRadius),
            ZIndex = 2,
            Parent = MainFrame
        })
        Library:MakeLine(MainFrame, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -20),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 2,
        })

        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            ZIndex = 2,
            Parent = MainFrame,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BottomBackground,
            })
        )

        --// Footer
        FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            ZIndex = 2,
            Parent = BottomBar,
        })

        --// Resize Button
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in Library.Tabs do
                    Tab:Resize(true)
                end
            end)
        end

        New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })

        --// Tabs \\--
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, 49),
            ScrollBarThickness = 0,
            Size = UDim2.new(0, InitialLeftWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            Parent = Tabs,
        })

        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, 49),
            Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })
    end

    --// Window Table \\--
    local Window = {}

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title
    end

    if WindowInfo.BackgroundImage then
        function Window:SetBackgroundImage(Image: string)
            assert(typeof(Image) == "string", "Expected string for Image got: " .. typeof(Image))
    
            BackgroundImage.Image = Image
            WindowInfo.BackgroundImage = Image
        end
    end

    function Window:SetFooter(footer: string)
        assert(typeof(footer) == "string", "Expected string for footer got: " .. typeof(footer))

        FooterLabel.Text = footer
        WindowInfo.Footer = footer
    end

    function Window:SetCornerRadius(Radius: number)
        assert(typeof(Radius) == "number", "Expected number for Radius got: " .. typeof(Radius))
        Radius = math.min(Radius, 20)

        for _, UICorner in Library.Corners do
            if UICorner.CornerRadius.Offset == Library.CornerRadius / 2 then
                UICorner.CornerRadius = UDim.new(0, Radius / 2)
            else
                UICorner.CornerRadius = UDim.new(0, Radius)
            end
        end

        Library.CornerRadius = Radius
        WindowInfo.CornerRadius = Radius

        ResizeButton.Position = UDim2.new(1, -Radius / 4, 0, 0)
        BottomBackground.Size = UDim2.new(1, 0, 0, 20 + Radius)

        for _, Tab in Library.Tabs do
            if Tab.IsKeyTab then
                continue
            end

            for _, Tabbox in Tab.Tabboxes do
                Tabbox:UpdateCorners()
            end
        end
    end

    local function ApplyCompact()
        IsCompact = Window:GetSidebarWidth() == WindowInfo.SidebarCompactWidth
        if WindowInfo.DisableCompactingSnap then
            IsCompact = Window:GetSidebarWidth() <= WindowInfo.CompactWidthActivation
        end

        WindowTitle.Visible = not IsCompact
        if not WindowInfo.Icon then
            WindowIcon.Visible = IsCompact
        end

        for _, Button in Library.TabButtons do
            if not Button.Icon then
                continue
            end

            Button.Label.Visible = not IsCompact
            Button.Padding.PaddingBottom = UDim.new(0, IsCompact and 6 or 11)
            Button.Padding.PaddingLeft = UDim.new(0, IsCompact and 6 or 12)
            Button.Padding.PaddingRight = UDim.new(0, IsCompact and 6 or 12)
            Button.Padding.PaddingTop = UDim.new(0, IsCompact and 6 or 11)
            Button.Icon.SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    function Window:SetCompact(State)
        Window:SetSidebarWidth(State and WindowInfo.SidebarCompactWidth or LastExpandedWidth)
    end

    function Window:GetSidebarWidth()
        return Tabs.Size.X.Offset
    end

    function Window:SetSidebarWidth(Width)
        Width = math.clamp(Width, 48, MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 1)

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        TitleHolder.Size = UDim2.new(0, Width, 1, 0)
        RightWrapper.Size = UDim2.new(1, -Width - 57 - 1, 1, -16)
        Tabs.Size = UDim2.new(0, Width, 1, -70)
        Container.Size = UDim2.new(1, -Width - 1, 1, -70)

        if WindowInfo.EnableCompacting then
            ApplyCompact()
        end
        if not IsCompact then
            LastExpandedWidth = Width
        end
    end

    function Window:ShowTabInfo(Name, Description)
        CurrentTabLabel.Text = Name
        CurrentTabDescription.Text = Description

        if IsDefaultSearchbarSize then
            SearchBox.Size = UDim2.fromScale(0.5, 1)
        end
        CurrentTabInfo.Visible = true
    end
    function Window:HideTabInfo()
        CurrentTabInfo.Visible = false
        if IsDefaultSearchbarSize then
            SearchBox.Size = UDim2.fromScale(1, 1)
        end
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer
        local TabLeft
        local TabRight

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, IsCompact and 6 or 11),
                PaddingLeft = UDim.new(0, IsCompact and 6 or 12),
                PaddingRight = UDim.new(0, IsCompact and 6 or 12),
                PaddingTop = UDim.new(0, IsCompact and 6 or 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
            })

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.new(0.5, -3, 1, 0),
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = TabLeft,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.new(0.5, -3, 1, 0),
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = TabRight,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })
            end
        end

        --// Warning Box \\--
        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = WarningBox,
                })
            )
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
            Description = Description,
            Sides = {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                or Color3.fromRGB(127, 0, 0)

            WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                or Color3.fromRGB(85, 0, 0)
            WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(255, 50, 50)

            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxShadowOutline] then
                Library:AddToRegistry(WarningBoxShadowOutline, {})
            end
            if not Library.Registry[WarningBoxOutline] then
                Library:AddToRegistry(WarningBoxOutline, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            end

            Library.Registry[WarningBoxShadowOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
            end

            Library.Registry[WarningBoxOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
            end
        end

        function Tab:RefreshSides()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            for _, Side in Tab.Sides do
                Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                Side.Size = UDim2.new(0.5, -3, 1, -Offset)
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        function Tab:AddGroupbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local GroupboxHolder
            local GroupboxLabel

            local GroupboxContainer
            local GroupboxList

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = GroupboxHolder,
                    })
                )
                Library:AddOutline(GroupboxHolder)

                Library:MakeLine(GroupboxHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = Info.Name,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    Parent = GroupboxLabel,
                })

                GroupboxContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = GroupboxContainer,
                })
            end

            local Groupbox = {
                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,

                Tab = Tab,
                DependencyBoxes = {},
                Elements = {},
            }

            local IsOpen = true
            function Groupbox:Resize()
                if IsOpen then
                    GroupboxHolder.Size = UDim2.new(1, 0, 0, (GroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                else
                    GroupboxHolder.Size = GroupboxLabel.Size
                end
            end

            Library:GiveSignal(GroupboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Groupbox:Resize()
            end))

            if Info.Collapsible ~= false  then
                local ToggleButton = New("ImageButton", {
                    Image = ArrowIcon and ArrowIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0,
                    Rotation = 180,

                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.new(1, -8, 0, 18),
                    Size = UDim2.fromOffset(20, 20),
                    Parent = GroupboxHolder,
                })
                table.insert(Library.Corners, New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = ToggleButton,
                }))
                New("UIStroke", { Color = "OutlineColor", Parent = ToggleButton })

                Library:GiveSignal(ToggleButton.MouseButton1Click:Connect(function()
                    IsOpen = not IsOpen
                    GroupboxContainer.Visible = IsOpen
                    ToggleButton.ImageTransparency = IsOpen and 0 or 0.5
                    ToggleButton.Rotation = IsOpen and 180 or 0
                    Groupbox:Resize()
                end))
            end

            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName })
        end

        function Tab:AddRightGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName })
        end

        function Tab:AddTabbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = TabboxHolder,
                    })
                )
                Library:AddOutline(TabboxHolder)

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })
            end

            local TotalButtons, TotalTabs = 0, 1
            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = TabboxHolder,
                Tabs = {}
            }

            function Tabbox:UpdateCorners()
                for _, Tab in Tabbox.Tabs do
                    Tab:UpdateCorners()
                end
            end

            function Tabbox:AddTab(Name, IconName)
                local TabIndex = TotalTabs

                TotalButtons = TotalButtons + 1
                TotalTabs = TotalTabs + 1

                local BoxIcon = Library:GetCustomIcon(IconName)

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = "",
                    Parent = TabboxButtons,
                })

                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = Button,
                    })
                )

                local BottomCover = New("Frame", {
                    Name = "BottomCover",
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -WindowInfo.CornerRadius),
                    Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius),
                    Parent = Button,
                })

                local LeftCover = New("Frame", {
                    Name = "LeftCover",
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0),
                    Visible = false,
                    Parent = Button,
                })

                local RightCover = New("Frame", {
                    Name = "RightCover",
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0),
                    Visible = false,
                    Parent = Button,
                })

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ButtonContent,
                    })
                end

                local ButtonLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 16),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = ButtonContent,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    ButtonHolder = Button,
                    Container = Container,

                    ButtonCovers = {
                        BottomCover = BottomCover,
                        LeftCover = LeftCover,
                        RightCover = RightCover
                    },

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    BottomCover.BackgroundTransparency = 1
                    LeftCover.BackgroundTransparency = 1
                    RightCover.BackgroundTransparency = 1

                    ButtonLabel.TextTransparency = 0
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0
                    end
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    BottomCover.BackgroundTransparency = 0
                    LeftCover.BackgroundTransparency = 0
                    RightCover.BackgroundTransparency = 0

                    ButtonLabel.TextTransparency = 0.5
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0.5
                    end
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end

                    TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                end

                function Tab:UpdateCorners()
                    LeftCover.Visible = TabIndex ~= 1
                    RightCover.Visible = TabIndex ~= TotalButtons
        
                    BottomCover.Position = UDim2.new(0, 0, 1, -WindowInfo.CornerRadius)
                    BottomCover.Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius)
        
                    LeftCover.Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0)
                    RightCover.Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0)
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab
                Tabbox:UpdateCorners()

                return Tab
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            TabContainer.Visible = true
            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, IsCompact and 6 or 11),
                PaddingLeft = UDim.new(0, IsCompact and 6 or 12),
                PaddingRight = UDim.new(0, IsCompact and 6 or 12),
                PaddingTop = UDim.new(0, IsCompact and 6 or 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
            })

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Elements = {},
            Description = Description,
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Box,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Box,
                })
            )

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )

            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end
        function Tab:UpdateCorners() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end
            TabContainer.Visible = true

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = MainFrame,
        })
        TweenService:Create(DialogOverlay, Library.TweenInfo, {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9001,
            Parent = DialogOverlay,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = DialogFrame,
            })
        )
        Library:AddOutline(DialogFrame)

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, Library.TweenInfo, {
            Scale = 1
        }):Play()
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = ParsedIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = 9002,
                    Parent = TitleRow,
                })
                if Info.TitleColor then
                    IconImg.ImageColor3 = Info.TitleColor
                end
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = TitleRow,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        end

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        end

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = DialogContainer,
        })
        
        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9002,
            Parent = InnerContainer,
        })

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            local MaxWidth = MainFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            Library.ActiveDialog = nil
            local CloseTween = TweenService:Create(DialogScale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            CloseTween:Play()
            
            task.delay(Library.TweenInfo.Time, function()
                DialogOverlay:Destroy()
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 9002,
                Parent = ButtonsHolder,
            })
            
            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"
            
            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                BackgroundTransparency = WaitTime > 0 and 0.5 or 0,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9002,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", { 
                    CornerRadius = UDim.new(0, Library.CornerRadius), 
                    Parent = TextBtn 
                })
            )

            local _BtnPadding = New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end
            
            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14,
                ZIndex = 9002,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", { 
                        CornerRadius = UDim.new(0, Library.CornerRadius), 
                        Parent = ProgressBar 
                    })
                )
            end

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end
                end
            }

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()
                
                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then
                        TweenService:Create(ProgressBar, Library.TweenInfo, {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        for BIdx, BInfo in Info.FooterButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseGroupbox)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()
        
        Library.ActiveDialog = Dialog
        return Dialog
    end

    function Window:Toggle(Value: boolean?)
        if Library.ActiveLoading then
            if Value == true then
                return
            end

            if not Library.Toggled then
                return
            end
        end

        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        MainFrame.Visible = Library.Toggled

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            pcall(function()
                RunService:UnbindFromRenderStep("ShowCursor")
            end)
            RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep("ShowCursor")
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(Value: boolean?)
        return Window:Toggle(Value)
    end

    if WindowInfo.EnableSidebarResize then
        local Threshold = (WindowInfo.MinSidebarWidth + WindowInfo.SidebarCompactWidth) * WindowInfo.SidebarCollapseThreshold
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 8, 1, 0),
            Text = "",
            Parent = DividerLine,
        })
        SidebarGrabber.MouseEnter:Connect(function()
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                TweenService:Create(DividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if WindowInfo.DisableCompactingSnap then
                    Window:SetSidebarWidth(Width)
                    return
                end

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, WindowInfo.MinSidebarWidth))
                else
                    Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
                end
            end
        end))
    end
    if WindowInfo.EnableCompacting and WindowInfo.SidebarCompacted then
        Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
    end
    if WindowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end, true)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end, true)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

            LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
        else
            LockButton.Button.Position = UDim2.fromOffset(6, 46)
        end

        if WindowInfo.ShowMobileButtons == false then
            ToggleButton.Button.Visible = false
            LockButton.Button.Visible = false
        end
    end

    --// Execution \\--
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        warn("Loading GUI already exists, you cannot create multiple Loading GUIs.")
        return Library.ActiveLoading
    end

    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,

        ShowSidebar = LoadingInfo.ShowSidebar,
        AutoResizeHeight = LoadingInfo.AutoResizeHeight,
        IsError = false,
        Destroyed = false,

        WindowWidth = LoadingInfo.WindowWidth,
        WindowHeight = LoadingInfo.WindowHeight,
        BaseWindowHeight = LoadingInfo.WindowHeight,
        WindowErrorHeight = LoadingInfo.WindowHeight,

        ContentWidth = LoadingInfo.ContentWidth,
        SidebarWidth = LoadingInfo.SidebarWidth,
    }

    --// ScreenGui \\--
    local ScreenGui = New("ScreenGui", {
        Name = "ObsidianLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui

    ScreenGui.DescendantRemoving:Connect(function(Instance)
        Library:RemoveFromRegistry(Instance)
    end)

    --// Main Frame \\--
    local MainFrame = New("TextButton", {
        Name = "Frame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
        end,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Loading.ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth, Loading.WindowHeight),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    })
    Library:AddOutline(MainFrame)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame }))
    
    local MainScale = New("UIScale", { Parent = MainFrame })
    table.insert(Library.Scales, MainScale)

    --// Layout Containers \\--
    local Container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, Loading.ContentWidth, 1, 0),
        Parent = MainFrame,
    })

    local SideBar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Loading.ContentWidth, 0),
        Size = UDim2.new(0, Loading.ShowSidebar and Loading.SidebarWidth or 0, 1, 0),
        ClipsDescendants = true,
        Visible = Loading.ShowSidebar,
        Parent = MainFrame,
    })
    local SidebarCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = SideBar })
    table.insert(Library.Corners, SidebarCorner)
    
    Library:AddOutline(SideBar)
    
    local SidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Visible = Loading.ShowSidebar,
        Parent = SideBar,
    })

    --// Top Bar \\--
    local TopBar = New("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2,
        Parent = Container,
    })
    Library:MakeDraggable(MainFrame, TopBar, true, true)

    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TitleHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        Parent = TitleHolder,
    })

    if LoadingInfo.Icon then
        local Icon = Library:GetCustomIcon(LoadingInfo.Icon)
        local _WindowIcon = New("ImageLabel", {
            Image = Icon.Url,
            ImageRectOffset = Icon.ImageRectOffset,
            ImageRectSize = Icon.ImageRectSize,
            Size = LoadingInfo.IconSize,
            Parent = TitleHolder,
        })
    else
        local _WindowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = LoadingInfo.IconSize,
            Text = LoadingInfo.Title:sub(1, 1),
            TextScaled = true,
            Visible = false,
            Parent = TitleHolder,
        })
    end

    local TitleX = Library:GetTextBounds(
        LoadingInfo.Title,
        Library.Scheme.Font,
        20,
        TitleHolder.AbsoluteSize.X - (LoadingInfo.Icon and (LoadingInfo.IconSize.X.Offset + 6) or 0) - 12
    )
    local _WindowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, TitleX, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 20,
        Parent = TitleHolder,
    })

    Library:MakeLine(Container, {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 1),
    })

    --// Loading Content Elements \\--
    local InnerContent = New("Frame", {
        Name = "InnerContent",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = InnerContent,
    })

    local IconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 64),
        Parent = InnerContent,
    })

    local LoaderIcon = Library:GetCustomIcon(LoadingInfo.LoadingIcon)
    local LoadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = LoaderIcon.Url,
        ImageRectOffset = LoaderIcon.ImageRectOffset,
        ImageRectSize = LoaderIcon.ImageRectSize,
        ImageColor3 = LoadingInfo.LoadingIconColor or ((LoadingInfo.LoadingIcon == Templates.Loading.LoadingIcon) and "AccentColor" or "WhiteColor"),
        Parent = IconHolder,
    })

    local RotationTween
    if LoadingInfo.LoadingIconTweenTime > 0 then
        RotationTween = TweenService:Create(
            LoadingIcon,
            TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }
        )
        RotationTween:Play()
    end

    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 18,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    --// Progress Bar \\--
    local SliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7, 0, 0, 15),
        Parent = InnerContent,
    })
    Library:AddOutline(SliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderBar }))

    local SliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = SliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderFill }))

    local ProgressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = SliderBar,
    })
    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = "DarkColor",
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = ProgressLabel,
    })

    --// Sidebar Object \\--
    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor",
        Parent = SideBar,
    })
    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarScrolling,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = SidebarScrolling,
    })

    local SidebarObject = {
        Elements = {},
        DependencyBoxes = {},
        Tabboxes = {},
        
        BoxHolder = SidebarScrolling,
        Container = SidebarScrolling,
        
        Resize = function(self)
            SidebarScrolling.CanvasSize = UDim2.fromOffset(0, SidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            DependencyBoxes = {},
            DependencyGroupboxes = {},
            Tabboxes = {},
        },
    }

    SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarObject:Resize()
    end)

    setmetatable(SidebarObject, BaseGroupbox)
    Loading.Sidebar = SidebarObject

    --// Error Frame \\--
    local ErrorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        ClipsDescendants = true,
        Visible = false,
        Parent = Container,
    })

    local _ErrorTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 0, 18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorFrame,
    })

    local ErrorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 39),
        Size = UDim2.new(1, -30, 1, -90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = ErrorFrame,
    })

    local ErrorButtonsDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(1, -30, 0, 1),
        Visible = false,
        Parent = ErrorFrame,
    })

    local ErrorButtonsHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Visible = false,
        Parent = ErrorFrame,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ErrorButtonsHolder,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = ErrorButtonsHolder,
    })

    function Loading:UpdateLayout()
        if Loading.IsError then
            Loading:RecalculateErrorHeight()
        end

        local ShowSidebar = Loading.ShowSidebar
        local FinalWidth = ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth
        local FinalHeight = Loading.IsError and Loading.WindowErrorHeight or Loading.WindowHeight
        
        if ShowSidebar then
            SideBar.Visible = true
            SidebarDivider.Visible = true
        end

        TweenService:Create(MainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(FinalWidth, FinalHeight) }):Play()
        TweenService:Create(SideBar, Library.TweenInfo, { Position = UDim2.fromOffset(Loading.ContentWidth, 0), Size = UDim2.new(0, ShowSidebar and Loading.SidebarWidth or 0, 1, 0) }):Play()
        TweenService:Create(Container, Library.TweenInfo, { Size = UDim2.new(0, ShowSidebar and Loading.ContentWidth or Loading.WindowWidth, 1, 0) }):Play()

        if not ShowSidebar then
            task.delay(Library.TweenInfo.Time, function()
                if not Loading.ShowSidebar then
                    SideBar.Visible = false
                    SidebarDivider.Visible = false
                end
            end)
        end
    end

    --// Content Page \\--
    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight = 
            49 -- TopBar
            + 48 -- Padding
            + InnerContent.UIListLayout.AbsoluteContentSize.Y

        Loading.WindowHeight = math.max(Loading.BaseWindowHeight, RequiredHeight)
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetDescription(Text)
        DescriptionLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetLoadingIcon(Icon)
        local IconData = Library:GetCustomIcon(Icon)
        LoadingIcon.Image = IconData.Url
        LoadingIcon.ImageRectOffset = IconData.ImageRectOffset
        LoadingIcon.ImageRectSize = IconData.ImageRectSize
    end

    function Loading:SetLoadingIconTweenTime(TweenTime)
        if RotationTween then
            RotationTween:Cancel()
            RotationTween:Destroy()
        end

        if TweenTime > 0 then
            RotationTween = TweenService:Create(
                LoadingIcon,
                TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                { Rotation = 360 }
            )
            RotationTween:Play()
        else
            LoadingIcon.Rotation = 0
        end
    end

    function Loading:SetLoadingIconColor(Color)
        LoadingIcon.ImageColor3 = Color
    end

    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)

        local Progress = Loading.CurrentStep / Loading.TotalSteps
        TweenService:Create(SliderFill, Library.TweenInfo, { Size = UDim2.fromScale(Progress, 1) }):Play()

        ProgressLabel.Text = string.format("%d/%d", Loading.CurrentStep, Loading.TotalSteps)
    end

    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end

    --// Size \\--
    function Loading:SetWindowHeight(Height)
        Loading.WindowHeight = Height
        Loading:UpdateLayout()
    end

    function Loading:SetWindowWidth(Width)
        Loading.WindowWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetContentWidth(Width)
        Loading.ContentWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetSidebarWidth(Width)
        Loading.SidebarWidth = Width
        Loading:UpdateLayout()
    end

    --// Sidebar \\--
    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    --// Error Page \\--
    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        InnerContent.Visible = not Enabled
        ErrorFrame.Visible = Enabled

        if Loading.ShowSidebar then
            Loading:ShowSidebarPage(not Enabled)
        else
            Loading:UpdateLayout()
        end
    end

    function Loading:RecalculateErrorHeight()
        local TargetWidth = (Loading.ShowSidebar and Loading.ContentWidth or Loading.WindowWidth) - 30
        local _, ErrorY = Library:GetTextBounds(ErrorLabel.Text, Library.Scheme.Font, 14, TargetWidth)

        ErrorLabel.Size = UDim2.new(1, -30, 0, ErrorY)

        local HasButtons = ErrorButtonsHolder.Visible
        local RequiredHeight =
            49                        -- TopBar
            + 15                        -- Padding Top
            + 18                        -- Title Height
            + 6                         -- Padding between Title and Label
            + ErrorY                    -- Label Height
            + 15                        -- Padding between Label and Buttons
            + (HasButtons and 48 or 0)  -- Buttons Area

        Loading.WindowErrorHeight = RequiredHeight -- math.max(Loading.WindowHeight, RequiredHeight)
    end

    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = Text
        Loading:UpdateLayout()
    end

    function Loading:SetErrorButtons(Buttons)
        assert(typeof(Buttons) == "table", "Buttons must be a table")

        for _, button in ErrorButtonsHolder:GetChildren() do
            if button:IsA("Frame") then 
                button:Destroy() 
            end
        end

        local HasButtons = GetTableSize(Buttons) > 0
        ErrorButtonsHolder.Visible = HasButtons
        ErrorButtonsDivider.Visible = HasButtons

        for Idx, ButtonInfo in Buttons do
            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                Parent = ErrorButtonsHolder,
            })
            
            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"
            
            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", { 
                    CornerRadius = UDim.new(0, Library.CornerRadius), 
                    Parent = TextBtn 
                })
            )

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or Idx,
                TextColor3 = TextColor,
                TextSize = 14,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Loading)
                end
            end)
        end

        Loading:UpdateLayout()
    end

    --// Destroy/Continue \\--
    function Loading:Destroy()
        if RotationTween then
            RotationTween:Cancel()
        end

        ScreenGui:Destroy()
        Loading.Destroyed = true
        Library.ActiveLoading = nil

        if Library.Toggle and Library.Toggled == false and Library.Unloaded ~= true then
            Library:Toggle(true)
        end
    end

    Loading.Continue = Loading.Destroy;

    if Library.Toggle and Library.Toggled and Library.Unloaded ~= true then
        Library:Toggle(false)
    end

    Loading:SetCurrentStep(Loading.CurrentStep)

    Library.ActiveLoading = Loading
    return Loading
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library
return Library
