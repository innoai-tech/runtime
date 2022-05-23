import json from "@rollup/plugin-json";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import del from "del";
import { existsSync, readFileSync } from "fs";
import { isEmpty, mapKeys, mapValues, merge, size, trim, trimStart } from "@innoai-tech/lodash";
import { join, relative, extname, basename, dirname } from "path";
import { OutputOptions, rollup, RollupOptions } from "rollup";
import { babel as rollupBabel } from "@rollup/plugin-babel";
import dts from "rollup-plugin-dts";
import { createAutoExternal } from "./autoExternal";
import { createLogger } from "./log";
import { tscOnce } from "./tscOnce";
import transformRequireResolveWithImport from "./babel-plugin-transform-require-resolve-with-import";
// @ts-ignore
import presetBabelEnv from "@babel/preset-env";
// @ts-ignore
import transformRuntime from "@babel/plugin-transform-runtime";
import { writeFile } from "fs/promises";
import { execSync } from "child_process";

const resolveProjectRoot = (p: string): string => {
  const pnpmWorkspaceYAML = join(p, "./pnpm-workspace.yaml");

  if (!existsSync(pnpmWorkspaceYAML)) {
    return resolveProjectRoot(join(p, "../"));
  }

  return p;
};

const entryAlias = (entry: string) => (entry === "." ? "index" : trimStart(entry, "./"));

export interface MonoBundleOptions {
  env: "browser" | "node";
  bin: { [k: string]: string };
  exports: { [k: string]: string };
  build: {
    clean: boolean;
  };
}

const patchPkg = async (projectRoot: string, cwd: string, pkg: { [k: string]: any }) => {
  const finalPkg = {
    ...pkg,
    type: "module",
    repository: {
      type: "git",
      url: `ssh://${trim(String(execSync("git remote get-url origin")), "\n")}`,
      directory: relative(projectRoot, cwd),
    },
  };

  await writeFile(
    join(cwd, "package.json"),
    `${JSON.stringify(finalPkg, null, 2)}
`,
  ); // line break here to make prettier happy
};

export const bundle = async ({ cwd = process.cwd(), dryRun }: { cwd?: string; dryRun?: boolean }) => {
  const projectRoot = resolveProjectRoot(cwd);

  const pkg = JSON.parse(String(readFileSync(join(cwd, "package.json")))) as { [k: string]: any };

  // skip if monobundle not defined
  if (!pkg["monobundle"] || !pkg["monobundle"].exports) {
    return await patchPkg(projectRoot, cwd, pkg);
  }

  if (size(pkg["monobundle"].exports) == 0) {
    return await patchPkg(projectRoot, cwd, pkg);
  }

  const options: MonoBundleOptions = merge(
    {
      bin: {},
      exports: {},
      build: {
        clean: true,
      },
    },
    pkg["monobundle"] || {},
  );

  const logger = createLogger(pkg["name"]);

  const autoExternal = createAutoExternal(projectRoot, pkg, {
    logger,
  });

  const inputs = mapValues(
    {
      ...options.bin,
      ...mapKeys(options.exports, (_, k) => {
        return entryAlias(k);
      }),
    },
    (entry, _) => join(cwd, entry),
  );

  const outputBase: OutputOptions = {
    dir: cwd,
    format: "es",
  };

  const resolveRollupOptions: Array<() => Promise<RollupOptions>> = [
    () =>
      Promise.resolve({
        input: inputs,
        output: {
          ...outputBase,
          entryFileNames: "[name].mjs",
          chunkFileNames: "[name]-[hash].mjs",
        },
        plugins: [
          autoExternal(),
          nodeResolve({
            extensions: [".ts", ".tsx", ".mjs", "", ".js", ".jsx"],
          }),
          json(),
          rollupBabel({
            root: projectRoot,
            babelrc: true,
            presets: [
              [
                presetBabelEnv,
                {
                  targets: {
                    node: "16",
                  },
                },
              ],
            ],
            plugins: [
              [
                transformRuntime,
                {
                  version: "7.x",
                  corejs: { version: 3, proposals: true },
                  // useESModules: true,
                },
              ],
              transformRequireResolveWithImport,
            ],
            babelHelpers: "runtime",
            envName: `rollup_${options.env}`.toUpperCase(),
            exclude: "node_modules/**",
            extensions: [".ts", ".tsx", "", ".jsx"],
          }),
        ],
      }),

    async () => {
      const { outDir } = await tscOnce(projectRoot);

      const indexForDts = mapValues(inputs, (input) => {
        const f = join(outDir, relative(projectRoot, input));
        return join(projectRoot, dirname(f), basename(f, extname(f))) + ".d.ts";
      });

      return {
        input: indexForDts,
        output: {
          ...outputBase,
          entryFileNames: "[name].d.ts",
          chunkFileNames: "[name]-[hash].d.ts",
        },
        plugins: [
          autoExternal(false),
          dts({
            respectExternal: true,
          }) as any,
        ],
      };
    },
  ];

  logger.warning("bundling");

  if (options.build.clean) {
    await del([
      "*.mjs",
      "*.d.ts",
    ], {
      cwd: cwd,
    });
  }

  let finalFiles: string[] = [];

  for (const resolveRollupOption of resolveRollupOptions) {
    const rollupOption = await resolveRollupOption();

    const files = await rollup(rollupOption).then((bundle) => {
      return Promise.all(
        ([] as OutputOptions[]).concat(rollupOption.output!).map((output) => {
          if (dryRun) {
            return [];
          }
          return bundle.write(output).then((ret) => {
            if (output.dir) {
              return (ret.output || []).map((o) => join(relative(cwd, output.dir!), o.fileName));
            }
            return relative(cwd, output.file!);
          });
        }),
      );
    });

    finalFiles = finalFiles.concat(files.flat());
  }

  logger.success("bundled", ...finalFiles);

  const unused = autoExternal.warningAndGetUnused();

  for (const dep in unused.peerDeps) {
    delete pkg["peerDependencies"][dep];
  }

  for (const dep in unused.deps) {
    delete pkg["dependencies"][dep];
  }

  ["type", "types", "main", "module"].forEach((field) => {
    delete pkg[field];
  });

  const exports = mapValues(options.exports, (_, e) => {
    const distName = entryAlias(e);
    return {
      import: {
        types: `./${distName}.d.ts`,
        default: `./${distName}.mjs`,
      },
    };
  });

  const finalPkg = {
    ...pkg,
    type: "module",
    bin: options.bin ? mapValues(options.bin, (_, name) => `./${name}.mjs`) : undefined,
    exports,
    types: exports["."]!["import"]["types"],
    files: ["*.mjs", "*.d.ts"],
    dependencies: isEmpty(pkg["dependencies"]) ? undefined : (pkg["dependencies"] as { [k: string]: string }),
    peerDependencies: isEmpty(pkg["peerDependencies"])
      ? undefined
      : (pkg["peerDependencies"] as { [k: string]: string }),
    scripts: {
      ...(pkg["scripts"] as { [k: string]: string }),
      prepublishOnly: `${relative(cwd, projectRoot)}/node_modules/.bin/monobundle`,
    },
  };


  await patchPkg(projectRoot, cwd, finalPkg);

  await writeFile(
    join(cwd, ".gitignore"), `
*.mjs
*.d.ts
`,
  );

  return;
};
