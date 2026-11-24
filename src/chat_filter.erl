-module(chat_filter).

-export([main/1]).

main([]) ->
    main([<<"The blue mug arrived cracked.">>, <<"[friendly greeting]">>]);
main([Input]) ->
    main([Input, <<>>]);
main([Input, Context]) ->
    case chat_filter_client:decide(Input, Context, #{}) of
        {ok, Response} ->
            io:format("~s~n", [jsone:encode(Response)]),
            halt(0);
        {error, Reason} ->
            io:format(standard_error, "Request failed: ~p~n", [Reason]),
            halt(1)
    end.
