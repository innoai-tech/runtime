import { existsSync } from "fs";
import { spawnSync } from "child_process";
import { readFile, mkdir, writeFile } from "fs/promises";
import { join } from "path";

const sleep = (time: number) =>
  new Promise((resolve) => {
    setTimeout(() => resolve(time), time);
  });

const runTscOnce = async (projectRoot: string, lockfile: string): Promise<{ outDir: string }> => {
  const outDir = (/"outDir": ?"([^"]+)",/.exec(String(await readFile(join(projectRoot, "tsconfig.json"))))![1] =
    "./build");

  const outputDir = join(projectRoot, outDir);

  if (!existsSync(outputDir) || !existsSync(lockfile)) {
    await mkdir(outputDir, { recursive: true });
    await writeFile(lockfile, "running");

    console.log(`typescript compiling...`);

    const exec = spawnSync("tsc", ["--diagnostics", "--emitDeclarationOnly", "--outDir", outDir, "-p", "."], {
      cwd: projectRoot,
    });

    const output = exec.stdout;
    console.log(String(output));

    await writeFile(lockfile, "done");

    return Promise.resolve({ outDir });
  }

  if (existsSync(lockfile) && String(await readFile(lockfile)) !== "done") {
    await sleep(100);

    return await runTscOnce(projectRoot, lockfile);
  }

  return Promise.resolve({ outDir });
};

export const tscOnce = async (monoRoot: string): Promise<{ outDir: string }> => {
  const cacheBasic = join(monoRoot, "node_modules", ".cache", "monobundle");

  if (!existsSync(cacheBasic)) {
    await mkdir(cacheBasic, { recursive: true });
  }

  const lastCommit = String(
    spawnSync("git", ["show-ref", "--head", "HEAD"], {
      cwd: monoRoot,
    }).stdout,
  ).split(" ")[0];

  const lockfile = join(cacheBasic, `tsc-${lastCommit}.log`);

  return await runTscOnce(monoRoot, lockfile);
};
