-- stuff
import XMonad
import XMonad.Config.Gnome
import qualified XMonad.StackSet as W
import System.IO (Handle, hPutStrLn)
import Data.List
import Data.Map as Map

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
import XMonad.Layout.Renamed
import XMonad.Layout.Tabbed
import XMonad.Layout.Reflect

-- actions
import XMonad.Actions.CycleWS

-------------------------------------------------------------------------------
-- Main --
main = do
       h1 <- spawnPipe "xmobar -x 0 ~/.xmonad/xmobarrc"
       h2 <- spawnPipe "xmobar -x 1 ~/.xmonad/xmobarrc"
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
              , ((modMask' .|. shiftMask, xK_b),  spawn "google-chrome")
              , ((modMask' .|. shiftMask, xK_s),  spawn "/home/simonbe/spotify-notify/spotify-notify.py -n")
              , ((modMask' .|. shiftMask, xK_F5), spawn "/opt/Citrix/ICAClient/wfica /local/config/XenApp-Outlook-simonbe.ica")
              , ((modMask' .|. shiftMask, xK_F6), spawn "/opt/Citrix/ICAClient/wfica /local/config/XenApp-Communicator-simonbe.ica")
              , ((modMask' .|. shiftMask, xK_p),  spawn "gmrun")
              , ((modMask',               xK_p),  spawn "gnome-do")
              ]

-------------------------------------------------------------------------------
-- Hooks --
manageHook' :: ManageHook
manageHook' = manageHook gnomeConfig <+> manageDocks <+> (composeOne . concat $
    [ [className =? c -?> doCenterFloat | c <- myFloats ] -- float my floats
    -- XenApp stuff
    , [fmap (isInfixOf a) appName                       -?> doFloat     | a <- myXenApps ] -- float my XenApps
    , [className =? "Wfica_Seamless" <&&> appName =? "" -?> doF W.focusDown <+> doIgnore ]
    , [className =? "Wfica_Seamless"                    -?> doCenterFloat                ]
    -- shift certain apps to certain workspaces
    , [fmap (isInfixOf a) appName   -?> doShift  " 6-chat "  |   a <- myChat     ] -- move to WS
    , [className    =? c            -?> doShift  " 7-music " |   c <- myMusic    ] -- move to WS
    -- catch all...
    , [className    =? c            -?> doIgnore       |   c <- myIgnores  ] -- ignore desktop
    , [isFullscreen                 -?> myDoFullFloat                      ] -- special full screen
    , [isDialog                     -?> doCenterFloat                      ] -- float dialogs
    , [return True                  -?> doF W.swapDown                     ] -- open below, not above
    ]) 
    where
        -- by className
        myIgnores = ["Do", "Notification-daemon", "notify-osd", "stalonetray", "trayer"]
        myFloats  = ["VirtualBox", "Xmessage", "XFontSel", "Nm-connection-editor", "Cinnamon-settings.py"]
        myMusic   = ["Spotify"]
        -- by appName (special treatment for _top-level_ windows of XenApps (Wfica_Seamless : className)
        myXenApps = ["Microsoft Outlook", "XenCenter", "XenRTCenter", "- Message", " Reminder", "Office Communicator"]
        myChat    = ["Pidgin", "Office Communicator", "- Conversation"]
        -- a trick for fullscreen but stil allow focusing of other WSs
        myDoFullFloat = doF W.focusDown <+> doFullFloat

logHook' h1 h2 = dynamicLogWithPP customPP { ppOutput = hPutStrLn h1 }
              >> dynamicLogWithPP customPP { ppOutput = hPutStrLn h2 }

layoutHook' =   onWorkspace "6-chat" imLayout $
                onWorkspace "3-web" rokLayout $
                customLayout

-------------------------------------------------------------------------------
-- Looks --
-- solarized colors
solarized :: Map String String
solarized = Map.fromList [
    ("base03",   "#002b36"),
    ("base02",   "#073642"),
    ("base01",   "#586e75"),
    ("base00",   "#657b83"),
    ("base0",    "#839496"),
    ("base1",    "#93a1a1"),
    ("base2",    "#eee8d5"),
    ("base3",    "#fdf6e3"),
    ("yellow",   "#b58900"),
    ("orange",   "#cb4b16"),
    ("red",      "#dc322f"),
    ("magenta",  "#d33682"),
    ("violet",   "#6c71c4"),
    ("blue",     "#268bd2"),
    ("cyan",     "#2aa198"),
    ("green",    "#859900")]

-- bar
customPP :: PP
customPP = defaultPP { ppCurrent = xmobarColor (Map.findWithDefault "" "orange" solarized) "" . wrap "—" "—"
                     , ppVisible = wrap "—" "—"
                     , ppTitle =  shorten 80
                     , ppSep =  "  ——  "
                     , ppWsSep = "  "
                     , ppHiddenNoWindows = xmobarColor (Map.findWithDefault "" "base01" solarized) ""
                     , ppUrgent = xmobarColor (Map.findWithDefault "" "yellow" solarized) "" . wrap "*" "*" . xmobarStrip
                     , ppSort = getSortByXineramaRule
                     }

-- borders
borderWidth' :: Dimension
borderWidth' = 2

normalBorderColor', focusedBorderColor' :: String
normalBorderColor'  =  Map.findWithDefault "" "base01" solarized
focusedBorderColor' =  Map.findWithDefault "" "orange" solarized

-- workspaces
workspaces' :: [WorkspaceId]
workspaces' = ["1-mail", "2-work", "3-web", "4-xen", "5-xenrt", "6-chat", "7-music", "8" , "9"]

-- layouts
customLayout = avoidStruts $ tiled ||| mtiled ||| tab ||| full
  where
    nmaster  = 1     -- Default number of windows in master pane
    delta    = 2/100 -- Percentage of the screen to increment when resizing
    ratio    = 5/8   -- Defaul proportion of the screen taken up by main pane
    rt       = spacing 5 $ ResizableTall nmaster delta ratio []
    tiled    = renamed [Replace "(T)"] $ smartBorders rt
    mtiled   = renamed [Replace "(M)"] $ smartBorders $ Mirror rt
    tab      = renamed [Replace "(*)"] $ noBorders $ tabbed shrinkText tabTheme
    full     = renamed [Replace "(X)"] $ noBorders Full
    tabTheme = defaultTheme { decoHeight = 16
                            , activeColor = Map.findWithDefault "" "base01" solarized
                            , activeBorderColor = Map.findWithDefault "" "base00" solarized
                            , activeTextColor = Map.findWithDefault "" "base2" solarized
                            , inactiveColor = Map.findWithDefault "" "base02" solarized
                            , inactiveBorderColor = Map.findWithDefault "" "base03" solarized
                            , inactiveTextColor = Map.findWithDefault "" "base1" solarized
                            }
imLayout    = renamed [Replace "(G)"] $ avoidStruts $ spacing 5 $
                    withIM (1/6) (Role "buddy_list") (Mirror Grid)
rokLayout   = renamed [Replace "(R)"] $ avoidStruts $
                    reflectHoriz $ withIM (1/18) (ClassName "rokclock-Main")
                        (reflectHoriz customLayout)

-------------------------------------------------------------------------------
-- Terminal --
terminal' :: String
terminal' = "gnome-terminal"

-------------------------------------------------------------------------------
-- Keys/Button bindings --
-- modmask
modMask' :: KeyMask
modMask' = mod1Mask
