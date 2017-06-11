local utils = require "luacheck.utils"

local multithreading = {}

local ok, lanes = pcall(require, "lanes")
ok = ok and pcall(lanes.configure)
multithreading.has_lanes = ok
multithreading.lanes = lanes
multithreading.default_jobs = 1

if not ok then
   return multithreading
end

local cpu_number_detection_commands = {}

if utils.is_windows then
   cpu_number_detection_commands[1] = "echo %NUMBER_OF_PROCESSORS%"
else
   cpu_number_detection_commands[1] = "getconf _NPROCESSORS_ONLN 2>&1"
   cpu_number_detection_commands[2] = "sysctl -n hw.ncpu 2>&1"
   cpu_number_detection_commands[3] = "psrinfo -p 2>&1"
end

for _, command in ipairs(cpu_number_detection_commands) do
   local handler = io.popen(command)

   if handler then
      local output = handler:read("*a")
      handler:close()

      if output then
         local cpu_number = tonumber(utils.strip(output))

         if cpu_number then
            multithreading.default_jobs = math.floor(math.max(cpu_number, 1))
            break
         end
      end
   end
end

-- Worker thread reads pairs {outkey, arg} from inkey channel of linda,
-- applies func to arg and sends result to outkey channel of linda
-- until arg is nil.
local function worker_task(linda, inkey, func)
   while true do
      local _, pair = linda:receive(nil, inkey)
      local outkey, arg = pair[1], pair[2]

      if arg == nil then
         return true
      end

      linda:send(nil, outkey, func(arg))
   end
end

local worker_gen = lanes.gen("*", worker_task)

-- Maps func over array, performing at most jobs calls in parallel.
function multithreading.pmap(func, array, jobs)
   jobs = math.min(jobs, #array)

   if jobs < 2 then
      return utils.map(func, array)
   end

   local workers = {}
   local linda = lanes.linda()

   for i = 1, jobs do
      workers[i] = worker_gen(linda, 0, func)
   end

   for i, item in ipairs(array) do
      linda:send(nil, 0, {i, item})
   end

   for _ = 1, jobs do
      linda:send(nil, 0, {})
   end

   local results = {}

   for i in ipairs(array) do
      local _, result = linda:receive(nil, i)
      results[i] = result
   end

   for _, worker in ipairs(workers) do
      assert(worker:join())
   end

   return results
end

return multithreading
