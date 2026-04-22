--[[
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║   ██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗     ██╗   ██╗██╗                      ║
║   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗    ██║   ██║██║                      ║
║   ███████║ ╚████╔╝ ██║  ██║██████╔╝███████║    ██║   ██║██║                      ║
║   ██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║    ██║   ██║██║                      ║
║   ██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║    ╚██████╔╝██║                      ║
║   ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═╝                      ║
║                                                                                  ║
║   HYDRA LAYOUT ENGINE — COMPLETE DEVELOPER REFERENCE                             ║
║   Version: 5.5.0 | Engine: HydraCLuaCore                                         ║
║   Author: @tenarx0                                                               ║
║                                                                                  ║
║   This script is the definitive reference for the loadlayout() function          ║
║   and the Hydra UI system. Every feature, pattern, and best practice is          ║
║   documented inline with working, production-grade examples.                     ║
║                                                                                  ║
║   TABLE OF CONTENTS:                                                             ║
║   ─────────────────                                                              ║
║     §1.  IMPORTS & SETUP                                                         ║
║     §2.  LOADLAYOUT — HOW IT WORKS                                               ║
║     §3.  LAYOUT TABLE ANATOMY                                                    ║
║     §4.  SIZING & DIMENSIONS                                                     ║
║     §5.  COLORS & THEMING                                                        ║
║     §6.  TEXT VIEWS & EDIT TEXT                                                  ║
║     §7.  BUTTONS & CLICK HANDLERS                                                ║
║     §8.  IMAGE VIEWS                                                             ║
║     §9.  SCROLL VIEWS                                                            ║
║     §10. LIST VIEWS (Classic Adapter Pattern)                                    ║
║     §11. RECYCLER VIEWS (Modern List/Grid)                                       ║
║     §12. CHECKBOXES, SWITCHES, RADIO BUTTONS                                     ║
║     §13. SEEKBARS & PROGRESS BARS                                                ║
║     §14. SPINNERS (Dropdowns)                                                    ║
║     §15. WEB VIEWS                                                               ║
║     §16. CUSTOM CANVAS DRAWING                                                   ║
║     §17. REACTIVE STATE BINDINGS                                                 ║
║     §18. VIEW IDS & PROGRAMMATIC ACCESS                                          ║
║     §19. AFTERLOAD CALLBACKS                                                     ║
║     §20. PRE-INFLATED VIEWS                                                      ║
║     §21. NESTED LAYOUTS & COMPLEX HIERARCHIES                                    ║
║     §22. ANIMATIONS                                                              ║
║     §23. NAVIGATION (navigator.push / pop)                                       ║
║     §24. EVENT HANDLING PATTERNS                                                 ║
║     §25. PERFORMANCE BEST PRACTICES                                              ║
║     §26. THE SHOWCASE — FULL PRODUCTION UI                                       ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §1. IMPORTS & SETUP
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    The `import` function loads Java classes into the Lua global scope.
    
    SYNTAX:
        import "fully.qualified.ClassName"     → Binds a single class
        import "package.name.*"                → Wildcard: auto-resolves classes on demand
    WILDCARD IMPORTS:
        When you write `import "android.widget.*"`, Hydra registers the package
        prefix. Any time you reference an undefined global (e.g., `LinearLayout`),
        Hydra's global resolver tries `android.widget.LinearLayout` via JNI.
        Once resolved, the class is cached — no repeated lookups.
    
    INTERFACE IMPORTS:
        Classes whose names end in Listener, Watcher, Callback, or Observer
        are automatically wrapped as interface factories:
            import "android.view.View$OnClickListener"
            -- Now `OnClickListener({...})` creates a Java proxy from a Lua table.

    COMMON IMPORTS FOR UI WORK:
--]]

import "android.widget.*"           -- LinearLayout, TextView, Button, EditText,
                                     -- ImageView, ScrollView, ListView, CheckBox,
                                     -- Switch, RadioGroup, RadioButton, SeekBar,
                                     -- ProgressBar, Spinner, FrameLayout, etc.

import "android.view.*"             -- View, ViewGroup, Gravity constants
import "android.view.View"          -- Explicit for View.VISIBLE, View.GONE, etc.
import "android.webkit.WebView"     -- For embedded web content
import "android.graphics.Color"     -- Color.RED, Color.parseColor(), etc.

import "androidx.recyclerview.widget.RecyclerView"  -- Modern scrolling lists
import "androidx.cardview.widget.CardView"          -- Material card containers
import "android.view.View$OnClickListener"
import "android.text.TextWatcher"
-- Hydra's custom canvas view for 2D drawing
-- import "com.hydra.hclc.HydraCanvasView"


-- ═══════════════════════════════════════════════════════════════════════════════
-- §2. LOADLAYOUT — HOW IT WORKS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    loadlayout(table) → Java View
    
    ┌──────────────────────────────────────────────────────────────────────┐
    │  PHASE 1: PARSE                                                      │
    │  Lua table → HydraNode tree (C++ intermediate representation)        │
    │  • Index [1] of each table must be a Java class or view instance     │
    │  • String keys become properties (layout_width, text, etc.)          │
    │  • Numeric indices > 1 become child views (recursive)                │
    │                                                                      │
    │  PHASE 2: INFLATE                                                    │
    │  HydraNode tree → Android View hierarchy (via JNI)                   │
    │  • Each node's class is instantiated with new ClassName(context)     │
    │  • Properties are applied via HydraPropertyEngine (Java side)        │
    │  • Children are added to parent ViewGroups via addView()             │
    │                                                                      │
    │  PHASE 3: REGISTER                                                   │
    │  Views with `id = "name"` are registered as Lua globals.             │
    │  After loadlayout returns, you can directly access `name` in Lua.    │
    │                                                                      │
    │  PHASE 4: RETURN                                                     │
    │  Returns the root View as a Hydra Java Object (userdata).            │
    │  Pass it to `this.setContentView()` or `navigator.push()`.           │
    └──────────────────────────────────────────────────────────────────────┘
    
    BASIC SYNTAX:
    
        local layout = {
            ViewClass,                      -- [1] = Java class (required)
            property_name = "value",        -- String property
            property_name = 123,            -- Number property (converted to string)
            property_name = true,           -- Boolean property
            property_name = function(v) end,-- Event handler (stored as Lua ref)
            id = "myView",                  -- Registers as global `myView`
            { ChildViewClass, ... },        -- Child at index [2]
            { ChildViewClass, ... },        -- Child at index [3]
        }
        
        local rootView = loadlayout(layout)
    
    WHAT HAPPENS TO EACH VALUE TYPE:
    
        ┌─────────────┬────────────────────────────────────────────────────┐
        │ Lua Type     │ Behavior                                          │
        ├─────────────┼────────────────────────────────────────────────────┤
        │ string       │ Passed as property value to Java PropertyEngine   │
        │ number       │ Converted to string, then passed to Java          │
        │ boolean      │ Converted to "true"/"false" string                │
        │ function     │ Stored in Lua registry;                           │
        │ table (key)  │ Special: "items"/"template" for RecyclerView      │
        │ table (idx)  │ Child view definition (recursive)                 │
        │ userdata     │ Proxy object binding (Java object passed through) │
        │ HydraState   │ Reactive binding: view auto-updates on change     │
        └─────────────┴────────────────────────────────────────────────────┘
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §3. LAYOUT TABLE ANATOMY
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Every layout table follows this structure:
    
    {
        JavaClass,                          -- REQUIRED at index [1]
        
        -- ─── Sizing (required for proper rendering) ───
        layout_width  = "fill" | "wrap" | "200dp" | "50%w" | "80%wp",
        layout_height = "fill" | "wrap" | "200dp" | "50%h" | "80%hp",
        
        -- ─── Identity ───
        id = "uniqueName",                  -- Becomes a Lua global after inflate
        
        -- ─── Any Android setter-based property ───
        propertyName = value,               -- Calls view.setPropertyName(value)
        
        -- ─── Children (index 2, 3, 4, ...) ───
        { ChildClass, ... },
        { ChildClass, ... },
    }
    
    DIMENSION FORMATS:
        "fill" or "match_parent"  → Fills parent completely
        "wrap" or "wrap_content"  → Wraps to content size
        "200dp"                   → 200 density-independent pixels
        "14sp"                    → 14 scaled pixels (for text)
        "50%w"                    → 50% of screen width
        "30%h"                    → 30% of screen height
        "80%wp"                   → 80% of parent width
        "60%hp"                   → 60% of parent height
        "100"                     → 100 raw pixels (avoid this)
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §4. SIZING & DIMENSIONS — QUICK REFERENCE
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    ┌───────────────────┬──────────────────────────────────────────────────┐
    │ Property           │ Values                                          │
    ├───────────────────┼──────────────────────────────────────────────────┤
    │ layout_width       │ "fill", "wrap", "Ndp", "N%w", "N%wp"            │
    │ layout_height      │ "fill", "wrap", "Ndp", "N%h", "N%hp"            │
    │ layout_weight      │ "1", "2.5" (LinearLayout only)                  │
    │ layout_gravity     │ "center", "left", "right|bottom", "top"         │
    │ layout_margin      │ "8dp" (all sides)                               │
    │ layout_marginLeft  │ "16dp"                                          │
    │ layout_marginTop   │ "8dp"                                           │
    │ layout_marginRight │ "16dp"                                          │
    │ layout_marginBottom│ "8dp"                                           │
    │ padding            │ "12dp" (all sides)                              │
    │ paddingLeft        │ "8dp"                                           │
    │ paddingTop         │ "4dp"                                           │
    │ paddingRight       │ "8dp"                                           │
    │ paddingBottom      │ "4dp"                                           │
    └───────────────────┴──────────────────────────────────────────────────┘
    
    GRAVITY VALUES (combinable with "|"):
        center, center_horizontal, center_vertical,
        left, right, top, bottom, start, end,
        fill, fill_horizontal, fill_vertical,
        clip_horizontal, clip_vertical
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §5. COLORS & THEMING
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Colors can be specified in multiple formats:
    
        "#RGB"          → "#F00" (red, expanded to #FF0000)
        "#RRGGBB"       → "#FF5722"
        "#AARRGGBB"     → "#80FF5722" (50% transparent deep orange)
        "0xRRGGBB"      → "0xFF5722"
        "0xAARRGGBB"    → "0x80FF5722"
    
    Any property that accepts an int and receives a color string will be
    auto-detected and parsed (backgroundColor, textColor, etc.)
--]]

-- ─── Theme Colors (define once, use everywhere) ───
local THEME = {
    -- Core palette
    primary       = "#1976D2",    -- Blue 700
    primaryDark   = "#0D47A1",    -- Blue 900
    primaryLight  = "#BBDEFB",    -- Blue 100
    accent        = "#FF6D00",    -- Orange A700
    
    -- Surfaces
    background    = "#FAFAFA",    -- Grey 50
    surface       = "#FFFFFF",
    card          = "#FFFFFF",
    divider       = "#E0E0E0",    -- Grey 300
    
    -- Text
    textPrimary   = "#212121",    -- Grey 900
    textSecondary = "#757575",    -- Grey 600
    textHint      = "#BDBDBD",    -- Grey 400
    textOnPrimary = "#FFFFFF",
    textOnAccent  = "#FFFFFF",
    
    -- Semantic
    success       = "#4CAF50",    -- Green 500
    warning       = "#FF9800",    -- Orange 500
    error         = "#F44336",    -- Red 500
    info          = "#2196F3",    -- Blue 500
    
    -- Spacing (in dp strings for direct use)
    spacing_xs    = "4dp",
    spacing_sm    = "8dp",
    spacing_md    = "16dp",
    spacing_lg    = "24dp",
    spacing_xl    = "32dp",
    
    -- Corner radius
    radius_sm     = "4dp",
    radius_md     = "8dp",
    radius_lg     = "16dp",
    radius_xl     = "24dp",
    radius_pill   = "999dp",
}


-- ═══════════════════════════════════════════════════════════════════════════════
-- §6. TEXT VIEWS & EDIT TEXT
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    TextView Properties:
        text            = "Hello World"
        textSize        = "16sp" | "14dp" | "18"  (default unit: sp)
        textColor       = "#212121"
        textStyle       = "bold" | "italic" | "bold|italic" | "normal"
        singleLine      = "true"
        maxLines        = "3"
        minLines        = "1"
        ellipsize       = "end" | "start" | "middle" | "marquee" | "none"
        lineSpacing     = "4"
        letterSpacing   = "0.05"
        gravity         = "center" | "left" | "right"
        
    EditText Additional Properties:
        hint            = "Enter your name..."
        hintColor       = "#BDBDBD"
        inputType       = "text" | "number" | "email" | "password" | "phone"
                          "multiline" | "decimal" | "uri" | "date" | "time"
                          "capwords" | "capsentences" | "nosuggestions"
                          (Combinable with "|": "number|decimal|signed")
        singleLine      = "true"
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §7. BUTTONS & CLICK HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Buttons are TextViews, so all text properties apply.
    
    EVENT HANDLERS: (inside OnClickListener {...})
        onClick = function(view)
            -- `view` is the Java View object that was clicked
            -- You can call any Java method on it:
            --   view.setText("Clicked!")
            --   view.setBackgroundColor(0xFFFF0000)
        end
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §8. IMAGE VIEWS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    ImageView Properties:
        src             = "icon.png"          -- Loads from assets
        src             = "https://..."       -- Loads from URL (async)
        scaleType       = "centerCrop" | "fitCenter" | "fitXY" | "center"
                          "centerInside" | "fitStart" | "fitEnd" | "matrix"
    
    The `src` property is intercepted by HydraPropertyEngine and routed
    to HydraAssetLoader, which handles both local assets and HTTP downloads.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §9. SCROLL VIEWS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    ScrollView wraps ONE child (typically a LinearLayout with vertical content).
    HorizontalScrollView wraps ONE child for horizontal scrolling.
    
    IMPORTANT: ScrollView can only have ONE direct child. Wrap multiple
    views in a LinearLayout inside the ScrollView.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §10. LIST VIEWS (Classic Adapter Pattern)
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    ListView uses three special properties:
        count    = 50                           -- Number of items
        onCreate = function(position)           -- Must return a View
            return loadlayout({ ... })
        end
        onBind   = function(position, view, count)  -- Populate the view
            view:findView("title").setText("Item #"..position)
        end
    
    Properties arrive in arbitrary order, so Hydra collects all three
    before constructing the adapter. The adapter is created automatically
    once count + onCreate + onBind are all present.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §11. RECYCLER VIEWS (Modern List/Grid)
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    RecyclerView uses a template-based approach:
    
        {
            RecyclerView,
            layout_width = "fill",
            layout_height = "fill",
            
            -- Template: a layout table defining each row's structure
            template = {
                LinearLayout,
                layout_width = "fill",
                layout_height = "wrap",
                padding = "12dp",
                { TextView, id = "title", textSize = "16sp" },
            },
            
            -- Data source: a Lua array of items
            items = {
                { name = "Item 1", color = "#FF0000" },
                { name = "Item 2", color = "#00FF00" },
            },
            
            -- Bind callback: populate each row with data
            onBind = function(view, item, position)
                view:findView("title").setText(item.name)
            end,
        }
    
    A LinearLayoutManager is applied by default if none is set.
    
    To update data dynamically:
        recyclerView:updateItems(newDataTable)
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §12. CHECKBOXES, SWITCHES, RADIO BUTTONS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    CheckBox / Switch:
        checked  = "true" | "false"
        text     = "Accept Terms"
        onClickListener  = OnClickListener {
            onClick = function(v) .... end
        }
    
    RadioGroup + RadioButton:
        The RadioGroup is a LinearLayout subclass. Each RadioButton inside
        it is mutually exclusive.
        
        {
            RadioGroup,
            orientation = "vertical",
            { RadioButton, text = "Option A", id = "optA" },
            { RadioButton, text = "Option B", id = "optB" },
            { RadioButton, text = "Option C", id = "optC" },
        }
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §13. SEEKBARS & PROGRESS BARS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    ProgressBar:
        indeterminate = "true"          -- Spinning animation
        -- Or:
        max      = "100"
        progress = "60"
    
    SeekBar (extends ProgressBar):
        max      = "100"
        progress = "50"
        -- Listen for changes via Java listener proxy (see §24)
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §14. SPINNERS (Dropdowns)
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Spinners require a Java ArrayAdapter. Set it up in afterLoad:
    
        {
            Spinner,
            id = "mySpinner",
            layout_width = "fill",
            layout_height = "wrap",
            afterLoad = function(view)
                local adapter = ArrayAdapter(this, 
                    android.R.layout.simple_spinner_item,
                    {"Option 1", "Option 2", "Option 3"})
                adapter.setDropDownViewResource(
                    android.R.layout.simple_spinner_dropdown_item)
                view.setAdapter(adapter)
            end,
        }
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §15. WEB VIEWS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    WebView loads web content inside your app:
    
        {
            WebView,
            id = "browser",
            layout_width = "fill",
            layout_height = "fill",
            afterLoad = function(view)
                view.getSettings().setJavaScriptEnabled(true)
                view.loadUrl("https://example.com")
            end,
        }
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §16. CUSTOM CANVAS DRAWING
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    HydraCanvasView gives you a 2D drawing surface:
    
        import "com.hydra.hclc.HydraCanvasView"
        
        {
            HydraCanvasView,
            layout_width = "fill",
            layout_height = "300dp",
            onDraw = function(canvas, width, height)
                -- canvas is a Java Canvas object
                -- Use canvas.drawCircle(), canvas.drawRect(), etc.
            end,
        }
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §17. REACTIVE STATE BINDINGS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    `state(initialValue)` creates a reactive value. When bound to a view
    property in a layout table, changing the state auto-updates the view.
    
    CREATING STATE:
        local counter = state("0")
        local name    = state("John")
    
    BINDING TO VIEWS:
        { TextView, text = counter }    -- Auto-updates when counter changes
    
    READING & WRITING:
        local val = counter:get()       -- Returns "0"
        counter:set("42")               -- View auto-updates to "42"
    
    HOW IT WORKS:
        During parseLayout, if a property value is a HydraState userdata,
        Hydra subscribes the inflated view to that state. When you call
        state:set(), it iterates all subscribers and calls
        HydraPropertyEngine.applySingleProperty() on each one via JNI.
        Stale (GC'd) views are automatically pruned via weak references.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §18. VIEW IDS & PROGRAMMATIC ACCESS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    id = "myButton"
    
    After loadlayout() returns, `myButton` exists as a Lua global:
        myButton.setText("New Text")
        myButton.setBackgroundColor(0xFF4CAF50)
        myButton.setVisibility(View.GONE)
    
    You can call ANY public Java method on the view directly.
    Hydra resolves methods dynamically via JNI reflection.
    
    FINDING VIEWS BY TAG (inside a parent):
        local child = parentView:findView("childId")
        child.setText("Found it!")
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §19. AFTERLOAD CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    `afterLoad` is called immediately after a view is inflated and all
    properties are applied. The inflated view is passed as the argument.
    
    USE CASES:
        • Setting up adapters (Spinner, ListView)
        • Configuring WebView settings
        • Running post-layout measurements
        • Attaching Java listeners that need the live view
        
        afterLoad = function(view)
            -- `view` is the fully inflated Java View
            view.requestFocus()
        end
    
    IMPORTANT: afterLoad fires during the inflation pass. The view is
    created but may not yet be attached to a window. For operations that
    need the view to be measured/drawn, use view.post(Runnable).
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §20. PRE-INFLATED VIEWS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    You can embed an already-created Java View into a layout table:
    
        local banner = loadlayout({ ImageView, src = "banner.png", ... })
        
        local layout = {
            LinearLayout,
            layout_width = "fill",
            layout_height = "fill",
            banner,                     -- Pre-inflated view at index [2]
            { TextView, text = "Below the banner" },
        }
    
    Hydra detects that index [2] is a Java object (not a table) and calls
    addView() directly, skipping inflation for that node.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §21. NESTED LAYOUTS & COMPLEX HIERARCHIES
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Layouts can be nested arbitrarily deep (up to 64 levels):
    
        {
            LinearLayout, orientation = "vertical",
            {
                LinearLayout, orientation = "horizontal",
                { TextView, text = "Left", layout_weight = "1" },
                { TextView, text = "Right", layout_weight = "1" },
            },
            {
                FrameLayout,
                { ImageView, src = "bg.png", layout_width = "fill" },
                { TextView, text = "Overlay", layout_gravity = "center" },
            },
        }
    
    LAYOUT TYPES:
        LinearLayout    → Horizontal or vertical stacking (orientation)
        FrameLayout     → Stacked layers (layout_gravity for positioning)
        RelativeLayout  → Relative positioning (use Android XML-style rules)
        ScrollView      → Single-child vertical scrolling
        HorizontalScrollView → Single-child horizontal scrolling
        CardView         → Material card with elevation and corner radius
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §22. ANIMATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Any view can be animated using the :animate() method:
    
        myView:animate({
            alpha = 0.5,                -- Fade to 50%
            translationX = 100,         -- Move 100px right
            translationY = -50,         -- Move 50px up
            scaleX = 1.2,              -- Scale 120% horizontal
            scaleY = 1.2,              -- Scale 120% vertical
            rotation = 45,             -- Rotate 45 degrees
            duration = 400,            -- Duration in milliseconds
            onEnd = function()         -- Completion callback
                print("Animation done!")
            end,
        })
    
    ANIMATABLE PROPERTIES:
        alpha, translationX, translationY, scaleX, scaleY,
        rotation, rotationX, rotationY, x, y
    
    These are dispatched to HydraAnimationEngine on the Java side,
    which uses Android's ViewPropertyAnimator for hardware-accelerated
    60fps animations.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §23. NAVIGATION (navigator.push / pop)
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    Hydra includes a stack-based screen navigator for single-Activity apps.
    
    SETUP:
        navigator.init(this)            -- Initialize with Activity context
    
    PUSH A SCREEN:
        navigator.push(view)            -- Default slide transition
        navigator.push(view, {          -- Custom transition
            type = "slide",             -- "slide" | "fade" | "zoom" | "none"
            duration = 300,             -- Transition duration (ms)
        })
    
    POP (GO BACK):
        navigator.pop()                 -- Default reverse transition
        navigator.pop({
            type = "fade",
            duration = 200,
        })
    
    TRANSITION TYPES:
        ┌──────────┬───────────────────────────────────────────────────┐
        │ Type      │ Effect                                           │
        ├──────────┼───────────────────────────────────────────────────┤
        │ "slide"   │ New screen slides in from right; old slides left │
        │ "fade"    │ Crossfade between screens                        │
        │ "zoom"    │ New screen zooms in from center                  │
        │ "none"    │ Instant swap, no animation                       │
        └──────────┴───────────────────────────────────────────────────┘
    
    PATTERN: Building Multi-Screen Apps:
    
        -- screen_home.lua
        function createHomeScreen()
            return loadlayout({
                LinearLayout,
                layout_width = "fill", layout_height = "fill",
                {
                    Button, text = "Go to Profile",
                    onClickListener  = OnClickListener {
                        onClick = function()
                            navigator.push(createProfileScreen(), { type = "slide" })
                        end
                    }
                },
            })
        end
        
        -- In your main script:
        navigator.init(this)
        navigator.push(createHomeScreen())
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §24. EVENT HANDLING PATTERNS
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    INLINE HANDLERS (simple):
        onClickListener  = OnClickListener {
            onClick = function(view)
                view.setText("Clicked!")
            end
        }
    
    JAVA LISTENER PROXIES (advanced):
        For listeners with multiple methods, use interface proxies:
        
        import "android.widget.SeekBar$OnSeekBarChangeListener"
        
        seekbar.setOnSeekBarChangeListener(OnSeekBarChangeListener({
            onProgressChanged = function(sb, progress, fromUser)
                label.setText("Value: "..progress)
            end,
            onStartTrackingTouch = function(sb) end,
            onStopTrackingTouch = function(sb) end,
        }))
    
    tenar table PROXY (generic):
        local listener = tenar.proxy("android.view.View$OnClickListener", {
            onClick = function(view)
                print("Proxy click!")
            end,
        })
        myView.setOnClickListener(listener)
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §25. PERFORMANCE BEST PRACTICES
-- ═══════════════════════════════════════════════════════════════════════════════
--[[
    1. MINIMIZE NESTING DEPTH
       Each level of nesting is a recursive JNI call. Use FrameLayout for
       overlapping content instead of stacking LinearLayouts.
    
    2. USE layout_weight INSTEAD OF FIXED SIZES
       Avoids needing to calculate screen-relative sizes at runtime.
    
    3. PREFER RecyclerView OVER ListView
       RecyclerView reuses views; ListView creates/binds every row.
    
    4. CACHE LAYOUT TABLES FOR REUSE
       If you push/pop screens, store layout functions, don't rebuild
       the table structure every time.
    
    5. BATCH STATE UPDATES
       Each state:set() triggers a JNI call per subscriber. If updating
       10 states, do them all at once rather than interleaving UI reads.
    
    6. USE afterLoad FOR POST-INFLATE SETUP
       Don't call Java methods on a view before loadlayout returns.
       Use afterLoad to guarantee the view exists.
    
    7. AVOID DEEP TABLES IN PROPERTIES
       Only "items" and "template" table-value properties are supported.
       Arbitrary nested tables in properties are ignored.
--]]


-- ═══════════════════════════════════════════════════════════════════════════════
-- §26. THE SHOWCASE — FULL PRODUCTION UI
-- ═══════════════════════════════════════════════════════════════════════════════
-- This is a complete, working layout demonstrating every major feature
-- in a single cohesive Material-style application interface.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Reactive State ───
local headerTitle    = state("Hydra Developer Showcase")
local statusText     = state("All systems operational")
local counterValue   = state("0")
local progressValue  = state("50")
local searchQuery    = state("")
local toggleLabel    = state("Notifications: ON")
local sliderLabel    = state("Brightness: 50%")
local itemCount      = state("6 items loaded")

-- ─── Data ───
local showcaseItems = {
    { title = "LinearLayout",    desc = "Vertical & horizontal stacking",    icon = "📦", color = "#E3F2FD" },
    { title = "FrameLayout",     desc = "Layered & overlapping views",       icon = "🖼️", color = "#FFF3E0" },
    { title = "ScrollView",      desc = "Scrollable content containers",     icon = "📜", color = "#E8F5E9" },
    { title = "RecyclerView",    desc = "Efficient scrolling lists",         icon = "♻️", color = "#FCE4EC" },
    { title = "CardView",        desc = "Material Design card surfaces",     icon = "🃏", color = "#F3E5F5" },
    { title = "WebView",         desc = "Embedded web browser component",    icon = "🌐", color = "#E0F7FA" },
}

-- ─── Helper: Create a section header ───
local function sectionHeader(title, subtitle)
    return {
        LinearLayout,
        layout_width = "fill",
        layout_height = "wrap",
        orientation = "vertical",
        padding = "16dp",
        layout_marginTop = "8dp",
        {
            TextView,
            layout_width = "wrap",
            layout_height = "wrap",
            text = title,
            textSize = "13sp",
            textStyle = "bold",
            textColor = THEME.primary,
            letterSpacing = "0.1",
        },
        {
            TextView,
            layout_width = "wrap",
            layout_height = "wrap",
            text = subtitle,
            textSize = "12sp",
            textColor = THEME.textSecondary,
            layout_marginTop = "2dp",
        },
    }
end

-- ─── Helper: Create a Material-style card ───
local function card(content)
    return {
        LinearLayout,
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginLeft = THEME.spacing_md,
        layout_marginRight = THEME.spacing_md,
        layout_marginTop = THEME.spacing_sm,
        layout_marginBottom = THEME.spacing_sm,
        backgroundColor = THEME.card,
        cornerRadius = THEME.radius_md,
        elevation = "2dp",
        orientation = "vertical",
        padding = THEME.spacing_md,
        content, -- Single child passed in
    }
end

-- ─── Helper: Horizontal key-value info row ───
local function infoRow(label, valueState)
    return {
        LinearLayout,
        layout_width = "fill",
        layout_height = "wrap",
        orientation = "horizontal",
        padding = "8dp",
        gravity = "center_vertical",
        {
            TextView,
            layout_width = "0dp",
            layout_height = "wrap",
            layout_weight = "1",
            text = label,
            textSize = "14sp",
            textColor = THEME.textSecondary,
        },
        {
            TextView,
            layout_width = "wrap",
            layout_height = "wrap",
            text = valueState,
            textSize = "14sp",
            textStyle = "bold",
            textColor = THEME.textPrimary,
        },
    }
end

-- ─── Counter Logic ───
local counterNum = 0
local function incrementCounter()
    counterNum = counterNum + 1
    counterValue:set(tostring(counterNum))
end
local function decrementCounter()
    counterNum = counterNum - 1
    if counterNum < 0 then counterNum = 0 end
    counterValue:set(tostring(counterNum))
end
local function resetCounter()
    counterNum = 0
    counterValue:set("0")
    statusText:set("Counter reset at " .. os.date("%H:%M:%S"))
end

-- ─── Notification toggle logic ───
local notifEnabled = true
local function toggleNotifications()
    notifEnabled = not notifEnabled
    toggleLabel:set("Notifications: " .. (notifEnabled and "ON" or "OFF"))
    statusText:set("Notifications " .. (notifEnabled and "enabled" or "disabled"))
end

-- ═════════════════════════════════════════════════════════════════════════════
-- MAIN LAYOUT — THE COMPLETE SHOWCASE
-- ═════════════════════════════════════════════════════════════════════════════

local mainLayout = {
    -- Root: Vertical LinearLayout filling the entire screen
    LinearLayout,
    layout_width  = "fill",
    layout_height = "fill",
    orientation   = "vertical",
    backgroundColor = THEME.background,

    -- ═════════════════════════════════════════════════
    -- TOOLBAR / STATUS BAR
    -- ═════════════════════════════════════════════════
    {
        LinearLayout,
        layout_width  = "fill",
        layout_height = "wrap",
        orientation   = "vertical",
        backgroundColor = THEME.primary,
        elevation     = "4dp",
        padding       = THEME.spacing_md,
        {
            -- App title (bound to reactive state)
            TextView,
            layout_width  = "fill",
            layout_height = "wrap",
            text          = headerTitle,
            textSize      = "20sp",
            textStyle     = "bold",
            textColor     = THEME.textOnPrimary,
        },
        {
            -- Status subtitle (bound to reactive state)
            TextView,
            id            = "statusBar",
            layout_width  = "fill",
            layout_height = "wrap",
            text          = statusText,
            textSize      = "12sp",
            textColor     = "#B3FFFFFF", -- 70% white
            layout_marginTop = "4dp",
        },
    },

    -- ═════════════════════════════════════════════════
    -- SCROLLABLE CONTENT AREA
    -- ═════════════════════════════════════════════════
    {
        ScrollView,
        layout_width  = "fill",
        layout_height = "0dp",
        layout_weight = "1",
        {
            LinearLayout,
            layout_width  = "fill",
            layout_height = "wrap",
            orientation   = "vertical",
            paddingBottom = "32dp",

            -- ─────────────────────────────────────────
            -- SECTION: Search Bar
            -- ─────────────────────────────────────────
            {
                LinearLayout,
                layout_width  = "fill",
                layout_height = "wrap",
                orientation   = "horizontal",
                padding       = THEME.spacing_md,
                gravity       = "center_vertical",
                {
                    EditText,
                    id            = "searchInput",
                    layout_width  = "0dp",
                    layout_height = "44dp",
                    layout_weight = "1",
                    hint          = "Search components...",
                    hintColor     = THEME.textHint,
                    textSize      = "14sp",
                    textColor     = THEME.textPrimary,
                    singleLine    = "true",
                    inputType     = "text",
                    padding       = "12dp",
                    backgroundColor = THEME.surface,
                    cornerRadius  = THEME.radius_pill,
                    elevation     = "1dp",
                    addTextChangedListener = TextWatcher {
                        onTextChanged = function(s, start, before, count)
                            statusText:set("Typing: " .. tostring(s))
                        end,

                        beforeTextChanged = function(s, start, count, after)
                            -- Optional: logic before change
                        end,

                        afterTextChanged = function(s)
                            -- Optional: logic after change (s is Editable)
                            -- Example: simple validation
                            if #tostring(s) < 3 then
                                -- logic for short input
                            end
                        end
                    },
                },
                {
                    Button,
                    layout_width   = "44dp",
                    layout_height  = "44dp",
                    layout_marginLeft = THEME.spacing_sm,
                    text           = "🔍",
                    textSize       = "18sp",
                    backgroundColor = THEME.accent,
                    textColor      = THEME.textOnAccent,
                    cornerRadius   = THEME.radius_pill,
                    elevation      = "2dp",
                    onClickListener  = OnClickListener {
                        onClick = function(v)
                            local query = searchInput.getText().toString()
                            searchQuery:set(query)
                            statusText:set("Searching: \"" .. query .. "\"")
                        end
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Counter Demo (State + Buttons)
            -- ─────────────────────────────────────────
            sectionHeader("§17 REACTIVE STATE", "Counter with live-updating display"),

            -- Counter card
            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_lg,
                {
                    -- Large counter display
                    TextView,
                    id            = "counterDisplay",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    text          = counterValue,
                    textSize      = "48sp",
                    textStyle     = "bold",
                    textColor     = THEME.primary,
                    gravity       = "center",
                },
                {
                    TextView,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    text          = "Tap + or - to modify the counter",
                    textSize      = "12sp",
                    textColor     = THEME.textSecondary,
                    gravity       = "center",
                    layout_marginTop = "4dp",
                },
                {
                    -- Button row
                    LinearLayout,
                    layout_width   = "fill",
                    layout_height  = "wrap",
                    orientation    = "horizontal",
                    gravity        = "center",
                    layout_marginTop = THEME.spacing_md,
                    {
                        Button,
                        --layout_width   = "0dp",
                        layout_height  = "48dp",
                        --layout_weight  = "1",
                        text           = "− Decrease",
                        textColor      = THEME.error,
                        backgroundColor = "#FFEBEE",
                        cornerRadius   = THEME.radius_sm,
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                decrementCounter()
                            end
                        }
                    },
                    {
                        Button,
                        --layout_width   = "0dp",
                        layout_height  = "48dp",
                        layout_weight  = "1",
                        text           = "↺ Reset",
                        textColor      = THEME.textSecondary,
                        backgroundColor = "#F5F5F5",
                        cornerRadius   = THEME.radius_sm,
                        layout_marginLeft  = "4dp",
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                resetCounter()
                            end
                        }
                    },
                    {
                        Button,
                        --layout_width   = "0dp",
                        layout_height  = "48dp",
                        layout_weight  = "1",
                        text           = "+ Increase",
                        textColor      = THEME.textOnPrimary,
                        backgroundColor = THEME.success,
                        cornerRadius   = THEME.radius_sm,
                        layout_marginLeft = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                incrementCounter()
                            end
                        }
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Input Controls
            -- ─────────────────────────────────────────
            sectionHeader("§6 TEXT INPUT", "EditText with various inputType configurations"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_md,
                {
                    EditText,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    hint          = "Your name (capwords)",
                    inputType     = "text|capwords",
                    textSize      = "14sp",
                    padding       = "12dp",
                    layout_marginBottom = THEME.spacing_sm,
                    addTextChangedListener = TextWatcher {
                        onTextChanged = function(s, start, before, count)
                            statusText:set("Typing: " .. tostring(s))
                        end,

                        beforeTextChanged = function(s, start, count, after)
                                -- Optional: logic before change
                        end,

                        afterTextChanged = function(s)
                                -- Optional: logic after change (s is Editable)
                                -- Example: simple validation
                            if #tostring(s) < 3 then
                                -- logic for short input
                            end
                        end
                    },
                },
                {
                    EditText,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    hint          = "Email address",
                    inputType     = "email",
                    textSize      = "14sp",
                    padding       = "12dp",
                    layout_marginBottom = THEME.spacing_sm,
                    addTextChangedListener = TextWatcher {
                                            onTextChanged = function(s, start, before, count)
                                                statusText:set("Typing: " .. tostring(s))
                                            end,

                                            beforeTextChanged = function(s, start, count, after)
                                                -- Optional: logic before change
                                            end,

                                            afterTextChanged = function(s)
                                                -- Optional: logic after change (s is Editable)
                                                -- Example: simple validation
                                                if #tostring(s) < 3 then
                                                    -- logic for short input
                                                end
                                            end
                                        },
                },
                {
                    EditText,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    hint          = "Password",
                    inputType     = "password",
                    textSize      = "14sp",
                    padding       = "12dp",
                    layout_marginBottom = THEME.spacing_sm,
                    addTextChangedListener = TextWatcher {
                                            onTextChanged = function(s, start, before, count)
                                                statusText:set("Typing: " .. tostring(s))
                                            end,

                                            beforeTextChanged = function(s, start, count, after)
                                                -- Optional: logic before change
                                            end,

                                            afterTextChanged = function(s)
                                                -- Optional: logic after change (s is Editable)
                                                -- Example: simple validation
                                                if #tostring(s) < 3 then
                                                    -- logic for short input
                                                end
                                            end
                                        },
                },
                {
                    EditText,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    hint          = "Phone number",
                    inputType     = "phone",
                    textSize      = "14sp",
                    padding       = "12dp",
                    layout_marginBottom = THEME.spacing_sm,
                    addTextChangedListener = TextWatcher {
                                            onTextChanged = function(s, start, before, count)
                                                statusText:set("Typing: " .. tostring(s))
                                            end,

                                            beforeTextChanged = function(s, start, count, after)
                                                -- Optional: logic before change
                                            end,

                                            afterTextChanged = function(s)
                                                -- Optional: logic after change (s is Editable)
                                                -- Example: simple validation
                                                if #tostring(s) < 3 then
                                                    -- logic for short input
                                                end
                                            end
                                        },
                },
                {
                    EditText,
                    id            = "multilineInput",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    hint          = "Write a multiline note...",
                    inputType     = "multiline|capsentences",
                    textSize      = "14sp",
                    padding       = "12dp",
                    minLines      = "3",
                    maxLines      = "6",
                    gravity       = "top",
                    addTextChangedListener = TextWatcher {
                                            onTextChanged = function(s, start, before, count)
                                                statusText:set("Typing: " .. tostring(s))
                                            end,

                                            beforeTextChanged = function(s, start, count, after)
                                                -- Optional: logic before change
                                            end,

                                            afterTextChanged = function(s)
                                                -- Optional: logic after change (s is Editable)
                                                -- Example: simple validation
                                                if #tostring(s) < 3 then
                                                    -- logic for short input
                                                end
                                            end
                                        },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Toggles & Selections
            -- ─────────────────────────────────────────
            sectionHeader("§12 TOGGLES & SELECTIONS", "CheckBox, Switch, RadioGroup"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_md,

                -- CheckBox
                {
                    CheckBox,
                    id            = "termsCheckbox",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    text          = "I accept the Terms of Service",
                    textSize      = "14sp",
                    textColor     = THEME.textPrimary,
                    checked       = "false",
                    padding       = "4dp",
                },

                -- Switch with reactive label
                {
                    LinearLayout,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    orientation   = "horizontal",
                    gravity       = "center_vertical",
                    padding       = "4dp",
                    {
                        TextView,
                        layout_width  = "0dp",
                        layout_height = "wrap",
                        layout_weight = "1",
                        text          = toggleLabel,
                        textSize      = "14sp",
                        textColor     = THEME.textPrimary,
                    },
                    {
                        Switch,
                        id            = "notifSwitch",
                        layout_width  = "wrap",
                        layout_height = "wrap",
                        checked       = "true",
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                toggleNotifications()
                            end
                        }
                    },
                },

                -- Divider
                {
                    View,
                    layout_width  = "fill",
                    layout_height = "1dp",
                    backgroundColor = THEME.divider,
                    layout_marginTop    = THEME.spacing_sm,
                    layout_marginBottom = THEME.spacing_sm,
                },

                -- RadioGroup
                {
                    TextView,
                    layout_width  = "wrap",
                    layout_height = "wrap",
                    text          = "Select your role:",
                    textSize      = "13sp",
                    textColor     = THEME.textSecondary,
                    layout_marginBottom = "4dp",
                },
                {
                    RadioGroup,
                    id            = "roleGroup",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    orientation   = "vertical",
                    {
                        RadioButton,
                        id            = "roleUser",
                        layout_width  = "fill",
                        layout_height = "wrap",
                        text          = "User",
                        textSize      = "14sp",
                        checked       = "true", -- always checked.
                    },
                    {
                        RadioButton,
                        id            = "roleDev",
                        layout_width  = "fill",
                        layout_height = "wrap",
                        text          = "Developer",
                        textSize      = "14sp",
                    },
                    {
                        RadioButton,
                        id            = "roleAdmin",
                        layout_width  = "fill",
                        layout_height = "wrap",
                        text          = "Administrator",
                        textSize      = "14sp",
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Progress & SeekBar
            -- ─────────────────────────────────────────
            sectionHeader("§13 PROGRESS & SEEKBAR", "ProgressBar (determinate & indeterminate) + SeekBar"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_md,

                -- Indeterminate spinner
                {
                    LinearLayout,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    orientation   = "horizontal",
                    gravity       = "center_vertical",
                    layout_marginBottom = THEME.spacing_md,
                    {
                        ProgressBar,
                        layout_width  = "32dp",
                        layout_height = "32dp",
                    },
                    {
                        TextView,
                        layout_width  = "wrap",
                        layout_height = "wrap",
                        text          = "Loading something awesome...",
                        textSize      = "13sp",
                        textColor     = THEME.textSecondary,
                        layout_marginLeft = "12dp",
                    },
                },

                -- Determinate progress bar
                {
                    ProgressBar,
                    id            = "fileProgress",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    max           = "100",
                    progress      = "65",
                    layout_marginBottom = THEME.spacing_sm,
                    afterLoad = function(view)
                        -- Force horizontal style
                        view.setIndeterminate(false)
                    end,
                },

                -- SeekBar with reactive label
                {
                    TextView,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    text          = sliderLabel,
                    textSize      = "13sp",
                    textColor     = THEME.textSecondary,
                    layout_marginBottom = "4dp",
                },
                {
                    SeekBar,
                    id            = "brightnessSeek",
                    layout_width  = "fill",
                    layout_height = "wrap",
                    max           = "100",
                    progress      = "50",
                    afterLoad = function(view)
                        import "android.widget.SeekBar$OnSeekBarChangeListener"
                        view.setOnSeekBarChangeListener(OnSeekBarChangeListener({
                            onProgressChanged = function(sb, progress, fromUser)
                                if fromUser then
                                    sliderLabel:set("Brightness: " .. progress .. "%")
                                    progressValue:set(tostring(progress))
                                end
                            end,
                            onStartTrackingTouch = function(sb) end,
                            onStopTrackingTouch = function(sb)
                                statusText:set("Brightness set to " .. progressValue:get() .. "%")
                            end,
                        }))
                    end,
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: RecyclerView
            -- ─────────────────────────────────────────
            sectionHeader("§11 RECYCLERVIEW & LISTVIEW", "Template-based efficient scrolling list"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",

                -- Item count label
                {
                    LinearLayout,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    orientation   = "horizontal",
                    gravity       = "center_vertical",
                    padding       = THEME.spacing_md,
                    {
                        TextView,
                        layout_width  = "0dp",
                        layout_height = "wrap",
                        layout_weight = "1",
                        text          = itemCount,
                        textSize      = "13sp",
                        textColor     = THEME.textSecondary,
                    },
                    {
                        Button,
                        layout_width  = "wrap",
                        layout_height = "36dp",
                        text          = "+ Add Item",
                        textSize      = "12sp",
                        textColor     = THEME.primary,
                        backgroundColor = THEME.primaryLight,
                        cornerRadius  = THEME.radius_sm,
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                local n = #showcaseItems + 1
                                showcaseItems[n] = {
                                    title = "Dynamic Item " .. n,
                                    desc  = "Added at runtime via updateItems",
                                    icon  = "✨",
                                    color = "#E8EAF6",
                                }
                                recyclerList:updateItems(showcaseItems)
                                itemCount:set(n .. " items loaded")
                                statusText:set("Added item #" .. n)
                            end
                        }
                    },
                },

                -- The RecyclerView
                {
                    RecyclerView,
                    id            = "recyclerList",
                    layout_width  = "fill",
                    layout_height = "300dp",

                    template = {
                        LinearLayout,
                        layout_width  = "fill",
                        layout_height = "wrap",
                        orientation   = "horizontal",
                        gravity       = "center_vertical",
                        padding       = "12dp",
                        layout_marginBottom = "1dp",
                        {
                            -- Icon circle
                            TextView,
                            id            = "icon",
                            layout_width  = "40dp",
                            layout_height = "40dp",
                            gravity       = "center",
                            textSize      = "20sp",
                            cornerRadius  = "20dp",
                        },
                        {
                            -- Text column
                            LinearLayout,
                            layout_width  = "0dp",
                            layout_height = "wrap",
                            layout_weight = "1",
                            orientation   = "vertical",
                            layout_marginLeft = "12dp",
                            {
                                TextView,
                                id         = "title",
                                layout_width  = "wrap",
                                layout_height = "wrap",
                                textSize   = "15sp",
                                textStyle  = "bold",
                                textColor  = THEME.textPrimary,
                            },
                            {
                                TextView,
                                id         = "desc",
                                layout_width  = "wrap",
                                layout_height = "wrap",
                                textSize   = "12sp",
                                textColor  = THEME.textSecondary,
                                layout_marginTop = "2dp",
                            },
                        },
                        {
                            -- Chevron
                            TextView,
                            layout_width  = "wrap",
                            layout_height = "wrap",
                            text          = "›",
                            textSize      = "24sp",
                            textColor     = THEME.textHint,
                        },
                    },

                    items = showcaseItems,

                    onBind = function(view, item, position)
                        local r, er = pcall(function()
                            view:findView("icon").setText(item.icon)
                            view:findView("icon").setBackgroundColor(Color.parseColor(item.color))
                            view:findView("title").setText(item.title)
                            view:findView("desc").setText(item.desc)
                        end)
                        if not r and er then logcat.error(tostring(er)) end
                    end,
                },
                {
                    ListView,
                    layout_width  = "fill",
                    layout_height = "300dp",
                    padding = "16dp",
                    count = 100,
                    onCreate = function()
                        return loadlayout({
                            TextView,
                            id = "txtID"
                        })
                    end,
                    onBind = function(pos, row, count)
                        textV = row:findView("txtID")
                        textV.setText("Row #" .. pos)
                    end,
                    afterLoad = function(v)
                        v.setNestedScrollingEnabled(true);
                    end
                }
            },

            -- ─────────────────────────────────────────
            -- SECTION: FrameLayout (Overlapping Layers)
            -- ─────────────────────────────────────────
            sectionHeader("§21 FRAMELAYOUT", "Overlapping views with layout_gravity"),

            {
                FrameLayout,
                layout_width    = "fill",
                layout_height   = "160dp",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = "#263238",
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                {
                    -- Background gradient placeholder
                    View,
                    layout_width  = "fill",
                    layout_height = "fill",
                    backgroundColor = "#1B5E20",
                    alpha         = "0.3",
                },
                {
                    -- Centered overlay text
                    TextView,
                    layout_width   = "wrap",
                    layout_height  = "wrap",
                    layout_gravity = "center",
                    text           = "HERO BANNER",
                    textSize       = "24sp",
                    textStyle      = "bold",
                    textColor      = "#FFFFFF",
                    letterSpacing  = "0.15",
                },
                {
                    -- Bottom-right badge
                    TextView,
                    layout_width   = "wrap",
                    layout_height  = "wrap",
                    layout_gravity = "bottom|right",
                    text           = " LIVE ",
                    textSize       = "11sp",
                    textStyle      = "bold",
                    textColor      = "#FFFFFF",
                    backgroundColor = THEME.error,
                    cornerRadius   = THEME.radius_sm,
                    padding        = "6dp",
                    layout_margin  = "12dp",
                },
                {
                    -- Top-left label
                    TextView,
                    layout_width   = "wrap",
                    layout_height  = "wrap",
                    layout_gravity = "top|left",
                    text           = "Featured",
                    textSize       = "11sp",
                    textColor      = "#B2FFFFFF",
                    layout_margin  = "12dp",
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Animations Demo
            -- ─────────────────────────────────────────
            sectionHeader("§22 ANIMATIONS", "ViewPropertyAnimator via :animate()"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_md,
                gravity         = "center",
                {
                    -- The animated box
                    TextView,
                    id             = "animBox",
                    layout_width   = "80dp",
                    layout_height  = "80dp",
                    gravity        = "center",
                    text           = "🎯",
                    textSize       = "32sp",
                    backgroundColor = THEME.primaryLight,
                    cornerRadius   = THEME.radius_lg,
                    elevation      = "4dp",
                },
                {
                    -- Animation control buttons
                    LinearLayout,
                    layout_width   = "fill",
                    layout_height  = "wrap",
                    orientation    = "horizontal",
                    gravity        = "center",
                    layout_marginTop = THEME.spacing_md,
                    {
                        Button,
                        layout_width   = "wrap",
                        layout_height  = "40dp",
                        text           = "Pulse",
                        textSize       = "12sp",
                        textColor      = THEME.primary,
                        backgroundColor = THEME.primaryLight,
                        cornerRadius   = THEME.radius_sm,
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function(v)
                                animBox:animate({
                                    scaleX   = 1.3,
                                    scaleY   = 1.3,
                                    duration = 200,
                                    onEnd = function()
                                        animBox:animate({
                                            scaleX   = 1.0,
                                            scaleY   = 1.0,
                                            duration = 200,
                                        })
                                    end,
                                })
                                statusText:set("Animation: Pulse")
                            end
                        }
                    },
                    {
                        Button,
                        layout_width   = "wrap",
                        layout_height  = "40dp",
                        text           = "Spin",
                        textSize       = "12sp",
                        textColor      = THEME.accent,
                        backgroundColor = "#FFF3E0",
                        cornerRadius   = THEME.radius_sm,
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function()
                                animBox:animate({
                                    rotation = 360,
                                    duration = 600,
                                    onEnd = function()
                                        animBox:animate({ rotation = 0, duration = 0 })
                                    end,
                                })
                                statusText:set("Animation: Spin 360°")
                            end
                        }
                    },
                    {
                        Button,
                        layout_width   = "wrap",
                        layout_height  = "40dp",
                        text           = "Fade",
                        textSize       = "12sp",
                        textColor      = THEME.success,
                        backgroundColor = "#E8F5E9",
                        cornerRadius   = THEME.radius_sm,
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function()
                                animBox:animate({
                                    alpha    = 0.0,
                                    duration = 400,
                                    onEnd = function()
                                        animBox:animate({
                                            alpha    = 1.0,
                                            duration = 400,
                                        })
                                    end,
                                })
                                statusText:set("Animation: Fade out & in")
                            end
                        }
                    },
                    {
                        Button,
                        layout_width   = "wrap",
                        layout_height  = "40dp",
                        text           = "Slide",
                        textSize       = "12sp",
                        textColor      = THEME.error,
                        backgroundColor = "#FFEBEE",
                        cornerRadius   = THEME.radius_sm,
                        onClickListener  = OnClickListener {
                            onClick = function()
                                animBox:animate({
                                    translationX = 100,
                                    duration     = 300,
                                    onEnd = function()
                                        animBox:animate({
                                            translationX = 0,
                                            duration     = 300,
                                        })
                                    end,
                                })
                                statusText:set("Animation: Slide right & back")
                            end
                        }
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Navigation Demo
            -- ─────────────────────────────────────────
            sectionHeader("§23 NAVIGATION", "Stack-based screen transitions"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_md,
                {
                    TextView,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    text          = "Navigator pushes new screens onto a stack. Each push/pop can use slide, fade, zoom, or no transition.",
                    textSize      = "13sp",
                    textColor     = THEME.textSecondary,
                    lineSpacing   = "4",
                    layout_marginBottom = THEME.spacing_md,
                },
                {
                    LinearLayout,
                    layout_width  = "fill",
                    layout_height = "wrap",
                    orientation   = "horizontal",
                    gravity       = "center",
                    {
                        Button,
                        layout_width   = "10dp",
                        layout_height  = "48dp",
                        layout_weight  = "1",
                        text           = "Push (Slide)",
                        textSize       = "12sp",
                        textColor      = THEME.textOnPrimary,
                        backgroundColor = THEME.primary,
                        cornerRadius   = THEME.radius_sm,
                        layout_marginRight = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function()
                                local detailScreen = loadlayout({
                                    LinearLayout,
                                    layout_width  = "fill",
                                    layout_height = "fill",
                                    orientation   = "vertical",
                                    backgroundColor = THEME.background,
                                    gravity       = "center",
                                    {
                                        TextView,
                                        layout_width  = "wrap",
                                        layout_height = "wrap",
                                        text          = "📄 Detail Screen",
                                        textSize      = "24sp",
                                        textStyle     = "bold",
                                        textColor     = THEME.textPrimary,
                                    },
                                    {
                                        TextView,
                                        layout_width  = "wrap",
                                        layout_height = "wrap",
                                        text          = "Pushed via navigator.push() with slide transition",
                                        textSize      = "14sp",
                                        textColor     = THEME.textSecondary,
                                        layout_marginTop = "8dp",
                                        gravity       = "center",
                                    },
                                    {
                                        Button,
                                        layout_width   = "wrap",
                                        layout_height  = "48dp",
                                        text           = "← Go Back",
                                        textSize       = "14sp",
                                        textColor      = THEME.textOnPrimary,
                                        backgroundColor = THEME.primary,
                                        cornerRadius   = THEME.radius_sm,
                                        layout_marginTop = "24dp",
                                        padding        = "16dp",
                                        onClickListener  = OnClickListener {
                                            onClick = function()
                                                navigator.pop({ type = "slide", duration = 300 })
                                            end
                                        }
                                    },
                                })
                                navigator.push(detailScreen, { type = "slide", duration = 300 })
                                statusText:set("Navigated → Detail Screen")
                            end
                        }
                    },
                    {
                        Button,
                        layout_width   = "0dp",
                        layout_height  = "48dp",
                        layout_weight  = "1",
                        text           = "Push (Zoom)",
                        textSize       = "12sp",
                        textColor      = THEME.textOnAccent,
                        backgroundColor = THEME.accent,
                        cornerRadius   = THEME.radius_sm,
                        layout_marginLeft = "4dp",
                        onClickListener  = OnClickListener {
                            onClick = function()
                                local zoomScreen = loadlayout({
                                    FrameLayout,
                                    layout_width  = "fill",
                                    layout_height = "fill",
                                    backgroundColor = "#1A237E",
                                    {
                                        LinearLayout,
                                        layout_width   = "wrap",
                                        layout_height  = "wrap",
                                        layout_gravity = "center",
                                        orientation    = "vertical",
                                        gravity        = "center",
                                        {
                                            TextView,
                                            layout_width  = "wrap",
                                            layout_height = "wrap",
                                            text          = "🚀",
                                            textSize      = "64sp",
                                        },
                                        {
                                            TextView,
                                            layout_width  = "wrap",
                                            layout_height = "wrap",
                                            text          = "Zoomed Screen",
                                            textSize      = "20sp",
                                            textStyle     = "bold",
                                            textColor     = "#FFFFFF",
                                            layout_marginTop = "16dp",
                                        },
                                        {
                                            Button,
                                            layout_width   = "wrap",
                                            layout_height  = "48dp",
                                            text           = "← Pop with Fade",
                                            textColor      = "#1A237E",
                                            backgroundColor = "#FFFFFF",
                                            cornerRadius   = THEME.radius_sm,
                                            layout_marginTop = "24dp",
                                            padding        = "16dp",
                                            onClickListener  = OnClickListener {
                                                onClick = function()
                                                    navigator.pop({ type = "fade", duration = 400 })
                                                end
                                            }
                                        },
                                },
                            })
                            navigator.push(zoomScreen, { type = "zoom", duration = 500 })
                            statusText:set("Navigated → Zoom Screen")
                        end
                        }
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: View Info Dashboard
            -- ─────────────────────────────────────────
            sectionHeader("§18 VIEW IDS & ACCESS", "Views registered as Lua globals after loadlayout"),

            {
                LinearLayout,
                layout_width    = "fill",
                layout_height   = "wrap",
                layout_marginLeft  = THEME.spacing_md,
                layout_marginRight = THEME.spacing_md,
                backgroundColor = THEME.card,
                cornerRadius    = THEME.radius_md,
                elevation       = "2dp",
                orientation     = "vertical",
                padding         = THEME.spacing_sm,
                infoRow("Counter Value", counterValue),
                infoRow("Progress",      progressValue),
                infoRow("Search Query",  searchQuery),
                infoRow("Notifications", toggleLabel),
                infoRow("Brightness",    sliderLabel),
                infoRow("Item Count",    itemCount),
            },

            -- ─────────────────────────────────────────
            -- SECTION: Horizontal Scroll Showcase
            -- ─────────────────────────────────────────
            sectionHeader("§9 HORIZONTAL SCROLL", "HorizontalScrollView with colored cards"),

            {
                HorizontalScrollView,
                layout_width  = "fill",
                layout_height = "wrap",
                {
                    LinearLayout,
                    layout_width  = "wrap",
                    layout_height = "wrap",
                    orientation   = "horizontal",
                    padding       = THEME.spacing_md,
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = THEME.primary,
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 1",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        layout_marginRight = THEME.spacing_sm,
                        elevation      = "2dp",
                    },
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = THEME.accent,
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 2",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        layout_marginRight = THEME.spacing_sm,
                        elevation      = "2dp",
                    },
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = THEME.success,
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 3",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        layout_marginRight = THEME.spacing_sm,
                        elevation      = "2dp",
                    },
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = THEME.error,
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 4",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        layout_marginRight = THEME.spacing_sm,
                        elevation      = "2dp",
                    },
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = "#9C27B0",
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 5",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        layout_marginRight = THEME.spacing_sm,
                        elevation      = "2dp",
                    },
                    {
                        TextView,
                        layout_width   = "120dp",
                        layout_height  = "80dp",
                        backgroundColor = "#009688",
                        cornerRadius   = THEME.radius_md,
                        text           = "Card 6",
                        textColor      = "#FFFFFF",
                        textSize       = "14sp",
                        textStyle      = "bold",
                        gravity        = "center",
                        elevation      = "2dp",
                    },
                },
            },

            -- ─────────────────────────────────────────
            -- SECTION: Footer
            -- ─────────────────────────────────────────
            {
                LinearLayout,
                layout_width  = "fill",
                layout_height = "wrap",
                orientation   = "vertical",
                gravity       = "center",
                padding       = THEME.spacing_xl,
                layout_marginTop = THEME.spacing_md,
                {
                    View,
                    layout_width  = "40%w",
                    layout_height = "1dp",
                    backgroundColor = THEME.divider,
                    layout_marginBottom = THEME.spacing_md,
                },
                {
                    TextView,
                    layout_width  = "wrap",
                    layout_height = "wrap",
                    text          = "Built with Hydra Layout Engine",
                    textSize      = "12sp",
                    textColor     = THEME.textHint,
                },
                {
                    TextView,
                    layout_width  = "wrap",
                    layout_height = "wrap",
                    text          = "HydraCLuaCore v1.0.0 • Lua 5.5 • JNI/C++20",
                    textSize      = "11sp",
                    textColor     = THEME.textHint,
                    layout_marginTop = "4dp",
                },
                {
                    TextView,
                    layout_width  = "wrap",
                    layout_height = "wrap",
                    text          = "© 2026 @tenarx0 — All rights reserved",
                    textSize      = "11sp",
                    textColor     = THEME.textHint,
                    layout_marginTop = "2dp",
                },
            },
        },
    },
}


-- ═════════════════════════════════════════════════════════════════════════════
-- LAUNCH
-- ═════════════════════════════════════════════════════════════════════════════

-- Initialize the screen navigator
navigator.init(this)

-- Inflate the entire layout tree and push as the initial screen
local rootView = loadlayout(mainLayout)
navigator.push(rootView)

-- Update status after everything is loaded
statusText:set("Ready • " .. #showcaseItems .. " components loaded")

function onHydraError(err) logcat.error(err) end

--[[
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║   END OF REFERENCE SCRIPT                                                        ║
║                                                                                  ║
║   This script documents every feature of the Hydra loadlayout() system:          ║
║                                                                                  ║
║   ✓ Layout table structure & syntax                                              ║
║   ✓ All dimension formats (dp, sp, %w, %h, %wp, %hp)                             ║
║   ✓ Color formats (#RGB, #RRGGBB, #AARRGGBB, 0x)                                 ║
║   ✓ Reactive state bindings (state/get/set)                                      ║
║   ✓ View IDs & programmatic access                                               ║
║   ✓ Event handlers (afterLoad, interface proxies)                                ║
║   ✓ RecyclerView (template + items + onBind)                                     ║
║   ✓ ListView (count + onCreate + onBind)                                         ║
║   ✓ All standard widgets (TextView, EditText, Button, ImageView,                 ║
║     CheckBox, Switch, RadioGroup, SeekBar, ProgressBar, Spinner,                 ║
║     ScrollView, HorizontalScrollView, FrameLayout, WebView, CardView)            ║
║   ✓ Animations (:animate with all properties)                                    ║
║   ✓ Navigation (navigator.push/pop with transitions)                             ║
║   ✓ Pre-inflated views                                                           ║
║   ✓ Nested layout hierarchies                                                    ║
║   ✓ Performance best practices                                                   ║
║                                                                                  ║
║   For questions: github.com/tenarx0                                              ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
--]]