%% -*- coding: utf-8 -*-
%%%-------------------------------------------------------------------
%%% @author liu.huidong
%%% @copyright (C)
%%% @doc
%%% @end
%%%-------------------------------------------------------------------
-module('ShoppingCart').

-export([main/1]).
-record(sales, {promotion = [], shopping = [], balance_date, coupon, block = 0}).
main([]) ->
	getopt:usage(option_spec_list(), escript:script_name());
main(Args) ->
	OptSpecList = option_spec_list(),
	case getopt:parse(OptSpecList, Args) of
		{ok, {Options, _NonOptArgs}} ->
			 Config = proplists:get_value(config, Options),
			 Input = proplists:get_value(input_file, Options),
			try
			 Sets = handle_config(Config),
			 Sales = handle_inputfile(Input),
				calculate(Sales, Sets)
			catch
				 throw:Reason ->
					 io:format("~p~n", [Reason])
			end;
		{error, {Reason, Data}} ->
			io:format("Error: ~s ~p~n~n", [Reason, Data]),
			getopt:usage(option_spec_list(), escript:script_name())
	end.

option_spec_list() ->
	[
		%% {Name,     ShortOpt,  LongOpt,       ArgSpec,               HelpMsg}
		{help,        $?,        "help",        undefined,             "Show the program options"},
		{config,      $c,        "config",      string,                "config file"},
		{verbose,     $v,        "verbose",     integer,               "Verbosity level"},
		{input_file, undefined,  undefined,     string,                "input file"}
	].

calculate(Sales, Sets)->
	calculate(Sales, Sets, 0.0, Sales#sales.promotion).


calculate(#sales{ balance_date = undefined}, _Sets, _Acc, _PromotionsT)->
    io:format("no balance date~n");
calculate(#sales{shopping = [], promotion = _PromotionsT, balance_date = _Date, coupon = undefined}, _Sets, Acc, _PromotionsT)->
    io:format("Sum: ~.2f~n", [Acc]);
calculate(#sales{shopping = [], promotion = _PromotionsT, balance_date = Date, coupon = [DeadDate, Total, SubPrice]}, _Sets, Acc, _PromotionsT)->
   Sum =  case Date < DeadDate of
		 true ->
			  case Acc < Total of
                   true ->
	                   Acc;
				   false ->
					   Acc - SubPrice
			  end;
		 false -> Acc
	end,
	io:format("Sum: ~.2f~n", [Sum]);

calculate(Sales = #sales{shopping = [{_Goods, Count, Price} |Shoppings], promotion = []}, Sets, Acc, PromotionsT)->
   calculate(Sales#sales{shopping = Shoppings,  promotion = PromotionsT}, Sets, Acc + Count * Price, PromotionsT);

calculate(Sales = #sales{shopping = [{Goods, Count, Price} |Shoppings],
	promotion = [{Class, Date, Discount} |Promotions], balance_date = BDate}, Sets, Acc, PromotionsT)->
	Set = proplists:get_value(Class, Sets),
	case sets:is_element(Goods, Set) of
		true  ->
			case Date =:= BDate of
				true ->
					calculate(Sales#sales{shopping = Shoppings,
						promotion = PromotionsT}, Sets, Acc + Price * Count * Discount, PromotionsT);
				false->
					calculate(Sales#sales{shopping = [{Goods, Count, Price} |Shoppings],
						promotion = Promotions}, Sets, Acc, PromotionsT)
			end;
		false ->
			calculate(Sales#sales{shopping = [{Goods, Count, Price} |Shoppings],
				promotion = Promotions}, Sets, Acc, PromotionsT)
	end.


handle_inputfile(Input)->
	case filelib:is_file(Input) of
		true ->
			{ok, S}= file:open(Input,read),
			Sales = read_line(S),
			file:close(S),
			Sales;
		 false->
		    throw("input file does not exist")
	end.

read_line(S)->
   read_line(file:read_line(S), S, #sales{}).

read_line(eof, _S, Sales)->
	Sales;
read_line({ok, Str}, S, Sales)->
	Strlist = string:tokens(Str, "\n "),
    read_line(file:read_line(S), S, match(Strlist, Sales)).

match([], #sales{block = Block} = Sales)->
	Sales#sales{block = Block + 1};

match([Balance_date], #sales{balance_date = undefined, shopping = Shoppings} = Sales) when Shoppings =/= []->
    Sales#sales{balance_date = datestr2day(Balance_date)};

match([DeadDate, Total, SubPrice], #sales{coupon = undefined} = Sales)->
    Sales#sales{coupon = [datestr2day(DeadDate), erlang:list_to_integer(Total), string2float(SubPrice)]};

match([Count,"*",Goods,":", Price], #sales{shopping = Acc} = Sales)->
	Sales#sales{shopping = [{list_to_binary(lists:flatten(Goods)), erlang:list_to_integer(Count), string2float(Price)} | Acc]};

match([Promotion_date,"|", Discount, "|" | T], #sales{promotion = Acc, shopping = []} = Sales)->
	Sales#sales{promotion = [{list_to_binary(lists:flatten(T)), datestr2day(Promotion_date), string2float(Discount)} | Acc]};

match(_List, _Sales)->
	throw("bad format in inputfile").

handle_config(Config)->
	case filelib:is_file(Config) of
		true ->
			{ok, List} = file:consult(Config),
			handle_config(List, []);
		false->
			throw("config file does not exist")
	end.

handle_config([], Acc)->Acc;
handle_config([{Class, Sets}|T], Acc)->
	Set = sets:from_list(Sets),
	handle_config(T, [{Class, Set} | Acc]).

datestr2day(Date)->
	Strlist = string:tokens(Date, "."),
	Date1 = list_to_tuple(lists:map(fun(X)-> list_to_integer(X) end, Strlist)),
    calendar:date_to_gregorian_days(Date1).

string2float(Str)->
	case length(string:tokens(Str, ". ")) of
		 1 -> erlang:list_to_integer(Str);
		 2 -> erlang:list_to_float(Str)
	end.