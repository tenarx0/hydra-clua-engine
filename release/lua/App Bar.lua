-- ==============================================================================
-- HYDRA NATIVE BRIDGE: AppBars
-- Description: UI manipulation using pure native Java classes via Lua.
-- Demonstrates Window flags, GradientDrawables, and View injection.
-- ==============================================================================

-- ─── 1. EXTENSIVE NATIVE IMPORTS ──────────────────────────────────────────────
import("android.widget.Toolbar")
import("android.widget.LinearLayout")
import("android.widget.TextView")
import("android.graphics.Color")
import("android.graphics.Typeface")
import("android.graphics.drawable.GradientDrawable")
import("android.view.Gravity")
import("android.view.WindowManager$LayoutParams")
import("android.widget.Toast")
import("android.view.View$OnClickListener")

-- ─── 2. STATUS BAR INTEGRATION (THE FLEX) ─────────────────────────────────────
-- Blend the Android system status bar (top of phone) into our custom header
local window = context:getWindow()
window:addFlags(WindowManager.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
window:setStatusBarColor(Color:parseColor("#09090B")) -- Ultra Dark Background

-- Clear default XML ActionBars to prevent IllegalStateException
if context:getActionBar() ~= nil then
    context:getActionBar():hide()
end

-- ─── 3. ROOT LAYOUT SETUP ─────────────────────────────────────────────────────
local rootLayout = LinearLayout(context)
rootLayout:setOrientation(1) -- 1 = VERTICAL
rootLayout:setBackgroundColor(Color:parseColor("#09090B"))

-- ─── 4. BASE TOOLBAR SETUP ────────────────────────────────────────────────────
local appBar = Toolbar(context)
appBar:setBackgroundColor(Color:parseColor("#121214")) -- Slightly lighter for contrast
appBar:setElevation(16.0) -- Heavy Material shadow

-- ─── 5. CUSTOM VIEW INJECTION (THE "PRO" BADGE) ───────────────────────────────
-- Instead of a boring standard title, we inject a custom container into the Toolbar
local titleContainer = LinearLayout(context)
titleContainer:setOrientation(0) -- 0 = HORIZONTAL
titleContainer:setGravity(Gravity.CENTER_VERTICAL)

-- The Main Title Text
local titleText = TextView(context)
titleText:setText("HYDRA")
titleText:setTextColor(Color:parseColor("#FFFFFF"))
titleText:setTextSize(18.0)
titleText:setTypeface(Typeface.DEFAULT_BOLD)

-- The "PRO" Badge Text
local badgeText = TextView(context)
badgeText:setText("PRO")
badgeText:setTextColor(Color:parseColor("#09090B"))
badgeText:setTextSize(10.0)
badgeText:setTypeface(Typeface.MONOSPACE, 1) -- 1 = BOLD
badgeText:setPadding(16, 4, 16, 4) -- Left, Top, Right, Bottom padding

-- The Badge Background (Rounded Neon Pill)
local badgeBg = GradientDrawable()
badgeBg:setShape(0) -- 0 = RECTANGLE
badgeBg:setCornerRadius(24.0)
badgeBg:setColor(Color:parseColor("#00E676")) -- Cyberpunk Neon Green
badgeText:setBackground(badgeBg)

-- Layout Parameters for the Badge (Margins)
local LayoutParams = import("android.widget.LinearLayout$LayoutParams")
local badgeParams = LayoutParams(-2, -2) -- -2 = WRAP_CONTENT
badgeParams:setMargins(16, 0, 0, 0) -- 16px Left margin

-- Assemble the custom title
titleContainer:addView(titleText)
titleContainer:addView(badgeText, badgeParams)

-- Inject the custom container into the Toolbar
local ToolbarParams = import("android.widget.Toolbar$LayoutParams")
appBar:addView(titleContainer, ToolbarParams(-2, -2, Gravity.START))

-- ─── 6. INTERACTIVE ELEMENTS (NO RESOURCE IDS) ────────────────────────────────
-- Create a custom programmatic "Back" button using a TextView to avoid R.drawable ints
local backIcon = TextView(context)
backIcon:setText("<") -- Simple back indicator
backIcon:setTextColor(Color:parseColor("#FFFFFF"))
backIcon:setTextSize(22.0)
backIcon:setTypeface(Typeface.DEFAULT_BOLD)
backIcon:setPadding(16, 0, 16, 0)

-- Inject it directly into the Toolbar as the first element
local ToolbarParams = import("android.widget.Toolbar$LayoutParams")
appBar:addView(backIcon, 0, ToolbarParams(-2, -2, Gravity.START))

backIcon:setOnClickListener(OnClickListener({
    onClick = function(view)
        context:finish()
    end
}))

-- Standard Menus (These don't require drawable IDs)
local menu = appBar:getMenu()
menu:add(0, 1, 0, "Build"):setShowAsAction(2)
appBar:setOnMenuItemClickListener(import("android.widget.Toolbar$OnMenuItemClickListener")({
    onMenuItemClick = function(item)
        if item:getItemId() == 1 then
            Toast:makeText(context, "Initiating Ninja Build...", Toast.LENGTH_SHORT):show()
            return true
        end
        return false
    end
}))

-- ─── 7. FINAL MOUNTING ────────────────────────────────────────────────────────
-- Add the completed Toolbar to the top of our Root layout
rootLayout:addView(appBar, LayoutParams(-1, -2)) -- -1 = MATCH_PARENT, -2 = WRAP_CONTENT

-- Render everything to the screen
context:setContentView(rootLayout)