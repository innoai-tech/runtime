import yargs from "yargs";
import { bundle } from "../bundle";

const opt = await yargs(process.argv.slice(2)).option("dryRun", {
  alias: "dry-run",
  type: "boolean",
}).argv;

void bundle({
  ...opt,
  ...(opt._.length > 0 ? { cwd: opt._[0] } : {}),
} as any);
