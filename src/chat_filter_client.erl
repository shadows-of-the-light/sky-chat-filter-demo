-module(chat_filter_client).

-export([create/2, create/3, decide/3, decide/4]).

-type result() :: #{binary() := term()}.

-spec create(binary() | map(), map()) -> {ok, result()} | {error, term()}.
create(Input, Questions) ->
    create(Input, Questions, #{}, []).

-spec decide(binary() | term(), term(), map()) -> {ok, result()} | {error, term()}.
decide(Message, Context, Options) ->
    decide(Message, Context, chat_filter_questions(), Options).

-spec decide(binary() | term(), term(), map(), map()) -> {ok, result()} | {error, term()}.
decide(Message, Context, Questions, Options) ->
    State = #{
        <<"message">> => to_binary(Message),
        <<"context">> => context_value(Context)
    },
    create(State, Questions, Options).

chat_filter_questions() ->
    #{
        <<"decision">> => #{
            <<"type">> => <<"choice">>,
            <<"instructions">> => <<"Decide whether this chat message should be sent or blocked in Sky: Children of the Light.">>,
            <<"criteria">> => #{
                <<"send">> => <<"Allow a friendly, relevant, safe message, including harmless play or slang and messages in any language.">>,
                <<"block">> => <<"Block harassment, threats, sexual or vulgar content, hate, spam, scams, grooming, self-harm encouragement, or text that is unsafe for a family-friendly game.">>
            }
        },
        <<"intent">> => #{
            <<"type">> => <<"choice">>,
            <<"instructions">> => <<"What is the message most likely trying to accomplish? Consider the conversation context.">>,
            <<"criteria">> => #{
                <<"social">> => <<"Friendly conversation or help within the game.">>,
                <<"harassment">> => <<"Insulting, humiliating, threatening, or targeting another player.">>,
                <<"sexual">> => <<"Sexual solicitation or explicit sexual content.">>,
                <<"spam">> => <<"Advertising, scams, repeated promotion, or unwanted commercial activity.">>,
                <<"neutral">> => <<"No harmful or disruptive intent.">>
            }
        },
        <<"vulgarity">> => #{
            <<"type">> => <<"score">>,
            <<"instructions">> => <<"Score vulgarity and offensiveness from 0 to 3, considering any language and obfuscated or translated wording. English examples are given for calibration only.">>,
            <<"criteria">> => [
                <<"Clean or harmless.">>,
                <<"Mild vulgarity or profanity.">>,
                <<"Clearly offensive or sexually suggestive.">>,
                <<"Severe, explicit, threatening, or hate-directed language.">>
            ]
        }
    }.

context_value(Context) ->
    case is_map(Context) orelse is_list(Context) orelse is_binary(Context) of
        true -> Context;
        false -> to_binary(Context)
    end.

to_binary(Value) when is_binary(Value) -> Value;
to_binary(Value) when is_list(Value) -> unicode:characters_to_binary(Value);
to_binary(Value) -> unicode:characters_to_binary(io_lib:format("~ts", [Value])).

-spec create(binary() | term(), map(), map()) -> {ok, result()} | {error, term()}.
create(Input, Questions, Options) ->
    create(Input, Questions, Options, []).

create(Input, Questions, Options, _InternalOptions) ->
    case api_key(Options) of
        {ok, ApiKey} ->
            Request = #{
                <<"model">> => model(Options),
                <<"input">> => input_items(Input),
                <<"questions">> => Questions
            },
            case jsone:encode(Request) of
                Body when is_binary(Body) ->
                    send(ApiKey, Body, Options);
                Error ->
                    {error, {json_encode_failed, Error}}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

api_key(Options) ->
    case maps:get(api_key, Options, os:getenv("GEMINI_API_KEY")) of
        ApiKey when is_binary(ApiKey), byte_size(ApiKey) > 0 ->
            {ok, ApiKey};
        ApiKey when is_list(ApiKey), ApiKey /= "" ->
            {ok, list_to_binary(ApiKey)};
        _ ->
            {error, missing_api_key}
    end.

input_items(Input) when is_map(Input) ->
    [#{<<"type">> => <<"text">>, <<"text">> => jsone:encode(Input)}];
input_items(Input) when is_binary(Input) ->
    [#{<<"type">> => <<"text">>, <<"text">> => Input}];
input_items(Input) when is_list(Input) ->
    case Input of
        [#{<<"type">> := _}|_] -> Input;
        _ -> [#{<<"type">> => <<"text">>, <<"text">> => unicode:characters_to_binary(Input)}]
    end;
input_items(Input) ->
    input_items(to_binary(Input)).

model(Options) ->
    maps:get(model, Options, application:get_env(chat_filter, model,
        <<"gemini-decision-1">>)).

send(ApiKey, Body, Options) ->
    Endpoint = maps:get(api_endpoint, Options,
        application:get_env(chat_filter, api_endpoint,
            <<"https://generativelanguage.googleapis.com">>)),
    ApiVersion = maps:get(api_version, Options,
        application:get_env(chat_filter, api_version, <<"v1beta">>)),
    Url = iolist_to_binary([Endpoint, "/", ApiVersion, "/decisions"]),

    Headers = [
        {<<"x-goog-api-key">>, ApiKey},
        {<<"Content-Type">>, <<"application/json">>},
        {<<"Accept">>, <<"application/json">>}
    ],

    Timeout = maps:get(timeout, Options, 30000),
    Result = hackney:request(post, Url, Headers, Body,
        [{with_body, true}, {recv_timeout, Timeout}, {connect_timeout, Timeout}]),

    case Result of
        {ok, Status, _ResponseHeaders, ResponseBody} when Status >= 200, Status < 300 ->
            decode_response(Status, ResponseBody);
        {ok, Status, _ResponseHeaders, ResponseBody} ->
            {error, #{status => Status, body => decode_error_body(ResponseBody)}};
        {error, Reason} ->
            {error, #{transport => Reason}}
    end.

decode_response(Status, ResponseBody) ->
    try jsone:decode(ResponseBody) of
        Response ->
            {ok, Response}
    catch
        Class:Reason ->
            {error, #{status => Status, json_decode_failed => {Class, Reason}}}
    end.

decode_error_body(Body) ->
    try jsone:decode(Body) of
        Decoded -> Decoded
    catch
        _:_ -> Body
    end.
