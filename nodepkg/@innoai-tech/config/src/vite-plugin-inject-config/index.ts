import { AppConfig, AppContext, stringify } from "../";
import type { Plugin } from "vite";
import { loadConfig } from "../loader";
import { join } from "path";

export const injectWebAppConfig = (): Plugin => {
  let injectEnabled = false;
  let conf: (AppConfig & AppContext) | null = null;
  let appEnv = (process.env as any).APP_ENV || "local";
  let appVersion = (process.env as any).APP_VERSION || "0.0.0";
  let appFeature = (process.env as any).APP_FEATURE || "";

  return {
    name: "vite-plugin/inject-config",
    async config(c, ce) {
      injectEnabled = (ce.command === "build");
      conf = (await loadConfig(join(c.root!, "config.ts")))({ env: injectEnabled ? "$" : appEnv, feature: appFeature });
    },
    transformIndexHtml(html) {
      return {
        html: html,
        tags: [
          {
            tag: "meta",
            attrs: {
              name: "webapp:base",
              content: stringify({
                name: conf!.name,
                env: injectEnabled ? "__ENV__" : appEnv,
                version: appVersion,
              }),
            },
          },
          {
            tag: "meta",
            attrs: {
              name: "webapp:config",
              content: injectEnabled ? "__APP_CONFIG__" : stringify(conf!.config as any),
            },
          },
        ],
      };
    },
  };
};
