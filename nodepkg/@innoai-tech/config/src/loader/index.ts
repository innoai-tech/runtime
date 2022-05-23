import * as vm from "vm";
import { createContext } from "vm";
import { build } from "esbuild";
import type { AppConfig, AppContext, ConfigBuilder } from "../config";
import { isFunction, mapValues } from "@innoai-tech/lodash";

export const loadConfig = async (configFile: string) => {
  const ret = await build({
    entryPoints: [configFile],
    format: "cjs",
    outfile: "config.json",
    sourcemap: false,
    bundle: true,
    splitting: false,
    globalName: "conf",
    write: false,
  });

  const ctx = {
    module: {
      exports: {},
    },
  };

  vm.runInContext(String(ret.outputFiles[0]!.text), createContext(ctx));

  const conf = ctx.module.exports as { CONFIG: AppConfig };

  return (configCtx: AppContext): AppConfig & AppContext => {
    return {
      ...conf.CONFIG,
      config: mapValues(conf.CONFIG.config, (fnOrValue: ConfigBuilder | string) =>
        isFunction(fnOrValue) ? fnOrValue(configCtx) : fnOrValue,
      ),
      env: configCtx.env,
      feature: configCtx.feature,
    };
  };
};