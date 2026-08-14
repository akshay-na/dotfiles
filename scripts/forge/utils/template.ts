const TEMPLATE_ROOT = new URL("../templates/", import.meta.url);

export function templateUrl(relativePath: string): URL {
  return new URL(relativePath, TEMPLATE_ROOT);
}

/** Read a file from `templates/`. Works with `deno compile --include`. */
export async function readTemplate(relativePath: string): Promise<string> {
  return await Deno.readTextFile(templateUrl(relativePath));
}

/** Replace `{{name}}` placeholders. Unknown keys throw. */
export function renderTemplate(
  template: string,
  vars: Record<string, string>,
): string {
  return template.replaceAll(
    /\{\{\s*([A-Za-z0-9_]+)\s*\}\}/g,
    (_match, key: string) => {
      if (!(key in vars)) {
        throw new Error(`Missing template variable: ${key}`);
      }
      return vars[key];
    },
  );
}

export async function renderTemplateFile(
  relativePath: string,
  vars: Record<string, string>,
): Promise<string> {
  const template = await readTemplate(relativePath);
  return renderTemplate(template, vars);
}
