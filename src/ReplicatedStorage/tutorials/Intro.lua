function getClosestBurpableInstancePosition(player: Player)
    -- Maybe do this on the client? May be better in case the instance gets burped away, so you can find a new one.
    warn("getClosestBurpableInstancePosition: Not implemented!")
end

function getDrinkMixingStationPosition()
    return workspace.DrinkMixingStation.PageActivationCircle.ActivationCircle.Position
end

local IntroTutorial = {
    rewards = {},
    steps = {
        {
            id = "Welcome",
            description = "Welcome to Burping Simulator 2! This tutorial will teach you the basics to get you started!",
            completeOn = "click"
        },
        {
            id = "PressToDrink",
            description = "First equip your drink, then press your screen to drink.",
            completeOn = "drink"
        },
        {
            id = "BurpCharge",
            description = "Great! This gives you more burp charge, allowing you to burp harder. You can get max 5 burp charge.",
            completeOn = "click"
        },
        {
            id = "Burp",
            description = "Now try burping by pressing the 'Burp' button on screen or by pressing the key displayed on the button.",
            completeOn = "burp"
        },
        {
            id = "BurpOnThings",
            description = "You can burp on items and buildings to blow them away! Try this out now.",
            pointToPositionFunction = getClosestBurpableInstancePosition,
            completeOn = "burpOnItem"
        },
        {
            id = "BurpOnThings_Items",
            description = "Nicely done! Burping on stuff can drop ingredients. Try burping on more things to get an ingredient.",
            pointToPositionFunction = getClosestBurpableInstancePosition,
            completeOn = "getIngredient"
        },
        {
            id = "DrinkMixingStation",
            description = "You got an ingredient! You can use this ingredient by heading to the drink mixing station.",
            pointToPositionFunction = getDrinkMixingStationPosition,
            completeOn = "openPage_DrinkMixingPage"
        },
        {
            id = "DrinkMixingStation_SelectRecipe",
            description = "Select the first recipe.",
            completeOn = "selectCorrectRecipe"
        },
        {
            id = "DrinkMixingStation_MixDrink",
            description = "Now click the button to mix the drink!",
            completeOn = "mixDrink"
        },
        {
            id = "IntroEnd",
            description = "You are all set! Explore the world and burp away! Reminder: You can always get back to this tutorial by pressing the tutorial button marked with '?'.",
            completeOn = "click"
        },
    }
}

return IntroTutorial
