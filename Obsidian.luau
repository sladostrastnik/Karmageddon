local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
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
    }
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

    function CustomImageManager.AddAsset(AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?)
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
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},

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

    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        Red = Color3.fromRGB(255, 50, 50),
        Dark = Color3.new(0, 0, 0),
        White = Color3.new(1, 1, 1),
    },

    Registry = {},
    DPIRegistry = {},
    
    ImageManager = CustomImageManager,
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.MinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.MinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.MinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
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
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        Compact = false,
        EnableSidebarResize = false,
        SidebarMinWidth = 180,
        SidebarCompactWidth = 54,
        SidebarCollapseThreshold = 0.5,
        SidebarHighlightCallback = nil,
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
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
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

--// Basic Functions \\--
local function ApplyDPIScale(Dimension, ExtraOffset)
    if typeof(Dimension) == "UDim" then
        return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
    end

    if ExtraOffset then
        return UDim2.new(
            Dimension.X.Scale,
            (Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
            Dimension.Y.Scale,
            (Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
        )
    end

    return UDim2.new(
        Dimension.X.Scale,
        Dimension.X.Offset * Library.DPIScale,
        Dimension.Y.Scale,
        Dimension.Y.Offset * Library.DPIScale
    )
end
local function ApplyTextScale(TextSize)
    return TextSize * Library.DPIScale
end

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

    for _, _ in pairs(Table) do
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
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
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
local function GetLighterColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:UpdateKeybindFrame()
    if not Library.KeybindFrame then
        return
    end

    local XSize = 0
    for _, KeybindToggle in pairs(Library.KeybindToggles) do
        if not KeybindToggle.Holder.Visible then
            continue
        end

        local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
        if FullSize > XSize then
            XSize = FullSize
        end
    end

    Library.KeybindFrame.Size = UDim2.fromOffset(XSize + 18 * Library.DPIScale, 0)
end
function Library:UpdateDependencyBoxes()
    for _, Depbox in pairs(Library.DependencyBoxes) do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in pairs(Box.Elements) do
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

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in pairs(Box.Elements) do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in pairs(Library.Tabs) do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    local function ResetTab(Tab)
        if not Tab then
            return
        end

        for _, Groupbox in pairs(Tab.Groupboxes) do
            for _, ElementInfo in pairs(Groupbox.Elements) do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            Groupbox:Resize()
            Groupbox.Holder.Visible = true
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                for _, ElementInfo in pairs(SubTab.Elements) do
                    ElementInfo.Holder.Visible =
                        typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
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
            Tabbox.Holder.Visible = true
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                ElementInfo.Holder.Visible =
                    typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            DepGroupbox:Resize()
            DepGroupbox.Holder.Visible = true
        end
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
            for _, Tab in pairs(Library.Tabs) do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local function ApplySearchToTab(Tab)
        if not Tab then
            return
        end

        local HasVisible = false

        --// Loop through Groupboxes to get Elements Info
        for _, Groupbox in pairs(Tab.Groupboxes) do
            local VisibleElements = 0

            for _, ElementInfo in pairs(Groupbox.Elements) do
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

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
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
            Groupbox.Holder.Visible = VisibleElements > 0
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            local VisibleTabs = 0
            local VisibleElements = {}

            for _, SubTab in pairs(Tabbox.Tabs) do
                VisibleElements[SubTab] = 0

                for _, ElementInfo in pairs(SubTab.Elements) do
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

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
                end
            end

            for SubTab, Visible in pairs(VisibleElements) do
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
            Tabbox.Holder.Visible = VisibleTabs > 0
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            local VisibleElements = 0

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
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

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            --// Update Groupbox Size and Visibility if found any element
            if VisibleElements > 0 then
                DepGroupbox:Resize()
                HasVisible = true
            end
            DepGroupbox.Holder.Visible = VisibleElements > 0
        end

        return HasVisible
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab)
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
    for Instance, Properties in pairs(Library.Registry) do
        for Property, ColorIdx in pairs(Properties) do
            if typeof(ColorIdx) == "string" then
                Instance[Property] = Library.Scheme[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:UpdateDPI(Instance, Properties)
    if not Library.DPIRegistry[Instance] then
        return
    end

    for Property, Value in pairs(Properties) do
        Library.DPIRegistry[Instance][Property] = Value and Value or nil
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize *= Library.DPIScale

    for Instance, Properties in pairs(Library.DPIRegistry) do
        for Property, Value in pairs(Properties) do
            if Property == "DPIExclude" or Property == "DPIOffset" then
                continue
            elseif Property == "TextSize" then
                Instance[Property] = ApplyTextScale(Value)
            else
                Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
            end
        end
    end

    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        Tab:Resize(true)
        for _, Groupbox in pairs(Tab.Groupboxes) do
            Groupbox:Resize()
        end
        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                SubTab:Resize()
            end
        end
    end

    for _, Option in pairs(Options) do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        elseif Option.Type == "KeyPicker" then
            Option:Update()
        end
    end

    Library:UpdateKeybindFrame()
    for _, Notification in pairs(Library.Notifications) do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
    table.insert(Library.Signals, Connection)
    return Connection
end

local function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local Icons = (function()
    local Lucide = {}

    local icons = {{"align-vertical-distribute-center","chevron-down","list-restart","table-cells-split","gavel","dna-off","refresh-ccw-dot","venus","bean","circle-question-mark","folder-code","bolt","heater","feather","align-horizontal-distribute-center","grip-vertical","pill-bottle","person-standing","badge-swiss-franc","between-horizontal-end","file-braces-corner","rotate-cw","framer","house-plus","bus-front","shield-ellipsis","between-vertical-end","globe-lock","tags","concierge-bell","bookmark-minus","file-down","picture-in-picture","messages-square","scissors","file-check-corner","phone-call","anchor","hand-helping","text-wrap","birdhouse","wifi-off","cloud-alert","message-square","cloud-download","folder-plus","hard-drive-download","user-round","pointer","between-horizontal-start","chevrons-up-down","brush","rail-symbol","message-circle-more","parentheses","book-up-2","flame","chevrons-up","square-dashed","square-mouse-pointer","superscript","signal","wifi-cog","hexagon","navigation-2-off","eye-off","arrows-up-from-line","file-code-corner","panels-right-bottom","scaling","hash","arrow-left-from-line","ship","ticket-percent","calendar-clock","x","non-binary","voicemail","presentation","tree-palm","badge","captions-off","align-vertical-justify-center","download","tent","repeat-1","focus","diamond-percent","arrow-big-up","volume-x","mouse-pointer-click","origami","hard-drive","grid-2x2-x","package-minus","cloud","pipette","flip-horizontal","corner-left-down","badge-cent","cloud-lightning","trello","arrow-left-to-line","book-open-text","monitor-cloud","parking-meter","cat","heart-handshake","dam","trees","ham","circle-pause","chess-king","bean-off","rat","separator-horizontal","ambulance","signal-zero","citrus","phone-missed","calendar-off","chart-column","battery-medium","square-minus","decimals-arrow-left","folder-output","menu","image-down","terminal","angry","circle-dot-dashed","medal","cake-slice","git-graph","armchair","tickets","qr-code","copy","goal","trending-down","creative-commons","ev-charger","user-star","nfc","align-center-horizontal","car","notebook-tabs","ear","videotape","sun-moon","chart-scatter","toolbox","calendar","calendar-cog","gallery-horizontal","clipboard-x","book-open","circle-pile","rectangle-ellipsis","badge-plus","badge-info","file-headphone","bow-arrow","clipboard-pen-line","folder-search","utensils-crossed","arrow-up","arrow-up-from-dot","align-vertical-justify-start","pause","shrub","flag","biceps-flexed","align-horizontal-distribute-end","donut","calendar-plus-2","move-vertical","file-pen-line","badge-russian-ruble","radius","pilcrow","corner-left-up","georgian-lari","cable","book-user","flip-vertical","square-arrow-down","circle-plus","view","cctv","circle-arrow-left","volume","facebook","octagon-alert","panel-bottom-dashed","book-a","align-end-vertical","thumbs-up","globe","rabbit","layers-plus","banknote-arrow-down","message-square-off","dice-4","message-circle-x","folder-x","message-circle-warning","map","move","arrow-up-left","award","arrow-down-wide-narrow","unfold-horizontal","motorbike","music-4","shield-x","file-volume","disc-3","file-signal","columns-4","archive-x","square-dashed-kanban","mouse-pointer-2","clock-arrow-up","clock-fading","vegan","message-circle-plus","fast-forward","user-pen","chess-knight","wifi-pen","files","send-to-back","alarm-clock","shopping-basket","send","brush-cleaning","skip-back","book-audio","file-scan","message-square-dashed","chevrons-left","umbrella","skip-forward","clipboard-copy","map-pin-off","arrow-up-from-line","circle-chevron-up","circle-small","align-vertical-space-between","lamp-desk","circle-arrow-up","zap","beaker","paintbrush","move-left","chevron-up","instagram","pen-tool","form","pencil-ruler","dna","arrow-big-down-dash","chart-area","bug-off","card-sim","gitlab","rotate-3d","spell-check","popcorn","blocks","washing-machine","microchip","badge-minus","cloud-sun","circle","shield-alert","map-minus","separator-vertical","ampersands","user-search","fence","square-user-round","sunrise","strikethrough","calendar-days","banknote-arrow-up","dollar-sign","message-square-quote","list-minus","cloud-hail","eye-closed","app-window-mac","ellipsis","copy-check","history","satellite","bookmark-plus","folder-key","coffee","circle-power","hourglass","tickets-plane","folder-git","bomb","layers-2","battery-full","user-minus","chart-gantt","folder-tree","command","badge-dollar-sign","align-start-vertical","briefcase-conveyor-belt","message-circle-question-mark","bluetooth-off","square-square","cannabis","book","grip-horizontal","circle-minus","audio-waveform","moon-star","arrow-down-narrow-wide","database-backup","wand","receipt-turkish-lira","calendar-minus-2","copy-minus","folder-input","book-image","shirt","server-off","move-up","plug-2","chess-rook","brackets","calendar-heart","list-ordered","mic-off","arrow-big-left","square-split-horizontal","clover","sun-snow","sofa","funnel-x","clock-2","calendar-fold","fish-off","baby","leaf","fold-vertical","hop","paperclip","cigarette","minus","smile-plus","diamond-plus","file-chart-column","triangle-dashed","git-pull-request-closed","badge-check","plug-zap","heading-4","chess-queen","graduation-cap","grid-3x2","square-dashed-bottom-code","clock-7","ethernet-port","scan-text","shower-head","equal-not","move-down","clock-arrow-down","ticket-slash","ruler","circle-user-round","list-filter","map-pin-check","egg-off","cog","dog","swords","spotlight","panel-right-dashed","truck-electric","check-line","bubbles","bot","chart-bar-increasing","trash-2","air-vent","dot","file-symlink","clipboard-paste","chevron-last","book-heart","circle-parking","cloud-check","panel-left","circle-chevron-right","squares-unite","arrow-down-up","git-fork","forward","brain-circuit","between-vertical-start","database","panel-right","log-out","git-branch-plus","clipboard-minus","file-text","table-rows-split","milk-off","tv-minimal","cloud-upload","banknote","drumstick","calendar-search","bell-ring","circle-chevron-left","arrow-down","arrow-up-down","folder-dot","whole-word","monitor","disc-2","trending-up-down","tv-minimal-play","circle-stop","align-vertical-space-around","arrow-big-down","circle-parking-off","calendar-x-2","user-plus","move-diagonal-2","bandage","gallery-horizontal-end","panel-top-dashed","tram-front","podcast","audio-lines","flip-vertical-2","github","ear-off","printer","megaphone-off","arrow-big-right","section","file-clock","toy-brick","square-chevron-down","dice-1","drill","app-window","shield-check","hand-metal","spell-check-2","list-plus","rotate-ccw-key","chart-pie","copy-slash","wind","layout-panel-left","circle-percent","circle-arrow-out-down-right","square-x","italic","chart-column-increasing","step-forward","a-arrow-down","container","sticker","import","badge-turkish-lira","square-terminal","file-music","zoom-out","beef","route-off","file-user","zoom-in","square-radical","shield-half","image-upscale","book-type","smile","signpost-big","remove-formatting","cloudy","square-split-vertical","square-percent","worm","navigation-off","arrow-left","car-taxi-front","workflow","wine-off","chevrons-right-left","wine","wind-arrow-down","refresh-cw","wifi-sync","search-code","wifi-high","wifi","square-pause","align-end-horizontal","wheat-off","equal","megaphone","calendar-x","wheat","weight-tilde","egg","weight","square-pi","gamepad","circle-pound-sterling","video-off","japanese-yen","webcam","waypoints","waves-ladder","library","file-terminal","circle-chevron-down","accessibility","square-arrow-out-up-left","square-library","amphora","waves-arrow-down","tally-2","list-music","watch","kayak","wand-sparkles","sheet","circle-check-big","wallpaper","wallet-minimal","map-pinned","corner-down-left","circuit-board","wallet-cards","wallet","vote","volume-off","folder-open-dot","book-dashed","rows-3","volume-1","bluetooth","tree-pine","receipt-indian-rupee","volleyball","video","tornado","vibrate","venus-and-mars","file-search-corner","flask-conical","monitor-cog","funnel","square-star","folder-sync","vault","badge-x","van","utility-pole","arrow-up-narrow-wide","fishing-hook","utensils","users-round","users","frame","calendar-arrow-down","clock-12","user-x","user-round-x","user-round-search","images","lollipop","book-text","move-3d","lamp-floor","file-plus-corner","image","user-round-pen","badge-euro","bike","meh","user-round-cog","user-round-check","user-lock","tablets","square-play","user","option","git-branch","scroll-text","table-of-contents","upload","unplug","soup","toggle-right","unlink","ferris-wheel","camera-off","university","ungroup","unfold-vertical","layout-dashboard","undo-2","group","codesandbox","battery","undo","tent-tree","underline","rectangle-horizontal","umbrella-off","type-outline","gamepad-directional","bitcoin","bell-off","battery-plus","hand-platter","twitch","file-diff","file-up","folder-root","turntable","spline-pointer","turkish-lira","axis-3d","truck","trophy","binoculars","ghost","triangle-alert","triangle","rose","trending-up","mail-minus","tree-deciduous","folder-cog","transgender","chevrons-left-right-ellipsis","clipboard-pen","bottle-wine","alarm-clock-off","train-front-tunnel","list","newspaper","square-arrow-right","traffic-cone","badge-pound-sterling","bookmark-check","tractor","tower-control","touchpad-off","a-arrow-up","clock-check","touchpad","torus","vibrate-off","mail-check","tool-case","toilet","file-code","toggle-left","chart-column-big","timer-reset","locate-fixed","cassette-tape","battery-low","timer","ticket-x","signpost","test-tubes","calendar-arrow-up","landmark","fish-symbol","logs","loader","bold","dice-2","file-type","clipboard-clock","beer","lectern","sliders-vertical","notepad-text","pickaxe","binary","move-diagonal","thermometer-sun","door-closed","thermometer-snowflake","layout-template","thermometer","theater","smartphone-nfc","panel-bottom-close","hand-heart","maximize-2","scan-qr-code","text-quote","pocket","text-cursor-input","text-cursor","brain","key-square","text-align-justify","text-align-end","key","clock-11","text-align-center","ticket-plus","arrow-up-0-1","bell-electric","test-tube-diagonal","heading","book-open-check","panel-top-close","lasso-select","bug","telescope","layers","tangent","bus","panels-left-bottom","bed-single","chart-no-axes-gantt","file-spreadsheet","log-in","clipboard-list","tally-3","contact-round","radio","keyboard-off","tag","file-badge","battery-warning","mail-question-mark","arrow-down-from-line","briefcase","biohazard","rectangle-circle","braces","scale-3d","panel-top-bottom-dashed","mail-x","square-dashed-mouse-pointer","user-cog","lock-open","tablet-smartphone","pizza","list-indent-decrease","arrow-up-wide-narrow","message-square-warning","clock-5","table-properties","rotate-ccw","align-horizontal-justify-center","table-columns-split","antenna","memory-stick","scan-eye","table-cells-merge","square-check","heart-plus","table-2","map-pin-minus-inside","git-merge","gallery-vertical-end","table","hand-coins","syringe","wifi-low","switch-camera","clock","file-pen","git-compare-arrows","cloud-sun-rain","align-horizontal-justify-start","swiss-franc","iteration-cw","sunset","calendar-plus","sun-medium","arrow-down-z-a","bath","sun-dim","unlink-2","subscript","stretch-vertical","folder-check","stretch-horizontal","book-key","ribbon","microwave","music-2","gallery-vertical","stone","sticky-note","stethoscope","map-pin-pen","move-up-left","step-back","folder-heart","star-off","signal-medium","star","arrow-up-a-z","stamp","square-dashed-top-solid","squirrel","computer","squircle","swatch-book","receipt-cent","spool","folder-archive","folder-symlink","columns-3","ban","message-square-x","paint-roller","skull","archive","squares-exclude","square-user","building-2","circle-slash-2","map-pin-x","cake","cloud-rain","chart-bar","square-stack","wrench","square-slash","codepen","square-sigma","flag-triangle-right","square-scissors","square-round-corner","bell","list-check","square-plus","music-3","chart-bar-big","user-check","proportions","square-pilcrow","plane","webhook-off","carrot","square-arrow-left","file-cog","circle-dashed","notepad-text-dashed","magnet","square-parking","mailbox","squares-subtract","square-m","square-kanban","split","twitter","square-equal","forklift","square-dot","alarm-clock-minus","square-divide","eraser","book-marked","square-dashed-bottom","bluetooth-connected","rotate-ccw-square","chart-no-axes-column","cannabis-off","folder-kanban","square-code","mars-stroke","square-chevron-up","message-circle-off","square-chevron-left","file-box","shield-ban","paint-bucket","glass-water","square-chart-gantt","glasses","piggy-bank","square-bottom-dashed-scissors","cuboid","cloud-off","check-check","activity","axe","plane-takeoff","square-asterisk","cloud-rain-wind","square-arrow-up-right","speech","copy-x","file-axis-3d","radical","chart-column-decreasing","satellite-dish","bug-play","align-vertical-distribute-start","square-arrow-out-up-right","waves-arrow-up","tally-5","square-arrow-out-down-left","square-arrow-down-right","grid-2x2","circle-divide","pen-off","square","linkedin","life-buoy","sprout","spray-can","volume-2","battery-charging","russian-ruble","square-arrow-up-left","brick-wall-shield","footprints","speaker","building","sparkles","sparkle","spade","flag-off","book-alert","link-2","moon","bell-minus","image-up","closed-caption","drum","arrow-up-z-a","sun","solar-panel","soap-dispenser-droplet","file-key","snowflake","package-2","scissors-line-dashed","text-select","circle-alert","smartphone","ticket-check","combine","sliders-horizontal","search","mountain","mars","picture-in-picture-2","monitor-off","flower-2","slack","squares-intersect","siren","signature","keyboard-music","star-half","signal-low","code-xml","pencil-line","mails","brain-cog","tablet","sigma","pi","trash","book-down","hdmi-port","fan","case-upper","circle-fading-arrow-up","shrimp","croissant","ice-cream-bowl","candy","barcode","radar","shopping-bag","bed","ship-wheel","divide","grape","shield-user","party-popper","file-chart-pie","shield-question-mark","shield-plus","dice-6","shield-off","calendar-range","heading-6","zap-off","square-check-big","shield","shell","globe-x","laptop-minimal","share","shapes","map-pin-minus","settings-2","chart-spline","message-square-more","settings","chart-candlestick","server-crash","arrow-down-a-z","server-cog","server","move-horizontal","file-sliders","frown","send-horizontal","cup-soda","search-x","search-slash","sword","expand","search-alert","earth","slice","dice-3","milk","mouse-pointer-ban","crown","circle-slash","circle-star","rotate-cw-square","atom","package-x","bed-double","scroll","circle-dot","file-exclamation-point","hand-fist","message-circle-code","folder-git-2","message-square-code","screen-share-off","screen-share","mail","arrow-big-left-dash","school","dumbbell","scan-search","saudi-riyal","orbit","scale","scan-face","flashlight","panel-top-open","scan-barcode","scan","notebook","redo-2","save-off","square-menu","panel-right-open","monitor-smartphone","laptop","scan-line","clock-4","square-arrow-up","book-minus","file-question-mark","sandwich","salad","sailboat","arrow-down-to-line","move-down-left","refresh-ccw","venetian-mask","calendar-check-2","rows-4","spline","banknote-x","git-pull-request-create-arrow","rows-2","circle-check","router","route","roller-coaster","hammer","rocket","rewind","timer-off","arrow-big-right-dash","reply","replace-all","replace","backpack","repeat-2","repeat","youtube","regex","refrigerator","arrow-down-right","refresh-cw-off","receipt","wifi-zero","copyright","redo","clapperboard","rectangle-vertical","image-off","rectangle-goggles","heading-2","receipt-swiss-franc","receipt-russian-ruble","square-chevron-right","mail-search","receipt-japanese-yen","receipt-euro","ratio","rainbow","puzzle","radio-receiver","tally-1","ampersand","radiation","shopping-cart","align-vertical-justify-end","quote","alarm-smoke","pyramid","file-input","clock-8","hand-grab","cloud-cog","blend","hd","radio-tower","list-tree","droplet","projector","eye","loader-pinwheel","printer-check","banana","gpu","power-off","power","circle-equal","pound-sterling","popsicle","folder-search-2","calculator","text-initial","arrow-up-right","plus","leafy-green","message-square-dot","file-chart-line","columns-3-cog","plug","play","minimize-2","plane-landing","pin-off","cone","currency","file-image","pill","palette","barrel","gallery-thumbnails","mouse-off","cpu","pilcrow-left","thumbs-down","merge","hamburger","piano","hat-glasses","code","circle-arrow-out-down-left","phone-off","phone-incoming","phone-forwarded","file-video-camera","phone","kanban","bone","apple","rocking-chair","bot-off","percent","pentagon","pencil-off","circle-arrow-out-up-left","dices","cable-car","arrow-down-left","square-activity","pen-line","cigarette-off","highlighter","message-circle","circle-arrow-out-up-right","pc-case","diff","fold-horizontal","shovel","calendar-1","cloud-moon","square-arrow-out-down-right","panel-top","clock-plus","save","cloud-snow","anvil","arrow-big-up-dash","panel-right-close","panel-left-right-dashed","panel-left-open","panel-left-dashed","monitor-pause","house-wifi","chevrons-down-up","clipboard-plus","circle-x","list-end","panel-bottom","panda","chevrons-right","paintbrush-vertical","message-square-reply","corner-down-right","package-search","package-plus","lamp-wall-down","package-open","paw-print","ellipsis-vertical","snail","square-stop","arrow-up-1-0","align-horizontal-justify-end","scan-heart","align-vertical-distribute-end","heart-crack","airplay","omega","map-pin","octagon-pause","monitor-x","list-chevrons-down-up","octagon-minus","square-pen","nut-off","nut","dice-5","octagon","ticket","circle-ellipsis","file-minus","train-front","bookmark","network","album","navigation-2","chart-bar-decreasing","navigation","calendar-sync","funnel-plus","store","circle-arrow-down","notebook-pen","egg-fried","move-up-right","move-right","corner-right-up","move-down-right","ruler-dimension-line","user-round-plus","panel-left-close","mouse-pointer","pilcrow-right","user-round-minus","circle-play","monitor-up","mail-plus","monitor-stop","monitor-speaker","monitor-play","mouse-pointer-2-off","drone","slash","milestone","aperture","arrow-right-left","monitor-dot","vector-square","circle-gauge","monitor-check","check","text-search","arrow-down-to-dot","monitor-down","microscope","chef-hat","mic-vocal","mic","file-archive","signal-high","inbox","flip-horizontal-2","message-square-text","image-play","align-horizontal-space-between","message-square-share","calendar-check","database-zap","droplets","message-square-plus","message-square-lock","message-square-heart","layout-list","file-search","message-square-diff","alarm-clock-plus","circle-dollar-sign","usb","house","receipt-pound-sterling","message-circle-heart","message-circle-dashed","id-card","mouse","minimize","maximize","land-plot","list-indent-increase","map-pin-x-inside","book-x","package","hospital","map-pin-plus","disc","headphone-off","asterisk","file-play","octagon-x","languages","ligature","alarm-clock-check","guitar","bird","beer-off","scooter","square-parking-off","notebook-text","arrow-right-to-line","ticket-minus","tally-4","lock-keyhole-open","lock-keyhole","door-open","flag-triangle-left","grid-3x3","file","lock","pocket-knife","book-copy","castle","car-front","clock-alert","reply-all","cloud-moon-rain","clipboard-type","locate","list-todo","printer-x","loader-circle","list-start","cloud-sync","a-large-small","list-video","waves","map-plus","laugh","list-collapse","list-chevrons-up-down","list-checks","arrow-right-from-line","flame-kindling","square-power","link-2-off","bring-to-front","link","figma","bell-plus","line-squiggle","caravan","lightbulb","folders","mail-warning","library-big","layout-panel-top","layout-grid","chevrons-left-right","chart-line","file-lock","cast","circle-fading-plus","clock-10","undo-dot","target","list-filter-plus","lasso","drama","book-plus","baseline","martini","contrast","lamp-wall-up","candy-off","lamp-ceiling","book-check","lamp","book-lock","keyboard","briefcase-medical","calendars","text-align-start","file-x-corner","hop-off","warehouse","joystick","drafting-compass","save-all","iteration-ccw","inspection-panel","info","infinity","indian-rupee","image-plus","book-headphones","credit-card","image-minus","id-card-lanyard","ice-cream-cone","shredder","panel-bottom-open","house-plug","house-heart","hotel","balloon","map-pin-plus-inside","bookmark-x","badge-question-mark","pen","helicopter","candy-cane","heart-pulse","heart-off","gamepad-2","heart-minus","heart","headset","file-x","shield-minus","circle-off","dessert","eclipse","church","heading-5","cylinder","badge-japanese-yen","heading-3","receipt-text","heading-1","haze","hard-hat","hard-drive-upload","file-output","disc-album","file-digit","arrow-down-0-1","captions","handbag","hand","philippine-peso","badge-alert","grip","folder-pen","cross","flower","chevron-right","grid-2x2-check","square-arrow-down-left","share-2","git-pull-request-draft","git-pull-request-create","cookie","folder-lock","git-compare","git-commit-vertical","chess-pawn","git-commit-horizontal","briefcase-business","clock-9","message-circle-reply","gift","triangle-right","folder-clock","gem","gauge","type","webhook","fullscreen","align-horizontal-distribute-start","fuel","folder-up","pointer-off","turtle","camera","folder-open","folder-minus","git-pull-request","bluetooth-searching","arrow-up-to-line","squircle-dashed","clock-3","badge-percent","shuffle","folder-closed","folder","grid-2x2-plus","flask-round","box","flask-conical-off","clock-1","file-heart","flashlight-off","space","fish","fire-extinguisher","fingerprint-pattern","corner-up-left","clock-6","film","key-round","headphones","tv","file-type-corner","file-stack","rss","brick-wall","at-sign","map-pin-check-inside","file-minus-corner","music","handshake","file-check","circle-user","copy-plus","file-chart-column-increasing","file-braces","shrink","factory","external-link","search-check","clipboard-check","columns-2","euro","equal-approximately","align-center-vertical","earth-lock","droplet-off","dribbble","cloud-fog","coins","dock","map-pin-house","package-check","chevron-first","pencil","diamond-minus","list-x","diameter","delete","corner-up-right","construction","pin","crosshair","crop","badge-indian-rupee","corner-right-down","redo-dot","copyleft","align-start-horizontal","chart-column-stacked","file-plus","git-pull-request-arrow","contact","decimals-arrow-right","bell-dot","folder-down","component","compass","align-horizontal-space-around","door-closed-locked","club","diamond","blinds","cloud-drizzle","cloud-backup","book-search","git-branch-minus","clipboard","recycle","mountain-snow","luggage","circle-arrow-right","bot-message-square","phone-outgoing","smartphone-charging","chromium","train-track","chevrons-down","chevron-left","chess-bishop","cherry","chart-no-axes-column-decreasing","chart-no-axes-column-increasing","chart-no-axes-combined","chart-network","chart-bar-stacked","arrow-down-1-0","case-sensitive","case-lower","arrow-left-right","lightbulb-off","panels-top-left","calendar-minus","locate-off","annoyed","test-tube","brick-wall-fire","cooking-pot","boxes","boom-box","book-up","laptop-minimal-check","mail-open","square-function","baggage-claim","variable","arrow-right","archive-restore"},{"rbxassetid://134788982523503", "rbxassetid://122251837315841"},{[48]={{1,{24,24},{175,0}},{1,{24,24},{525,100}},{1,{24,24},{900,150}},{1,{24,24},{925,650}},{1,{24,24},{550,375}},{1,{24,24},{725,75}},{1,{24,24},{675,600}},{2,{24,24},{100,0}},{1,{24,24},{150,250}},{1,{24,24},{525,150}},{1,{24,24},{800,100}},{1,{24,24},{225,225}},{1,{24,24},{475,500}},{1,{24,24},{375,450}},{1,{24,24},{50,75}},{1,{24,24},{550,400}},{1,{24,24},{825,400}},{1,{24,24},{500,700}},{1,{24,24},{375,0}},{1,{24,24},{250,175}},{1,{24,24},{175,650}},{1,{24,24},{750,550}},{1,{24,24},{0,900}},{1,{24,24},{175,800}},{1,{24,24},{225,300}},{1,{24,24},{425,925}},{1,{24,24},{200,225}},{1,{24,24},{900,50}},{1,{24,24},{675,900}},{1,{24,24},{675,75}},{1,{24,24},{500,0}},{1,{24,24},{700,150}},{1,{24,24},{950,275}},{1,{24,24},{500,600}},{1,{24,24},{575,750}},{1,{24,24},{25,800}},{1,{24,24},{450,750}},{1,{24,24},{100,100}},{1,{24,24},{275,675}},{1,{24,24},{825,800}},{1,{24,24},{0,425}},{2,{24,24},{100,125}},{1,{24,24},{125,575}},{1,{24,24},{525,575}},{1,{24,24},{25,675}},{1,{24,24},{400,500}},{1,{24,24},{125,825}},{1,{24,24},{900,975}},{1,{24,24},{375,850}},{1,{24,24},{225,200}},{1,{24,24},{200,425}},{1,{24,24},{400,125}},{1,{24,24},{525,725}},{1,{24,24},{200,875}},{1,{24,24},{900,300}},{1,{24,24},{125,350}},{1,{24,24},{350,525}},{1,{24,24},{175,450}},{1,{24,24},{950,525}},{1,{24,24},{700,775}},{1,{24,24},{725,825}},{1,{24,24},{975,425}},{2,{24,24},{175,50}},{1,{24,24},{425,550}},{1,{24,24},{800,350}},{1,{24,24},{525,300}},{1,{24,24},{225,100}},{1,{24,24},{825,25}},{1,{24,24},{975,225}},{1,{24,24},{875,450}},{1,{24,24},{25,925}},{1,{24,24},{75,200}},{1,{24,24},{800,575}},{1,{24,24},{950,700}},{1,{24,24},{500,50}},{2,{24,24},{50,200}},{1,{24,24},{625,525}},{2,{24,24},{75,50}},{1,{24,24},{975,275}},{1,{24,24},{800,900}},{1,{24,24},{300,75}},{1,{24,24},{500,75}},{1,{24,24},{100,75}},{1,{24,24},{475,325}},{1,{24,24},{825,775}},{1,{24,24},{500,775}},{1,{24,24},{50,825}},{1,{24,24},{300,475}},{1,{24,24},{125,125}},{2,{24,24},{125,25}},{1,{24,24},{475,650}},{1,{24,24},{200,950}},{1,{24,24},{75,875}},{1,{24,24},{675,275}},{1,{24,24},{950,225}},{1,{24,24},{400,325}},{1,{24,24},{725,500}},{1,{24,24},{175,700}},{1,{24,24},{200,550}},{1,{24,24},{300,50}},{1,{24,24},{675,50}},{1,{24,24},{725,975}},{1,{24,24},{25,250}},{1,{24,24},{275,200}},{1,{24,24},{150,950}},{1,{24,24},{875,325}},{1,{24,24},{150,425}},{1,{24,24},{625,350}},{1,{24,24},{550,225}},{1,{24,24},{750,950}},{1,{24,24},{450,500}},{1,{24,24},{0,650}},{1,{24,24},{0,600}},{1,{24,24},{175,225}},{1,{24,24},{475,775}},{1,{24,24},{825,525}},{1,{24,24},{200,0}},{1,{24,24},{400,975}},{1,{24,24},{250,425}},{1,{24,24},{375,825}},{1,{24,24},{325,225}},{1,{24,24},{450,150}},{1,{24,24},{300,100}},{1,{24,24},{725,750}},{1,{24,24},{450,325}},{1,{24,24},{450,450}},{1,{24,24},{325,750}},{1,{24,24},{0,975}},{1,{24,24},{800,800}},{1,{24,24},{75,125}},{1,{24,24},{275,375}},{1,{24,24},{450,625}},{1,{24,24},{125,400}},{1,{24,24},{225,700}},{1,{24,24},{50,175}},{1,{24,24},{800,850}},{1,{24,24},{775,475}},{1,{24,24},{325,425}},{1,{24,24},{825,125}},{1,{24,24},{975,750}},{1,{24,24},{25,725}},{1,{24,24},{625,200}},{1,{24,24},{950,950}},{1,{24,24},{650,500}},{1,{24,24},{0,100}},{1,{24,24},{400,175}},{1,{24,24},{575,575}},{1,{24,24},{150,650}},{2,{24,24},{125,0}},{1,{24,24},{850,700}},{1,{24,24},{200,400}},{1,{24,24},{925,750}},{1,{24,24},{125,425}},{1,{24,24},{475,75}},{1,{24,24},{750,175}},{1,{24,24},{675,25}},{1,{24,24},{250,225}},{1,{24,24},{650,25}},{1,{24,24},{875,400}},{1,{24,24},{75,275}},{1,{24,24},{175,175}},{1,{24,24},{650,200}},{1,{24,24},{275,225}},{1,{24,24},{50,625}},{1,{24,24},{325,575}},{2,{24,24},{0,0}},{1,{24,24},{250,75}},{1,{24,24},{100,200}},{1,{24,24},{50,125}},{1,{24,24},{825,375}},{1,{24,24},{550,825}},{1,{24,24},{400,475}},{1,{24,24},{150,275}},{1,{24,24},{25,100}},{1,{24,24},{600,200}},{1,{24,24},{300,250}},{1,{24,24},{950,200}},{1,{24,24},{400,450}},{1,{24,24},{0,350}},{1,{24,24},{550,700}},{1,{24,24},{850,375}},{1,{24,24},{175,575}},{1,{24,24},{500,425}},{1,{24,24},{150,375}},{1,{24,24},{75,400}},{1,{24,24},{125,750}},{1,{24,24},{500,925}},{1,{24,24},{600,75}},{2,{24,24},{100,25}},{1,{24,24},{125,450}},{1,{24,24},{0,625}},{2,{24,24},{100,50}},{1,{24,24},{475,350}},{1,{24,24},{400,750}},{1,{24,24},{625,550}},{1,{24,24},{150,300}},{1,{24,24},{75,50}},{1,{24,24},{675,950}},{1,{24,24},{850,100}},{1,{24,24},{725,525}},{1,{24,24},{850,175}},{1,{24,24},{150,225}},{1,{24,24},{725,375}},{1,{24,24},{150,625}},{1,{24,24},{950,150}},{1,{24,24},{200,700}},{1,{24,24},{975,125}},{1,{24,24},{600,475}},{1,{24,24},{925,225}},{1,{24,24},{50,250}},{1,{24,24},{75,250}},{1,{24,24},{150,125}},{1,{24,24},{800,975}},{1,{24,24},{650,475}},{1,{24,24},{850,300}},{1,{24,24},{875,500}},{1,{24,24},{775,100}},{1,{24,24},{0,775}},{1,{24,24},{175,675}},{1,{24,24},{50,675}},{1,{24,24},{100,125}},{1,{24,24},{500,950}},{1,{24,24},{525,600}},{1,{24,24},{275,425}},{1,{24,24},{225,475}},{2,{24,24},{50,25}},{1,{24,24},{150,925}},{1,{24,24},{400,425}},{1,{24,24},{850,975}},{1,{24,24},{625,0}},{2,{24,24},{75,150}},{1,{24,24},{675,200}},{1,{24,24},{875,475}},{1,{24,24},{75,25}},{1,{24,24},{725,650}},{1,{24,24},{850,500}},{1,{24,24},{425,100}},{1,{24,24},{850,550}},{1,{24,24},{100,350}},{1,{24,24},{250,600}},{1,{24,24},{875,225}},{1,{24,24},{275,350}},{1,{24,24},{925,850}},{1,{24,24},{825,575}},{1,{24,24},{150,525}},{1,{24,24},{825,250}},{1,{24,24},{75,225}},{1,{24,24},{375,275}},{1,{24,24},{450,225}},{1,{24,24},{0,175}},{1,{24,24},{250,750}},{1,{24,24},{525,125}},{2,{24,24},{200,75}},{1,{24,24},{200,200}},{1,{24,24},{725,450}},{1,{24,24},{225,900}},{1,{24,24},{400,225}},{1,{24,24},{625,375}},{1,{24,24},{700,500}},{1,{24,24},{75,825}},{1,{24,24},{600,600}},{1,{24,24},{700,100}},{1,{24,24},{25,200}},{1,{24,24},{100,475}},{1,{24,24},{350,175}},{1,{24,24},{350,225}},{1,{24,24},{0,925}},{1,{24,24},{875,425}},{1,{24,24},{775,650}},{1,{24,24},{350,875}},{1,{24,24},{375,75}},{2,{24,24},{75,100}},{1,{24,24},{400,700}},{1,{24,24},{125,225}},{1,{24,24},{475,250}},{1,{24,24},{300,375}},{1,{24,24},{500,850}},{1,{24,24},{975,100}},{1,{24,24},{800,550}},{1,{24,24},{150,50}},{1,{24,24},{975,925}},{1,{24,24},{350,475}},{1,{24,24},{625,875}},{1,{24,24},{775,775}},{1,{24,24},{950,600}},{1,{24,24},{450,100}},{1,{24,24},{125,250}},{1,{24,24},{625,175}},{1,{24,24},{675,425}},{1,{24,24},{50,975}},{1,{24,24},{700,25}},{1,{24,24},{550,275}},{1,{24,24},{200,25}},{1,{24,24},{800,25}},{1,{24,24},{450,300}},{1,{24,24},{375,600}},{1,{24,24},{375,925}},{1,{24,24},{475,25}},{1,{24,24},{575,325}},{1,{24,24},{200,525}},{1,{24,24},{550,125}},{1,{24,24},{250,725}},{1,{24,24},{825,825}},{1,{24,24},{675,225}},{1,{24,24},{200,250}},{1,{24,24},{875,150}},{1,{24,24},{350,50}},{1,{24,24},{875,950}},{1,{24,24},{425,175}},{1,{24,24},{250,650}},{1,{24,24},{0,725}},{1,{24,24},{250,100}},{1,{24,24},{0,150}},{1,{24,24},{525,0}},{1,{24,24},{125,950}},{1,{24,24},{325,125}},{1,{24,24},{750,750}},{1,{24,24},{525,50}},{1,{24,24},{25,450}},{1,{24,24},{575,375}},{1,{24,24},{100,550}},{1,{24,24},{100,225}},{1,{24,24},{700,425}},{1,{24,24},{275,0}},{1,{24,24},{525,250}},{2,{24,24},{125,50}},{1,{24,24},{950,325}},{1,{24,24},{375,175}},{1,{24,24},{425,325}},{1,{24,24},{625,275}},{1,{24,24},{425,50}},{1,{24,24},{775,600}},{1,{24,24},{725,625}},{1,{24,24},{975,175}},{1,{24,24},{575,650}},{1,{24,24},{550,75}},{1,{24,24},{175,325}},{1,{24,24},{400,150}},{1,{24,24},{950,100}},{1,{24,24},{475,625}},{1,{24,24},{225,25}},{1,{24,24},{800,700}},{1,{24,24},{350,375}},{1,{24,24},{825,725}},{1,{24,24},{450,950}},{1,{24,24},{825,100}},{1,{24,24},{525,175}},{1,{24,24},{425,125}},{1,{24,24},{575,300}},{1,{24,24},{0,325}},{1,{24,24},{650,375}},{1,{24,24},{0,875}},{1,{24,24},{325,650}},{1,{24,24},{925,275}},{1,{24,24},{75,550}},{1,{24,24},{200,900}},{1,{24,24},{575,825}},{1,{24,24},{275,500}},{1,{24,24},{100,725}},{1,{24,24},{875,850}},{1,{24,24},{150,775}},{1,{24,24},{275,75}},{1,{24,24},{550,675}},{1,{24,24},{825,150}},{1,{24,24},{575,50}},{1,{24,24},{775,175}},{1,{24,24},{625,325}},{1,{24,24},{550,900}},{1,{24,24},{400,300}},{1,{24,24},{675,150}},{1,{24,24},{675,650}},{1,{24,24},{650,725}},{1,{24,24},{750,75}},{1,{24,24},{275,850}},{1,{24,24},{300,400}},{1,{24,24},{900,750}},{1,{24,24},{525,775}},{1,{24,24},{375,300}},{1,{24,24},{125,900}},{1,{24,24},{925,150}},{1,{24,24},{25,775}},{1,{24,24},{175,550}},{1,{24,24},{650,150}},{1,{24,24},{600,950}},{1,{24,24},{650,775}},{1,{24,24},{400,775}},{1,{24,24},{775,950}},{1,{24,24},{125,475}},{1,{24,24},{375,150}},{1,{24,24},{325,175}},{1,{24,24},{25,550}},{1,{24,24},{875,825}},{1,{24,24},{0,50}},{1,{24,24},{500,300}},{1,{24,24},{75,775}},{1,{24,24},{75,600}},{1,{24,24},{475,150}},{1,{24,24},{450,25}},{1,{24,24},{25,625}},{1,{24,24},{75,625}},{1,{24,24},{450,725}},{1,{24,24},{400,250}},{1,{24,24},{925,600}},{1,{24,24},{175,100}},{1,{24,24},{250,675}},{1,{24,24},{50,850}},{1,{24,24},{150,350}},{1,{24,24},{175,250}},{1,{24,24},{475,300}},{1,{24,24},{350,825}},{1,{24,24},{450,600}},{1,{24,24},{400,525}},{1,{24,24},{100,575}},{1,{24,24},{25,825}},{1,{24,24},{825,750}},{1,{24,24},{300,800}},{1,{24,24},{875,875}},{1,{24,24},{425,300}},{1,{24,24},{75,300}},{1,{24,24},{225,575}},{1,{24,24},{225,325}},{1,{24,24},{300,125}},{1,{24,24},{425,225}},{1,{24,24},{100,175}},{1,{24,24},{125,175}},{1,{24,24},{750,150}},{2,{24,24},{200,25}},{1,{24,24},{725,400}},{1,{24,24},{25,750}},{1,{24,24},{950,775}},{1,{24,24},{900,850}},{1,{24,24},{400,275}},{1,{24,24},{25,150}},{1,{24,24},{0,225}},{1,{24,24},{50,600}},{1,{24,24},{175,375}},{1,{24,24},{975,875}},{1,{24,24},{375,750}},{1,{24,24},{175,200}},{1,{24,24},{775,150}},{1,{24,24},{275,900}},{1,{24,24},{925,775}},{1,{24,24},{425,800}},{1,{24,24},{125,200}},{1,{24,24},{150,725}},{1,{24,24},{25,900}},{1,{24,24},{175,625}},{1,{24,24},{900,350}},{1,{24,24},{425,650}},{1,{24,24},{175,75}},{1,{24,24},{925,425}},{1,{24,24},{850,0}},{1,{24,24},{775,900}},{1,{24,24},{675,775}},{1,{24,24},{225,550}},{1,{24,24},{375,425}},{1,{24,24},{175,50}},{1,{24,24},{450,900}},{1,{24,24},{250,700}},{1,{24,24},{800,625}},{1,{24,24},{925,125}},{1,{24,24},{850,450}},{1,{24,24},{225,375}},{1,{24,24},{375,375}},{2,{24,24},{200,50}},{1,{24,24},{725,300}},{1,{24,24},{675,0}},{1,{24,24},{625,25}},{1,{24,24},{575,925}},{1,{24,24},{600,400}},{1,{24,24},{500,100}},{1,{24,24},{700,825}},{1,{24,24},{0,0}},{1,{24,24},{550,200}},{1,{24,24},{650,875}},{1,{24,24},{775,225}},{1,{24,24},{350,25}},{1,{24,24},{650,850}},{1,{24,24},{450,400}},{2,{24,24},{150,125}},{1,{24,24},{50,350}},{1,{24,24},{725,575}},{1,{24,24},{825,50}},{2,{24,24},{175,100}},{1,{24,24},{925,575}},{1,{24,24},{400,950}},{1,{24,24},{850,150}},{1,{24,24},{150,325}},{1,{24,24},{550,850}},{1,{24,24},{925,475}},{1,{24,24},{525,750}},{1,{24,24},{375,350}},{1,{24,24},{775,725}},{1,{24,24},{575,900}},{2,{24,24},{100,150}},{1,{24,24},{750,400}},{1,{24,24},{0,275}},{1,{24,24},{425,150}},{2,{24,24},{125,125}},{2,{24,24},{175,75}},{1,{24,24},{250,375}},{2,{24,24},{150,100}},{2,{24,24},{225,25}},{1,{24,24},{600,675}},{2,{24,24},{50,175}},{1,{24,24},{375,950}},{2,{24,24},{150,75}},{2,{24,24},{0,225}},{1,{24,24},{625,850}},{1,{24,24},{100,25}},{2,{24,24},{0,200}},{1,{24,24},{725,100}},{1,{24,24},{400,675}},{1,{24,24},{150,400}},{2,{24,24},{225,0}},{2,{24,24},{50,150}},{1,{24,24},{0,800}},{2,{24,24},{25,175}},{1,{24,24},{550,925}},{1,{24,24},{600,325}},{1,{24,24},{575,100}},{2,{24,24},{25,75}},{1,{24,24},{525,475}},{2,{24,24},{125,75}},{2,{24,24},{150,50}},{2,{24,24},{200,0}},{1,{24,24},{550,475}},{1,{24,24},{50,800}},{1,{24,24},{450,200}},{1,{24,24},{50,0}},{1,{24,24},{950,500}},{1,{24,24},{800,675}},{1,{24,24},{125,75}},{2,{24,24},{25,150}},{1,{24,24},{625,950}},{1,{24,24},{975,75}},{2,{24,24},{50,125}},{1,{24,24},{450,550}},{2,{24,24},{150,25}},{1,{24,24},{550,800}},{1,{24,24},{500,150}},{2,{24,24},{175,0}},{2,{24,24},{25,125}},{1,{24,24},{650,425}},{1,{24,24},{250,500}},{1,{24,24},{275,400}},{2,{24,24},{50,100}},{2,{24,24},{0,150}},{2,{24,24},{75,75}},{2,{24,24},{150,0}},{1,{24,24},{500,400}},{1,{24,24},{25,425}},{1,{24,24},{625,675}},{2,{24,24},{25,100}},{1,{24,24},{275,175}},{1,{24,24},{775,925}},{1,{24,24},{375,875}},{2,{24,24},{50,75}},{2,{24,24},{0,100}},{1,{24,24},{900,775}},{2,{24,24},{50,50}},{2,{24,24},{0,75}},{1,{24,24},{225,625}},{1,{24,24},{250,625}},{1,{24,24},{125,975}},{1,{24,24},{800,125}},{1,{24,24},{700,800}},{1,{24,24},{275,625}},{2,{24,24},{0,50}},{1,{24,24},{325,50}},{2,{24,24},{50,0}},{2,{24,24},{0,25}},{1,{24,24},{25,275}},{1,{24,24},{500,375}},{2,{24,24},{25,0}},{1,{24,24},{950,975}},{1,{24,24},{975,975}},{1,{24,24},{25,875}},{1,{24,24},{25,500}},{1,{24,24},{550,150}},{1,{24,24},{925,975}},{1,{24,24},{925,950}},{1,{24,24},{950,925}},{1,{24,24},{800,200}},{1,{24,24},{400,650}},{1,{24,24},{175,300}},{1,{24,24},{400,725}},{1,{24,24},{225,775}},{1,{24,24},{325,525}},{1,{24,24},{825,175}},{1,{24,24},{875,975}},{1,{24,24},{225,125}},{1,{24,24},{125,300}},{1,{24,24},{375,700}},{1,{24,24},{925,925}},{1,{24,24},{950,900}},{1,{24,24},{900,925}},{1,{24,24},{725,850}},{1,{24,24},{500,975}},{1,{24,24},{975,950}},{1,{24,24},{250,900}},{1,{24,24},{375,550}},{1,{24,24},{475,850}},{1,{24,24},{875,700}},{1,{24,24},{825,975}},{1,{24,24},{850,950}},{1,{24,24},{975,450}},{1,{24,24},{675,975}},{1,{24,24},{875,925}},{1,{24,24},{325,500}},{1,{24,24},{75,475}},{1,{24,24},{925,875}},{1,{24,24},{950,850}},{1,{24,24},{975,825}},{1,{24,24},{800,225}},{1,{24,24},{875,900}},{1,{24,24},{500,450}},{1,{24,24},{225,500}},{1,{24,24},{225,175}},{1,{24,24},{825,950}},{1,{24,24},{850,750}},{1,{24,24},{900,875}},{1,{24,24},{825,450}},{1,{24,24},{950,825}},{1,{24,24},{775,975}},{1,{24,24},{625,300}},{1,{24,24},{450,0}},{1,{24,24},{350,75}},{1,{24,24},{275,125}},{1,{24,24},{225,725}},{1,{24,24},{825,925}},{1,{24,24},{750,100}},{1,{24,24},{850,25}},{1,{24,24},{375,525}},{1,{24,24},{950,800}},{1,{24,24},{750,675}},{1,{24,24},{975,775}},{1,{24,24},{25,300}},{1,{24,24},{750,975}},{1,{24,24},{800,925}},{1,{24,24},{75,350}},{1,{24,24},{475,450}},{1,{24,24},{900,825}},{1,{24,24},{825,900}},{1,{24,24},{900,400}},{1,{24,24},{925,800}},{1,{24,24},{300,750}},{1,{24,24},{825,875}},{1,{24,24},{775,125}},{1,{24,24},{900,800}},{1,{24,24},{325,300}},{1,{24,24},{25,650}},{1,{24,24},{300,200}},{1,{24,24},{0,75}},{1,{24,24},{700,975}},{1,{24,24},{750,300}},{1,{24,24},{675,475}},{1,{24,24},{900,550}},{1,{24,24},{725,950}},{1,{24,24},{50,300}},{1,{24,24},{0,475}},{1,{24,24},{750,925}},{1,{24,24},{800,875}},{1,{24,24},{850,825}},{1,{24,24},{25,0}},{1,{24,24},{250,450}},{1,{24,24},{825,850}},{1,{24,24},{875,800}},{2,{24,24},{75,25}},{1,{24,24},{325,725}},{1,{24,24},{950,725}},{1,{24,24},{975,700}},{1,{24,24},{800,50}},{1,{24,24},{700,950}},{1,{24,24},{550,50}},{1,{24,24},{750,900}},{1,{24,24},{650,400}},{1,{24,24},{225,350}},{1,{24,24},{325,75}},{1,{24,24},{725,925}},{1,{24,24},{875,775}},{1,{24,24},{900,500}},{1,{24,24},{725,875}},{1,{24,24},{0,525}},{1,{24,24},{100,900}},{1,{24,24},{550,325}},{1,{24,24},{425,625}},{1,{24,24},{675,375}},{1,{24,24},{250,200}},{1,{24,24},{200,575}},{1,{24,24},{875,0}},{1,{24,24},{175,500}},{1,{24,24},{0,400}},{1,{24,24},{600,425}},{1,{24,24},{675,725}},{1,{24,24},{475,675}},{1,{24,24},{225,975}},{1,{24,24},{100,325}},{1,{24,24},{350,775}},{1,{24,24},{750,875}},{1,{24,24},{550,250}},{1,{24,24},{775,850}},{1,{24,24},{675,350}},{1,{24,24},{725,900}},{1,{24,24},{800,825}},{1,{24,24},{625,775}},{1,{24,24},{650,525}},{1,{24,24},{300,650}},{1,{24,24},{500,575}},{1,{24,24},{725,600}},{1,{24,24},{900,725}},{1,{24,24},{450,775}},{1,{24,24},{975,650}},{1,{24,24},{950,675}},{1,{24,24},{100,400}},{1,{24,24},{400,600}},{1,{24,24},{650,950}},{1,{24,24},{675,925}},{1,{24,24},{375,625}},{1,{24,24},{575,125}},{1,{24,24},{700,900}},{1,{24,24},{925,725}},{1,{24,24},{200,100}},{1,{24,24},{400,25}},{1,{24,24},{775,825}},{1,{24,24},{750,225}},{1,{24,24},{300,175}},{1,{24,24},{300,875}},{1,{24,24},{950,75}},{1,{24,24},{300,225}},{1,{24,24},{875,725}},{1,{24,24},{825,200}},{1,{24,24},{925,675}},{1,{24,24},{200,325}},{1,{24,24},{200,975}},{1,{24,24},{100,300}},{1,{24,24},{250,350}},{1,{24,24},{125,725}},{1,{24,24},{475,575}},{1,{24,24},{125,550}},{1,{24,24},{600,975}},{1,{24,24},{600,150}},{1,{24,24},{575,675}},{1,{24,24},{325,675}},{1,{24,24},{700,875}},{1,{24,24},{225,600}},{1,{24,24},{250,150}},{1,{24,24},{225,825}},{1,{24,24},{25,225}},{1,{24,24},{475,50}},{1,{24,24},{50,375}},{1,{24,24},{900,375}},{1,{24,24},{200,300}},{1,{24,24},{925,400}},{1,{24,24},{325,850}},{1,{24,24},{150,900}},{1,{24,24},{475,975}},{1,{24,24},{925,900}},{1,{24,24},{525,525}},{1,{24,24},{775,800}},{1,{24,24},{700,525}},{1,{24,24},{100,925}},{1,{24,24},{300,25}},{1,{24,24},{575,525}},{1,{24,24},{450,250}},{1,{24,24},{850,725}},{1,{24,24},{800,500}},{1,{24,24},{150,0}},{1,{24,24},{900,675}},{1,{24,24},{25,175}},{1,{24,24},{350,725}},{1,{24,24},{825,500}},{1,{24,24},{950,625}},{1,{24,24},{700,750}},{1,{24,24},{550,425}},{1,{24,24},{975,600}},{1,{24,24},{875,200}},{1,{24,24},{200,725}},{1,{24,24},{700,225}},{1,{24,24},{800,775}},{1,{24,24},{375,575}},{1,{24,24},{575,975}},{2,{24,24},{125,100}},{1,{24,24},{650,900}},{1,{24,24},{175,525}},{1,{24,24},{375,475}},{1,{24,24},{300,625}},{1,{24,24},{500,225}},{1,{24,24},{100,50}},{1,{24,24},{675,875}},{1,{24,24},{550,450}},{1,{24,24},{750,800}},{1,{24,24},{275,275}},{1,{24,24},{875,675}},{1,{24,24},{125,150}},{1,{24,24},{400,0}},{1,{24,24},{900,650}},{1,{24,24},{900,900}},{1,{24,24},{925,625}},{1,{24,24},{975,575}},{1,{24,24},{875,25}},{1,{24,24},{550,975}},{1,{24,24},{400,75}},{1,{24,24},{300,975}},{1,{24,24},{350,750}},{1,{24,24},{900,250}},{1,{24,24},{675,250}},{1,{24,24},{600,925}},{1,{24,24},{625,900}},{1,{24,24},{675,850}},{1,{24,24},{800,275}},{1,{24,24},{175,950}},{1,{24,24},{725,800}},{1,{24,24},{650,250}},{1,{24,24},{775,750}},{1,{24,24},{425,950}},{1,{24,24},{750,775}},{1,{24,24},{150,150}},{1,{24,24},{825,700}},{1,{24,24},{975,500}},{1,{24,24},{850,675}},{1,{24,24},{700,50}},{1,{24,24},{875,650}},{1,{24,24},{700,850}},{1,{24,24},{425,825}},{1,{24,24},{675,750}},{1,{24,24},{900,0}},{1,{24,24},{300,600}},{1,{24,24},{75,650}},{1,{24,24},{225,150}},{1,{24,24},{550,550}},{1,{24,24},{775,400}},{1,{24,24},{800,600}},{1,{24,24},{75,150}},{1,{24,24},{525,975}},{1,{24,24},{600,900}},{1,{24,24},{275,250}},{1,{24,24},{500,175}},{1,{24,24},{700,375}},{1,{24,24},{100,425}},{1,{24,24},{550,175}},{1,{24,24},{600,0}},{1,{24,24},{725,775}},{2,{24,24},{75,175}},{1,{24,24},{825,675}},{1,{24,24},{250,475}},{1,{24,24},{850,650}},{1,{24,24},{425,450}},{1,{24,24},{875,625}},{1,{24,24},{900,600}},{1,{24,24},{275,150}},{1,{24,24},{300,725}},{1,{24,24},{975,525}},{1,{24,24},{875,275}},{1,{24,24},{75,500}},{1,{24,24},{950,875}},{1,{24,24},{850,400}},{1,{24,24},{525,950}},{1,{24,24},{625,600}},{2,{24,24},{100,100}},{1,{24,24},{325,250}},{1,{24,24},{475,950}},{1,{24,24},{775,75}},{1,{24,24},{350,300}},{1,{24,24},{500,650}},{1,{24,24},{350,700}},{1,{24,24},{650,825}},{1,{24,24},{100,950}},{1,{24,24},{950,575}},{1,{24,24},{775,700}},{1,{24,24},{825,650}},{1,{24,24},{700,725}},{1,{24,24},{800,950}},{1,{24,24},{875,600}},{1,{24,24},{100,800}},{1,{24,24},{900,575}},{1,{24,24},{25,50}},{1,{24,24},{925,550}},{1,{24,24},{700,125}},{1,{24,24},{350,125}},{1,{24,24},{525,925}},{1,{24,24},{350,100}},{1,{24,24},{825,475}},{1,{24,24},{300,300}},{1,{24,24},{550,25}},{1,{24,24},{600,300}},{1,{24,24},{575,875}},{1,{24,24},{575,500}},{1,{24,24},{600,850}},{1,{24,24},{175,900}},{1,{24,24},{650,800}},{1,{24,24},{200,625}},{1,{24,24},{475,875}},{1,{24,24},{800,375}},{1,{24,24},{950,0}},{1,{24,24},{750,700}},{1,{24,24},{925,25}},{1,{24,24},{925,300}},{1,{24,24},{775,675}},{1,{24,24},{650,125}},{1,{24,24},{600,125}},{1,{24,24},{150,450}},{1,{24,24},{25,25}},{1,{24,24},{50,275}},{1,{24,24},{650,575}},{1,{24,24},{800,650}},{1,{24,24},{575,150}},{1,{24,24},{850,600}},{1,{24,24},{825,600}},{1,{24,24},{350,400}},{1,{24,24},{250,575}},{1,{24,24},{650,600}},{1,{24,24},{525,75}},{1,{24,24},{400,900}},{1,{24,24},{325,200}},{1,{24,24},{125,50}},{1,{24,24},{925,525}},{2,{24,24},{0,175}},{1,{24,24},{950,650}},{1,{24,24},{450,975}},{1,{24,24},{525,900}},{1,{24,24},{650,300}},{1,{24,24},{325,325}},{1,{24,24},{725,475}},{1,{24,24},{550,950}},{1,{24,24},{325,700}},{1,{24,24},{525,500}},{1,{24,24},{600,825}},{1,{24,24},{625,800}},{2,{24,24},{0,125}},{1,{24,24},{375,25}},{1,{24,24},{500,800}},{1,{24,24},{875,575}},{1,{24,24},{50,450}},{1,{24,24},{125,775}},{1,{24,24},{850,575}},{1,{24,24},{250,275}},{1,{24,24},{875,550}},{1,{24,24},{900,525}},{1,{24,24},{925,500}},{1,{24,24},{475,400}},{1,{24,24},{125,325}},{1,{24,24},{375,650}},{1,{24,24},{675,450}},{1,{24,24},{375,50}},{1,{24,24},{875,125}},{1,{24,24},{150,550}},{1,{24,24},{250,550}},{1,{24,24},{275,50}},{1,{24,24},{800,750}},{1,{24,24},{425,975}},{1,{24,24},{475,925}},{1,{24,24},{550,300}},{1,{24,24},{500,900}},{1,{24,24},{175,975}},{1,{24,24},{600,725}},{1,{24,24},{850,775}},{1,{24,24},{50,575}},{1,{24,24},{600,800}},{1,{24,24},{650,975}},{1,{24,24},{25,700}},{1,{24,24},{700,700}},{1,{24,24},{950,400}},{1,{24,24},{600,525}},{1,{24,24},{550,525}},{1,{24,24},{975,250}},{1,{24,24},{925,200}},{1,{24,24},{100,775}},{1,{24,24},{775,625}},{1,{24,24},{975,550}},{1,{24,24},{875,525}},{1,{24,24},{950,450}},{1,{24,24},{350,650}},{1,{24,24},{800,725}},{1,{24,24},{450,925}},{1,{24,24},{300,425}},{1,{24,24},{650,550}},{1,{24,24},{75,975}},{1,{24,24},{125,375}},{1,{24,24},{750,825}},{1,{24,24},{500,875}},{1,{24,24},{275,925}},{1,{24,24},{850,850}},{1,{24,24},{0,450}},{1,{24,24},{925,50}},{1,{24,24},{425,400}},{1,{24,24},{250,325}},{1,{24,24},{175,475}},{1,{24,24},{600,775}},{1,{24,24},{775,0}},{1,{24,24},{100,875}},{1,{24,24},{575,0}},{1,{24,24},{50,325}},{1,{24,24},{700,550}},{1,{24,24},{750,625}},{1,{24,24},{75,325}},{1,{24,24},{825,550}},{1,{24,24},{750,50}},{1,{24,24},{750,200}},{1,{24,24},{900,475}},{1,{24,24},{850,350}},{1,{24,24},{50,775}},{1,{24,24},{925,450}},{1,{24,24},{950,425}},{1,{24,24},{100,675}},{1,{24,24},{975,400}},{1,{24,24},{250,300}},{1,{24,24},{775,200}},{2,{24,24},{225,50}},{1,{24,24},{725,725}},{1,{24,24},{850,525}},{1,{24,24},{525,825}},{1,{24,24},{875,75}},{1,{24,24},{25,975}},{1,{24,24},{575,775}},{1,{24,24},{625,725}},{1,{24,24},{850,225}},{1,{24,24},{675,675}},{1,{24,24},{175,425}},{1,{24,24},{750,350}},{1,{24,24},{650,700}},{1,{24,24},{575,25}},{1,{24,24},{750,600}},{1,{24,24},{50,200}},{1,{24,24},{775,575}},{1,{24,24},{700,650}},{1,{24,24},{250,875}},{1,{24,24},{150,700}},{1,{24,24},{925,0}},{1,{24,24},{900,450}},{1,{24,24},{625,150}},{1,{24,24},{975,375}},{1,{24,24},{350,975}},{1,{24,24},{625,925}},{1,{24,24},{600,225}},{1,{24,24},{425,900}},{1,{24,24},{100,700}},{1,{24,24},{725,675}},{1,{24,24},{175,600}},{1,{24,24},{275,825}},{1,{24,24},{500,625}},{1,{24,24},{675,100}},{1,{24,24},{475,200}},{1,{24,24},{425,250}},{1,{24,24},{775,525}},{1,{24,24},{150,175}},{1,{24,24},{850,325}},{1,{24,24},{125,275}},{1,{24,24},{450,875}},{1,{24,24},{250,400}},{1,{24,24},{675,175}},{1,{24,24},{350,600}},{1,{24,24},{275,800}},{1,{24,24},{700,200}},{1,{24,24},{900,200}},{1,{24,24},{525,800}},{1,{24,24},{500,825}},{1,{24,24},{125,925}},{1,{24,24},{250,0}},{1,{24,24},{625,700}},{1,{24,24},{200,600}},{1,{24,24},{700,625}},{1,{24,24},{350,950}},{1,{24,24},{225,925}},{1,{24,24},{900,425}},{1,{24,24},{800,525}},{1,{24,24},{300,575}},{1,{24,24},{250,925}},{1,{24,24},{850,475}},{1,{24,24},{650,675}},{1,{24,24},{525,625}},{1,{24,24},{750,525}},{1,{24,24},{975,350}},{1,{24,24},{750,725}},{1,{24,24},{375,800}},{1,{24,24},{850,275}},{1,{24,24},{975,50}},{1,{24,24},{750,575}},{1,{24,24},{475,225}},{1,{24,24},{825,625}},{1,{24,24},{325,150}},{1,{24,24},{275,575}},{1,{24,24},{425,875}},{1,{24,24},{450,850}},{1,{24,24},{475,825}},{1,{24,24},{200,75}},{1,{24,24},{325,800}},{1,{24,24},{650,625}},{2,{24,24},{25,50}},{1,{24,24},{550,0}},{1,{24,24},{600,700}},{1,{24,24},{725,700}},{1,{24,24},{100,275}},{1,{24,24},{125,800}},{1,{24,24},{650,650}},{1,{24,24},{475,175}},{1,{24,24},{675,625}},{1,{24,24},{700,600}},{1,{24,24},{925,375}},{1,{24,24},{400,550}},{1,{24,24},{975,325}},{1,{24,24},{325,950}},{1,{24,24},{775,875}},{1,{24,24},{200,50}},{1,{24,24},{350,925}},{1,{24,24},{425,850}},{1,{24,24},{400,875}},{1,{24,24},{350,0}},{1,{24,24},{475,800}},{1,{24,24},{450,825}},{2,{24,24},{25,225}},{1,{24,24},{550,725}},{1,{24,24},{575,700}},{1,{24,24},{250,25}},{1,{24,24},{625,650}},{1,{24,24},{925,350}},{2,{24,24},{25,200}},{1,{24,24},{275,475}},{1,{24,24},{700,575}},{1,{24,24},{225,450}},{1,{24,24},{800,475}},{1,{24,24},{950,50}},{1,{24,24},{850,425}},{1,{24,24},{875,100}},{1,{24,24},{275,975}},{1,{24,24},{300,950}},{1,{24,24},{625,825}},{1,{24,24},{200,850}},{1,{24,24},{350,900}},{1,{24,24},{400,850}},{1,{24,24},{450,800}},{1,{24,24},{500,750}},{1,{24,24},{825,425}},{1,{24,24},{625,625}},{1,{24,24},{650,925}},{1,{24,24},{175,25}},{1,{24,24},{675,575}},{1,{24,24},{700,675}},{1,{24,24},{75,100}},{1,{24,24},{750,500}},{1,{24,24},{50,50}},{1,{24,24},{800,450}},{1,{24,24},{575,275}},{1,{24,24},{375,325}},{1,{24,24},{325,625}},{1,{24,24},{50,650}},{1,{24,24},{425,25}},{1,{24,24},{950,25}},{1,{24,24},{600,650}},{1,{24,24},{825,225}},{1,{24,24},{300,500}},{1,{24,24},{875,375}},{1,{24,24},{500,325}},{1,{24,24},{700,350}},{1,{24,24},{950,300}},{1,{24,24},{200,175}},{1,{24,24},{800,150}},{1,{24,24},{275,950}},{1,{24,24},{250,975}},{1,{24,24},{200,450}},{1,{24,24},{300,925}},{1,{24,24},{325,900}},{1,{24,24},{350,550}},{1,{24,24},{75,450}},{1,{24,24},{925,700}},{1,{24,24},{0,300}},{1,{24,24},{500,725}},{1,{24,24},{625,400}},{1,{24,24},{825,275}},{1,{24,24},{75,750}},{1,{24,24},{100,625}},{1,{24,24},{525,700}},{1,{24,24},{600,625}},{1,{24,24},{250,850}},{1,{24,24},{675,550}},{1,{24,24},{775,450}},{1,{24,24},{650,100}},{1,{24,24},{600,175}},{1,{24,24},{600,250}},{1,{24,24},{800,425}},{1,{24,24},{700,475}},{1,{24,24},{25,350}},{1,{24,24},{725,200}},{1,{24,24},{575,550}},{1,{24,24},{50,700}},{1,{24,24},{900,325}},{1,{24,24},{700,925}},{1,{24,24},{300,775}},{1,{24,24},{425,525}},{1,{24,24},{250,950}},{1,{24,24},{0,950}},{1,{24,24},{275,450}},{1,{24,24},{650,0}},{1,{24,24},{350,850}},{1,{24,24},{400,800}},{1,{24,24},{425,775}},{1,{24,24},{800,75}},{1,{24,24},{300,900}},{1,{24,24},{475,525}},{1,{24,24},{175,275}},{1,{24,24},{150,75}},{1,{24,24},{950,350}},{1,{24,24},{350,150}},{1,{24,24},{525,675}},{1,{24,24},{550,650}},{1,{24,24},{625,575}},{1,{24,24},{600,50}},{1,{24,24},{75,700}},{1,{24,24},{175,350}},{1,{24,24},{0,250}},{1,{24,24},{575,850}},{1,{24,24},{750,450}},{1,{24,24},{100,525}},{1,{24,24},{400,575}},{1,{24,24},{925,175}},{1,{24,24},{575,75}},{1,{24,24},{775,425}},{1,{24,24},{50,725}},{1,{24,24},{25,850}},{1,{24,24},{675,700}},{1,{24,24},{50,475}},{1,{24,24},{625,100}},{1,{24,24},{975,475}},{1,{24,24},{225,950}},{1,{24,24},{200,500}},{1,{24,24},{950,375}},{1,{24,24},{525,200}},{1,{24,24},{0,200}},{1,{24,24},{150,100}},{1,{24,24},{425,750}},{1,{24,24},{475,700}},{1,{24,24},{500,675}},{1,{24,24},{525,650}},{1,{24,24},{900,225}},{1,{24,24},{150,825}},{1,{24,24},{375,250}},{1,{24,24},{0,675}},{1,{24,24},{325,350}},{1,{24,24},{175,850}},{1,{24,24},{575,600}},{1,{24,24},{675,500}},{1,{24,24},{225,400}},{1,{24,24},{750,425}},{1,{24,24},{650,450}},{1,{24,24},{225,525}},{1,{24,24},{875,300}},{1,{24,24},{900,275}},{1,{24,24},{200,800}},{1,{24,24},{925,250}},{1,{24,24},{800,400}},{1,{24,24},{825,0}},{1,{24,24},{525,875}},{1,{24,24},{675,825}},{1,{24,24},{175,125}},{1,{24,24},{125,25}},{1,{24,24},{775,550}},{1,{24,24},{150,25}},{1,{24,24},{650,325}},{1,{24,24},{75,0}},{1,{24,24},{275,875}},{1,{24,24},{675,400}},{1,{24,24},{350,800}},{1,{24,24},{750,375}},{1,{24,24},{250,775}},{1,{24,24},{375,775}},{1,{24,24},{600,875}},{1,{24,24},{450,700}},{1,{24,24},{425,725}},{1,{24,24},{125,650}},{1,{24,24},{300,850}},{1,{24,24},{850,800}},{1,{24,24},{225,425}},{1,{24,24},{475,375}},{1,{24,24},{975,725}},{1,{24,24},{425,75}},{1,{24,24},{700,450}},{1,{24,24},{25,75}},{1,{24,24},{775,375}},{1,{24,24},{50,525}},{1,{24,24},{725,425}},{1,{24,24},{200,350}},{1,{24,24},{850,75}},{1,{24,24},{575,950}},{1,{24,24},{25,600}},{1,{24,24},{600,550}},{1,{24,24},{50,750}},{1,{24,24},{150,975}},{1,{24,24},{200,925}},{1,{24,24},{125,625}},{1,{24,24},{300,825}},{1,{24,24},{550,750}},{1,{24,24},{975,900}},{1,{24,24},{550,625}},{1,{24,24},{450,675}},{1,{24,24},{875,350}},{1,{24,24},{900,950}},{1,{24,24},{625,50}},{1,{24,24},{775,350}},{1,{24,24},{250,800}},{1,{24,24},{800,325}},{1,{24,24},{825,300}},{1,{24,24},{875,250}},{1,{24,24},{550,575}},{1,{24,24},{350,450}},{1,{24,24},{750,650}},{1,{24,24},{325,775}},{1,{24,24},{225,0}},{1,{24,24},{275,25}},{1,{24,24},{975,150}},{2,{24,24},{75,0}},{1,{24,24},{125,525}},{1,{24,24},{175,925}},{1,{24,24},{100,500}},{1,{24,24},{875,750}},{1,{24,24},{225,50}},{1,{24,24},{950,175}},{1,{24,24},{375,725}},{1,{24,24},{75,525}},{1,{24,24},{450,650}},{1,{24,24},{425,675}},{1,{24,24},{275,550}},{1,{24,24},{475,900}},{1,{24,24},{750,250}},{1,{24,24},{200,675}},{1,{24,24},{600,500}},{1,{24,24},{925,75}},{1,{24,24},{50,100}},{1,{24,24},{625,475}},{1,{24,24},{525,25}},{1,{24,24},{500,275}},{1,{24,24},{275,525}},{1,{24,24},{700,400}},{1,{24,24},{775,325}},{1,{24,24},{800,300}},{1,{24,24},{750,275}},{1,{24,24},{200,650}},{1,{24,24},{850,250}},{1,{24,24},{100,0}},{1,{24,24},{300,350}},{1,{24,24},{975,850}},{1,{24,24},{125,850}},{1,{24,24},{325,925}},{1,{24,24},{225,850}},{1,{24,24},{250,825}},{1,{24,24},{25,950}},{1,{24,24},{425,700}},{1,{24,24},{225,875}},{1,{24,24},{475,600}},{1,{24,24},{125,875}},{1,{24,24},{75,950}},{1,{24,24},{725,350}},{1,{24,24},{50,425}},{1,{24,24},{825,350}},{1,{24,24},{300,675}},{1,{24,24},{750,325}},{1,{24,24},{775,25}},{1,{24,24},{725,250}},{1,{24,24},{200,125}},{1,{24,24},{350,500}},{1,{24,24},{325,825}},{1,{24,24},{75,925}},{1,{24,24},{500,525}},{1,{24,24},{50,25}},{1,{24,24},{475,475}},{1,{24,24},{25,400}},{1,{24,24},{25,375}},{1,{24,24},{550,775}},{1,{24,24},{675,800}},{1,{24,24},{550,600}},{1,{24,24},{250,50}},{1,{24,24},{975,675}},{1,{24,24},{975,625}},{1,{24,24},{575,475}},{1,{24,24},{550,500}},{1,{24,24},{525,275}},{1,{24,24},{450,425}},{1,{24,24},{600,350}},{1,{24,24},{700,175}},{1,{24,24},{500,550}},{1,{24,24},{475,750}},{1,{24,24},{50,400}},{1,{24,24},{175,400}},{1,{24,24},{450,125}},{1,{24,24},{325,375}},{1,{24,24},{375,900}},{1,{24,24},{650,75}},{1,{24,24},{700,0}},{1,{24,24},{600,450}},{1,{24,24},{850,200}},{1,{24,24},{925,325}},{1,{24,24},{725,325}},{1,{24,24},{875,175}},{1,{24,24},{450,275}},{1,{24,24},{0,25}},{1,{24,24},{800,250}},{2,{24,24},{175,25}},{1,{24,24},{625,450}},{1,{24,24},{900,125}},{1,{24,24},{200,825}},{1,{24,24},{225,800}},{1,{24,24},{275,750}},{1,{24,24},{300,0}},{1,{24,24},{375,500}},{1,{24,24},{950,550}},{1,{24,24},{400,625}},{1,{24,24},{450,75}},{1,{24,24},{350,675}},{1,{24,24},{300,525}},{1,{24,24},{325,100}},{1,{24,24},{425,600}},{1,{24,24},{375,200}},{1,{24,24},{450,575}},{1,{24,24},{150,750}},{1,{24,24},{175,875}},{1,{24,24},{575,450}},{1,{24,24},{700,325}},{1,{24,24},{775,250}},{1,{24,24},{300,325}},{1,{24,24},{400,200}},{1,{24,24},{525,325}},{1,{24,24},{200,375}},{1,{24,24},{150,500}},{1,{24,24},{600,100}},{1,{24,24},{850,925}},{1,{24,24},{900,700}},{1,{24,24},{150,875}},{1,{24,24},{925,100}},{1,{24,24},{425,375}},{1,{24,24},{225,250}},{1,{24,24},{0,375}},{1,{24,24},{525,550}},{1,{24,24},{525,225}},{1,{24,24},{175,825}},{1,{24,24},{0,550}},{1,{24,24},{275,725}},{1,{24,24},{75,375}},{1,{24,24},{150,850}},{1,{24,24},{375,100}},{1,{24,24},{300,700}},{1,{24,24},{500,25}},{1,{24,24},{100,450}},{1,{24,24},{625,975}},{1,{24,24},{750,125}},{1,{24,24},{350,625}},{2,{24,24},{100,75}},{1,{24,24},{500,500}},{1,{24,24},{450,350}},{1,{24,24},{325,975}},{1,{24,24},{575,425}},{1,{24,24},{650,350}},{1,{24,24},{675,325}},{1,{24,24},{700,300}},{1,{24,24},{725,275}},{1,{24,24},{900,100}},{1,{24,24},{475,0}},{1,{24,24},{0,750}},{1,{24,24},{975,25}},{1,{24,24},{50,925}},{1,{24,24},{75,900}},{1,{24,24},{625,750}},{1,{24,24},{600,575}},{1,{24,24},{200,775}},{1,{24,24},{225,750}},{1,{24,24},{275,700}},{1,{24,24},{250,125}},{1,{24,24},{775,300}},{1,{24,24},{450,50}},{1,{24,24},{25,325}},{1,{24,24},{675,525}},{1,{24,24},{450,525}},{1,{24,24},{25,525}},{1,{24,24},{525,450}},{1,{24,24},{575,400}},{1,{24,24},{650,275}},{1,{24,24},{600,375}},{1,{24,24},{500,475}},{1,{24,24},{675,300}},{1,{24,24},{725,150}},{1,{24,24},{375,975}},{1,{24,24},{75,575}},{1,{24,24},{375,400}},{1,{24,24},{75,725}},{1,{24,24},{125,500}},{1,{24,24},{800,175}},{1,{24,24},{575,200}},{1,{24,24},{150,200}},{1,{24,24},{850,125}},{1,{24,24},{975,300}},{1,{24,24},{900,75}},{1,{24,24},{975,0}},{1,{24,24},{50,900}},{1,{24,24},{100,850}},{1,{24,24},{425,425}},{1,{24,24},{800,0}},{1,{24,24},{725,125}},{1,{24,24},{100,150}},{1,{24,24},{475,100}},{1,{24,24},{175,775}},{1,{24,24},{200,750}},{1,{24,24},{475,725}},{1,{24,24},{325,25}},{1,{24,24},{525,425}},{1,{24,24},{425,475}},{1,{24,24},{725,50}},{1,{24,24},{75,800}},{1,{24,24},{425,200}},{1,{24,24},{725,225}},{1,{24,24},{550,875}},{1,{24,24},{600,750}},{1,{24,24},{75,850}},{1,{24,24},{100,825}},{1,{24,24},{500,250}},{1,{24,24},{550,350}},{1,{24,24},{275,650}},{1,{24,24},{325,600}},{1,{24,24},{600,25}},{1,{24,24},{350,575}},{1,{24,24},{0,500}},{1,{24,24},{350,350}},{1,{24,24},{100,975}},{1,{24,24},{450,475}},{1,{24,24},{850,875}},{1,{24,24},{850,50}},{1,{24,24},{525,400}},{1,{24,24},{575,350}},{1,{24,24},{975,800}},{2,{24,24},{75,125}},{1,{24,24},{875,50}},{1,{24,24},{0,125}},{1,{24,24},{900,25}},{1,{24,24},{225,675}},{1,{24,24},{400,825}},{1,{24,24},{925,825}},{1,{24,24},{50,500}},{1,{24,24},{475,425}},{1,{24,24},{525,375}},{1,{24,24},{50,875}},{1,{24,24},{300,150}},{1,{24,24},{325,0}},{1,{24,24},{900,625}},{1,{24,24},{500,200}},{1,{24,24},{100,250}},{1,{24,24},{525,850}},{1,{24,24},{825,75}},{1,{24,24},{175,725}},{1,{24,24},{700,250}},{1,{24,24},{225,650}},{1,{24,24},{250,250}},{1,{24,24},{275,600}},{1,{24,24},{625,75}},{1,{24,24},{625,225}},{1,{24,24},{325,550}},{1,{24,24},{950,475}},{1,{24,24},{525,350}},{1,{24,24},{600,275}},{1,{24,24},{625,250}},{1,{24,24},{100,650}},{1,{24,24},{425,275}},{1,{24,24},{650,225}},{1,{24,24},{425,575}},{1,{24,24},{700,275}},{1,{24,24},{850,900}},{1,{24,24},{0,850}},{1,{24,24},{100,750}},{1,{24,24},{575,725}},{1,{24,24},{25,475}},{1,{24,24},{175,150}},{1,{24,24},{950,125}},{1,{24,24},{500,350}},{1,{24,24},{825,325}},{1,{24,24},{150,800}},{1,{24,24},{0,825}},{1,{24,24},{350,325}},{1,{24,24},{400,350}},{1,{24,24},{125,700}},{1,{24,24},{150,675}},{1,{24,24},{575,800}},{1,{24,24},{450,375}},{1,{24,24},{575,250}},{1,{24,24},{400,925}},{1,{24,24},{200,475}},{1,{24,24},{125,600}},{1,{24,24},{650,175}},{1,{24,24},{775,50}},{1,{24,24},{125,0}},{1,{24,24},{125,675}},{1,{24,24},{325,475}},{1,{24,24},{400,400}},{1,{24,24},{725,0}},{1,{24,24},{150,575}},{1,{24,24},{675,125}},{1,{24,24},{900,175}},{1,{24,24},{975,200}},{1,{24,24},{500,125}},{1,{24,24},{575,625}},{1,{24,24},{325,450}},{1,{24,24},{775,275}},{1,{24,24},{350,425}},{1,{24,24},{400,375}},{1,{24,24},{75,675}},{1,{24,24},{625,125}},{1,{24,24},{750,475}},{1,{24,24},{700,75}},{1,{24,24},{750,25}},{1,{24,24},{200,150}},{1,{24,24},{150,600}},{1,{24,24},{725,550}},{1,{24,24},{300,450}},{1,{24,24},{25,125}},{1,{24,24},{475,125}},{1,{24,24},{300,550}},{1,{24,24},{175,750}},{1,{24,24},{575,175}},{1,{24,24},{425,350}},{1,{24,24},{425,0}},{1,{24,24},{725,175}},{1,{24,24},{725,25}},{1,{24,24},{750,0}},{1,{24,24},{75,75}},{1,{24,24},{575,225}},{1,{24,24},{325,400}},{1,{24,24},{250,525}},{1,{24,24},{400,50}},{1,{24,24},{0,700}},{1,{24,24},{100,600}},{1,{24,24},{200,275}},{1,{24,24},{425,500}},{1,{24,24},{650,50}},{1,{24,24},{775,500}},{1,{24,24},{625,500}},{1,{24,24},{375,675}},{1,{24,24},{550,100}},{1,{24,24},{375,125}},{1,{24,24},{325,875}},{1,{24,24},{650,750}},{1,{24,24},{150,475}},{1,{24,24},{950,750}},{1,{24,24},{350,275}},{1,{24,24},{450,175}},{1,{24,24},{25,575}},{1,{24,24},{50,550}},{1,{24,24},{350,250}},{1,{24,24},{325,275}},{1,{24,24},{275,325}},{1,{24,24},{375,225}},{1,{24,24},{0,575}},{1,{24,24},{75,175}},{1,{24,24},{275,300}},{1,{24,24},{300,275}},{1,{24,24},{50,225}},{1,{24,24},{475,550}},{1,{24,24},{950,250}},{1,{24,24},{350,200}},{1,{24,24},{625,425}},{1,{24,24},{50,150}},{1,{24,24},{750,850}},{1,{24,24},{75,425}},{1,{24,24},{475,275}},{1,{24,24},{225,275}},{1,{24,24},{400,100}},{1,{24,24},{100,375}},{1,{24,24},{50,950}},{1,{24,24},{275,775}},{1,{24,24},{850,625}},{1,{24,24},{275,100}},{2,{24,24},{25,25}},{1,{24,24},{225,75}},{1,{24,24},{125,100}}}}}
    local iconIndices: { string } = icons[1]
    local idIndices: { string } = icons[2]
    local iconRegistry: { [number]: { number | { number } } } = icons[3]

    Lucide.Icons = iconIndices
    function Lucide.GetAsset(name: string)
        local size = 48

        local iconIndex = table.find(iconIndices, name)

        if not iconIndex then
            return nil
        end

        local currentDifference = math.huge
        local currentSize = size

        for registrySize, _ in iconRegistry do
            local diff = math.abs(size - registrySize)

            if diff < currentDifference then
                currentDifference = diff
                currentSize = registrySize
            end
        end

        local icon = iconRegistry[currentSize][iconIndex]
        if icon then
            return {
                IconName = name,
                Url = idIndices[icon[1]],
                ImageRectSize = Vector2.new(icon[2][1], icon[2][2]),
                ImageRectOffset = Vector2.new(icon[3][1], icon[3][2]),
            }
        end

        return nil
    end

    return Lucide
end)()

function Library:GetIcon(IconName: string)
    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end
    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
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
    local DPIProperties = Library.DPIRegistry[Instance] or {}

    local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
    local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

    for k, v in pairs(Table) do
        if k == "DPIExclude" or k == "DPIOffset" then
            continue
        elseif ThemeProperties[k] then
            ThemeProperties[k] = nil
        elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
            -- me when Red in dropdowns break things (temp fix - or perm idk if deivid will do something about this)
            ThemeProperties[k] = v
            Instance[k] = Library.Scheme[v] or v()
            continue
        end

        if not DPIExclude[k] then
            if k == "Position" or k == "Size" or k:match("Padding") then
                DPIProperties[k] = v
                v = ApplyDPIScale(v, DPIOffset[k])
            elseif k == "TextSize" then
                DPIProperties[k] = v
                v = ApplyTextScale(v)
            end
        end

        Instance[k] = v
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
    if GetTableSize(DPIProperties) > 0 then
        DPIProperties["DPIExclude"] = DPIExclude
        DPIProperties["DPIOffset"] = DPIOffset
        Library.DPIRegistry[Instance] = DPIProperties
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
    DisplayOrder = 999,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
    Library.DPIRegistry[Instance] = nil
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
local Cursor
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 999,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = CursorV,
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
    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
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
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
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
        ZIndex = Info.ZIndex or 1,
        Parent = Frame,
    })

    return Line
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    local Holder = New("Frame", {
        BackgroundColor3 = "Dark",
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

function Library:AddDraggableButton(Text: string, Func)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Button,
    })
    Library:MakeOutline(Button, Library.CornerRadius, 9)

    Table.Button = Button
    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    function Table:SetText(NewText: string)
        local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)

        Button.Text = NewText
        Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
        Library:UpdateDPI(Button, {
            Size = UDim2.fromOffset(X * 2, Y * 2),
        })
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = UDim2.fromOffset(6, 6)
    Background.Size = UDim2.fromOffset(0, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
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

    Library:MakeDraggable(Background, Label, true)
    return Background, Container
end

--// Watermark \\--
do
    local WatermarkBackground = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    WatermarkBackground.AutomaticSize = Enum.AutomaticSize.Y
    WatermarkBackground.Position = UDim2.fromOffset(6, 6)
    WatermarkBackground.Size = UDim2.fromOffset(0, 0)
    WatermarkBackground.Visible = false

    Library:UpdateDPI(WatermarkBackground, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = WatermarkBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })

    local WatermarkLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.fromOffset(0, -8 * Library.DPIScale + 7),
        Text = "",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = WatermarkLabel,
    })

    Library:MakeDraggable(WatermarkBackground, WatermarkLabel, true)

    local function ResizeWatermark()
        local X, Y = Library:GetTextBounds(WatermarkLabel.Text, Library.Scheme.Font, 15)
        WatermarkBackground.Size = UDim2.fromOffset((12 + X + 12 + 4) * Library.DPIScale, Y + 12 + 4)
        Library:UpdateDPI(WatermarkBackground, {
            Size = UDim2.fromOffset(12 + X + 12 + 4, Y + 12 + 4),
        })
        WatermarkLabel.Size = UDim2.new(1, 0, 0, WatermarkBackground.Size.Y.Offset)
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        WatermarkBackground.Visible = Visible
        if Visible then
            ResizeWatermark()
        end
    end

    function Library:SetWatermark(Text: string)
        WatermarkLabel.Text = Text
        ResizeWatermark()
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
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
        if typeof(Table.Size) == "function" then
            Menu.Size = Table.Size()
        else
            Menu.Size = ApplyDPIScale(Table.Size)
        end
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
    BackgroundColor3 = "BackgroundColor",
    BorderColor3 = "OutlineColor",
    BorderSizePixel = 1,
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    local X, Y = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 4
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8 * Library.DPIScale, Y + 4 * Library.DPIScale)
    Library:UpdateDPI(TooltipLabel, {
        Size = UDim2.fromOffset(X, Y),
        DPIOffset = {
            Size = { 8, 4 },
        },
    })
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
            --or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end

        CurrentHoverInstance = HoverInstance

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            Library.Toggled
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            --and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
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

    table.insert(TooltipTable.Signals, HoverInstance.MouseEnter:Connect(DoHover))
    table.insert(TooltipTable.Signals, HoverInstance.MouseMoved:Connect(DoHover))
    table.insert(
        TooltipTable.Signals,
        HoverInstance.MouseLeave:Connect(function()
            if CurrentHoverInstance ~= HoverInstance then
                return
            end

            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end)
    )

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            Connection:Disconnect()
        end

        if CurrentHoverInstance == HoverInstance then
            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end
    end

    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        Connection:Disconnect()
    end

    for _, Callback in pairs(Library.UnloadSignals) do
        Library:SafeCallback(Callback)
    end

    Library.Unloaded = true
    ScreenGui:Destroy()
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")

function Library:SetIconModule(module: IconModule)
    Icons = module

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
            Info.Modes = { "Toggle" }
            Info.Mode = "Toggle"
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

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers) -- Verify default modifiers

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

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
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,

                DPIExclude = {
                    Size = true,
                },
            })

            local Checkbox = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
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
                local X = Library:GetTextBounds(Text, Label.FontFace, Label.TextSize)
                Label.Text = Text
                Label.Size = UDim2.new(0, X, 1, 0)
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22 * Library.DPIScale, 0)
                Checkbox.Visible = not Normal
            end

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
        end, 1)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in pairs(Info.Modes) do
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
                for _, Button in pairs(ModeButtons) do
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
            Picker.Size = UDim2.fromOffset(X + 9 * Library.DPIScale, Y + 4 * Library.DPIScale)
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

            Library:UpdateKeybindFrame()
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

            if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
                ParentObj:SetValue(KeyPicker.Toggled)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
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
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

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
            Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

            -- Wait for an non modifier key --
            local Input
            local ActiveModifiers = {}

            local GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() then
                    return true
                end
            end

            repeat
                task.wait()

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

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
                Key = SpecialKeysInput[Input.UserInputType];
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name;
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers;

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
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Size = UDim2.fromScale(1, 1),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

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
            BackgroundColor3 = "White",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "Dark",
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Holder,
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
            BackgroundColor3 = "White",
            BorderColor3 = "Dark",
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
                });
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "White",
                BorderColor3 = "Dark",
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
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
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
            Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
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

    function Funcs:AddDivider(...)
        local Data = ... or {}

        local Groupbox = self
        local Container = Groupbox.Container

        local Divider = {
            Visible = Data.Visible or true,
        }

        local Holder = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.new(1, 0, 0, 2),
            Visible = Divider.Visible,
            Parent = Container,
        })

        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })

        function Divider:SetVisible(Visible: boolean)
            Divider.Visible = Visible

            Holder.Visible = Divider.Visible
            Groupbox:Resize()
        end

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
            Data.Visible = Params.Visible or true
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
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local _, Y =
                Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        if Data.DoesWrap then
            local Last = TextLabel.AbsoluteSize

            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
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
                Info.Func = Params.Func or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
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
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

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
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.Red or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "Red" or "FontColor"

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
                SubButton.Base.TextColor3 = Library.Scheme.Red
                Library.Registry[SubButton.Base].TextColor3 = "Red"
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

            Holder.Visible = Button.Visible
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
            Button.Base.TextColor3 = Library.Scheme.Red
            Library.Registry[Button.Base].TextColor3 = "Red"
        end

        Button:UpdateColors()
        Groupbox:Resize()

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
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Checkbox,
        })

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

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
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
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
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

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
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
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
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
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

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
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
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
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
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

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

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
            Rounding = Info.Rounding,

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
            Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
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
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 13),
            Text = "",
            Parent = Holder,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = 2,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "Dark",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,

            DPIExclude = {
                Size = true,
            },
        })

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
    
            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value)) --this will make  so it updates. and im calling this so i dont need to add an if :P
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")
    
            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max)) --same here. adding these comments for the funny
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

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = false
            end

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = true
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
            Parent = Holder,
        })

        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = Display,
        })

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
                return UDim2.fromOffset(Display.AbsoluteSize.X, 0)
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
            end
        )
        Dropdown.Menu = MenuTable
        Library:UpdateDPI(MenuTable.Menu, {
            Position = false,
            Size = false,
        })

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp(
                (Count or GetTableSize(Dropdown.Values)) * (21 * Library.DPIScale),
                0,
                Info.MaxVisibleDropdownItems * (21 * Library.DPIScale)
            )

            MenuTable:SetSize(function()
                return UDim2.fromOffset(Display.AbsoluteSize.X, Y)
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
                for _, Value in pairs(Dropdown.Values) do
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

                for Value, _ in pairs(Dropdown.Value) do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        local Buttons = {}
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues

            for Button, _ in pairs(Buttons) do
                Button:Destroy()
            end
            table.clear(Buttons)

            local Count = 0
            for _, Value in pairs(Values) do
                if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                    continue
                end

                Count += 1
                local IsDisabled = table.find(DisabledValues, Value)
                local Table = {}

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = tostring(Value),
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MenuTable.Menu,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    Parent = Button,
                })

                local Tooltip = (Info.Tooltips) and Info.Tooltips[Value]
                if Tooltip then
                    Library:AddTooltip(Tooltip, nil, Button)
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    Button.BackgroundTransparency = Selected and 0 or 1
                    Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function()
                        local Try = not Selected

                        if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                            Selected = Try
                            if Info.Multi then
                                Dropdown.Value[Value] = Selected and true or nil
                            else
                                Dropdown.Value = Selected and Value or nil
                            end

                            for _, OtherButton in pairs(Buttons) do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:UpdateDependencyBoxes()
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if Active and table.find(Dropdown.Values, Val) then
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
            for _, Button in pairs(Buttons) do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                Library:UpdateDependencyBoxes()
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            if Dropdown.SpecialType then
                local NewValue = {}
                for Object in Dropdown.Value do
                    if Object:IsDescendantOf(game) then
                        NewValue[Object] = true
                    end
                end
                Library:SafeCallback(Dropdown.Callback, NewValue)
                Library:SafeCallback(Dropdown.Changed, NewValue)
            end
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in pairs(Values) do
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
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
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
            Holder.Size = UDim2.new(1, 0, 0, (Text and 39 or 21) * Library.DPIScale)

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

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
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
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y * Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in pairs(Depbox.Dependencies) do
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
            for _, Dependency in pairs(Dependencies) do
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

        local Background = Library:MakeOutline(BoxHolder, Library.CornerRadius)
        Background.Size = UDim2.fromScale(1, 0)
        Background.Visible = false
        Library:UpdateDPI(Background, {
            Size = false,
        })

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Background,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = DepGroupboxContainer,
            })

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
            Holder = Background,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            Background.Size = UDim2.new(1, 0, 0, DepGroupboxList.AbsoluteContentSize.Y + 18 * Library.DPIScale)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in pairs(DepGroupbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    Background.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                Background.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
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

        DPIExclude = {
            Size = true,
        },
    })

    local Background = Library:MakeOutline(FakeBackground, Library.CornerRadius, 5)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2)
    Background.Size = UDim2.fromScale(1, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "MainColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
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

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    function Data:Resize()
        if Title then
            local X, Y = Library:GetTextBounds(
                Title.Text,
                Title.FontFace,
                Title.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Title.Size = UDim2.fromOffset(math.ceil(X), Y)
            TitleX = X
        end

        if Desc then
            local X, Y = Library:GetTextBounds(
                Desc.Text,
                Desc.FontFace,
                Desc.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Desc.Size = UDim2.fromOffset(math.ceil(X), Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset((TitleX > DescX and TitleX or DescX) + (24 * Library.DPIScale), 0)
    end

    function Data:ChangeTitle(NewText)
        if Title then
            Data.Title = tostring(NewText)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(NewText)
        if Desc then
            Data.Description = tostring(NewText)
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
            :Create(Background, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2),
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
    TweenService:Create(Background, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(-2, -2),
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

    Library.MinSize = Vector2.new(math.min(Library.MinSize.X, MaxX), math.min(Library.MinSize.Y, MaxY))
    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local Window
    local WindowTitle

    local SidebarHighlightCallback = WindowInfo.SidebarHighlightCallback

    local LayoutState = {
        IsCompact = WindowInfo.Compact,
        MinWidth = WindowInfo.SidebarMinWidth,
        CompactWidth = WindowInfo.SidebarCompactWidth,
        MinContentWidth = WindowInfo.MinContentWidth or 260,
        CollapseThreshold = WindowInfo.SidebarCollapseThreshold,
        CurrentWidth = nil,
        LastExpandedWidth = nil,
        MaxWidth = nil,
        GrabberHighlighted = false,
    }

    if LayoutState.MinWidth <= LayoutState.CompactWidth then
        LayoutState.MinWidth = LayoutState.CompactWidth + 32
    end

    if LayoutState.CollapseThreshold <= 0 then
        LayoutState.CollapseThreshold = 0.5
    elseif LayoutState.CollapseThreshold >= 1 then
        LayoutState.CollapseThreshold = 0.9
    end

    local InitialFrameWidth = math.max(WindowInfo.Size.X.Offset, LayoutState.MinWidth + LayoutState.MinContentWidth)
    local InitialExpandedWidth = WindowInfo.InitialSidebarWidth
        or math.floor(InitialFrameWidth * (WindowInfo.InitialSidebarScale or 0.3))
    LayoutState.CurrentWidth = math.max(LayoutState.MinWidth, InitialExpandedWidth)
    LayoutState.LastExpandedWidth = LayoutState.CurrentWidth

    local LayoutRefs = {
        DividerLine = nil,
        TitleHolder = nil,
        WindowIcon = nil,
        WindowTitle = nil,
        RightWrapper = nil,
        TabsFrame = nil,
        ContainerFrame = nil,
        SidebarGrabber = nil,
        TabPadding = {},
        TabLabels = {},
    }

    local MoveReservedWidth = (MoveIcon and 28 + 10) or 0

    local SidebarDrag = {
        Active = false,
        StartWidth = 0,
        StartX = 0,
        TouchId = nil,
    }

    local function GetSidebarWidth()
        return LayoutState.IsCompact and LayoutState.CompactWidth or LayoutState.CurrentWidth
    end

    local function EnsureSidebarBounds()
        local Width = MainFrame and MainFrame.AbsoluteSize.X or WindowInfo.Size.X.Offset
        if Width <= 0 then
            return
        end

        local MaxSidebar = Width - LayoutState.MinContentWidth
        LayoutState.MaxWidth = math.max(LayoutState.MinWidth, MaxSidebar)

        LayoutState.CurrentWidth = math.clamp(LayoutState.CurrentWidth, LayoutState.MinWidth, LayoutState.MaxWidth)
        LayoutState.LastExpandedWidth = math.clamp(
            LayoutState.LastExpandedWidth or LayoutState.CurrentWidth,
            LayoutState.MinWidth,
            LayoutState.MaxWidth
        )
    end

    local function SetSidebarHighlight(IsActive)
        local DividerLine = LayoutRefs.DividerLine
        if not DividerLine then
            return
        end

        LayoutState.GrabberHighlighted = IsActive == true

        if typeof(SidebarHighlightCallback) == "function" then
            Library:SafeCallback(SidebarHighlightCallback, DividerLine, LayoutState.GrabberHighlighted)
        else
            local TargetColor = LayoutState.GrabberHighlighted and GetLighterColor(Library.Scheme.OutlineColor)
                or Library.Scheme.OutlineColor

            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = TargetColor,
            }):Play()
        end
    end

    local function ApplySidebarLayout()
        EnsureSidebarBounds()

        local SidebarWidth = GetSidebarWidth()
        local IsCompact = LayoutState.IsCompact

        if LayoutRefs.DividerLine then
            LayoutRefs.DividerLine.Position = UDim2.new(0, SidebarWidth, 0, 0)
        end

        if LayoutRefs.TabsFrame then
            LayoutRefs.TabsFrame.Size = UDim2.new(0, SidebarWidth, 1, -70)
        end

        if LayoutRefs.ContainerFrame then
            LayoutRefs.ContainerFrame.Position = UDim2.fromOffset(SidebarWidth, 49)
            LayoutRefs.ContainerFrame.Size = UDim2.new(1, -SidebarWidth, 1, -70)
        end

        if LayoutRefs.SidebarGrabber then
            LayoutRefs.SidebarGrabber.Position =
                UDim2.fromOffset(SidebarWidth - LayoutRefs.SidebarGrabber.Size.X.Offset / 2, 49)
        end

        if LayoutRefs.TitleHolder then
            LayoutRefs.TitleHolder.Size = UDim2.new(0, math.max(LayoutState.CompactWidth, SidebarWidth), 1, 0)
        end

        if LayoutRefs.WindowIcon then
            if WindowInfo.Icon then
                LayoutRefs.WindowIcon.Visible = true
            else
                LayoutRefs.WindowIcon.Visible = IsCompact or not LayoutRefs.WindowTitle
            end
        end

        if LayoutRefs.WindowTitle then
            LayoutRefs.WindowTitle.Visible = not IsCompact
            if not IsCompact then
                local MaxTextWidth =
                    math.max(0, SidebarWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12))
                local TextWidth =
                    Library:GetTextBounds(LayoutRefs.WindowTitle.Text, Library.Scheme.Font, 20, MaxTextWidth)
                LayoutRefs.WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
            else
                LayoutRefs.WindowTitle.Size = UDim2.new(0, 0, 1, 0)
            end
        end

        if LayoutRefs.RightWrapper then
            local PositionX = SidebarWidth + 8
            LayoutRefs.RightWrapper.Position = UDim2.new(0, PositionX, 0.5, 0)
            LayoutRefs.RightWrapper.Size = UDim2.new(1, -PositionX - 8 - MoveReservedWidth, 1, -16)
        end

        for _, Padding in ipairs(LayoutRefs.TabPadding) do
            Padding.PaddingLeft = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingRight = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingTop = UDim.new(0, IsCompact and 7 or 11)
            Padding.PaddingBottom = UDim.new(0, IsCompact and 7 or 11)
        end

        for _, LabelObject in ipairs(LayoutRefs.TabLabels) do
            LabelObject.Visible = not IsCompact
        end

        SetSidebarHighlight(LayoutState.GrabberHighlighted)

        WindowInfo.Compact = LayoutState.IsCompact

        for _, TabObject in pairs(Library.Tabs) do
            if TabObject.RefreshSides then
                TabObject:RefreshSides()
            end
        end
    end

    local function SetSidebarWidth(Width)
        EnsureSidebarBounds()

        Width = Width or LayoutState.CurrentWidth

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        local WasCompact = LayoutState.IsCompact

        if Width <= Threshold then
            if not WasCompact then
                LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            end
            LayoutState.IsCompact = true
        else
            local TargetWidth = Width
            if WasCompact then
                TargetWidth = math.max(Width, LayoutState.MinWidth)
            end

            LayoutState.CurrentWidth = math.clamp(TargetWidth, LayoutState.MinWidth, LayoutState.MaxWidth)
            LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            LayoutState.IsCompact = false
        end

        ApplySidebarLayout()
    end

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false
        Library:UpdateDPI(Library.KeybindFrame, {
            Position = false,
            Size = false,
        })

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

            DPIExclude = {
                Position = true,
            },
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = MainFrame,
        })
        local InitialSidebarWidth = GetSidebarWidth()
        LayoutRefs.DividerLine = Library:MakeLine(MainFrame, {
            Position = UDim2.new(0, InitialSidebarWidth, 0, 0),
            Size = UDim2.new(0, 1, 1, -21),
            ZIndex = 2,
        })

        local Lines = {
            {
                Position = UDim2.fromOffset(0, 48),
                Size = UDim2.new(1, 0, 0, 1),
            },
            {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -20),
                Size = UDim2.new(1, 0, 0, 1),
            },
        }
        for _, Info in pairs(Lines) do
            Library:MakeLine(MainFrame, Info)
        end
        Library:MakeOutline(MainFrame, WindowInfo.CornerRadius, 0)

        if WindowInfo.BackgroundImage then
            New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })
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
        local TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, math.max(LayoutState.CompactWidth, InitialSidebarWidth), 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })
        LayoutRefs.TitleHolder = TitleHolder

        local WindowIcon
        if WindowInfo.Icon then
            WindowIcon = New("ImageButton", {
                Image = if tonumber(WindowInfo.Icon)
                    then string.format("rbxassetid://%d", WindowInfo.Icon)
                    else WindowInfo.Icon,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        else
            WindowIcon = New("TextButton", {
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        end
        WindowIcon.Visible = WindowInfo.Icon ~= nil or LayoutState.IsCompact
        LayoutRefs.WindowIcon = WindowIcon

        WindowTitle = New("TextButton", {
            BackgroundTransparency = 1,
            Text = WindowInfo.Title,
            TextSize = 20,
            Visible = not LayoutState.IsCompact,
            Parent = TitleHolder,
        })
        if not LayoutState.IsCompact then
            local MaxTextWidth =
                math.max(0, InitialSidebarWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12))
            local TextWidth = Library:GetTextBounds(WindowTitle.Text, Library.Scheme.Font, 20, MaxTextWidth)
            WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
        else
            WindowTitle.Size = UDim2.new(0, 0, 1, 0)
        end

        LayoutRefs.WindowTitle = WindowTitle

        --// Top Right Bar
        local RightWrapper = New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, InitialSidebarWidth + 8, 0.5, 0),
            Size = UDim2.new(1, -(InitialSidebarWidth + 16 + MoveReservedWidth), 1, -16),
            Parent = TopBar,
        })
        LayoutRefs.RightWrapper = RightWrapper

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
            PaddingLeft = UDim.new(0, 2),
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
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = SearchBox,
        })
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
        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        do
            local Cover = Library:MakeCover(BottomBar, "Top")
            Library:AddToRegistry(Cover, {
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
                end,
            })
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = BottomBar,
        })

        --// Footer
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            Parent = BottomBar,
        })

        --// Resize Button
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                EnsureSidebarBounds()
                ApplySidebarLayout()
                for _, Tab in pairs(Library.Tabs) do
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

        Library:GiveSignal(MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            EnsureSidebarBounds()
            ApplySidebarLayout()
        end))

        --// Tabs \\--
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, 49),
            ScrollBarThickness = 0,
            Size = UDim2.new(0, InitialSidebarWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            Parent = Tabs,
        })
        LayoutRefs.TabsFrame = Tabs

        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.fromOffset(InitialSidebarWidth, 49),
            Size = UDim2.new(1, -InitialSidebarWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })

        LayoutRefs.ContainerFrame = Container

        if WindowInfo.EnableSidebarResize then
            local SidebarGrabber = New("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(0, 12, 1, -70),
                Position = UDim2.fromOffset(InitialSidebarWidth - 6, 49),
                ZIndex = 5,
                Parent = MainFrame,
            })
            LayoutRefs.SidebarGrabber = SidebarGrabber

            SidebarGrabber.MouseEnter:Connect(function()
                if Library.Toggled then
                    SetSidebarHighlight(true)
                end
            end)
            SidebarGrabber.MouseLeave:Connect(function()
                if not SidebarDrag.Active then
                    SetSidebarHighlight(false)
                end
            end)

            Library:GiveSignal(SidebarGrabber.InputBegan:Connect(function(input)
                if not Library.Toggled then
                    return
                end

                if
                    input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch
                then
                    return
                end

                SidebarDrag.Active = true
                SidebarDrag.StartWidth = GetSidebarWidth()
                SidebarDrag.StartX = input.Position.X
                SidebarDrag.TouchId = input.UserInputType == Enum.UserInputType.Touch and input or nil

                SetSidebarHighlight(true)

                local Connection
                Connection = Library:GiveSignal(input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        SidebarDrag.Active = false
                        SidebarDrag.TouchId = nil
                        local IsOver = Library:MouseIsOverFrame(SidebarGrabber, Vector2.new(Mouse.X, Mouse.Y))
                        SetSidebarHighlight(IsOver and Library.Toggled)
                        if Connection then
                            Connection:Disconnect()
                        end
                    end
                end))
            end))

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                if not SidebarDrag.Active then
                    return
                end

                if not Library.Toggled then
                    SidebarDrag.Active = false
                    SidebarDrag.TouchId = nil
                    SetSidebarHighlight(false)
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement or input == SidebarDrag.TouchId then
                    local Delta = input.Position.X - SidebarDrag.StartX
                    SetSidebarWidth(SidebarDrag.StartWidth + Delta)
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if not SidebarDrag.Active then
                    return
                end

                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                    or input == SidebarDrag.TouchId
                then
                    SidebarDrag.Active = false
                    SidebarDrag.TouchId = nil
                    local IsOver = Library:MouseIsOverFrame(SidebarGrabber, Vector2.new(Mouse.X, Mouse.Y))
                    SetSidebarHighlight(IsOver and Library.Toggled)
                end
            end))

            SetSidebarHighlight(false)
        end

        task.defer(function()
            EnsureSidebarBounds()
            ApplySidebarLayout()
        end)
    end

    --// Window Table \\--
    Window = {}

    function Window:GetSidebarWidth()
        return GetSidebarWidth()
    end

    function Window:IsSidebarCompacted()
        return LayoutState.IsCompact
    end

    function Window:SetSidebarWidth(Width)
        SetSidebarWidth(Width)
    end

    function Window:SetCompact(State)
        assert(typeof(State) == "boolean", "State must be a boolean")

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        if State then
            SetSidebarWidth(Threshold * 0.5)
        else
            SetSidebarWidth(LayoutState.LastExpandedWidth or LayoutState.CurrentWidth or LayoutState.MinWidth)
        end
    end

    function Window:ApplyLayout()
        ApplySidebarLayout()
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))
        
        WindowTitle.Text = title
        WindowInfo.Title = title
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
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, ButtonPadding)

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

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
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
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

                TabLeft.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabLeft, { Size = TabLeft.Size })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
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

                TabRight.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabRight, { Size = TabRight.Size })
            end
        end

        --// Warning Box \\--
        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(2, 6),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer
        })

        local WarningBoxBackground, WarningBoxOutline = Library:MakeOutline(WarningBoxHolder, WindowInfo.CornerRadius)
        WarningBoxBackground.Size = UDim2.fromScale(1, 0)
        Library:UpdateDPI(WarningBoxBackground, {
            Size = false,
        })

        local WarningBox
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 0, 100),
                Parent = WarningBoxBackground,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                Parent = WarningBox,
            })
            
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
                Color = "Dark",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
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

            WarningBoxBackground.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.Dark
                or Color3.fromRGB(169, 0, 0)
            WarningBoxOutline.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(255, 50, 50)
            
            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxBackground] then
                Library:AddToRegistry(WarningBoxBackground, {})
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

            Library.Registry[WarningBoxBackground].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.Dark or Color3.fromRGB(169, 0, 0)
            end
            
            Library.Registry[WarningBoxOutline].BackgroundColor3 = function()
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
            local Offset = WarningBoxHolder.Visible and WarningBoxBackground.AbsoluteSize.Y + 6 or 0
            for _, Side in pairs(Tab.Sides) do
                Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                Side.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, -Offset)
                Library:UpdateDPI(Side, {
                    Position = Side.Position,
                    Size = Side.Size,
                })
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
                Library:UpdateDPI(WarningText, { Size = WarningText.Size })

                WarningBox.Size = UDim2.new(1, -4, 0, YBox)
                Library:UpdateDPI(WarningBox, { Size = WarningBox.Size })

                WarningBoxBackground.Size = UDim2.new(1, 0, 0, YBox + 4 * Library.DPIScale)
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

            local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
            Background.Size = UDim2.fromScale(1, 0)
            Library:UpdateDPI(Background, {
                Size = false,
            })

            local GroupboxHolder
            local GroupboxLabel

            local GroupboxContainer
            local GroupboxList

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Background,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                    Parent = GroupboxHolder,
                })
                Library:MakeLine(GroupboxHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "White" or "AccentColor",
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
                Holder = Background,
                Container = GroupboxContainer,

                Tab = Tab,
                DependencyBoxes = {},
                Elements = {},
            }

            function Groupbox:Resize()
                Background.Size = UDim2.new(1, 0, 0, GroupboxList.AbsoluteContentSize.Y + 53 * Library.DPIScale)
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

            local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
            Background.Size = UDim2.fromScale(1, 0)
            Library:UpdateDPI(Background, {
                Size = false,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Background,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                    Parent = TabboxHolder,
                })

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

            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = Background,
                Tabs = {},
            }

            function Tabbox:AddTab(Name)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = TabboxButtons,
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

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    Button.TextTransparency = 0
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    Button.TextTransparency = 0.5
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end
                    Background.Size = UDim2.new(1, 0, 0, List.AbsoluteContentSize.Y + 53 * Library.DPIScale)
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab

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
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
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

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
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

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            local KeyTabPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, KeyTabPadding)

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

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
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(...)
            local Data = {}

            local First = select(1, ...)

            if typeof(First) == "function" then
                Data.Callback = First
            else
                Data.ExpectedKey = First
                Data.Callback = select(2, ...)
            end

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
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

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })

            Button.MouseButton1Click:Connect(function()
                if Data.ExpectedKey and Box.Text ~= Data.ExpectedKey then
                    Data.Callback(false, Box.Text)
                    return
                end

                Data.Callback(true, Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end

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
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
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

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
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

    function Library:Toggle(Value: boolean?)
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
            SetSidebarHighlight(false)
            TooltipLabel.Visible = false
            for _, Option in pairs(Library.Options) do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    if WindowInfo.AutoShow then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

            LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
        else
            LockButton.Button.Position = UDim2.fromOffset(6, 46)
        end
    end

    --// Execution \\--
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
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

    task.delay(0.1, function()
        for Instance, Properties in pairs(Library.DPIRegistry) do
            for Property, Value in pairs(Properties) do
                if Property == "DPIExclude" or Property == "DPIOffset" then
                    continue
                elseif Property == "TextSize" then
                    Instance[Property] = ApplyTextScale(Value)
                else
                    Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
                end
            end
        end

        for _, Tab in pairs(Library.Tabs) do
            if Tab.IsKeyTab then
                continue
            end

            Tab:Resize(true)
            for _, Groupbox in pairs(Tab.Groupboxes) do
                Groupbox:Resize()
            end
            for _, Tabbox in pairs(Tab.Tabboxes) do
                for _, SubTab in pairs(Tabbox.Tabs) do
                    SubTab:Resize()
                end
            end
        end

        for _, Option in pairs(Options) do
            if Option.Type == "Dropdown" then
                Option:RecalculateListSize()
            elseif Option.Type == "KeyPicker" then
                Option:Update()
            end
        end

        Library:UpdateKeybindFrame()
        for _, Notification in pairs(Library.Notifications) do
            Notification:Resize()
        end
    end)

    return Window
end

local function OnPlayerChange()
    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)

    for _, Dropdown in pairs(Options) do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end
local function OnTeamChange()
    local TeamList = GetTeams()

    for _, Dropdown in pairs(Options) do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

Library.ThemeManager = (function()
    local cloneref = (cloneref or clonereference or function(instance: any)
        return instance
    end)
    local clonefunction = (clonefunction or copyfunction or function(func) 
        return func 
    end)

    local HttpService: HttpService = cloneref(game:GetService("HttpService"))
    local isfolder, isfile, listfiles = isfolder, isfile, listfiles

    if typeof(clonefunction) == "function" then
        -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

        local
            isfolder_copy,
            isfile_copy,
            listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

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

    local ThemeManager = {}
    do
        local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        ThemeManager.Folder = "ObsidianLibSettings"
        -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

        ThemeManager.Library = nil
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
            }
        }

        function ThemeManager:SetLibrary(library)
            self.Library = library
        end

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

            for _, field in { "Red", "Dark", "White" } do
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

    return ThemeManager
end)()

Library.SaveManager = (function()
    local cloneref = (cloneref or clonereference or function(instance: any)
        return instance
    end)
    local clonefunction = (clonefunction or copyfunction or function(func) 
        return func 
    end)

    local HttpService: HttpService = cloneref(game:GetService("HttpService"))
    local isfolder, isfile, listfiles = isfolder, isfile, listfiles

    if typeof(clonefunction) == "function" then
        -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

        local
            isfolder_copy,
            isfile_copy,
            listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

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

    local SaveManager = {} do
        SaveManager.Folder = "ObsidianLibSettings"
        SaveManager.SubFolder = ""
        SaveManager.Ignore = {}
        SaveManager.Library = nil
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
                    return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
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

        function SaveManager:SetLibrary(library)
            self.Library = library
        end

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

return Library
