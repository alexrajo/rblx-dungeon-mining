local components = script.Parent.components
local contexts = script.Parent.contexts
local utils = script.Parent.utils

local ModuleIndex = {
	PageManager = components.PageManager,
	ControlsOverlay = components.ControlsOverlay,
	Button = components.Button,
	TextButton = components.TextButton,
	ActionButton = components.ActionButton,
	Window = components.Window,
	Panel = components.Panel,
	SelectablePanel = components.SelectablePanel,
	SelectableItemTile = components.SelectableItemTile,
	PageWrapper = components.PageWrapper,
	Sidebar = components.Sidebar,
	ProgressBar = components.ProgressBar,
	LevelBar = components.LevelBar,
	TextLabel = components.TextLabel,
	Toolbar = components.Toolbar,
	ChangeVisualizer = components.ChangeVisualizer,
	NotificationManager = components.NotificationManager,
	MineTransitionOverlay = components.MineTransitionOverlay,
	NotificationPanel = components.NotificationPanel,
	TutorialManager = components.TutorialManager,
	ConversationManager = components.ConversationManager,
	ConfirmationModal = components.ConfirmationModal,
	ItemCounter = components.ItemCounter,
	Tab = components.Tab,
	Clickable = components.Clickable,
	HealthBar = components.HealthBar,
	ActiveEffectsBar = components.ActiveEffectsBar,
	FloorIndicator = components.FloorIndicator,
	EnemyBillboard = components.EnemyBillboard,
	QuestTracker = components.QuestTracker,

	SellConfirmationDialog = components.SellConfirmationDialog,
	InventoryPopup = components.InventoryPopup,
	InventoryPopupManager = components.InventoryPopupManager,

	InventoryResourcesView = components.InventoryPage.ResourcesView,
	InventoryGearView = components.InventoryPage.GearView,
	InventoryLoadoutView = components.InventoryPage.LoadoutView,

	StatsContext = contexts.StatsContext,
	ScreenContext = contexts.ScreenContext,
	InventoryUtils = utils.InventoryUtils,
	QuestDataUtils = utils.QuestDataUtils,

	TutorialSteps = components.Tutorials,
}

return ModuleIndex
