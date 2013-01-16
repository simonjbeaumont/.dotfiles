-- stuff
import XMonad
import XMonad.Config.Gnome
import qualified XMonad.StackSet as W
import System.IO (Handle, hPutStrLn)

-- utils
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.WorkspaceCompare
import XMonad.Util.EZConfig

-- hooks
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.UrgencyHook

-- layouts
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import XMonad.Layout.IM
import XMonad.Layout.Grid
import XMonad.Layout.PerWorkspace
import XMonad.Layout.SimpleFloat

-- actions
import XMonad.Actions.CycleWS

-------------------------------------------------------------------------------
-- Main --
main = do
       h1 <- spawnPipe "xmobar -x 0 ~/.xmonad/.xmobarrc"
       h2 <- spawnPipe "xmobar -x 1 ~/.xmonad/.xmobarrc"
       xmonad $ withUrgencyHook NoUrgencyHook $ gnomeConfig
              { workspaces = workspaces'
              , modMask = modMask'
              , borderWidth = borderWidth'
              , normalBorderColor = normalBorderColor'
              , focusedBorderColor = focusedBorderColor'
              , terminal = terminal'
              , logHook = logHook' h1 h2 
              , layoutHook = layoutHook'
              , manageHook = manageHook'
              } `additionalKeys`
              [-- windows and session
                ((modMask',               xK_q),     kill)
              , ((modMask',               xK_r),     spawn "xmonad --recompile; xmonad --restart")
              , ((modMask' .|. shiftMask, xK_q),     spawn "gnome-session-quit")
              , ((modMask' .|. shiftMask, xK_l),     sendMessage MirrorShrink)
              , ((modMask' .|. shiftMask, xK_h),     sendMessage MirrorExpand)
              -- workspaces (imagine vertical stack with horizontal screens)
              , ((modMask',               xK_Down),  nextWS)
              , ((modMask',               xK_Up),    prevWS)
              , ((modMask' .|. shiftMask, xK_Down),  shiftToNext >> nextWS)
              , ((modMask' .|. shiftMask, xK_Up),    shiftToPrev >> prevWS)
              , ((modMask',               xK_grave), toggleWS)
              , ((modMask',               xK_f),     moveTo Next EmptyWS)
              -- screens
              , ((modMask',               xK_Right), nextScreen)
              , ((modMask',               xK_Left),  prevScreen)
              , ((modMask' .|. shiftMask, xK_Right), shiftNextScreen)
              , ((modMask' .|. shiftMask, xK_Left),  shiftPrevScreen)
              -- launching
              , ((modMask' .|. shiftMask, xK_b), spawn "google-chrome")
              , ((modMask' .|. shiftMask, xK_s), spawn "/home/simonbe/spotify-notify/spotify-notify.py -n")
              , ((modMask' .|. shiftMask, xK_p), spawn "gnome-do")
              , ((modMask',               xK_p), spawn "gmrun")
              ]

-------------------------------------------------------------------------------
-- Hooks --
manageHook' :: ManageHook
myManageHook = manageHook gnomeConfig <+> (composeOne . concat $
    [ [className    =? r    -?> doIgnore                |   r   <- myIgnores        ] -- ignore desktop
    , [className    =? c    -?> doShift  " 4-xen "      |   c   <- ["XenCenter"]    ] -- move to WS
    , [className    =? c    -?> doShift  " 5-xenrt "    |   c   <- ["XenRTCenter"]  ] -- move to WS
    , [className    =? c    -?> doShift  " 6-chat "     |   c   <- myChat       ] -- move to WS
    , [className    =? c    -?> doShift  " 7-music "    |   c   <- myMusic      ] -- move to WS
    , [className    =? c    -?> doCenterFloat           |   c   <- myFloats     ] -- float my floats
    , [name         =? n    -?> doCenterFloat           |   n   <- myNames      ] -- float my names
    , [name         =? n    -?> doCenterFloat           |   n   <- myXenApps    ] -- float my names
    , [isFullscreen         -?> myDoFullFloat                                   ]
    , [isDialog             -?> doCenterFloat                                   ] -- float dialogs
    , [return True          -?> doF W.swapDown                                  ] -- open below, not above
    ]) 
    where
        role      = stringProperty "WM_WINDOW_ROLE"
        name      = stringProperty "WM_NAME"
        -- classnames
        myFloats  = ["Smplayer","MPlayer","VirtualBox","Xmessage","XFontSel","Downloads","Nm-connection-editor"]
        myWebs    = ["Firefox","Google-chrome","Chromium", "Chromium-browser"]
        myMovie   = ["Boxee","Trine"]
        myMusic   = ["Rhythmbox","Spotify"]
        myChat    = ["Pidgin","Buddy List"]
        myGimp    = ["Gimp"]
        myDev     = ["gnome-terminal"]
        myVim     = ["Gvim"]
        -- resources
        myIgnores = ["desktop","desktop_window","Do", "notify-osd","stalonetray","trayer", "panel"]
        myXenApps = ["Wfica_Seamless"]
        -- names
        myNames   = ["bashrun","Google Chrome Options","Chromium Options","Cinnamon Settings"]
-- a trick for fullscreen but stil allow focusing of other WSs
myDoFullFloat :: ManageHook
myDoFullFloat = doF W.focusDown <+> doFullFloat
manageHook' = myManageHook <+> manageDocks

logHook' h1 h2 = dynamicLogWithPP customPP { ppOutput = hPutStrLn h1 }
              >> dynamicLogWithPP customPP { ppOutput = hPutStrLn h2 }

layoutHook' =   onWorkspace " 6-chat " imLayout $
                onWorkspace " 3-web " rokLayout $
                customLayout

-------------------------------------------------------------------------------
-- Looks --
-- bar
customPP :: PP
customPP = defaultPP { ppCurrent = xmobarColor "#1b8ac2" "" . wrap "·" "·"
                     , ppVisible = wrap "·" "·"
                     , ppTitle =  shorten 80
                     , ppSep =  "<fc=#AFAF87>       </fc>"
                     , ppWsSep = "    "
                     , ppHiddenNoWindows = xmobarColor "#777777" ""
                     , ppUrgent = xmobarColor "#FFFFAF" "" . wrap "*" "*" . xmobarStrip
                     , ppSort = getSortByXineramaRule
                     , ppLayout = (\x -> case x of
                            "Spacing 15 ResizableTall"        -> "· T ·"
                            "Mirror Spacing 15 ResizableTall" -> "· M ·"
                            "Full"                            -> "· X ·"
                            "Spacing 15 IM Grid"              -> "· G ·"
                            "IM Spacing 15 ResizableTall"     -> "· R ·"
                            _                                 ->  x)
                     }


-- borders
borderWidth' :: Dimension
borderWidth' = 3

normalBorderColor', focusedBorderColor' :: String
normalBorderColor'  = "#333333"
focusedBorderColor' = "#0775a8"

-- workspaces
workspaces' :: [WorkspaceId]
workspaces' = [" 1-mail ", " 2-work ", " 3-web ", " 4-xen ", " 5-xenrt ", " 6-chat ", " 7-music ", " 8 ", " 9 "]

-- layouts
customLayout = avoidStruts $ smartBorders tiled ||| smartBorders (Mirror tiled)  ||| noBorders Full
  where
    tiled = spacing 15 $ ResizableTall nmaster delta ratio []
    -- Default number of windows in master pane
    nmaster = 1
    -- Percent of the screen to increment when resizing
    delta   = 2/100
    -- Default proportion of the screen taken up by main pane
    -- ratio   = toRational (2/(1 + sqrt 5 :: Double)) 
    ratio = 5/8

imLayout    = avoidStruts $ spacing 15 $ withIM (1/5) (Or (And (ClassName "Pidgin") (Role "buddy_list")) (ClassName "Office Communicator")) (Mirror Grid)
rokLayout   = avoidStruts $ withIM (1/15) (ClassName "rokclock-Main") customLayout

-------------------------------------------------------------------------------
-- Terminal --
terminal' :: String
terminal' = "gnome-terminal"

-------------------------------------------------------------------------------
-- Keys/Button bindings --
-- modmask
modMask' :: KeyMask
modMask' = mod1Mask
