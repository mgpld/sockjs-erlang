-module(sockjs_util).

-export([rand32/0]).
-export([guid/0]).
-export([encode_frame/1]).

%% --------------------------------------------------------------------------

-spec rand32() -> non_neg_integer().
rand32() ->
    case get(random_seeded) of
        undefined ->
            {MegaSecs, Secs, MicroSecs} = now(),
            random:seed(MegaSecs, Secs, MicroSecs),
            put(random_seeded, true);
        _Else ->
            ok
    end,
    random:uniform(erlang:trunc(math:pow(2,32)))-1.

-spec guid() -> binary().
guid() ->
    list_to_binary(
      safe_encode(
        erlang:md5(
          term_to_binary({rand32(), rand32(), rand32(), rand32()})
         ))).

safe_encode(Binary) ->
    Base64 = base64:encode_to_string(Binary),
    %% Replace '+' and '/' if necessary
    lists:map(fun ($/) -> $-;
                  ($+) -> $_;
                  (C)  -> C
          end, Base64).


-spec encode_frame({open, nil}) -> iodata();
                  ({close, {non_neg_integer(), string()}}) -> iodata();
                  ({data, list(iodata())}) -> iodata().
encode_frame({open, nil}) ->
    <<"o">>;
encode_frame({close, {Code, Reason}}) ->
    [<<"c">>,
     sockjs_json:encode([Code, list_to_binary(Reason)])];
encode_frame({data, L}) ->
    [<<"a">>,
     sockjs_json:encode([iolist_to_binary(D) || D <- L])].

