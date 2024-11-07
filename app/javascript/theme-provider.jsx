// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { CssBaseline } from "@mui/material";
import { createTheme, ThemeProvider as MuiThemeProvider } from "@mui/material/styles";
import PropTypes from "prop-types";
import { useMemo, useEffect, useLayoutEffect, createContext, useReducer, useContext, useCallback } from "react";
import createCache from "@emotion/cache";
import { prefixer } from "stylis";
import rtlPlugin from "stylis-plugin-rtl";
import { CacheProvider } from "@emotion/react";

import theme, { colors, drawerWidth, fontFamily, fontSizes, setCssVars, shadows, spacing } from "./theme";
import useMemoizedSelector from "./libs/use-memoized-selector";
import { getAppDirection } from "./components/i18n/selectors";

const themeInitialOptions = {
  direction: "ltr"
};

const emotionCacheCommon = {
  prepend: true,
  container: document.getElementsByName("emotion-insertion-point")[0],
  nonce: document.querySelector('meta[property="csp-nonce"]')?.getAttribute("content")
};

const rtlCache = createCache({
  key: "rtl",
  stylisPlugins: [prefixer, rtlPlugin],
  ...emotionCacheCommon
});

const ltrCache = createCache({
  key: "css",
  ...emotionCacheCommon
});

const useEnhancedEffect = typeof window === "undefined" ? useEffect : useLayoutEffect;

// eslint-disable-next-line import/exports-last
export const DispatchContext = createContext(() => {});

DispatchContext.displayName = "ThemeDispatchContext";

function ThemeProvider({ children }) {
  const directionFromStore = useMemoizedSelector(state => getAppDirection(state));

  const [options, dispatch] = useReducer((state, action) => {
    switch (action.type) {
      case "CHANGE": {
        return {
          ...state,
          direction: action.payload.direction || state.direction
        };
      }
      default:
        throw new Error(`Unrecognized type ${action.type}`);
    }
  }, themeInitialOptions);

  const { direction } = options;

  useEnhancedEffect(() => {
    document.dir = direction;
    document.body.dir = direction;
  }, [direction]);

  useEffect(() => {
    if (directionFromStore && directionFromStore !== direction) {
      dispatch({ type: "CHANGE", payload: { direction: directionFromStore } });
    }
  }, [directionFromStore, direction]);

  const themeConfig = useMemo(() => {
    const muiTheme = createTheme({ ...theme, direction });

    muiTheme.components.MuiCssBaseline.styleOverrides.html = { fontSize: `var(--fs-${direction === "rtl" ? 18 : 16})` };

    muiTheme.components.MuiCssBaseline.styleOverrides[":root"] = {
      ...setCssVars("fs", fontSizes, muiTheme.typography.pxToRem),
      ...setCssVars("c", colors),
      ...setCssVars("sp", spacing, muiTheme.spacing),
      "--ff": fontFamily,
      "--fwb": muiTheme.typography.fontWeightBold,
      "--drawer": drawerWidth,
      "--shadow-0": shadows[0],
      "--shadow-1": shadows[1],
      "--spacing-0-1": muiTheme.spacing(0, 1),
      "--transition": muiTheme.transitions.create("margin", {
        easing: muiTheme.transitions.easing.sharp,
        duration: muiTheme.transitions.duration.leavingScreen
      })
    };

    return muiTheme;
  }, [direction]);

  const emotionCache = direction === "rtl" ? rtlCache : ltrCache;

  return (
    <CacheProvider value={emotionCache}>
      <MuiThemeProvider theme={themeConfig}>
        <DispatchContext.Provider value={dispatch}>
          <CssBaseline />
          {children}
        </DispatchContext.Provider>
      </MuiThemeProvider>
    </CacheProvider>
  );
}

ThemeProvider.propTypes = {
  children: PropTypes.node
};

ThemeProvider.displayName = "ThemeProvider";

export default ThemeProvider;

export const useChangeTheme = () => {
  const dispatch = useContext(DispatchContext);

  return useCallback(options => dispatch({ type: "CHANGE", payload: options }), [dispatch]);
};
