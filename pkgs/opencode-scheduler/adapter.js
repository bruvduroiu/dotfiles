import { SchedulerPlugin, object, toJSONSchema, schedulerDirectory } from './upstream.js';
import { isAbsolute } from 'node:path';

// One set of tools and job files for OpenWork's v1 and standalone OpenCode v2.
async function tools(directory) {
  const plugin = await SchedulerPlugin();
  for (const [name, tool] of Object.entries(plugin.tool)) {
    const execute = tool.execute;
    tool.execute = async (input, context) => {
      const args = object(tool.args).parse(input);
      for (const key of ['name', 'source', 'workdir', 'scopeRoot', 'directory']) {
        if (typeof args[key] === 'string' && /[\r\n\0]/.test(args[key])) {
          throw new Error(`${key} cannot contain control characters`);
        }
      }
      // Upstream interpolates source into filenames and systemctl commands.
      if (args.source && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(args.source)) {
        throw new Error('source must contain only lowercase letters, digits and single hyphens');
      }
      if (name === 'schedule_job') {
        args.workdir ??= directory;
        if (!args.workdir || !isAbsolute(args.workdir)) {
          throw new Error('Provide an absolute workdir for the scheduled job');
        }
        if (!/[a-z0-9]/i.test(args.name)) throw new Error('Job name must contain letters or digits');
      }
      if (name === 'list_jobs' && !args.allScopes) args.scopeRoot ??= directory;
      if (name === 'install_skill') args.directory ??= directory;
      return schedulerDirectory.run(directory, () => execute(args, context));
    };
  }
  return plugin.tool;
}

export default {
  id: 'opencode-scheduler',
  async server(context) {
    return { tool: await tools(context.directory) };
  },
  async setup(context) {
    const definitions = await tools(context.location.directory);
    await context.tool.transform((editor) => {
      for (const [name, tool] of Object.entries(definitions)) {
        editor.add({
          name,
          description: tool.description,
          input: toJSONSchema(object(tool.args)),
          async execute(input, execution) {
            return { content: await tool.execute(input, execution) };
          },
        });
      }
    });
  },
};
