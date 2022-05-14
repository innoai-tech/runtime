import { BaseConfig, stringify } from "../";
import type { Plugin } from "vite";

export const injectWebAppConfig = (base: BaseConfig, config: { [k: string]: string }): Plugin => {
  let injectEnabled = false;

  return {
    name: "vite-plugin/inject-config",
    config(_, ce) {
      injectEnabled = ce.command === "build";
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
                name: base.name,
                version: injectEnabled ? (process.env as any).PROJECT_VERSION || "0.0.0" : base.version || "",
                env: injectEnabled ? "__ENV__" : base.env,
              }),
            },
          },
          {
            tag: "meta",
            attrs: {
              name: "webapp:config",
              content: injectEnabled ? "__APP_CONFIG__" : stringify(config),
            },
          },
        ],
      };
    },
  };
};
