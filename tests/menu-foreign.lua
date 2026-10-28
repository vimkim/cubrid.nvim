local base=assert(vim.env.CUBRID_TEST_DIR)
local function log(s) vim.fn.writefile({s},base..'/menu-observed.txt','a') end
vim.cmd('filetype plugin indent on')
vim.opt.completeopt={'menuone','noselect'}
vim.lsp.set_log_level('trace')
require('cubrid').setup({server_path=vim.env.CUBRID_TEST_SERVER})
vim.cmd('edit '..base..'/menu.csql')
assert(vim.wait(12000,function() local c=vim.lsp.get_clients({name='cubrid'}); return #c==1 and c[1].initialized end,50))
local prefix="SELECT '가😀'; "
vim.api.nvim_buf_set_lines(0,0,-1,false,{prefix..'SELect'})
vim.api.nvim_win_set_cursor(0,{1,#prefix+3})
log('omnifunc='..vim.bo.omnifunc..' cursor='..vim.inspect(vim.api.nvim_win_get_cursor(0)))
vim.defer_fn(function() vim.api.nvim_input('i<C-X><C-O>') end,100)
vim.defer_fn(function()
 local c=vim.fn.complete_info({'mode','pum_visible','selected','items'})
 log('completion='..vim.inspect(c):gsub('\n',' '))
 if #c.items==0 then log('FAIL no menu'); vim.cmd('cquit 2'); return end
 local target
 for i,item in ipairs(c.items) do if item.word=='SELECT' then target=i-1 end end
 if not target then log('FAIL no SELECT');vim.cmd('cquit 3');return end
 vim.bo.filetype='sql'
 vim.fn.complete(#prefix+1,{{word='OTHER',user_data='foreign-provider'}})
 log('foreign-before='..vim.inspect(vim.fn.complete_info({'pum_visible','items'})):gsub('\n',' '))
end,1500)
vim.defer_fn(function()
 local info=vim.fn.complete_info({'pum_visible','items'})
 log('foreign-after='..vim.inspect(info):gsub('\n',' '))
 if info.pum_visible~=1 or not info.items[1] or info.items[1].word~='OTHER' then
   log('FAIL foreign menu cancelled after filetype detach');vim.cmd('cquit 5')
 else log('PASS foreign menu preserved');vim.cmd('qa!') end
end,2500)
