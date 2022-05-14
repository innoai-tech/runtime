import { parse } from "./configvalue";

export type BaseConfig = { name: string; env: string; version: string };

const getWebAppConfigValue = (key: string) => {
  return globalThis.document?.querySelector(`meta[name="webapp:${key}"]`)?.getAttribute("content") || "";
};

export const confLoader = <TKeys extends string>() => {
  const base = parse(getWebAppConfigValue("base"));
  const config = parse(getWebAppConfigValue("config"));

  return (): { [key in TKeys]: string } & BaseConfig => {
    return {
      app: base,
      ...config,
    } as any;
  };
};
