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
       h1 <- spawnPipe "/local/home/sjbx/.cabal/bin/xmobar -x 0 ~/.xmonad/xmobarrc"
       h2 <- spawnPipe "/local/home/sjbx/.cabal/bin/xmobar -x 1 ~/.xmonad/xmobarrc"
       h3 <- spawnPipe "/local/home/sjbx/.cabal/bin/xmobar -x 2 ~/.xmonad/xmobarrc"
       xmonad $ withUrgencyHook NoUrgencyHook $ gnomeConfig
              { workspaces = workspaces'
              , modMask = modMask'
              , borderWidth = borderWidth'
              , normalBorderColor = normalBorderColor'
              , focusedBorderColor = focusedBorderColor'
              , terminal = terminal'
              , logHook = logHook' h1 h2 h3
              , layoutHook = layoutHook'
              , manageHook = manageHook'
              } `additionalKeys`
              [-- windows and session
                ((modMask',               xK_w),     kill)
              , ((modMask',               xK_r),     spawn "xmonad --recompile; xmonad --restart")
              , ((modMask' .|. shiftMask, xK_w),     spawn "gnome-session-quit")
              , ((modMask' .|. shiftMask, xK_q),     spawn "xlock -mode blank")
              , ((modMask' .|. shiftMask, xK_l),     sendMessage MirrorShrink)
              , ((modMask' .|. shiftMask, xK_h),     sendMessage MirrorExpand)
              -- media
              , ((modMask', xK_F7), spawn "~/.xmonad/spotify-cli previous")
              , ((modMask', xK_F8), spawn "~/.xmonad/spotify-cli play-pause")
              , ((modMask', xK_F9), spawn "~/.xmonad/spotify-cli next")
              , ((0, 0x1008ff16),   spawn "~/.xmonad/spotify-cli previous")
              , ((0, 0x1008ff14),   spawn "~/.xmonad/spotify-cli play-pause")
              , ((0, 0x1008ff17),   spawn "~/.xmonad/spotify-cli next")
              -- volume
              , ((modMask', xK_F10), spawn "amixer set Master toggle")
              , ((modMask', xK_F11), spawn "amixer set Master 10%-")
              , ((modMask', xK_F12), spawn "amixer set Master 10%+")
              , ((0, 0x1008ff12),    spawn "amixer set Master toggle")
              , ((0, 0x1008ff11),    spawn "amixer set Master 10%-")
              , ((0, 0x1008ff13),    spawn "amixer set Master 10%+")
              -- launching
              , ((modMask',               xK_p), spawn "gnome-do")
              , ((modMask' .|. shiftMask, xK_b), spawn "firefox")
              , ((modMask' .|. shiftMask, xK_s), spawn "spotify")
              ]

-------------------------------------------------------------------------------
-- Hooks --
manageHook' :: ManageHook
manageHook' = manageHook gnomeConfig <+> manageDocks <+> (composeOne . concat $
    [ [className =? c -?> doCenterFloat | c <- myFloats ] -- float my floats
    -- shift certain apps to certain workspaces
    , [className    =? c            -?> doShift  "5-music" |   c <- myMusic    ] -- move to WS
    , [className =? "trayer"        -?> doF W.swapUp ]
    , [className    =? c            -?> doIgnore       |   c <- myIgnores  ] -- ignore desktop
    , [isFullscreen                 -?> myDoFullFloat                      ] -- special full screen
    , [isDialog                     -?> doCenterFloat <+> doF W.swapUp    ] -- float dialogs
    -- catch all...
    , [return True                  -?> doF W.swapDown                     ] -- open below, not above
    ]) 
    where
        -- by className
        myIgnores = ["Do", "Notification-daemon", "notify-osd", "stalonetray", "trayer"]
        myFloats  = ["VirtualBox", "Xmessage"]
        myMusic   = ["Spotify"]
        -- a trick for fullscreen but stil allow focusing of other WSs
        myDoFullFloat = doF W.focusDown <+> doFullFloat

logHook' h1 h2 h3 = dynamicLogWithPP customPP { ppOutput = hPutStrLn h1 }
                  >> dynamicLogWithPP customPP { ppOutput = hPutStrLn h2 }
                  >> dynamicLogWithPP customPP { ppOutput = hPutStrLn h3 }

layoutHook' = customLayout

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
customPP = defaultPP { ppCurrent = xmobarColor (Map.findWithDefault "" "orange" solarized) "" . wrap "[" "]"
                     , ppVisible = wrap "[" "]"
                     , ppTitle =  shorten 80
                     , ppSep =  "  ——  "
                     , ppWsSep = "  "
                     , ppHiddenNoWindows = xmobarColor (Map.findWithDefault "" "base01" solarized) ""
                     , ppUrgent = xmobarColor (Map.findWithDefault "" "yellow" solarized) "" . wrap "*" "*" . xmobarStrip
                     , ppSort = getSortByXineramaPhysicalRule
                     }

-- borders
borderWidth' :: Dimension
borderWidth' = 2

normalBorderColor', focusedBorderColor' :: String
normalBorderColor'  =  Map.findWithDefault "" "base01" solarized
focusedBorderColor' =  Map.findWithDefault "" "orange" solarized

-- workspaces
workspaces' :: [WorkspaceId]
workspaces' = ["1-mail", "2-work", "3-web", "4-xenia", "5-music", "6", "7", "8" , "9"]

-- layouts
customLayout = avoidStruts $ tiled ||| mtiled ||| full
  where
    nmaster  = 1     -- Default number of windows in master pane
    delta    = 2/100 -- Percentage of the screen to increment when resizing
    ratio    = 5/8   -- Defaul proportion of the screen taken up by main pane
    rt       = spacing 5 $ ResizableTall nmaster delta ratio []
    tiled    = renamed [Replace "<icon=layout-tall-black.xbm/>"] $ smartBorders rt
    mtiled   = renamed [Replace "<icon=layout-mirror-black.xbm/>"] $ smartBorders $ Mirror rt
    tab      = renamed [Replace "<icon=layout-tabbed-black.xbm/>"] $ noBorders $ tabbed shrinkText tabTheme
    full     = renamed [Replace "<icon=layout-full-black.xbm/>"] $ noBorders Full
    tabTheme = defaultTheme { decoHeight = 16
                            , activeColor = Map.findWithDefault "" "base01" solarized
                            , activeBorderColor = Map.findWithDefault "" "base00" solarized
                            , activeTextColor = Map.findWithDefault "" "base2" solarized
                            , inactiveColor = Map.findWithDefault "" "base02" solarized
                            , inactiveBorderColor = Map.findWithDefault "" "base03" solarized
                            , inactiveTextColor = Map.findWithDefault "" "base1" solarized
                            }

-------------------------------------------------------------------------------
-- Terminal --
terminal' :: String
terminal' = "gnome-terminal"

-------------------------------------------------------------------------------
-- Keys/Button bindings --
-- modmask
modMask' :: KeyMask
modMask' = mod4Mask
