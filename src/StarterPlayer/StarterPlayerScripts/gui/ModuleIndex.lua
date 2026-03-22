local components = script.Parent.components
local contexts = script.Parent.contexts

local ModuleIndex = {
	PageManager = components.PageManager,
	ControlsOverlay = components.ControlsOverlay,
	Button = components.Button,
	TextButton = components.TextButton,
	ActionButton = components.ActionButton,
	Window = components.Window,
	Panel = components.Panel,
	SelectablePanel = components.SelectablePanel,
	PageWrapper = components.PageWrapper,
	Sidebar = components.Sidebar,
	ProgressBar = components.ProgressBar,
	LevelBar = components.LevelBar,
	TextLabel = components.TextLabel,
	Toolbar = components.Toolbar,
	ChangeVisualizer = components.ChangeVisualizer,
	NotificationManager = components.NotificationManager,
	NotificationPanel = components.NotificationPanel,
	TutorialManager = components.TutorialManager,
	IngredientCounter = components.IngredientCounter,
	Tab = components.Tab,
	Clickable = components.Clickable,

	InventoryIngredientsView = components.InventoryPage.IngredientsView,
	InventoryDrinksView = components.InventoryPage.DrinksView,

	StatsContext = contexts.StatsContext,
	ScreenContext = contexts.ScreenContext,

	TutorialSteps = components.Tutorials,
}

return ModuleIndex
