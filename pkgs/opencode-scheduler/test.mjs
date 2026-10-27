import assert from 'node:assert/strict';
import plugin from './index.js';
import { execFileSync } from 'node:child_process';
import { cronToSystemdCalendars } from './upstream.js';

for (const cron of ['0 9 * * *', '0 9 * * 1', '0 0 1 1 *', '*/15 * * * *', '0 9 1 * 1']) {
  const calendars = cronToSystemdCalendars(cron);
  assert(calendars.length > 0);
  for (const calendar of calendars) {
    execFileSync('systemd-analyze', ['calendar', calendar], { stdio: 'pipe' });
  }
}

const v1 = await plugin.server({ directory: '/tmp/project' });
assert.equal(Object.keys(v1.tool).length, 11);
for (const args of [
  { name: 'test', source: 'x;touch /tmp/injected' },
  { name: 'test\nExecStart=bad' },
  { name: 'test', workdir: 'relative' },
  { name: '---' },
]) {
  await assert.rejects(v1.tool.schedule_job.execute({
    schedule: '0 9 * * *', prompt: 'noop', ...args,
  }));
}
const definitions = [];
await plugin.setup({
  location: { directory: '/tmp/project' },
  tool: { transform: async cb => cb({ add: t => definitions.push(t) }) },
});
assert.equal(definitions.length, 11);
for (const t of definitions) assert.equal(t.input.type, 'object');
await assert.rejects(definitions.find(t => t.name === 'schedule_job').execute({
  name: 'test', schedule: '0 9 * * *', prompt: 'noop', source: '../escape',
}));
console.log('PASS: both plugin APIs, all tool schemas, unsafe-input rejection');
