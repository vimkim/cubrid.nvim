local M = {}
function M.check()
  local doctor = require('cubrid.doctor')
  local report = require('cubrid').doctor()
  vim.health.start('CUBRID')
  for line in doctor.format(report):gmatch('[^\n]+') do vim.health.info(line) end
  if report.ok then vim.health.ok('Native diagnostic probe passed') else vim.health.error(report.error or 'Native diagnostic probe failed') end
end
return M
