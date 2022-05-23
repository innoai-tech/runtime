import { loadConfig } from "../index";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

describe("loadConfig", () => {
  it("load", async () => {
    const config = await loadConfig(join(__dirname, "./__example__/config.ts"));
    const f = config({ env: "local", feature: "" });
    expect(f.config).toEqual({
      "APPS": "",
      "SRV_TEST": "//127.0.0.1:80",
    });

    const f2 = config({ env: "$", feature: "" });
    expect(f2.config).toEqual({
      "APPS": "${{ keys.demo.demo.apps }}",
      "SRV_TEST": "${{ endpoint.srv-test.apps }}",
    });
  });
});
