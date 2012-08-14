open Logging

include Namespace.Unsupported

let ( |> ) a b = b a

let general_params = [
	"coalesce", disable_coalesce;
	"conflict", disable_conflict;
	"commit", disable_conflict;
	"newconn", disable_newconn;
	"endconn", disable_endconn;
	"transaction", disable_transaction;
]

let read t (perms: Perms.t) (path: Store.Path.t) =
	match Store.Path.to_string_list path with
		| "request" :: [] -> ""
		| "reply-ok" :: [] -> ""
		| "reply-err" :: [] -> ""
		| "request" :: x :: [] -> if List.mem x !disable_request then "1" else raise Store.Path.Doesnt_exist
		| "reply-ok" :: x :: [] -> if List.mem x !disable_reply_ok then "1" else raise Store.Path.Doesnt_exist
		| "reply-err" :: x :: [] -> if List.mem x !disable_reply_err then "1" else raise Store.Path.Doesnt_exist
		| x :: [] ->
			if List.mem_assoc x general_params
			then if !(List.assoc x general_params) then "1" else raise Store.Path.Doesnt_exist
			else raise Store.Path.Doesnt_exist
		| _ -> raise Store.Path.Doesnt_exist

let exists t perms path = try ignore(read t perms path); true with Store.Path.Doesnt_exist -> false

let write t creator perms path value =
	let f list value key = match value with
		| "1" -> if not(List.mem key !list) then list := key :: !list
		| _ -> raise (Invalid_argument value) in
	match Store.Path.to_string_list path with
		| "request" :: x :: [] -> f disable_request value x
		| "reply-ok" :: x :: [] -> f disable_reply_ok value x
		| "reply-err" :: x :: [] -> f disable_reply_err value x
		| x :: [] ->
			begin
				if List.mem_assoc x general_params then
					(List.assoc x general_params) := match value with
						| "1" -> true
						| _ -> raise (Invalid_argument value)
			end
		| _ -> raise Store.Path.Doesnt_exist

let list t perms path =
	Printf.fprintf stderr "hello\n%!";
	match Store.Path.to_string_list path with
		| [] -> [ "request"; "reply-ok"; "reply-err" ] @ (List.map fst (List.filter (fun (_, b) -> !b) general_params))
		| "request" :: [] -> !disable_request
		| "reply-ok" :: [] -> !disable_reply_ok
		| "reply-err" :: [] -> !disable_reply_err
		| _ -> []

let rm t perms path =
	let f list key = list := List.filter (fun x -> x <> key) !list in
	match Store.Path.to_string_list path with
		| "request" :: x :: [] -> f disable_request x
		| "reply-ok" :: x :: [] -> f disable_reply_ok x
		| "reply-err" :: x :: [] -> f disable_reply_err x
		| x :: [] ->
			if List.mem_assoc x general_params
			then (List.assoc x general_params) := false
			else raise Store.Path.Doesnt_exist
		| _ -> raise Store.Path.Doesnt_exist
