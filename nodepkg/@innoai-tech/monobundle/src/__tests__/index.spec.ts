import { bundle } from "../bundle";
import { dirname, join } from "path";
// @ts-ignore
import { jest } from "@jest/globals";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

describe("monobundle", () => {
  jest.setTimeout(100000);

  it("bundle", async () => {
    await bundle({
      cwd: join(__dirname, "../../"),
    });
  });
});
