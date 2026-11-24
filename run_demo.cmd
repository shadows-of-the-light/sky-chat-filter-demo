@echo off
set "ERL_LIBS=%~dp0_build\default\lib"
erl -noshell -eval "application:ensure_all_started(hackney), application:ensure_all_started(chat_filter), Args0 = init:get_plain_arguments(), Args = case Args0 of [] -> []; [M] -> [unicode:characters_to_binary(M)]; [M, C | _] -> [unicode:characters_to_binary(M), unicode:characters_to_binary(C)] end, chat_filter:main(Args), halt(0)." -extra %*
