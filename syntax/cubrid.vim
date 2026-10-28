if exists('b:current_syntax') | finish | endif
syn case ignore
syn keyword cubridKeyword select from where insert into values update set delete create table alter drop join on as and or not null is group by order having limit union distinct begin end case when then else
syn keyword cubridType int integer bigint smallint numeric decimal float double char varchar string date time datetime timestamp boolean
syn match cubridNumber '\<\d\+\%(\.\d\+\)\?\>'
syn region cubridString start="'" skip="''" end="'"
syn match cubridComment '--.*$'
syn region cubridComment start='/\*' end='\*/'
hi def link cubridKeyword Keyword
hi def link cubridType Type
hi def link cubridNumber Number
hi def link cubridString String
hi def link cubridComment Comment
let b:current_syntax = 'cubrid'
